import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const { guild_id, user_id, status } = await req.json()
    const admin = getAdminClient()
    const { user } = await getCaller(req)

    await requireRole(admin, guild_id, user.id, 'leader')

    await admin.from('guild_members').update({ status }).eq('guild_id', guild_id).eq('user_id', user_id)
    await audit(admin, { guild_id, actor_id: user.id, action: 'admin_set_member_status', target_type: 'member', target_id: user_id, payload: { status } })

    return Response.json({ ok: true })
  } catch (e) {
    return errorResponse(e)
  }
})
