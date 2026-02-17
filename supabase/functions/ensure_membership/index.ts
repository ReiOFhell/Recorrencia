import { serve } from 'https://deno.land/std/http/server.ts'
import { audit, errorResponse, getAdminClient, getCaller } from '../_shared/auth.ts'

type Body = {
  display_name?: string
  avatar_url?: string
}

serve(async (req) => {
  try {
    const admin = getAdminClient()
    const { user } = await getCaller(req)
    const body = (await req.json().catch(() => ({}))) as Body

    const displayName = body.display_name?.trim() || user.user_metadata?.name || user.email || 'Membro'
    const avatarUrl = body.avatar_url ?? user.user_metadata?.avatar_url ?? null

    const { data: profile, error: profileError } = await admin
      .from('profiles')
      .upsert({
        id: user.id,
        display_name: displayName,
        avatar_url: avatarUrl,
        updated_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (profileError) throw profileError

    const { data: guild, error: guildErr } = await admin
      .from('guilds')
      .upsert({ name: 'Recorrência' }, { onConflict: 'name' })
      .select()
      .single()

    if (guildErr || !guild) throw guildErr ?? new Error('Guild not available')

    const { data: existingMembership } = await admin
      .from('guild_members')
      .select('*')
      .eq('guild_id', guild.id)
      .eq('user_id', user.id)
      .maybeSingle()

    const { data: leaderRows, error: leaderErr } = await admin
      .from('guild_members')
      .select('id')
      .eq('guild_id', guild.id)
      .eq('role', 'leader')
      .eq('status', 'active')

    if (leaderErr) throw leaderErr

    const hasLeader = (leaderRows?.length ?? 0) > 0
    const isFirstLeader = !hasLeader && !existingMembership
    const role = existingMembership?.role ?? (isFirstLeader ? 'leader' : 'observer')

    const { data: membership, error: memberError } = await admin
      .from('guild_members')
      .upsert(
        {
          guild_id: guild.id,
          user_id: user.id,
          role,
          status: 'active',
        },
        { onConflict: 'guild_id,user_id' },
      )
      .select()
      .single()

    if (memberError) throw memberError

    if (isFirstLeader) {
      await audit(admin, {
        guild_id: guild.id,
        actor_id: user.id,
        action: 'first_leader_bootstrap',
        target_type: 'guild_member',
        target_id: membership.id,
      })
    }

    return Response.json({
      ok: true,
      profile,
      guild,
      membership,
      is_first_leader: isFirstLeader,
    })
  } catch (error) {
    return errorResponse(error)
  }
})
