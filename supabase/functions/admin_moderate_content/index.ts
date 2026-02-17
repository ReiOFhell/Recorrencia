import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'
serve(async (req) => {
  try {
    const { guild_id, table, id, patch } = await req.json()
    const admin = getAdminClient(); const caller = await getCaller(req)
    await requireRole(admin, guild_id, caller.id, 'curator')
    await admin.from(table).update(patch).eq('id', id)
    await audit(admin, { guild_id, actor_id: caller.id, action: 'admin_moderate_content', target_type: table, target_id: id, payload: patch })
    return Response.json({ ok: true })
  } catch (e) { return Response.json({ error: String(e) }, { status: 400 }) }
})
