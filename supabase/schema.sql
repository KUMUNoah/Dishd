-- ============================================================
-- Dishd v2 schema — run once in Supabase SQL editor
-- ============================================================

-- ---------- TABLES ----------

create table public.profiles (
  id          uuid primary key references auth.users on delete cascade,
  username    text unique not null check (username ~ '^[a-z0-9_]{3,20}$'),
  full_name   text,
  bio         text,
  avatar_url  text,
  is_private  boolean not null default false,
  created_at  timestamptz not null default now()
);

create table public.recipes (
  id            uuid primary key default gen_random_uuid(),
  title         text not null,
  source_url    text unique,                -- nullable: quick-post recipes have no link
  thumbnail_url text,
  platform      text check (platform in ('tiktok','instagram','youtube','web')),
  created_by    uuid references public.profiles on delete set null,
  created_at    timestamptz not null default now()
);

create table public.folders (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles on delete cascade,
  name       text not null,
  section    text not null check (section in ('want_to_make','made')),
  created_at timestamptz not null default now()
);

create table public.saves (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles on delete cascade,
  recipe_id  uuid not null references public.recipes on delete cascade,
  status     text not null default 'want_to_make' check (status in ('want_to_make','made')),
  folder_id  uuid references public.folders on delete set null,
  created_at timestamptz not null default now(),
  unique (user_id, recipe_id)
);

create table public.reviews (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles on delete cascade,
  recipe_id  uuid not null references public.recipes on delete cascade,
  rating     int  not null check (rating between 1 and 5),
  notes      text,
  photo_url  text not null,                 -- photo required, no exceptions
  created_at timestamptz not null default now(),
  unique (user_id, recipe_id)
);

create table public.follows (
  follower_id  uuid not null references public.profiles on delete cascade,
  following_id uuid not null references public.profiles on delete cascade,
  status       text not null default 'accepted' check (status in ('accepted','pending')),
  created_at   timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table public.likes (
  user_id    uuid not null references public.profiles on delete cascade,
  review_id  uuid not null references public.reviews on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, review_id)
);

create table public.blocks (
  blocker_id uuid not null references public.profiles on delete cascade,
  blocked_id uuid not null references public.profiles on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

create table public.reports (
  id               uuid primary key default gen_random_uuid(),
  reporter_id      uuid not null references public.profiles on delete cascade,
  review_id        uuid references public.reviews on delete cascade,
  reported_user_id uuid references public.profiles on delete cascade,
  reason           text,
  created_at       timestamptz not null default now(),
  check (review_id is not null or reported_user_id is not null)
);

create table public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles on delete cascade,  -- recipient
  actor_id   uuid not null references public.profiles on delete cascade,
  type       text not null check (type in ('follow_request','new_follower','like','save_from_profile')),
  review_id  uuid references public.reviews on delete cascade,
  recipe_id  uuid references public.recipes on delete cascade,
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.starter_recipes (
  recipe_id  uuid primary key references public.recipes on delete cascade,
  cuisines   text[] not null default '{}',   -- matches taste-question answers
  difficulty text check (difficulty in ('beginner','intermediate','comfortable'))
);

create table public.analytics_events (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid references public.profiles on delete set null,
  event      text not null,
  properties jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ---------- INDEXES ----------

create index idx_saves_user      on public.saves (user_id, status);
create index idx_reviews_user    on public.reviews (user_id, created_at desc);
create index idx_reviews_recipe  on public.reviews (recipe_id);
create index idx_follows_target  on public.follows (following_id, status);
create index idx_notifs_user     on public.notifications (user_id, read, created_at desc);
create index idx_likes_review    on public.likes (review_id);

-- ---------- VISIBILITY (the privacy rule, defined ONCE) ----------

-- True iff `viewer` may see content owned by `owner`:
-- no block in either direction, AND (owner is public / is self / accepted follow).
create or replace function public.can_view(viewer uuid, owner uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select
    not exists (
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

-- ---------- ROW LEVEL SECURITY ----------

alter table public.profiles         enable row level security;
alter table public.recipes          enable row level security;
alter table public.folders          enable row level security;
alter table public.saves            enable row level security;
alter table public.reviews          enable row level security;
alter table public.follows          enable row level security;
alter table public.likes            enable row level security;
alter table public.blocks           enable row level security;
alter table public.reports          enable row level security;
alter table public.notifications    enable row level security;
alter table public.starter_recipes  enable row level security;
alter table public.analytics_events enable row level security;

-- profiles: readable unless blocked (header always visible, content gated separately)
create policy profiles_select on public.profiles for select using (
  not exists (select 1 from blocks
              where (blocker_id = auth.uid() and blocked_id = id)
                 or (blocker_id = id and blocked_id = auth.uid()))
);
create policy profiles_insert on public.profiles for insert with check (id = auth.uid());
create policy profiles_update on public.profiles for update using (id = auth.uid());

-- recipes: canonical, readable by all, immutable after creation
create policy recipes_select on public.recipes for select using (true);
create policy recipes_insert on public.recipes for insert with check (auth.uid() is not null);
-- no update/delete policies: canonical recipes are read-only by design

-- folders: owner only
create policy folders_all on public.folders for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- saves: owner writes; visible to those who can view the owner (profile Recipes tab, save activity)
create policy saves_select on public.saves for select using (public.can_view(auth.uid(), user_id));
create policy saves_write  on public.saves for insert with check (user_id = auth.uid());
create policy saves_update on public.saves for update using (user_id = auth.uid());
create policy saves_delete on public.saves for delete using (user_id = auth.uid());

-- reviews: THE privacy rule, applied everywhere reviews surface
create policy reviews_select on public.reviews for select using (public.can_view(auth.uid(), user_id));
create policy reviews_insert on public.reviews for insert with check (user_id = auth.uid());
create policy reviews_update on public.reviews for update using (user_id = auth.uid());
create policy reviews_delete on public.reviews for delete using (user_id = auth.uid());

-- follows: involved parties can read; follower creates; target resolves requests
create policy follows_select on public.follows for select
  using (follower_id = auth.uid() or following_id = auth.uid()
         or public.can_view(auth.uid(), following_id));
create policy follows_insert on public.follows for insert with check (follower_id = auth.uid());
create policy follows_update on public.follows for update using (following_id = auth.uid());
create policy follows_delete on public.follows for delete
  using (follower_id = auth.uid() or following_id = auth.uid());

-- likes: visible where the review is visible
create policy likes_select on public.likes for select using (
  exists (select 1 from reviews r where r.id = review_id
          and public.can_view(auth.uid(), r.user_id))
);
create policy likes_insert on public.likes for insert with check (user_id = auth.uid());
create policy likes_delete on public.likes for delete using (user_id = auth.uid());

-- blocks / reports: owner only
create policy blocks_all on public.blocks for all
  using (blocker_id = auth.uid()) with check (blocker_id = auth.uid());
create policy reports_insert on public.reports for insert with check (reporter_id = auth.uid());

-- notifications: recipient reads/updates; inserts happen via triggers (security definer)
create policy notifs_select on public.notifications for select using (user_id = auth.uid());
create policy notifs_update on public.notifications for update using (user_id = auth.uid());

-- starter recipes: readable by all
create policy starter_select on public.starter_recipes for select using (true);

-- analytics: insert own events only
create policy analytics_insert on public.analytics_events for insert
  with check (user_id = auth.uid() or user_id is null);

-- ---------- TRIGGERS ----------

-- 1) Create profile + row on signup (username/full_name passed as auth metadata)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, full_name)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'username', 'user_' || left(new.id::text, 8)),
          new.raw_user_meta_data->>'full_name');
  return new;
