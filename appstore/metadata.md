# dishd — App Store Connect metadata

Everything here is ready to paste into App Store Connect once developer
enrollment clears. Privacy answers reflect the code as of July 2026 — if the
app starts collecting anything new (e.g. phone numbers, contacts, crash
reporting), update the label before shipping that build.

---

## 1. Privacy nutrition label (App Privacy section)

**Do you or your third-party partners collect data from this app?** → Yes

### Data types collected

**Contact Info → Name**
- Used for: App Functionality
- Linked to the user's identity: Yes
- Used for tracking: No

**Contact Info → Email Address**
- Used for: App Functionality
- Linked to the user's identity: Yes
- Used for tracking: No

**User Content → Photos or Videos** (review photos, profile photo)
- Used for: App Functionality
- Linked to the user's identity: Yes
- Used for tracking: No

**User Content → Other User Content** (reviews, ratings, saved recipe links,
follows, likes)
- Used for: App Functionality
- Linked to the user's identity: Yes
- Used for tracking: No

**Identifiers → User ID** (account UUID)
- Used for: App Functionality, Analytics
- Linked to the user's identity: Yes
- Used for tracking: No

**Usage Data → Product Interaction** (in-app events: signup, recipe saved,
review posted, onboarding completed)
- Used for: Analytics
- Linked to the user's identity: Yes
- Used for tracking: No

### Everything else → Not collected

Location, contacts, phone number, physical address, health, financial info,
messages, browsing history, search history, purchase history, diagnostics,
crash data, advertising data. No tracking across apps/websites. No
third-party advertising or analytics SDKs.

---

## 2. App Store listing

**App name** (30 chars max)
> dishd

**Subtitle** (30 chars max)
> What your friends really cook

**Category**
- Primary: Food & Drink
- Secondary: Social Networking

**Privacy policy URL**
> https://kumunoah.github.io/Dishd/privacy.html

**Promotional text** (170 chars max, editable without review)
> Your friends are cooking more than you think. See what they actually
> made, save the recipes worth making, and post your own honest results.

**Description**
> You save recipe videos constantly. TikTok, Instagram, YouTube — they pile
> up in your bookmarks and you never make any of them. Because you have no
> idea which ones are actually good.
>
> dishd fixes that with the one signal you trust: your friends.
>
> SAVE — Drop in a link from anywhere. Your recipes live in one place
> instead of scattered across three apps.
>
> COOK — Pick something a friend already made and rated. No more gambling
> on whether that 45-second video actually works.
>
> POST — Made it? Photo or it didn't happen. Every review on dishd has a
> real photo of a real attempt — honest results, not food styling.
>
> FRIENDS — Follow your people, see what they cook, request recipes from
> the friend whose food always slaps.
>
> No ads. No influencers. No 800-word blog intros. Just what your friends
> actually make, and whether it was worth it.

**Keywords** (100 chars max, comma-separated, no spaces after commas)
> recipes,recipe,cooking,food,social,save,tiktok,friends,meal,dinner,college,review,cook,easy

**Support URL**
> https://github.com/KUMUNoah/Dishd  (replace with a real support page or
> mailto link target before submission if preferred)

**Age rating questionnaire** — answer None/No to everything except:
- Unrestricted Web Access: No (links open in-app but only recipe sources)
- User-Generated Content: the UGC questions appear based on category; dishd
  has all four required safeguards: content reporting, user blocking,
  moderation (reports table reviewed within 24h), and terms with zero
  tolerance (linked at signup).
- Expected result: 12+ (social networking with UGC lands here; do not
  aim for 4+, reviewers will bounce it)

---

## 3. Screenshot plan (capture after seeding good content)

Required size: 6.9" (iPhone 16 Pro Max / 15 Pro Max) — 1320 × 2868.
5–6 screenshots, in this story order:

1. Feed with 3–4 appetizing friend reviews (the hook)
2. Recipe detail — photo, ratings, friend reviews
3. Save flow — pasting a TikTok link
4. Review composer — photo + stars (the "photo or it didn't happen" moment)
5. Profile with a filled cooking grid
6. (optional) Collection/folders view

Seed 2–3 test accounts with real cooked food photos before capturing —
stock-photo-looking content reads as fake and weakens the listing.
