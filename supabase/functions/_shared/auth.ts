import { createClient, type User } from 'https://esm.sh/@supabase/supabase-js@2'

export class HttpError extends Error {
  status: number
  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

export function getAdminClient() {
  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  )
}

export function extractBearerToken(req: Request): string {
  const header = req.headers.get('Authorization') ?? req.headers.get('authorization')
  if (!header) throw new HttpError(401, 'Missing Authorization header')

  const match = header.match(/^Bearer\s+(.+)$/i)
  if (!match?.[1]) throw new HttpError(401, 'Invalid Authorization header format')
  return match[1]
}

export async function getCaller(req: Request): Promise<{ user: User; token: string }> {
  const token = extractBearerToken(req)
  const admin = getAdminClient()

  const { data, error } = await admin.auth.getUser(token)
  if (error || !data.user) {
    throw new HttpError(401, 'Invalid or expired JWT')
  }

  return { user: data.user, token }
}

export async function requireRole(
  admin: ReturnType<typeof getAdminClient>,
  guildId: string,
  userId: string,
  minRole: 'curator' | 'leader',
) {
  const { data, error } = await admin
    .from('guild_members')
    .select('role,status')
    .eq('guild_id', guildId)
    .eq('user_id', userId)
    .single()

  if (error || !data) throw new HttpError(403, 'Not a guild member')
  if (data.status !== 'active') throw new HttpError(403, 'Member is not active')

  const order: Record<string, number> = { observer: 0, registrar: 1, curator: 2, leader: 3 }
  if (order[data.role] < order[minRole]) throw new HttpError(403, 'Insufficient role')
}

export async function audit(
  admin: ReturnType<typeof getAdminClient>,
  payload: Record<string, unknown>,
) {
  await admin.from('audit_log').insert(payload)
}

export function errorResponse(error: unknown) {
  if (error instanceof HttpError) {
    return Response.json({ error: error.message }, { status: error.status })
  }
  return Response.json({ error: String(error) }, { status: 400 })
}
