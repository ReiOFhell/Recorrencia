import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const {
      guild_id,
      style = 'rupture_frame',
      intensity = 'low',
      message = 'O padrão observa sem pressa.',
    } = await req.json()

    const admin = getAdminClient()
    const { user } = await getCaller(req)

    await requireRole(admin, guild_id, user.id, 'leader')

    const expires_at = new Date(Date.now() + 30_000).toISOString()
    const { data } = await admin
      .from('inkosi_signals')
      .insert({ guild_id, style, intensity, message, source: 'manual', created_by: user.id, expires_at })
      .select()
      .single()

    await admin.from('inkosi_trigger_log').insert({ guild_id, trigger_type: 'manual', style, payload: { intensity } })
    await audit(admin, { guild_id, actor_id: user.id, action: 'inkosi_emit_manual', target_type: 'inkosi_signal', target_id: data?.id })

    return Response.json({ ok: true, signal: data })
  } catch (e) {
    return errorResponse(e)
  }
})
