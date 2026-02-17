import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'

const ALLOWED_TABLES = new Set([
  'posts',
  'forum_topics',
  'forum_replies',
  'dossiers',
  'post_comments',
  'dossier_comments',
])

serve(async (req) => {
  try {
    const { guild_id, table, id, patch } = await req.json()
    if (!ALLOWED_TABLES.has(table)) throw new Error('table not allowed')

    const admin = getAdminClient()
    const { user } = await getCaller(req)

    await requireRole(admin, guild_id, user.id, 'curator')

    await admin.from(table).update(patch).eq('id', id)
    await audit(admin, { guild_id, actor_id: user.id, action: 'admin_moderate_content', target_type: table, target_id: id, payload: patch })

    return Response.json({ ok: true })
  } catch (e) {
    return errorResponse(e)
  }
})
