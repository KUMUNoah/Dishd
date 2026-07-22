-- ============================================================
-- DESTRUCTIVE · wipes every account and all user content.
-- Pre-launch use only. There is no undo and no backup taken.
--
-- Keeps: the schema, RLS policies, functions, triggers, and the
--        seeded starter recipes.
-- Deletes: all auth users and everything owned by them (profiles,
--          reviews, saves, follows, likes, blocks, goals,
--          notifications), user-created recipes, reports, analytics.
--
-- Run STEP 1 alone first and read the counts. Only then run STEP 2.
-- ============================================================

-- ---------- STEP 1 · look before you delete ----------
select 'auth users'         as what, count(*) from auth.users
union all select 'profiles',          count(*) from public.profiles
union all select 'reviews',           count(*) from public.reviews
union all select 'saves',             count(*) from public.saves
union all select 'follows',           count(*) from public.follows
union all select 'goals',             count(*) from public.goals
union all select 'reports',           count(*) from public.reports
union all select 'analytics events',  count(*) from public.analytics_events
union all select 'recipes (total)',   count(*) from public.recipes
union all select 'recipes (starter — KEPT)', count(*) from public.starter_recipes
order by what;

-- Who exactly is about to be deleted:
-- select email, created_at, confirmed_at from auth.users order by created_at;


-- ---------- STEP 2 · the wipe ----------
-- Uncomment and run only after checking STEP 1.
/*
begin;

-- Cascades to profiles → reviews, saves, follows, likes, blocks, goals,
-- notifications. Recipes survive (created_by is SET NULL) so the starter
-- catalogue isn't collateral damage.
delete from auth.users;

-- User-created recipes, keeping anything in the seeded starter set.
delete from public.recipes r
 where not exists (
   select 1 from public.starter_recipes s where s.recipe_id = r.id
 );

-- Reports mostly self-clear via cascade; this catches any with a null
-- reporter (kept deliberately) whose target is already gone.
delete from public.reports;

-- Analytics rows survive user deletion by design (user_id SET NULL), so
-- clear them explicitly for a true zero state.
delete from public.analytics_events;

commit;
*/


-- ---------- STEP 3 · storage (dashboard, not SQL) ----------
-- Supabase blocks deleting storage.objects from SQL. Do this by hand:
--   Storage → review-photos → select all → Delete
--   Storage → avatars       → select all → Delete
-- Photos are orphaned once their reviews are gone, but they still occupy
-- your storage quota and remain reachable by direct URL.


-- ---------- STEP 4 · verify you're at zero ----------
-- select 'auth users' as what, count(*) from auth.users
-- union all select 'profiles', count(*) from public.profiles
-- union all select 'reviews',  count(*) from public.reviews;
