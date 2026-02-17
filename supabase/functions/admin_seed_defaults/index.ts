import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'

const defaults = [
  { name: 'Arquivo', description: 'Referências centrais', sort_order: 1, min_role: 'observer' },
  { name: 'Registro', description: 'Registros operacionais', sort_order: 2, min_role: 'registrar' },
  { name: 'Observações', description: 'Notas e discussões', sort_order: 3, min_role: 'observer' },
]

serve(async (req) => {
  try {
    const { guild_id, create_welcome_post = true } = await req.json()
    const admin = getAdminClient()
    const { user } = await getCaller(req)

    await requireRole(admin, guild_id, user.id, 'leader')

    for (const cat of defaults) {
      const { data: existing } = await admin
        .from('forum_categories')
        .select('id')
        .eq('guild_id', guild_id)
        .eq('name', cat.name)
        .maybeSingle()

      if (!existing) {
        await admin.from('forum_categories').insert({ ...cat, guild_id })
      }
    }

    if (create_welcome_post) {
      const { data: postExists } = await admin
        .from('posts')
        .select('id')
        .eq('guild_id', guild_id)
        .ilike('body', '%Bem-vindo%')
        .maybeSingle()

      if (!postExists) {
        await admin.from('posts').insert({
          guild_id,
          author_id: user.id,
          body: 'Bem-vindo ao Recorrência. Este é o primeiro registro do arquivo.',
          tags: ['boas-vindas'],
          visibility: 'public',
          pinned: true,
        })
      }
    }

    await audit(admin, {
      guild_id,
      actor_id: user.id,
      action: 'admin_seed_defaults',
      target_type: 'guild',
      target_id: guild_id,
      payload: { create_welcome_post },
    })

    return Response.json({ ok: true })
  } catch (e) {
    return errorResponse(e)
  }
})
