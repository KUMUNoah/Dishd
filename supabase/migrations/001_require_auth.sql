-- ============================================================
-- 001 · Require authentication to read user data
--
-- The publishable key ships inside the app binary and is trivially
-- extracted, so an unauthenticated caller is effectively "anyone on the
-- internet". Before this migration they could read every profile, every
-- public user's reviews (photos + notes), and every save.
--
-- Run once in the Supabase SQL editor.
-- ============================================================

-- 1) can_view: a null viewer is never allowed. This is the single rule
--    reviews, saves and follows all funnel through.
create or replace function public.can_view(viewer uuid, owner uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select
    viewer is not null
    and not exists (
      select 1 from blocks
      where (blocker_id = viewer and blocked_id = owner)
         or (blocker_id = owner  and blocked_id = viewer)
    )
    and (
      viewer = owner
      or exists (select 1 from profiles p where p.id = owner and not p.is_private)
      or exists (select 1 from follows f
                 where f.follower_id = viewer and f.following_id = owner
                   and f.status = 'accepted')
    )
$$;

-- 2) profiles: signed-in only (was readable by anyone)
drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles for select using (
  auth.uid() is not null
  and not exists (select 1 from blocks
                  where (blocker_id = auth.uid() and blocked_id = id)
                     or (blocker_id = id and blocked_id = auth.uid()))
);

-- 3) recipes + starter recipes: signed-in only. Canonical rows aren't
--    private, but there's no reason to serve the catalogue anonymously.
drop policy if exists recipes_select on public.recipes;
create policy recipes_select on public.recipes for select
  using (auth.uid() is not null);

drop policy if exists starter_select on public.starter_recipes;
create policy starter_select on public.starter_recipes for select
  using (auth.uid() is not null);

-- 4) analytics: only your own events. The old policy allowed
--    user_id IS NULL, i.e. unauthenticated writes to our table.
drop policy if exists analytics_insert on public.analytics_events;
create policy analytics_insert on public.analytics_events for insert
  with check (user_id = auth.uid());

-- 5) Username availability is needed BEFORE sign-in, so it can't go
--    through the profiles table any more. This returns a bare boolean and
--    leaks nothing else about who exists.
create or replace function public.username_available(candidate text)
returns boolean
language sql stable security definer set search_path = public as $$
  select not exists (
    select 1 from profiles where username = lower(candidate)
  )
$$;
revoke execute on function public.username_available(text) from public;
grant execute on function public.username_available(text) to anon, authenticated;

-- 6) recipes: the old insert policy checked only that you were signed in,
--    so a crafted client could attribute a recipe to another user.
drop policy if exists recipes_insert on public.recipes;
create policy recipes_insert on public.recipes for insert with check (
  auth.uid() is not null
  and (created_by = auth.uid() or created_by is null)
);

-- 7) Cap uploads. Buckets had no size or MIME limit, so a client could
--    push arbitrary files of any size into our storage bill.
update storage.buckets
   set file_size_limit = 8388608,   -- 8 MB
       allowed_mime_types = array['image/jpeg','image/png','image/heic','image/webp']
 where id in ('avatars', 'review-photos');

-- 8) Reports must outlive the reporter. reporter_id cascaded, so a user
--    deleting their account erased every report they had filed — abuse
--    evidence disappearing on request. Keep the report, drop the identity.
alter table public.reports alter column reporter_id drop not null;
alter table public.reports drop constraint if exists reports_reporter_id_fkey;
alter table public.reports add constraint reports_reporter_id_fkey
  foreign key (reporter_id) references public.profiles(id) on delete set null;
