import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const { token } = await req.json()
    const admin = getAdminClient()
    const { user } = await getCaller(req)

    const { data: invite, error } = await admin.from('invites').select('*').eq('token', token).single()
    if (error || !invite) throw error ?? new Error('Invite not found')

    if (invite.revoked_at) throw new Error('Invite revoked')
    if (invite.expires_at && new Date(invite.expires_at) < new Date()) throw new Error('Invite expired')
    if (invite.used_count >= invite.max_uses) throw new Error('Invite exhausted')

    await admin.from('guild_members').upsert({ guild_id: invite.guild_id, user_id: user.id, role: invite.role })
    await admin.from('invite_uses').insert({ invite_id: invite.id, user_id: user.id })
    await admin.from('invites').update({ used_count: invite.used_count + 1 }).eq('id', invite.id)

    await audit(admin, {
      guild_id: invite.guild_id,
      actor_id: user.id,
      action: 'consume_invite_and_join',
      target_type: 'invite',
      target_id: invite.id,
    })

    return Response.json({ ok: true, guild_id: invite.guild_id })
  } catch (e) {
    return errorResponse(e)
  }
})
