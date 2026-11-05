-- Executar no SQL Editor de um projeto Supabase NOVO.
create extension if not exists pgcrypto;
create table if not exists public.shopping_lists (
 id uuid primary key default gen_random_uuid(),
 name text not null check(char_length(name) between 1 and 80),
 owner_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
create table if not exists public.list_members (
 list_id uuid not null references public.shopping_lists(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(list_id,user_id)
);
create table if not exists public.shopping_items (
 id uuid primary key default gen_random_uuid(),
 list_id uuid not null references public.shopping_lists(id) on delete cascade,
 name text not null check(char_length(name) between 1 and 120),
 quantity numeric(10,2) not null default 1 check(quantity > 0 and quantity <= 999999),
 unit text not null default 'un.' check(unit in ('un.','kg','g','L','ml','emb.')),
 category text not null default 'Outros' check(category in ('Fruta e legumes','Laticínios','Carnes e peixe','Padaria','Mercearia','Bebidas','Congelados','Limpeza','Higiene','Outros')),
 price numeric(12,2) check(price is null or (price >= 0 and price <= 999999)),
 notes text not null default '' check(char_length(notes)<=250),
 checked boolean not null default false,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create index if not exists shopping_items_list_idx on public.shopping_items(list_id);
create table if not exists public.list_invites (
 id uuid primary key default gen_random_uuid(),
 list_id uuid not null references public.shopping_lists(id) on delete cascade,
 code_hash text not null unique,
 expires_at timestamptz not null,
 max_uses integer not null default 10,
 uses integer not null default 0,
 created_at timestamptz not null default now()
);
create index if not exists list_invites_list_idx on public.list_invites(list_id);
alter table public.shopping_lists enable row level security;
alter table public.list_members enable row level security;
alter table public.shopping_items enable row level security;
alter table public.list_invites enable row level security;
create or replace function public.is_list_member(p_list_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
 select exists(select 1 from public.list_members where list_id=p_list_id and user_id=(select auth.uid()));
$$;
revoke all on function public.is_list_member(uuid) from public;
grant execute on function public.is_list_member(uuid) to authenticated;
create policy "members read lists" on public.shopping_lists for select to authenticated using(public.is_list_member(id));
create policy "owner updates lists" on public.shopping_lists for update to authenticated using(owner_id=(select auth.uid())) with check(owner_id=(select auth.uid()));
create policy "owner deletes lists" on public.shopping_lists for delete to authenticated using(owner_id=(select auth.uid()));
create policy "members read members" on public.list_members for select to authenticated using(public.is_list_member(list_id));
create policy "members read items" on public.shopping_items for select to authenticated using(public.is_list_member(list_id));
create policy "members add items" on public.shopping_items for insert to authenticated with check(public.is_list_member(list_id) and created_by=(select auth.uid()));
create policy "members update items" on public.shopping_items for update to authenticated using(public.is_list_member(list_id)) with check(public.is_list_member(list_id));
create policy "members delete items" on public.shopping_items for delete to authenticated using(public.is_list_member(list_id));
-- Os códigos de convite não podem ser consultados diretamente.
create or replace function public.create_shopping_list(p_name text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'É necessário iniciar sessão'; end if;
 p_name:=btrim(p_name);
 if length(p_name) not between 1 and 80 then raise exception 'Nome inválido'; end if;
 insert into public.shopping_lists(name,owner_id) values(p_name,auth.uid()) returning id into v_id;
 insert into public.list_members(list_id,user_id) values(v_id,auth.uid());
 return v_id;
end $$;
create or replace function public.create_invite(p_list_id uuid)
returns text language plpgsql security definer set search_path = '' as $$
declare v_code text;
begin
 if not exists(select 1 from public.shopping_lists where id=p_list_id and owner_id=auth.uid()) then raise exception 'Apenas o criador pode convidar pessoas'; end if;
 v_code:=upper(encode(gen_random_bytes(10),'hex'));
 insert into public.list_invites(list_id,code_hash,expires_at,max_uses)
 values(p_list_id,encode(digest(v_code,'sha256'),'hex'),now()+interval '7 days',10);
 return v_code;
end $$;
create or replace function public.join_list_by_code(p_code text)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_inv public.list_invites%rowtype;
begin
 if auth.uid() is null then raise exception 'É necessário iniciar sessão'; end if;
 update public.list_invites set uses=uses+1
 where id=(select id from public.list_invites where code_hash=encode(digest(upper(btrim(p_code)),'sha256'),'hex') and expires_at>now() and uses<max_uses limit 1)
 and expires_at>now() and uses<max_uses
 returning * into v_inv;
 if not found then raise exception 'Código inválido, expirado ou sem utilizações disponíveis'; end if;
 insert into public.list_members(list_id,user_id) values(v_inv.list_id,auth.uid()) on conflict do nothing;
 return v_inv.list_id;
end $$;
create or replace function public.leave_list(p_list_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
 if exists(select 1 from public.shopping_lists where id=p_list_id and owner_id=auth.uid()) then raise exception 'O criador não pode sair: deve eliminar a lista'; end if;
 delete from public.list_members where list_id=p_list_id and user_id=auth.uid();
end $$;
revoke all on function public.create_shopping_list(text) from public;
revoke all on function public.create_invite(uuid) from public;
revoke all on function public.join_list_by_code(text) from public;
revoke all on function public.leave_list(uuid) from public;
grant execute on function public.create_shopping_list(text),public.create_invite(uuid),public.join_list_by_code(text),public.leave_list(uuid) to authenticated;
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='shopping_items') then
 alter publication supabase_realtime add table public.shopping_items;
 end if;
end $$;
