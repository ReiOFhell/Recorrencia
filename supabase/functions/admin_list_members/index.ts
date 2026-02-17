import { serve } from 'https://deno.land/std/http/server.ts'
import { errorResponse, getAdminClient, getCaller, requireRole } from '../_shared/auth.ts'

serve(async (req) => {
  try {
    const guildId = new URL(req.url).searchParams.get('guild_id')
    if (!guildId) throw new Error('guild_id is required')

    const admin = getAdminClient()
    const { user } = await getCaller(req)
    await requireRole(admin, guildId, user.id, 'leader')

    const { data, error } = await admin
      .from('guild_members')
      .select('id,user_id,role,status,joined_at,profiles!inner(display_name,avatar_url)')
      .eq('guild_id', guildId)
      .order('joined_at', { ascending: true })

    if (error) throw error

    return Response.json({ ok: true, members: data })
  } catch (e) {
    return errorResponse(e)
  }
})
