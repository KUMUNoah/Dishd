#!/usr/bin/env python3
"""Cross-user RLS probe against the live Dishd backend.

Creates two throwaway accounts, tries every cross-user access we care about,
then deletes both. Only uses the publishable key — i.e. exactly what an
attacker who unpacked the app binary would have.
"""
import json, urllib.request, urllib.error, uuid, sys

BASE = "https://zzmffvjrqjweuggkgejc.supabase.co"
KEY  = "sb_publishable_jmlWCipuBULA1pmhlsBIwA_ZQVFUjFV"

def call(method, path, token=None, body=None, prefer=None):
    url = f"{BASE}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("apikey", KEY)
    req.add_header("Content-Type", "application/json")
    if token:  req.add_header("Authorization", f"Bearer {token}")
    if prefer: req.add_header("Prefer", prefer)
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read().decode()
            return r.status, (json.loads(raw) if raw.strip() else None)
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        try: return e.code, json.loads(raw)
        except Exception: return e.code, raw

def signup(tag):
    email = f"dishd-sec-{tag}-{uuid.uuid4().hex[:8]}@mailinator.com"
    st, r = call("POST", "/auth/v1/signup", body={
        "email": email, "password": "Testpass-2026-sec-x",
        "data": {"username": f"sec{tag}{uuid.uuid4().hex[:6]}", "full_name": f"Sec {tag}"}})
    if not r or not r.get("access_token"):
        print(f"  !! signup {tag} failed: {st} {r}"); sys.exit(1)
    return r["access_token"], r["user"]["id"], email

results = []
def check(name, condition_ok, detail=""):
    results.append((name, condition_ok, detail))
    print(f"  [{'PASS' if condition_ok else 'FAIL'}] {name}" + (f"  — {detail}" if detail else ""))

print("Creating two throwaway accounts...")
tokA, idA, emailA = signup("a")
tokB, idB, emailB = signup("b")
print(f"  A={idA[:8]}  B={idB[:8]}\n")

print("Cross-user reads:")
st, r = call("GET", f"/rest/v1/goals?select=*&user_id=eq.{idB}", tokA)
check("A cannot read B's goals", isinstance(r, list) and len(r) == 0, f"got {r}")

st, r = call("GET", f"/rest/v1/notifications?select=*&user_id=eq.{idB}", tokA)
check("A cannot read B's notifications", isinstance(r, list) and len(r) == 0)

st, r = call("GET", "/rest/v1/reports?select=*", tokA)
check("A cannot read reports", isinstance(r, list) and len(r) == 0)

st, r = call("GET", "/rest/v1/analytics_events?select=*", tokA)
check("A cannot read analytics", isinstance(r, list) and len(r) == 0)

st, r = call("GET", f"/rest/v1/blocks?select=*&blocker_id=eq.{idB}", tokA)
check("A cannot read B's blocks", isinstance(r, list) and len(r) == 0)

print("\nCross-user writes:")
st, r = call("PATCH", f"/rest/v1/profiles?id=eq.{idB}", tokA,
             body={"bio": "PWNED by A"}, prefer="return=representation")
check("A cannot edit B's profile", not (isinstance(r, list) and len(r) > 0), f"status {st}")

st, r = call("POST", "/rest/v1/goals", tokA,
             body={"user_id": idB, "cook_per_week": 99, "new_recipes_per_year": 99})
check("A cannot write goals as B", st >= 400, f"status {st}")

st, r = call("POST", "/rest/v1/analytics_events", tokA,
             body={"user_id": idB, "event": "forged", "properties": {}})
check("A cannot forge analytics as B", st >= 400, f"status {st}")

st, r = call("POST", "/rest/v1/notifications", tokA,
             body={"user_id": idB, "actor_id": idA, "type": "like"})
check("A cannot forge a notification to B", st >= 400, f"status {st}")

st, r = call("POST", "/rest/v1/follows", tokA,
             body={"follower_id": idB, "following_id": idA, "status": "accepted"})
check("A cannot make B follow A", st >= 400, f"status {st}")

st, r = call("POST", "/rest/v1/blocks", tokA,
             body={"blocker_id": idB, "blocked_id": idA})
check("A cannot block on B's behalf", st >= 400, f"status {st}")

print("\nPrivate-account content:")
call("PATCH", f"/rest/v1/profiles?id=eq.{idB}", tokB, body={"is_private": True})
st, recipe = call("POST", "/rest/v1/recipes", tokB,
                  body={"title": "Secret dish", "created_by": idB}, prefer="return=representation")
rid = recipe[0]["id"] if isinstance(recipe, list) and recipe else None
if rid:
    call("POST", "/rest/v1/reviews", tokB,
         body={"user_id": idB, "recipe_id": rid, "rating": 5,
               "notes": "PRIVATE NOTE", "photo_url": "https://example.com/x.jpg"})
    st, r = call("GET", f"/rest/v1/reviews?select=*&user_id=eq.{idB}", tokA)
    check("A cannot read private B's reviews", isinstance(r, list) and len(r) == 0, f"got {len(r) if isinstance(r,list) else r}")
    st, r = call("GET", f"/rest/v1/reviews?select=*&user_id=eq.{idB}")
    check("anon cannot read private B's reviews", isinstance(r, list) and len(r) == 0)

    st, r = call("POST", "/rest/v1/follows", tokA,
                 body={"follower_id": idA, "following_id": idB}, prefer="return=representation")
    status = r[0]["status"] if isinstance(r, list) and r else "?"
    check("follow of a private account is forced pending", status == "pending", f"status={status}")

    st, r = call("GET", f"/rest/v1/reviews?select=*&user_id=eq.{idB}", tokA)
    check("pending follower still cannot read", isinstance(r, list) and len(r) == 0)

    st, r = call("PATCH", f"/rest/v1/follows?follower_id=eq.{idA}&following_id=eq.{idB}",
                 tokA, body={"status": "accepted"}, prefer="return=representation")
    st2, r2 = call("GET", f"/rest/v1/reviews?select=*&user_id=eq.{idB}", tokA)
    check("A cannot self-approve its own follow request",
          isinstance(r2, list) and len(r2) == 0, f"reviews visible: {len(r2) if isinstance(r2,list) else r2}")

    st, r = call("DELETE", f"/rest/v1/recipes?id=eq.{rid}", tokA)
    st2, r2 = call("GET", f"/rest/v1/recipes?select=id&id=eq.{rid}", tokB)
    check("canonical recipes are immutable", isinstance(r2, list) and len(r2) == 1)

print("\nCleaning up...")
for tok, tag in ((tokA, "A"), (tokB, "B")):
    st, _ = call("POST", "/rest/v1/rpc/delete_user", tok, body={})
    print(f"  deleted {tag}: HTTP {st}")

failed = [n for n, ok, _ in results if not ok]
print(f"\n{len(results)-len(failed)}/{len(results)} passed")
if failed:
    print("FAILURES:")
    for f in failed: print("  -", f)
