#!/usr/bin/env python3
"""Localize subscription + IAP display names/descriptions from
store/product_localizations.json. Idempotent: creates only missing locales,
updates changed ones. Waits until no app version is in review (adding
subscription localizations mid-review tangles their states — learned on
MultiPlant, June 2026).

STANDING RULE: run this after adding any new App Store locale, and add the new
locale's copy to product_localizations.json first.

Usage: python3 store/localize_products.py [--now]
"""
import json, os, sys, time, urllib.request, urllib.error, jwt

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = json.load(open(os.path.join(ROOT, "store", "product_localizations.json")))
KEY = open(os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_K34HFNJTXH.p8")).read()
APP = "6761796877"

def tok():
    now = int(time.time())
    return jwt.encode({"iss":"69a6de84-f289-47e3-e053-5b8c7c11a4d1","iat":now,"exp":now+900,"aud":"appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid":"K34HFNJTXH"})
def call(m, p, b=None):
    r = urllib.request.Request("https://api.appstoreconnect.apple.com"+p, method=m)
    r.add_header("Authorization", f"Bearer {tok()}"); r.add_header("Content-Type","application/json")
    try:
        with urllib.request.urlopen(r, json.dumps(b).encode() if b else None) as x:
            d=x.read(); return x.status, (json.loads(d) if d else {})
    except urllib.error.HTTPError as e:
        d=e.read()
        try: return e.code, json.loads(d)
        except Exception: return e.code, {}
def log(*a): print(time.strftime("%H:%M:%S"), *a, flush=True)

if "--now" not in sys.argv:
    while True:
        st, r = call("GET", f"/v1/apps/{APP}/appStoreVersions?limit=5")
        busy = [v["attributes"]["versionString"] for v in r["data"]
                if v["attributes"].get("appVersionState") in ("WAITING_FOR_REVIEW","IN_REVIEW")]
        if not busy: break
        log("waiting — in review:", busy); time.sleep(1800)

def sync(existing, want, post_path, post_type, rel_name, rel_type, rel_id):
    """existing: locale -> (id, attrs). want: locale -> {name, description}."""
    for loc, m in want.items():
        if loc in existing:
            lid, cur = existing[loc]
            if cur.get("name") == m["name"] and cur.get("description") == m.get("description"):
                log("  ", loc, "up to date"); continue
            st, r = call("PATCH", f"{post_path}/{lid}", {"data":{"type":post_type,"id":lid,
                "attributes":{k:v for k,v in m.items()}}})
            log("  ", loc, "update", st)
        else:
            st, r = call("POST", post_path, {"data":{"type":post_type,"attributes":dict(m, locale=loc),
                "relationships":{rel_name:{"data":{"type":rel_type,"id":rel_id}}}}})
            log("  ", loc, "create", st, "" if st in (200,201) else json.dumps(r)[:200])

st, r = call("GET", f"/v1/apps/{APP}/subscriptionGroups?limit=10")
gid = r["data"][0]["id"]

# Subscription group display name per locale
st, gl = call("GET", f"/v1/subscriptionGroups/{gid}/subscriptionGroupLocalizations?limit=30")
have = {l["attributes"]["locale"]: (l["id"], l["attributes"]) for l in gl["data"]}
gname = DATA["group"]["name"]
log("group localizations")
group_want = {loc: {"name": gname} for locs in DATA["products"].values() for loc in locs}
sync(have, group_want, "/v1/subscriptionGroupLocalizations", "subscriptionGroupLocalizations",
     "subscriptionGroup", "subscriptionGroups", gid)

# Subscriptions
st, s = call("GET", f"/v1/subscriptionGroups/{gid}/subscriptions?limit=20")
for sub in s["data"]:
    pid = sub["attributes"]["productId"]
    want = DATA["products"].get(pid)
    if not want: continue
    st, loc = call("GET", f"/v1/subscriptions/{sub['id']}/subscriptionLocalizations?limit=30")
    have = {l["attributes"]["locale"]: (l["id"], l["attributes"]) for l in loc["data"]}
    log(pid)
    sync(have, want, "/v1/subscriptionLocalizations", "subscriptionLocalizations",
         "subscription", "subscriptions", sub["id"])

# One-time IAPs
st, r = call("GET", f"/v1/apps/{APP}/inAppPurchasesV2?limit=20")
for attempt in range(5):
    if "data" in r: break
    log("iap list retry", st); time.sleep(10)
    st, r = call("GET", f"/v1/apps/{APP}/inAppPurchasesV2?limit=20")
for iap in r.get("data", []):
    pid = iap["attributes"]["productId"]
    want = DATA["products"].get(pid)
    if not want: continue
    st, loc = call("GET", f"/v2/inAppPurchases/{iap['id']}/inAppPurchaseLocalizations?limit=30")
    have = {l["attributes"]["locale"]: (l["id"], l["attributes"]) for l in loc["data"]}
    log(pid)
    sync(have, want, "/v1/inAppPurchaseLocalizations", "inAppPurchaseLocalizations",
         "inAppPurchaseV2", "inAppPurchases", iap["id"])

log("PRODUCT LOCALIZATIONS SYNCED")
