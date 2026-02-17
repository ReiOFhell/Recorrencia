# Recorrência

App Flutter cloud-first com Supabase para Feed, Fórum, Dossiês, Busca, Arquivo/Console e subsistema Inkosi.

## Stack
- Flutter + Dart
- Riverpod + go_router
- Supabase (Auth, Postgres, Storage, Realtime, Edge Functions, Scheduled Functions)

## 1) Pré-requisitos
- Flutter SDK 3.22+
- Supabase CLI
- Node/Deno (para Edge Functions)

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

## 6) Configurar app Flutter
Passe variáveis:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## 7) Realtime
Habilite realtime nas tabelas:
- posts, post_comments
- forum_topics, forum_replies
- dossiers, dossier_comments
- notifications
- inkosi_signals

## 8) Segurança / RLS
Todas as tabelas no migration estão com RLS habilitado e policies por guild/role.
Ações sensíveis são por Edge Functions (convites, roles/status, moderação, Inkosi manual).

## 9) Cron (scheduled)
- `inkosi_random_cron`: `0 */6 * * *`
- `inkosi_cleanup`: `15 3 * * *`

## Estrutura
```
lib/
  app/
  core/
  features/
  data/
  domain/
  presentation/
supabase/
  migrations/
  functions/
```
