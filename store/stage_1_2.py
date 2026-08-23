#!/usr/bin/env python3
"""Stage SleepLock 1.2 in App Store Connect once 1.1 leaves review.
Creates version 1.2, attaches build 12, writes 14 locales (app-level + version-level),
uploads 6.9" screenshots for every locale. Never submits for review.
Usage: python3 store/stage_1_2.py [--now]   (--now skips the wait)"""
import json, os, sys, time, hashlib, urllib.request, urllib.error, jwt

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
META = json.load(open(os.path.join(ROOT, "store", "asc_meta_1_2.json")))
SHOTS = os.path.join(ROOT, "screenshots", "appstore")
KEY = open(os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_K34HFNJTXH.p8")).read()
APP = "6761796877"; BUILD_NO = "12"; VERSION = "1.2"
LANG_FOR = {"en-US":"en","en-GB":"en","en-AU":"en","en-CA":"en","es-MX":"es","es-ES":"es","pt-BR":"pt-BR","fr-FR":"fr","it":"it","de-DE":"de","nl-NL":"nl","ja":"ja","ko":"ko","sv":"sv"}
FRAMES = ["01-LOCK-IN-YOUR-BEDTIME","02-BUILD-UNBREAKABLE-STREAKS","03-LEVEL-UP-YOUR-SLEEP","04-SEE-YOUR-SLEEP-TRENDS"]

def tok():
    now = int(time.time())
    return jwt.encode({"iss":"69a6de84-f289-47e3-e053-5b8c7c11a4d1","iat":now,"exp":now+900,"aud":"appstoreconnect-v1"}, KEY, algorithm="ES256", headers={"kid":"K34HFNJTXH"})
def call(m, p, b=None, headers=None, data=None):
    url = p if p.startswith("http") else "https://api.appstoreconnect.apple.com"+p
    r = urllib.request.Request(url, method=m)
    if headers is None:
        r.add_header("Authorization", f"Bearer {tok()}"); r.add_header("Content-Type","application/json")
    else:
        for k,v in headers.items(): r.add_header(k,v)
    body = data if data is not None else (json.dumps(b).encode() if b else None)
    try:
        with urllib.request.urlopen(r, body) as x: d=x.read(); return x.status, (json.loads(d) if d and headers is None else {})
    except urllib.error.HTTPError as e:
        d=e.read()
        try: return e.code, json.loads(d)
        except Exception: return e.code, {"raw": d[:200].decode(errors="replace")}
def log(*a): print(time.strftime("%H:%M:%S"), *a, flush=True)

# ── 1. Wait for the review queue to clear ───────────────────────────────
def blocking_versions():
    st, r = call("GET", f"/v1/apps/{APP}/appStoreVersions?limit=5")
    return [(v["attributes"]["versionString"], v["attributes"].get("appVersionState")) for v in r["data"]
            if v["attributes"].get("appVersionState") in ("WAITING_FOR_REVIEW","IN_REVIEW","PENDING_APPLE_RELEASE","PROCESSING_FOR_DISTRIBUTION")]
if "--now" not in sys.argv:
    while True:
        b = blocking_versions()
        if not b: break
        log("waiting — in review:", b); time.sleep(1800)

# ── 2. Version 1.2 ──────────────────────────────────────────────────────
st, r = call("GET", f"/v1/apps/{APP}/appStoreVersions?filter[versionString]={VERSION}")
vid = r["data"][0]["id"] if r.get("data") else None
if not vid:
    st, r = call("POST", "/v1/appStoreVersions", {"data":{"type":"appStoreVersions","attributes":{"platform":"IOS","versionString":VERSION},"relationships":{"app":{"data":{"type":"apps","id":APP}}}}})
    if st not in (200,201): log("CREATE VERSION FAILED", st, r); sys.exit(1)
    vid = r["data"]["id"]
log("version", VERSION, vid)

# ── 3. Attach build 12 ──────────────────────────────────────────────────
st, r = call("GET", f"/v1/builds?filter[app]={APP}&filter[version]={BUILD_NO}&sort=-uploadedDate&limit=5")
valid = [b for b in r.get("data",[]) if b["attributes"].get("processingState")=="VALID"]
if valid:
    st, r2 = call("PATCH", f"/v1/appStoreVersions/{vid}/relationships/build", {"data":{"type":"builds","id":valid[0]["id"]}})
    log("attach build", BUILD_NO, st)
else:
    log("build", BUILD_NO, "not VALID yet — attach later")

# ── 4. App-level localizations (name / subtitle) ────────────────────────
st, r = call("GET", f"/v1/apps/{APP}/appInfos")
info = next((i for i in r["data"] if i["attributes"].get("state") not in ("READY_FOR_SALE","READY_FOR_DISTRIBUTION")), r["data"][-1])["id"]
st, r = call("GET", f"/v1/appInfos/{info}/appInfoLocalizations?limit=50")
have = {l["attributes"]["locale"]: l for l in r["data"]}
priv = have["en-US"]["attributes"].get("privacyPolicyUrl")
for loc, m in META.items():
    attrs = {"name": m["name"], "subtitle": m["subtitle"]} if "name" in m else {}
    if not attrs: continue
    if loc in have:
        st, r2 = call("PATCH", f"/v1/appInfoLocalizations/{have[loc]['id']}", {"data":{"type":"appInfoLocalizations","id":have[loc]["id"],"attributes":attrs}})
    else:
        attrs.update({"locale": loc, "privacyPolicyUrl": priv})
        st, r2 = call("POST", "/v1/appInfoLocalizations", {"data":{"type":"appInfoLocalizations","attributes":attrs,"relationships":{"appInfo":{"data":{"type":"appInfos","id":info}}}}})
    log("appInfo", loc, st, "" if st in (200,201) else json.dumps(r2)[:200])

# ── 5. Version-level localizations ──────────────────────────────────────
st, r = call("GET", f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50")
vloc = {l["attributes"]["locale"]: l["id"] for l in r["data"]}
for loc, m in META.items():
    attrs = {k: m[k] for k in ("keywords","promotionalText","description","whatsNew") if k in m}
    if loc in vloc:
        st, r2 = call("PATCH", f"/v1/appStoreVersionLocalizations/{vloc[loc]}", {"data":{"type":"appStoreVersionLocalizations","id":vloc[loc],"attributes":attrs}})
    else:
        attrs["locale"] = loc
        st, r2 = call("POST", "/v1/appStoreVersionLocalizations", {"data":{"type":"appStoreVersionLocalizations","attributes":attrs,"relationships":{"appStoreVersion":{"data":{"type":"appStoreVersions","id":vid}}}}})
        if st in (200,201): vloc[loc] = r2["data"]["id"]
    log("versionLoc", loc, st, "" if st in (200,201) else json.dumps(r2)[:300])

# ── 6. Screenshots (6.9" iPhone) ────────────────────────────────────────
def upload_set(loc_id, lang):
    st, r = call("GET", f"/v1/appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=50")
    for s in r.get("data", []):
        if s["attributes"]["screenshotDisplayType"] == "APP_IPHONE_67":
            call("DELETE", f"/v1/appScreenshotSets/{s['id']}")
    st, r = call("POST", "/v1/appScreenshotSets", {"data":{"type":"appScreenshotSets","attributes":{"screenshotDisplayType":"APP_IPHONE_67"},"relationships":{"appStoreVersionLocalization":{"data":{"type":"appStoreVersionLocalizations","id":loc_id}}}}})
    if st not in (200,201): return f"set FAIL {st} {json.dumps(r)[:150]}"
    set_id = r["data"]["id"]; ok = 0
    for f in FRAMES:
        path = os.path.join(SHOTS, lang, f + ".png")
        if not os.path.exists(path): continue
        data = open(path, "rb").read()
        st, r = call("POST", "/v1/appScreenshots", {"data":{"type":"appScreenshots","attributes":{"fileName":f+".png","fileSize":len(data)},"relationships":{"appScreenshotSet":{"data":{"type":"appScreenshotSets","id":set_id}}}}})
        if st not in (200,201): return f"reserve FAIL {st} {json.dumps(r)[:150]}"
        sid = r["data"]["id"]
        for op in r["data"]["attributes"]["uploadOperations"]:
            h = {x["name"]: x["value"] for x in op.get("requestHeaders", [])}
            st2, _ = call(op["method"], op["url"], headers=h, data=data[op["offset"]:op["offset"]+op["length"]])
            if st2 >= 300: return f"PUT FAIL {st2}"
        st, r = call("PATCH", f"/v1/appScreenshots/{sid}", {"data":{"type":"appScreenshots","id":sid,"attributes":{"uploaded":True,"sourceFileChecksum":hashlib.md5(data).hexdigest()}}})
        if st == 200: ok += 1
    return f"{ok}/{len(FRAMES)} uploaded"
for loc, lid in vloc.items():
    lang = LANG_FOR.get(loc)
    if lang: log("screenshots", loc, upload_set(lid, lang))

log("STAGED — version 1.2 is in Prepare for Submission. NOT submitted.")
