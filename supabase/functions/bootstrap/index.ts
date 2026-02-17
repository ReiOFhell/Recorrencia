import { serve } from 'https://deno.land/std/http/server.ts'
import { getAdminClient } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const secret = req.headers.get('x-bootstrap-secret')
    if (secret !== Deno.env.get('BOOTSTRAP_SECRET')) throw new Error('forbidden')

    const { leader_user_id } = await req.json()
    const admin = getAdminClient()
    const { data: guild } = await admin.from('guilds').insert({ name: 'Recorrência' }).select().single()
    await admin.from('guild_members').insert({ guild_id: guild!.id, user_id: leader_user_id, role: 'leader' })
    await admin.from('audit_log').insert({ guild_id: guild!.id, actor_id: leader_user_id, action: 'bootstrap' })
    return Response.json({ ok: true, guild })
  } catch (e) { return Response.json({ error: String(e) }, { status: 400 }) }
})
