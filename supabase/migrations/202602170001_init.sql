create extension if not exists "pgcrypto";

create type app_role as enum ('observer','registrar','curator','leader');
create type visibility_type as enum ('public','restricted');
create type dossier_classification as enum ('open','restricted','sealed');
create type dossier_status as enum ('draft','published','archived');
create type reaction_type as enum ('like','star');
create type member_status as enum ('active','suspended','banned');
create type inkosi_style as enum ('rupture_frame','nav_glitch','blackout_soft');
create type inkosi_intensity as enum ('low','medium');

create table guilds (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table guild_members (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role app_role not null default 'observer',
  status member_status not null default 'active',
  joined_at timestamptz not null default now(),
  unique (guild_id, user_id)
);

create table invites (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  token text not null unique,
  role app_role not null default 'observer',
  max_uses int not null default 1,
  used_count int not null default 0,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now()
);

create table invite_uses (
  id uuid primary key default gen_random_uuid(),
  invite_id uuid not null references invites(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  used_at timestamptz not null default now()
);

create table posts (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  author_id uuid not null references profiles(id),
  body text not null,
  tags text[] not null default '{}',
  visibility visibility_type not null default 'public',
  min_role app_role,
  pinned boolean not null default false,
  hidden boolean not null default false,
  locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index posts_guild_created_idx on posts(guild_id, created_at desc);

create table post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references posts(id) on delete cascade,
  guild_id uuid not null references guilds(id) on delete cascade,
  author_id uuid not null references profiles(id),
  body text not null,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);

create table forum_categories (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  name text not null,
  description text,
  sort_order int not null default 0,
  min_role app_role not null default 'observer',
  created_at timestamptz not null default now()
);

create table forum_topics (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  category_id uuid not null references forum_categories(id) on delete cascade,
  author_id uuid not null references profiles(id),
  title text not null,
  body text not null,
  tags text[] not null default '{}',
  pinned boolean not null default false,
  locked boolean not null default false,
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table forum_replies (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references forum_topics(id) on delete cascade,
  guild_id uuid not null references guilds(id) on delete cascade,
  author_id uuid not null references profiles(id),
  body text not null,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);

create table dossiers (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  author_id uuid not null references profiles(id),
  title text not null,
  subtitle text,
  body_md text not null,
  tags text[] not null default '{}',
  classification dossier_classification not null default 'open',
  status dossier_status not null default 'draft',
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table dossier_comments (
  id uuid primary key default gen_random_uuid(),
  dossier_id uuid not null references dossiers(id) on delete cascade,
  guild_id uuid not null references guilds(id) on delete cascade,
  author_id uuid not null references profiles(id),
  body text not null,
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);

create table tags (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  name text not null,
  unique(guild_id, name)
);

create table tag_links (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  tag_id uuid not null references tags(id) on delete cascade,
  target_type text not null,
  target_id uuid not null
);

create table reactions (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id),
  target_type text not null,
  target_id uuid not null,
  reaction reaction_type not null,
  created_at timestamptz not null default now(),
  unique(guild_id, user_id, target_type, target_id, reaction)
);

create table favorites (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id),
  target_type text not null,
  target_id uuid not null,
  created_at timestamptz not null default now(),
  unique(guild_id, user_id, target_type, target_id)
);

create table read_state (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id),
  target_type text not null,
  target_id uuid not null,
  read_at timestamptz not null default now(),
  unique(guild_id, user_id, target_type, target_id)
);

create table attachments (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  owner_id uuid not null references profiles(id),
  bucket text not null,
  path text not null,
  mime text,
  size_bytes bigint,
  target_type text,
  target_id uuid,
  created_at timestamptz not null default now()
);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id),
  type text not null,
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table audit_log (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid references guilds(id) on delete set null,
  actor_id uuid references profiles(id) on delete set null,
  action text not null,
  target_type text,
  target_id text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table user_presence_daily (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  day date not null,
  active_seconds int not null default 0,
  updated_at timestamptz not null default now(),
  unique(guild_id, user_id, day)
);

create table user_presence_weekly (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  week_start date not null,
  active_seconds int not null default 0,
  updated_at timestamptz not null default now(),
  unique(guild_id, user_id, week_start)
);

create table inkosi_signals (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  style inkosi_style not null,
  intensity inkosi_intensity not null default 'low',
  message text not null,
  source text not null,
  expires_at timestamptz not null,
  created_by uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table inkosi_seen (
  id uuid primary key default gen_random_uuid(),
  signal_id uuid not null references inkosi_signals(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  seen_at timestamptz not null default now(),
  unique(signal_id, user_id)
);

create table inkosi_milestones (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  milestone text not null,
  achieved_at timestamptz not null default now(),
  unique(guild_id, user_id, milestone, date(achieved_at))
);

create table inkosi_trigger_log (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references guilds(id) on delete cascade,
  trigger_type text not null,
  style inkosi_style not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table client_effect_prefs (
  user_id uuid primary key references profiles(id) on delete cascade,
  effects_enabled boolean not null default true,
  consented boolean not null default false,
  updated_at timestamptz not null default now()
);

alter table guilds enable row level security;
alter table profiles enable row level security;
alter table guild_members enable row level security;
alter table invites enable row level security;
alter table invite_uses enable row level security;
alter table posts enable row level security;
alter table post_comments enable row level security;
alter table forum_categories enable row level security;
alter table forum_topics enable row level security;
alter table forum_replies enable row level security;
alter table dossiers enable row level security;
alter table dossier_comments enable row level security;
alter table tags enable row level security;
alter table tag_links enable row level security;
alter table reactions enable row level security;
alter table favorites enable row level security;
alter table read_state enable row level security;
alter table attachments enable row level security;
alter table notifications enable row level security;
alter table audit_log enable row level security;
alter table user_presence_daily enable row level security;
alter table user_presence_weekly enable row level security;
alter table inkosi_signals enable row level security;
alter table inkosi_seen enable row level security;
alter table inkosi_milestones enable row level security;
alter table inkosi_trigger_log enable row level security;
alter table client_effect_prefs enable row level security;

create function is_member(gid uuid) returns boolean language sql stable as $$
  select exists(select 1 from guild_members gm where gm.guild_id = gid and gm.user_id = auth.uid() and gm.status = 'active');
$$;

create function member_role(gid uuid) returns app_role language sql stable as $$
  select coalesce((select gm.role from guild_members gm where gm.guild_id = gid and gm.user_id = auth.uid() and gm.status = 'active'), 'observer'::app_role);
$$;

create policy member_read_profiles on profiles for select using (id = auth.uid() or exists(select 1 from guild_members gm1 join guild_members gm2 on gm1.guild_id=gm2.guild_id where gm1.user_id=auth.uid() and gm2.user_id=profiles.id));
create policy own_profile_write on profiles for all using (id = auth.uid()) with check (id = auth.uid());

create policy member_read_guild on guilds for select using (is_member(id));
create policy member_read_gm on guild_members for select using (is_member(guild_id));
create policy leader_manage_gm on guild_members for update using (member_role(guild_id)='leader');

create policy member_read_posts on posts for select using (
  is_member(guild_id) and not hidden and (
    visibility='public' or member_role(guild_id) >= min_role
  )
);
create policy registrar_create_posts on posts for insert with check (is_member(guild_id) and member_role(guild_id) >= 'registrar' and author_id = auth.uid());
create policy author_update_posts on posts for update using (author_id = auth.uid());

create policy member_read_post_comments on post_comments for select using (is_member(guild_id) and not hidden);
create policy member_write_post_comments on post_comments for insert with check (is_member(guild_id) and author_id=auth.uid());

create policy member_read_categories on forum_categories for select using (is_member(guild_id) and member_role(guild_id) >= min_role);
create policy curator_manage_categories on forum_categories for all using (member_role(guild_id) >= 'curator');
create policy member_read_topics on forum_topics for select using (is_member(guild_id) and not hidden);
create policy registrar_write_topics on forum_topics for insert with check (is_member(guild_id) and member_role(guild_id) >= 'registrar' and author_id=auth.uid());
create policy member_read_replies on forum_replies for select using (is_member(guild_id) and not hidden);
create policy member_write_replies on forum_replies for insert with check (is_member(guild_id) and author_id=auth.uid());

create policy member_read_dossiers on dossiers for select using (
  is_member(guild_id) and not hidden and (
    classification='open' or
    (classification='restricted' and member_role(guild_id) >= 'registrar') or
    (classification='sealed' and member_role(guild_id) = 'leader')
  )
);
create policy registrar_write_dossiers on dossiers for insert with check (is_member(guild_id) and member_role(guild_id) >= 'registrar' and author_id=auth.uid());
create policy member_read_dossier_comments on dossier_comments for select using (is_member(guild_id) and not hidden);
create policy member_write_dossier_comments on dossier_comments for insert with check (is_member(guild_id) and author_id=auth.uid());

create policy member_rw_simple on tags for all using (is_member(guild_id)) with check (is_member(guild_id));
create policy member_rw_simple2 on tag_links for all using (is_member(guild_id)) with check (is_member(guild_id));
create policy member_rw_simple3 on reactions for all using (is_member(guild_id)) with check (is_member(guild_id));
create policy member_rw_simple4 on favorites for all using (is_member(guild_id)) with check (is_member(guild_id));
create policy member_rw_simple5 on read_state for all using (is_member(guild_id)) with check (is_member(guild_id));
create policy member_rw_simple6 on attachments for all using (is_member(guild_id)) with check (is_member(guild_id));
create policy user_notifications on notifications for select using (user_id = auth.uid());
create policy user_notifications_update on notifications for update using (user_id = auth.uid());
create policy leader_audit on audit_log for select using (guild_id is null or member_role(guild_id)='leader');
create policy own_presence_daily on user_presence_daily for select using (user_id=auth.uid());
create policy own_presence_weekly on user_presence_weekly for select using (user_id=auth.uid());
create policy member_read_inkosi on inkosi_signals for select using (is_member(guild_id));
create policy own_inkosi_seen on inkosi_seen for all using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy own_inkosi_milestone on inkosi_milestones for select using (user_id=auth.uid());
create policy leader_inkosi_logs on inkosi_trigger_log for select using (member_role(guild_id)='leader');
create policy own_effect_prefs on client_effect_prefs for all using (user_id=auth.uid()) with check (user_id=auth.uid());

create or replace function search_global(query_text text)
returns table(type text, id uuid, title text, excerpt text)
language sql stable as $$
  select 'post'::text, p.id, left(p.body, 80), p.body from posts p where p.body ilike '%'||query_text||'%'
  union all
  select 'topic'::text, t.id, t.title, left(t.body, 120) from forum_topics t where t.title ilike '%'||query_text||'%' or t.body ilike '%'||query_text||'%'
  union all
  select 'dossier'::text, d.id, d.title, left(d.body_md, 120) from dossiers d where d.title ilike '%'||query_text||'%' or d.body_md ilike '%'||query_text||'%';
$$;
