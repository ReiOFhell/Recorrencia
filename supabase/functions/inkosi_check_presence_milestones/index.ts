import { serve } from 'https://deno.land/std/http/server.ts'
import { getAdminClient, getCaller } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const { guild_id } = await req.json()
    const admin = getAdminClient(); const caller = await getCaller(req)
    const day = new Date().toISOString().slice(0,10)
    const weekStart = new Date(Date.now() - new Date().getDay() * 86400000).toISOString().slice(0,10)

    const { data: daily } = await admin.from('user_presence_daily').select('active_seconds').eq('guild_id', guild_id).eq('user_id', caller.id).eq('day', day).maybeSingle()
    const { data: weekly } = await admin.from('user_presence_weekly').select('active_seconds').eq('guild_id', guild_id).eq('user_id', caller.id).eq('week_start', weekStart).maybeSingle()

    const milestones: string[] = []
    if ((daily?.active_seconds ?? 0) >= 1200) milestones.push('PRESENCE_20M_DAILY')
    if ((daily?.active_seconds ?? 0) >= 14400) milestones.push('PRESENCE_4H_DAILY')
    if ((weekly?.active_seconds ?? 0) >= 14400) milestones.push('PRESENCE_4H_WEEKLY')

    for (const m of milestones) {
      await admin.from('inkosi_milestones').upsert({ guild_id, user_id: caller.id, milestone: m })
    }

    return Response.json({ ok: true, milestones })
  } catch (e) { return Response.json({ error: String(e) }, { status: 400 }) }
})
