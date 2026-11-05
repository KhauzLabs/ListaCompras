# ListaCompras

PWA de listas de compras partilhadas, com autenticação por email, Supabase e GitHub Pages. Projeto independente da app Escala.

## Configuração (uma única vez)

1. No GitHub, criar um novo repositório chamado **ListaCompras** dentro de **KhauzLabs**. Não modificar `Escala-pages`. O GitHub Pages gratuito em repositórios privados depende do plano; para alojamento gratuito, pode ser necessário um repositório **público**. Nunca guardar segredos no código.
2. Criar um **novo projeto Supabase**, separado de outras aplicações.
3. Em Supabase → SQL Editor, executar todo o ficheiro `supabase/schema.sql`.
4. Em Supabase → Authentication → Providers, ativar Email/OTP (Magic Link). Em Authentication → URL Configuration, definir **Site URL** como `https://khauzlabs.github.io/ListaCompras/` e adicionar o mesmo URL em **Redirect URLs** (incluindo `/` final). Se usares domínio personalizado, substitui o URL.
5. Em Supabase → Project Settings → API, copiar o **Project URL** e a chave **publishable/anon** para `config.js`. **Nunca usar service_role ou secret API key no frontend**.
6. Enviar os ficheiros para a raiz do novo repositório, conservando a pasta `supabase/`.
7. GitHub → Settings → Pages → Build and deployment → Deploy from a branch → `main` → `/ (root)` → Save. Aguarda o GitHub confirmar a publicação. Abre `https://khauzlabs.github.io/ListaCompras/`.
8. No Supabase, garantir que **Realtime** está disponível e testar em dois dispositivos com contas de email diferentes.

## Funcionalidades incluídas

- Autenticação por link enviado para email.
- Criar, alterar e eliminar listas.
- Adicionar, editar, apagar e marcar produtos; categorias, quantidades, unidades, notas e preço opcional.
- Total previsto e valor dos produtos marcados como comprados.
- Partilha por código aleatório (7 dias / 10 utilizações); apenas o criador pode emitir convites.
- Regras RLS de acesso: utilizadores só conseguem aceder a listas de que são membros.
- Sincronização de alterações via Supabase Realtime com atualização periódica de reserva.
- Instalação PWA e cache da interface.

## Limitações da V1

- É necessária internet para autenticação, consultar listas e escrever alterações. A interface pode estar em cache, **mas não há edição offline nem fila de sincronização**.
- O Supabase tem quotas e pode ter custos conforme utilização/plano.
- A partilha requer que cada participante tenha conta por email.
- O código de convite não identifica utilizadores: quem tiver o código pode aderir, até expirar ou esgotar utilizações. Não partilhar publicamente.
- O frontend usa a biblioteca Supabase carregada de CDN e requer uma primeira abertura online.
- Ainda não há testes reais executados contra um projeto Supabase; a implementação requer verificação após configuração.

## Segurança e desenvolvimento

O ficheiro `config.js` contém **apenas** a URL e chave pública do Supabase. As autorizações são aplicadas no servidor por RLS. Nunca enviar para o repositório passwords, tokens pessoais ou a `service_role` do Supabase.

Para testar localmente: `python -m http.server 8080` na raiz do projeto e abrir `http://localhost:8080`. Adiciona esse endereço às Redirect URLs do Supabase para autenticação local.