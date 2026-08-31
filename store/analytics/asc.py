import json, time, urllib.request, urllib.error, jwt, os
KEY=open(os.path.expanduser("~/.appstoreconnect/private_keys/AuthKey_K34HFNJTXH.p8")).read()
APP="6761796877"
def tok():
    now=int(time.time()); return jwt.encode({"iss":"69a6de84-f289-47e3-e053-5b8c7c11a4d1","iat":now,"exp":now+900,"aud":"appstoreconnect-v1"},KEY,algorithm="ES256",headers={"kid":"K34HFNJTXH"})
def call(m,p,b=None):
    r=urllib.request.Request(("https://api.appstoreconnect.apple.com"+p) if p.startswith("/") else p, method=m)
    r.add_header("Authorization",f"Bearer {tok()}"); r.add_header("Content-Type","application/json")
    try:
        with urllib.request.urlopen(r, json.dumps(b).encode() if b else None) as x:
            d=x.read(); return x.status,(json.loads(d) if d else {})
    except urllib.error.HTTPError as e:
        d=e.read()
        try: return e.code, json.loads(d)
        except Exception: return e.code, {}
