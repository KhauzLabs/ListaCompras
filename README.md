# ListaCompras

PWA de listas de compras partilhadas, com autenticação por email, Supabase e GitHub Pages. Projeto independente da app Escala.

## Configuração (uma única vez)

1. **Concluído:** Repositório `KhauzLabs/ListaCompras` criado, independente do `Escala-pages`.
2. **Concluído:** Projeto Supabase `onftbgxifnloftparnvw` ligado.
3. **Concluído:** Migração SQL `initial_listacompras_schema` executada, incluindo tabelas, RLS e Realtime.
4. Em Supabase → Authentication → Providers, ativar Email/OTP (Magic Link). Em Authentication → URL Configuration, definir **Site URL** como `https://khauzlabs.github.io/ListaCompras/` e adicionar o mesmo URL em **Redirect URLs** (incluindo `/` final). Se usares domínio personalizado, substitui o URL.
5. **Concluído:** `config.js` atualizado com a URL do projeto e a chave publicável. **Nunca usar service_role ou secret API key no frontend**.
6. **Concluído:** Ficheiros enviados à raiz do repositório, incluindo `supabase/`.
7. **Pendente de confirmação:** GitHub → Settings → Pages → Build and deployment → Source → **GitHub Actions**. O workflow `.github/workflows/pages.yml` publica automaticamente as alterações após a ativação. Verifica a URL `https://khauzlabs.github.io/ListaCompras/`.
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
- As tabelas e o RLS foram verificados na base de dados real; ainda falta um teste funcional de autenticação e sincronização entre duas contas.

## Segurança e desenvolvimento

O ficheiro `config.js` contém **apenas** a URL e chave pública do Supabase. As autorizações são aplicadas no servidor por RLS. Nunca enviar para o repositório passwords, tokens pessoais ou a `service_role` do Supabase.

Para testar localmente: `python -m http.server 8080` na raiz do projeto e abrir `http://localhost:8080`. Adiciona esse endereço às Redirect URLs do Supabase para autenticação local.

## Diagnóstico de publicação

O workflow `.github/workflows/pages.yml` é executado a cada push na branch `main` depois de o GitHub Pages estar configurado com Source = GitHub Actions. Se o endereço mostrar 404, consultar o separador Actions e Settings > Pages para verificar se o deploy foi concluído.
