# Recorrência (V1 simplificado sem convite)

App Flutter cloud-first com Supabase para Feed, Fórum, Dossiês, Busca, Arquivo/Console e subsistema Inkosi.

## Visão V1 (produto)
- ✅ Login Email/Senha
- ✅ Login Google
- ✅ Auto-registro sem token de convite
- ✅ Guild única padrão: `Recorrência`
- ✅ Primeiro usuário vira `leader` automaticamente
- ✅ Próximos usuários entram como `observer`

## Auth em Edge Functions com ES256
Com JWT Signing Keys assimétricas (ES256), o gateway de Functions pode falhar com `verify_jwt = true` em alguns ambientes.

Por isso, neste projeto:
- `verify_jwt = false` nas functions autenticadas
- validação JWT manual dentro da função:
  1. parse de `Authorization: Bearer <token>`
  2. `supabase.auth.getUser(token)`
  3. validação de role/status em `guild_members` quando necessário

`service_role` é usada somente no servidor (Edge Functions), nunca no Flutter.

## Pré-requisitos
- Flutter SDK 3.22+
- Supabase CLI
- Deno

## Setup Supabase
1. Criar projeto no Supabase.
2. Em **Auth > Providers** habilitar:
   - Email/Password
   - Google
3. Configurar Google OAuth (web + Android) e SHA-1 Android.
4. Deep link Android:
   - `com.demoncorp.recorrencia://login-callback/`
5. Criar bucket de storage: `attachments`.

## Banco
```bash
supabase db push
```

## Deploy das Edge Functions
```bash
supabase functions deploy ensure_membership
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

> `consume_invite_and_join` foi mantida para V1.1, mas **não faz parte do fluxo V1 atual**.

Secrets:
```bash
supabase secrets set BOOTSTRAP_SECRET=seu_segredo
```

## Fluxo de entrada V1
1. Onboarding + consentimento Inkosi.
2. Login (email/senha ou Google).
3. App chama `ensure_membership` automaticamente.
4. `ensure_membership` garante:
   - profile do usuário
   - guild `Recorrência` existente (cria se não existir)
   - membership ativa (`leader` para primeiro usuário, `observer` para os demais)
5. Usuário entra no app.

## Exemplo de chamada autenticada (ensure_membership)
```bash
curl -X POST \
  'https://<project-ref>.functions.supabase.co/ensure_membership' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <access_token>' \
  -d '{"display_name":"Fulano"}'
```

Resposta:
```json
{
  "ok": true,
  "profile": {...},
  "guild": {...},
  "membership": {...},
  "is_first_leader": false
}
```

## Rodar app
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

## Realtime
Habilitar realtime em:
- posts, post_comments
- forum_topics, forum_replies
- dossiers, dossier_comments
- notifications
- inkosi_signals

## Cron
- `inkosi_random_cron`: `0 */6 * * *`
- `inkosi_cleanup`: `15 3 * * *`
