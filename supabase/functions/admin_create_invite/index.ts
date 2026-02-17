import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const { guild_id, role = 'observer', max_uses = 1, expires_at } = await req.json()
    const admin = getAdminClient()
    const { user } = await getCaller(req)

    await requireRole(admin, guild_id, user.id, 'leader')

    const token = crypto.randomUUID().replaceAll('-', '')
    const { data, error } = await admin
      .from('invites')
      .insert({ guild_id, role, max_uses, expires_at, token, created_by: user.id })
      .select()
      .single()

    if (error) throw error

    await audit(admin, {
      guild_id,
      actor_id: user.id,
      action: 'admin_create_invite',
      target_type: 'invite',
      target_id: data.id,
      payload: { role, max_uses, expires_at },
    })

    return Response.json(data)
  } catch (e) {
    return errorResponse(e)
  }
})
