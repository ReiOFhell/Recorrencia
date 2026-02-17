import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

export function getAdminClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
}

export async function getCaller(req: Request) {
  const token = req.headers.get('Authorization')?.replace('Bearer ', '')
  if (!token) throw new Error('missing token')

  const client = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  })

  const { data, error } = await client.auth.getUser()
  if (error || !data.user) throw new Error('unauthorized')
  return data.user
}

export async function requireRole(admin: ReturnType<typeof getAdminClient>, guildId: string, userId: string, minRole: 'curator' | 'leader') {
  const { data, error } = await admin
    .from('guild_members')
    .select('role')
    .eq('guild_id', guildId)
    .eq('user_id', userId)
    .single()
  if (error) throw error
  const order: Record<string, number> = { observer: 0, registrar: 1, curator: 2, leader: 3 }
  if (order[data.role] < order[minRole]) throw new Error('forbidden')
}

export async function audit(admin: ReturnType<typeof getAdminClient>, payload: Record<string, unknown>) {
  await admin.from('audit_log').insert(payload)
}
