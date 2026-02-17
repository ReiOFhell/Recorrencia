import { serve } from 'https://deno.land/std/http/server.ts'
import { getAdminClient } from '../_shared/auth.ts'

serve(async () => {
  const admin = getAdminClient()
  await admin.from('inkosi_signals').delete().lt('expires_at', new Date().toISOString())
  return Response.json({ ok: true })
})
