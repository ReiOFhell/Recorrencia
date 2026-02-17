import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'
serve(async (req) => {
  try {
    const { guild_id, invite_id } = await req.json()
    const admin = getAdminClient(); const caller = await getCaller(req)
    await requireRole(admin, guild_id, caller.id, 'leader')
    await admin.from('invites').update({ revoked_at: new Date().toISOString() }).eq('id', invite_id)
    await audit(admin, { guild_id, actor_id: caller.id, action: 'admin_revoke_invite', target_type: 'invite', target_id: invite_id })
    return Response.json({ ok: true })
  } catch (e) { return Response.json({ error: String(e) }, { status: 400 }) }
})
