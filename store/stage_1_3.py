#!/usr/bin/env python3
"""Create ASC version 1.3, set localized What's New, attach build 14, submit.
Metadata (keywords/desc/promo/screenshots) carries over from 1.2 automatically."""
import json, os, sys, time, urllib.request, urllib.error, jwt
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WN=json.load(open(os.path.join(ROOT,"store","whatsnew_1_3.json")))
LOCMAP={"en-US":"en","en-GB":"en","en-AU":"en","en-CA":"en","es-MX":"es","es-ES":"es","pt-BR":"pt","fr-FR":"fr","it":"it","de-DE":"de","nl-NL":"nl","ja":"ja","ko":"ko","sv":"sv"}
KEY=open(os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_K34HFNJTXH.p8")).read()
APP="6761796877"; BUILD="14"; V="1.3"
def tok():
    now=int(time.time()); return jwt.encode({"iss":"69a6de84-f289-47e3-e053-5b8c7c11a4d1","iat":now,"exp":now+900,"aud":"appstoreconnect-v1"},KEY,algorithm="ES256",headers={"kid":"K34HFNJTXH"})
def call(m,p,b=None):
    r=urllib.request.Request("https://api.appstoreconnect.apple.com"+p,method=m); r.add_header("Authorization",f"Bearer {tok()}"); r.add_header("Content-Type","application/json")
    try:
        with urllib.request.urlopen(r, json.dumps(b).encode() if b else None) as x: d=x.read(); return x.status,(json.loads(d) if d else {})
    except urllib.error.HTTPError as e:
        d=e.read()
        try: return e.code, json.loads(d)
        except Exception: return e.code, {}
def log(*a): print(time.strftime("%H:%M:%S"),*a,flush=True)
# version
st,r=call("GET",f"/v1/apps/{APP}/appStoreVersions?filter[versionString]={V}")
vid=r["data"][0]["id"] if r.get("data") else None
if not vid:
    st,r=call("POST","/v1/appStoreVersions",{"data":{"type":"appStoreVersions","attributes":{"platform":"IOS","versionString":V},"relationships":{"app":{"data":{"type":"apps","id":APP}}}}})
    if st not in (200,201): log("CREATE FAIL",st,json.dumps(r)[:300]); sys.exit(1)
    vid=r["data"]["id"]
log("version",V,vid)
# whatsNew per locale
st,r=call("GET",f"/v1/appStoreVersions/{vid}/appStoreVersionLocalizations?limit=50")
for l in r["data"]:
    loc=l["attributes"]["locale"]; wn=WN.get(LOCMAP.get(loc,"en"),WN["en"])
    st2,r2=call("PATCH",f"/v1/appStoreVersionLocalizations/{l['id']}",{"data":{"type":"appStoreVersionLocalizations","id":l["id"],"attributes":{"whatsNew":wn}}})
    log("whatsNew",loc,st2,"" if st2==200 else json.dumps(r2)[:200])
# wait for build 14 VALID and attach
deadline=time.time()+45*60; bid=None
while time.time()<deadline:
    st,b=call("GET",f"/v1/builds?filter[app]={APP}&filter[version]={BUILD}&sort=-uploadedDate&limit=3")
    for x in b.get("data",[]):
        ps=x["attributes"].get("processingState"); log("build",BUILD,ps)
        if ps=="VALID": bid=x["id"]
        elif ps in ("FAILED","INVALID"): log("BUILD FAILED"); sys.exit(1)
    if bid: break
    time.sleep(60)
if not bid: log("TIMEOUT build"); sys.exit(1)
st,r=call("PATCH",f"/v1/appStoreVersions/{vid}/relationships/build",{"data":{"type":"builds","id":bid}})
log("attach",st)
# submit
st,r=call("POST","/v1/reviewSubmissions",{"data":{"type":"reviewSubmissions","attributes":{"platform":"IOS"},"relationships":{"app":{"data":{"type":"apps","id":APP}}}}})
sub=r["data"]["id"] if st in (200,201) else None
if not sub:
    st,r=call("GET",f"/v1/reviewSubmissions?filter[app]={APP}&filter[platform]=IOS&filter[state]=READY_FOR_REVIEW&limit=5")
    sub=r["data"][0]["id"]
st,r=call("POST","/v1/reviewSubmissionItems",{"data":{"type":"reviewSubmissionItems","relationships":{"reviewSubmission":{"data":{"type":"reviewSubmissions","id":sub}},"appStoreVersion":{"data":{"type":"appStoreVersions","id":vid}}}}})
log("add item",st,"" if st in (200,201) else json.dumps(r)[:400])
if st not in (200,201): sys.exit(1)
st,r=call("PATCH",f"/v1/reviewSubmissions/{sub}",{"data":{"type":"reviewSubmissions","id":sub,"attributes":{"submitted":True}}})
log("submit",st,r.get("data",{}).get("attributes",{}).get("state") or json.dumps(r)[:300])
