# Moderation runbook

App Store guideline 1.2 requires apps with user-generated content to act on
reports **within 24 hours**. This is the process. It is not optional — an
unhandled report backlog is grounds for removal from the store.

## Daily: triage the report queue

Supabase dashboard → SQL Editor. `reports` has no SELECT policy, so this
only works from the dashboard (which uses the service role), never from the
app — that's deliberate.

```sql
-- Open reports, newest first, with the reported content inline.
select r.id,
       r.created_at,
       r.reason,
       reported.username        as reported_user,
       rev.notes                as review_notes,
       rev.photo_url            as review_photo,
       reporter.username        as reported_by      -- null if they deleted their account
  from reports r
  left join profiles reported  on reported.id  = coalesce(r.reported_user_id, rev.user_id)
  left join reviews  rev       on rev.id       = r.review_id
  left join profiles reporter  on reporter.id  = r.reporter_id
 order by r.created_at desc
 limit 50;
```

## Acting on a report

**Remove one review** (photo stays in storage; delete it separately if the
image itself is the violation):

```sql
delete from reviews where id = '<review_id>';
```

**Eject a user** — Apple's wording. This deletes the account and cascades
every review, save, follow and like:

```sql
delete from auth.users where id = '<user_id>';
```

**Remove a stored photo**: dashboard → Storage → `review-photos` →
`<user_id>/` → delete the file.

## After acting

Delete the handled report so the queue reflects only open items:

```sql
delete from reports where id = '<report_id>';
```

Keep reports about the same user if you're tracking a pattern — reports
survive the reporter deleting their account (`reporter_id` goes null), so
repeat-abuse evidence can't be erased on request.

## What to remove

Terms of Service §3 sets zero tolerance for: hateful, harassing,
threatening, sexually explicit, violent, illegal, deceptive, or spam
content; impersonation; and misuse of another person's content or likeness.
When it's ambiguous, the honest question is whether an 18–26 year old would
feel unsafe seeing it in their feed.

## If you can't check daily

Turn off new sign-ups before a stretch away rather than let reports sit:
Supabase dashboard → Authentication → Sign In / Providers → disable email
sign-ups. Existing users keep working.
