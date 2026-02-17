# Recorrência

Aplicativo Flutter + Supabase (cloud-first) com Feed, Fórum, Dossiês, Busca e Arquivo/Console.

## Stack
- Flutter/Dart (Riverpod + go_router)
- Supabase Auth/Postgres/Storage/Realtime/Edge Functions

## Importante (JWT ES256)
Para compatibilidade com JWT Signing Keys ES256:
- `verify_jwt = false` nas functions autenticadas
- validação do Bearer token é feita dentro das functions com `admin.auth.getUser(token)`

## Setup rápido
1. Configure Supabase URL/ANON key no app:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

2. Aplique migrations:
```bash
supabase db push
```

3. Deploy das functions:
```bash
supabase functions deploy ensure_membership
supabase functions deploy admin_list_members
supabase functions deploy admin_set_member_role
supabase functions deploy admin_set_member_status
supabase functions deploy admin_moderate_content
supabase functions deploy admin_seed_defaults
supabase functions deploy inkosi_emit_manual
supabase functions deploy admin_create_invite
supabase functions deploy admin_revoke_invite
supabase functions deploy consume_invite_and_join
supabase functions deploy presence_heartbeat
supabase functions deploy inkosi_check_presence_milestones
supabase functions deploy inkosi_random_cron
supabase functions deploy inkosi_cleanup
supabase functions deploy bootstrap
```

## Primeiro uso (V1 funcional)
1. Faça login (email/senha ou Google).
2. O app chama `ensure_membership` automaticamente.
3. Se for primeiro usuário da guild, vira `leader` automaticamente.
4. No **Arquivo > Console do Líder**, clique **Inicializar Base (Seed)** para criar categorias padrão e post de boas-vindas.
5. Vá para:
   - **Feed**: criar primeiro post (texto/tags/anexo opcional imagem/pdf)
   - **Fórum**: gerenciar categorias (curator/leader) e criar tópicos (registrar+)
   - **Dossiês**: criar dossiê markdown

## Notas V1
- Fluxo por convite ficou fora do caminho principal (mantido para V1.1).
- Console do Líder inclui:
  - Usuários (alterar role/status)
  - Conteúdo (moderação rápida de posts)
  - Inkosi (emitir sinal manual)
  - Seed inicial
