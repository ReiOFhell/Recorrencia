# Recorrência

App Flutter cloud-first com Supabase para Feed, Fórum, Dossiês, Busca, Arquivo/Console e subsistema Inkosi.

## Diagnóstico do 401 `Invalid JWT` em Edge Functions
Quando `verify_jwt = true` no gateway das Functions, alguns projetos com **JWT Signing Keys assimétricas (ES256)** podem retornar `401 Invalid JWT` antes da execução do código da função.

### Causa confirmada no projeto
- As functions autenticadas estavam com validação no gateway (`verify_jwt = true`).
- O erro ocorria **antes** do código da função rodar.
- O token de acesso era válido via Auth API, mas bloqueado no gateway.

### Solução aplicada
- `verify_jwt = false` para functions autenticadas no `supabase/config.toml`.
- Validação robusta do Bearer token **dentro das functions**:
  - extrai `Authorization: Bearer <token>`
  - valida com `admin.auth.getUser(token)`
  - rejeita token inválido/expirado
  - verifica role/status em `guild_members` para ações sensíveis
- Auditoria mantida (`audit_log`) para ações administrativas.

> Segurança: o cliente segue usando apenas `anon key`. `service_role` é usada somente no ambiente das Edge Functions.

---

## Stack
- Flutter + Dart
- Riverpod + go_router
- Supabase (Auth, Postgres, Storage, Realtime, Edge Functions, Scheduled Functions)

## 1) Pré-requisitos
- Flutter SDK 3.22+
- Supabase CLI
- Deno (Edge Functions)

## 2) Configurar Supabase
1. Crie um projeto no Supabase.
2. Em **Auth > Providers** habilite:
   - Email/Password
   - Google
3. Em **Google Cloud Console**:
   - Configure OAuth consent screen
   - Crie Client ID/Secret Web para Supabase
   - Crie credenciais Android e adicione SHA-1 do keystore
4. Configure deep link Android:
   - `com.demoncorp.recorrencia://login-callback/`
5. Crie bucket de storage: `attachments`.

## 3) Banco (migrations)
```bash
supabase db push
```
Migration principal: `supabase/migrations/202602170001_init.sql`.

## 4) Deploy das Edge Functions
```bash
supabase functions deploy admin_create_invite
supabase functions deploy admin_revoke_invite
supabase functions deploy admin_set_member_role
supabase functions deploy admin_set_member_status
supabase functions deploy admin_moderate_content
supabase functions deploy consume_invite_and_join
supabase functions deploy inkosi_emit_manual
supabase functions deploy presence_heartbeat
supabase functions deploy inkosi_check_presence_milestones
supabase functions deploy inkosi_random_cron
supabase functions deploy inkosi_cleanup
supabase functions deploy bootstrap
```

Defina secrets:
```bash
supabase secrets set BOOTSTRAP_SECRET=seu_segredo
```

## 5) Bootstrap inicial (1x)
Crie primeiro usuário líder no Auth e execute:
```bash
curl -X POST \
  'https://<project-ref>.functions.supabase.co/bootstrap' \
  -H 'Content-Type: application/json' \
  -H 'x-bootstrap-secret: seu_segredo' \
  -d '{"leader_user_id":"<uuid-do-user>"}'
```

## 6) Fluxo correto de login + convite
1. Usuário autentica (email/senha ou Google).
2. App obtém `access_token` da sessão Supabase.
3. App chama `consume_invite_and_join` com header:
   - `Authorization: Bearer <access_token>`
4. Function valida token internamente e registra `guild_members`.

## 7) Como chamar function autenticada (exemplo `admin_create_invite`)
```bash
curl -X POST \
  'https://<project-ref>.functions.supabase.co/admin_create_invite' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <access_token>' \
  -d '{"guild_id":"<guild-uuid>","role":"observer","max_uses":1}'
```

### Resultado esperado
- `200` para usuário com role `leader` ativo na guild.
- `403` para roles abaixo de `leader`.
- `401` para token inválido/expirado/ausente.

## 8) Rodar app Flutter
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## 9) Realtime
Habilite realtime nas tabelas:
- posts, post_comments
- forum_topics, forum_replies
- dossiers, dossier_comments
- notifications
- inkosi_signals

## 10) Cron (scheduled)
- `inkosi_random_cron`: `0 */6 * * *`
- `inkosi_cleanup`: `15 3 * * *`
