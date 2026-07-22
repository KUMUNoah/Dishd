-- ============================================================
-- 001 · Require authentication to read user data
--
-- The publishable key ships inside the app binary and is trivially
-- extracted, so an unauthenticated caller is effectively "anyone on the
-- internet". Before this migration they could read every profile, every
-- public user's reviews (photos + notes), and every save.
--
-- Run in the Supabase SQL editor. Safe to re-run: every statement is
-- idempotent, and the whole file executes as one transaction, so a failure
-- anywhere rolls back everything rather than leaving the DB half-migrated.
-- ============================================================

begin;

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

-- Drop by whatever Postgres actually named the FK, not the conventional
-- name — guessing wrong would leave the cascade in place silently.
do $$
declare fk text;
begin
  select conname into fk
    from pg_constraint
   where conrelid = 'public.reports'::regclass
     and contype = 'f'
     and conkey = array[(select attnum from pg_attribute
                          where attrelid = 'public.reports'::regclass
                            and attname = 'reporter_id')];
  if fk is not null then
    execute format('alter table public.reports drop constraint %I', fk);
  end if;
end $$;

alter table public.reports add constraint reports_reporter_id_fkey
  foreign key (reporter_id) references public.profiles(id) on delete set null;

-- 9) User-supplied URLs and text were completely unbounded.
--    source_url is UGC that becomes CANONICAL and IMMUTABLE, then gets
--    tapped by other users — URL(string:) accepts any scheme, so a crafted
--    "recipe" could send tappers to tel:, sms:, or another app. There is
--    already a bogus "url.come" row from testing, so clean before adding
--    the constraint.
update public.recipes
   set source_url = null
 where source_url is not null
   and source_url !~* '^https?://';

alter table public.recipes drop constraint if exists recipes_source_url_http;
alter table public.recipes add constraint recipes_source_url_http
  check (source_url is null or
         (source_url ~* '^https?://' and length(source_url) <= 2048));

alter table public.recipes drop constraint if exists recipes_title_len;
alter table public.recipes add constraint recipes_title_len
  check (length(title) between 1 and 200);

-- Unbounded notes mean one user can push megabytes of text to every
-- follower's feed.
alter table public.reviews drop constraint if exists reviews_notes_len;
alter table public.reviews add constraint reviews_notes_len
  check (notes is null or length(notes) <= 2000);

alter table public.profiles drop constraint if exists profiles_bio_len;
alter table public.profiles add constraint profiles_bio_len
  check (bio is null or length(bio) <= 300);

alter table public.profiles drop constraint if exists profiles_full_name_len;
alter table public.profiles add constraint profiles_full_name_len
  check (full_name is null or length(full_name) <= 80);

alter table public.reports drop constraint if exists reports_reason_len;
alter table public.reports add constraint reports_reason_len
  check (reason is null or length(reason) <= 500);

-- Fail loudly if anything above silently no-opped.
do $$
begin
  if (select count(*) from pg_policies
       where schemaname = 'public' and tablename = 'profiles'
         and policyname = 'profiles_select'
         and qual like '%auth.uid() IS NOT NULL%') = 0 then
    raise exception 'profiles_select did not pick up the auth requirement';
  end if;
  if not exists (select 1 from pg_proc where proname = 'username_available') then
    raise exception 'username_available was not created';
  end if;
  if exists (select 1 from public.recipes
              where source_url is not null and source_url !~* '^https?://') then
    raise exception 'non-http source_url rows survived';
  end if;
end $$;

commit;
