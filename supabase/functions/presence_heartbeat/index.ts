import { serve } from 'https://deno.land/std/http/server.ts'
import { getAdminClient, getCaller } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const { guild_id, active_seconds = 30 } = await req.json()
    const admin = getAdminClient(); const caller = await getCaller(req)
    const day = new Date().toISOString().slice(0,10)
    const now = new Date(); const weekStart = new Date(now.setDate(now.getDate() - now.getDay())).toISOString().slice(0,10)

    const { data: d } = await admin.from('user_presence_daily').select('*').eq('guild_id', guild_id).eq('user_id', caller.id).eq('day', day).maybeSingle()
    if (d) await admin.from('user_presence_daily').update({ active_seconds: d.active_seconds + active_seconds, updated_at: new Date().toISOString() }).eq('id', d.id)
    else await admin.from('user_presence_daily').insert({ guild_id, user_id: caller.id, day, active_seconds })

    const { data: w } = await admin.from('user_presence_weekly').select('*').eq('guild_id', guild_id).eq('user_id', caller.id).eq('week_start', weekStart).maybeSingle()
    if (w) await admin.from('user_presence_weekly').update({ active_seconds: w.active_seconds + active_seconds, updated_at: new Date().toISOString() }).eq('id', w.id)
    else await admin.from('user_presence_weekly').insert({ guild_id, user_id: caller.id, week_start: weekStart, active_seconds })

    return Response.json({ ok: true })
  } catch (e) { return Response.json({ error: String(e) }, { status: 400 }) }
})
