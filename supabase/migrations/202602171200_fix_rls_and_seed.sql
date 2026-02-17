-- V1 usability + non-recursive guild_members RLS + forum category soft delete

alter table forum_categories add column if not exists deleted_at timestamptz;
create index if not exists forum_categories_guild_sort_idx on forum_categories(guild_id, sort_order) where deleted_at is null;
create index if not exists guild_members_user_status_idx on guild_members(user_id, status);
create index if not exists forum_topics_guild_created_idx on forum_topics(guild_id, created_at desc);
create index if not exists dossiers_guild_updated_idx on dossiers(guild_id, updated_at desc);
create index if not exists notifications_user_created_idx on notifications(user_id, created_at desc);

-- remove potentially recursive/self-referencing policies on guild_members
-- and rebuild key policies for V1.
drop policy if exists member_read_gm on guild_members;
drop policy if exists leader_manage_gm on guild_members;

create policy gm_select_self on guild_members
for select
using (user_id = auth.uid());

create policy gm_update_self on guild_members
for update
using (user_id = auth.uid())
with check (user_id = auth.uid());

-- profiles self read/write
alter table profiles enable row level security;
drop policy if exists member_read_profiles on profiles;
drop policy if exists own_profile_write on profiles;
create policy profiles_select_self on profiles for select using (id = auth.uid());
create policy profiles_insert_self on profiles for insert with check (id = auth.uid());
create policy profiles_update_self on profiles for update using (id = auth.uid()) with check (id = auth.uid());

-- posts readable by membership + role
alter table posts enable row level security;
drop policy if exists member_read_posts on posts;
drop policy if exists registrar_create_posts on posts;
drop policy if exists author_update_posts on posts;
create policy posts_select_visible on posts for select using (
  is_member(guild_id) and (
    member_role(guild_id) >= 'curator' or (
      not hidden and (
        visibility = 'public' or (visibility = 'restricted' and member_role(guild_id) >= coalesce(min_role, 'observer'::app_role))
      )
    )
  )
);
create policy posts_insert_registrar on posts for insert with check (
  is_member(guild_id) and member_role(guild_id) >= 'registrar' and author_id = auth.uid()
);
create policy posts_update_author_or_mod on posts for update using (
  author_id = auth.uid() or member_role(guild_id) >= 'curator'
);

-- forum categories
alter table forum_categories enable row level security;
drop policy if exists member_read_categories on forum_categories;
drop policy if exists curator_manage_categories on forum_categories;
create policy forum_categories_select on forum_categories for select using (
  is_member(guild_id) and deleted_at is null and member_role(guild_id) >= min_role
);
create policy forum_categories_insert_curator on forum_categories for insert with check (
  is_member(guild_id) and member_role(guild_id) >= 'curator'
);
create policy forum_categories_update_curator on forum_categories for update using (
  is_member(guild_id) and member_role(guild_id) >= 'curator'
);

-- forum topics
alter table forum_topics enable row level security;
drop policy if exists member_read_topics on forum_topics;
drop policy if exists registrar_write_topics on forum_topics;
create policy forum_topics_select on forum_topics for select using (
  is_member(guild_id) and (
    member_role(guild_id) >= 'curator' or not hidden
  )
);
create policy forum_topics_insert_registrar on forum_topics for insert with check (
  is_member(guild_id) and member_role(guild_id) >= 'registrar' and author_id = auth.uid()
);
create policy forum_topics_update_author_or_mod on forum_topics for update using (
  author_id = auth.uid() or member_role(guild_id) >= 'curator'
);

-- dossiers
alter table dossiers enable row level security;
drop policy if exists member_read_dossiers on dossiers;
drop policy if exists registrar_write_dossiers on dossiers;
create policy dossiers_select on dossiers for select using (
  is_member(guild_id) and (
    member_role(guild_id) >= 'curator' or (
      not hidden and (
        classification='open' or
        (classification='restricted' and member_role(guild_id) >= 'registrar') or
        (classification='sealed' and member_role(guild_id) = 'leader')
      )
    )
  )
);
create policy dossiers_insert_registrar on dossiers for insert with check (
  is_member(guild_id) and member_role(guild_id) >= 'registrar' and author_id = auth.uid() and
  (
    classification <> 'sealed' or member_role(guild_id) = 'leader'
  )
);
create policy dossiers_update_author_or_mod on dossiers for update using (
  author_id = auth.uid() or member_role(guild_id) >= 'curator'
);

-- notifications self only
alter table notifications enable row level security;
drop policy if exists user_notifications on notifications;
drop policy if exists user_notifications_update on notifications;
create policy notifications_select_self on notifications for select using (user_id = auth.uid());
create policy notifications_update_self on notifications for update using (user_id = auth.uid());
