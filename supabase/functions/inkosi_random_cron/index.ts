import { serve } from 'https://deno.land/std/http/server.ts'
import { getAdminClient } from '../_shared/auth.ts'

const messages = [
  'Tudo move, e retorna ao centro.',
  'O arquivo respira no intervalo.',
  'Inkosi.'
]

serve(async () => {
  const admin = getAdminClient()
  const day = new Date().toISOString().slice(0,10)
  const { data: today } = await admin.from('inkosi_trigger_log').select('id').gte('created_at', `${day}T00:00:00Z`)
  if ((today?.length ?? 0) >= 3) return Response.json({ ok: true, skipped: 'daily cap' })

  const { data: guilds } = await admin.from('guilds').select('id')
  for (const g of guilds ?? []) {
    const style = ['rupture_frame', 'nav_glitch', 'blackout_soft'][Math.floor(Math.random() * 3)]
    await admin.from('inkosi_signals').insert({
      guild_id: g.id,
      style,
      intensity: 'low',
      message: messages[Math.floor(Math.random() * messages.length)],
      source: 'random_cron',
      expires_at: new Date(Date.now() + 30_000).toISOString(),
    })
    await admin.from('inkosi_trigger_log').insert({ guild_id: g.id, trigger_type: 'random_cron', style, payload: {} })
  }

  return Response.json({ ok: true })
})
