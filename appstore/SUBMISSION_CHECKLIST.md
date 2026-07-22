# Pre-submission checklist

Status as of 22 July 2026. Ordered so the blocking work comes first.

---

## ✅ Backend security — done and verified 22 July

All three verified by probing the live API with only the publishable key —
the same access an attacker gets from unpacking the app binary.

- [x] **Migration 001 run.** Every table returns zero rows anonymously:
      profiles, reviews, saves, recipes, starter_recipes, goals,
      notifications, reports, analytics, blocks, follows, likes. The
      `username_available` RPC still answers anonymously, so signup works.
      This is also what makes the published privacy policy's security
      section true.
- [x] **Email confirmation on.** Signup returns no session and
      `confirmed_at: null`.
- [x] **Password minimum 8.** 5, 6 and 7 characters rejected as
      `weak_password`; 8 accepted.

## 🟡 Needs Apple Developer enrollment to clear

- [ ] **Create the app record** in App Store Connect, bundle ID
      `com.noahtakashima.Dishd`
- [ ] **Privacy policy URL**: `https://kumunoah.github.io/Dishd/privacy.html`
- [ ] **Privacy nutrition label** — answers already written in
      [`metadata.md`](metadata.md) §1. Includes cooking-goals data.
- [ ] **Listing copy** — name, subtitle, description, keywords in
      [`metadata.md`](metadata.md) §2
- [ ] **Age rating** — expect 12+. Don't fight for 4+; UGC apps don't get it.
- [ ] **Support URL** — currently pointing at the GitHub repo. A plain
      mailto or simple page reads better.
- [ ] **TestFlight** with friends before public release. Doubles as the
      seeded launch group.

## 🟡 Screenshots (needs real content)

Required: 6.9" / 1320 × 2868, five to six images. Story order and full plan
in [`metadata.md`](metadata.md) §3.

Seed two or three accounts with **real photos of real cooked food** first.
Synthetic or stock-looking images actively weaken the listing — the whole
pitch is honest results.

---

## ✅ Done

- App icon (1024×1024, no alpha) — brand-consistent placeholder, replace if
  you commission artwork
- `ITSAppUsesNonExemptEncryption=false` so export compliance stops being
  asked every upload
- Account deletion works end-to-end (App Store 5.1.1) — verified against the
  live backend
- Report + block, with a custom sheet; blocks bidirectional
- Terms of Service with zero-tolerance UGC clause, indemnity, Apple
  third-party-beneficiary, severability
- Privacy policy covering account data, content, goals, analytics,
  retention, security, children, and CA/EU rights
- Both docs live at `kumunoah.github.io/Dishd/`
- [Moderation runbook](../docs/MODERATION.md) for Apple's 24-hour SLA
- Cross-user RLS verified: 17/17 checks pass (private accounts, forced
  pending follows, no self-approval, no forged notifications, immutable
  recipes)
- Write-side hardening: no spoofed recipe authorship, 8 MB image-only upload
  caps, reports survive reporter deletion

## Known tradeoffs, accepted for v1

**Storage buckets are public.** A private user's review photos live on a
public CDN behind unguessable UUID paths. Standard practice (Instagram does
the same) and the API handing out those URLs is gated after migration 001 —
but it is technically weaker than "only approved followers see your
cooking." Moving to signed URLs is a real refactor; revisit if the app grows.

**No in-app admin tooling.** Moderation runs through the Supabase dashboard
per the runbook. Fine at launch scale, will not stay fine.

## Not legal advice

The docs are accurate and cover the standard bases, and the biggest real
liability — claiming protections the software doesn't have — has been
hunted down and fixed. That is not the same as a lawyer signing off. Worth
a consult before launch; UCI likely has a free entrepreneurship clinic.