end $$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 2) Follow requests: force 'pending' when target is private; notify target
create or replace function public.handle_new_follow()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from profiles where id = new.following_id and is_private) then
    new.status := 'pending';
  else
    new.status := 'accepted';
  end if;
  insert into public.notifications (user_id, actor_id, type)
  values (new.following_id, new.follower_id,
          case when new.status = 'pending' then 'follow_request' else 'new_follower' end);
  return new;
end $$;
create trigger on_follow_created
  before insert on public.follows
  for each row execute function public.handle_new_follow();

-- 3) Posting a review auto-moves the save to Made (creates the save if missing)
create or replace function public.handle_new_review()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.saves (user_id, recipe_id, status)
  values (new.user_id, new.recipe_id, 'made')
  on conflict (user_id, recipe_id)
  do update set status = 'made', folder_id = null;
  return new;
end $$;
create trigger on_review_created
  after insert on public.reviews
  for each row execute function public.handle_new_review();

-- 4) Like → notify the review owner (skip self-likes)
create or replace function public.handle_new_like()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner uuid;
begin
  select user_id into owner from reviews where id = new.review_id;
  if owner is not null and owner <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, review_id)
    values (owner, new.user_id, 'like', new.review_id);
  end if;
  return new;
end $$;
create trigger on_like_created
  after insert on public.likes
  for each row execute function public.handle_new_like();

-- ---------- GOALS (v2) ----------
-- Personal cooking goals, set in onboarding, editable in Settings.
-- Private to the owner; progress is computed client-side from reviews.
create table public.goals (
  user_id               uuid primary key references public.profiles on delete cascade,
  cook_per_week         int not null check (cook_per_week between 1 and 21),
  new_recipes_per_year  int not null check (new_recipes_per_year between 1 and 1000),
  updated_at            timestamptz not null default now()
);
alter table public.goals enable row level security;
create policy goals_own on public.goals
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 5) Account deletion (App Store 5.1.1). Runs as definer so it can delete the
--    auth.users row; profile + all app data cascade. Storage files can't be
--    deleted from SQL (Supabase blocks it) — the client removes its own files
--    via the Storage API before calling this.
create or replace function public.delete_user()
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from auth.users where id = auth.uid();
end $$;
revoke execute on function public.delete_user() from anon, public;
grant execute on function public.delete_user() to authenticated;

-- ---------- STORAGE ----------

insert into storage.buckets (id, name, public) values
  ('avatars', 'avatars', true),
  ('review-photos', 'review-photos', true);

create policy storage_read on storage.objects for select using (
  bucket_id in ('avatars','review-photos')
);
create policy storage_insert_own on storage.objects for insert with check (
  bucket_id in ('avatars','review-photos')
  and auth.uid() is not null
  and (storage.foldername(name))[1] = auth.uid()::text   -- files live under {user_id}/...
);
create policy storage_update_own on storage.objects for update using (
  bucket_id in ('avatars','review-photos')
  and (storage.foldername(name))[1] = auth.uid()::text
);
create policy storage_delete_own on storage.objects for delete using (
  bucket_id in ('avatars','review-photos')
  and (storage.foldername(name))[1] = auth.uid()::text
);
