import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const { guild_id, user_id, role } = await req.json()
    const admin = getAdminClient()
    const { user } = await getCaller(req)

    await requireRole(admin, guild_id, user.id, 'leader')

    await admin.from('guild_members').update({ role }).eq('guild_id', guild_id).eq('user_id', user_id)
    await audit(admin, { guild_id, actor_id: user.id, action: 'admin_set_member_role', target_type: 'member', target_id: user_id, payload: { role } })

    return Response.json({ ok: true })
  } catch (e) {
    return errorResponse(e)
  }
})
