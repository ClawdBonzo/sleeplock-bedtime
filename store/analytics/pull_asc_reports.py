#!/usr/bin/env python3
"""Download ASC Analytics report instances (ONGOING request) into a dir.
Prefix-matches report names (Apple renames reports); prints what exists."""
import json, sys, os, gzip, io, time, urllib.request
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asc import call
REQ="41455f71-6c25-43a7-b99b-273e5ee39613"
WANT_PREFIXES=["App Store Discovery and Engagement","App Downloads","App Sessions","App Store Installation and Deletion","App Crashes","App Store Purchases"]
OUT=sys.argv[1]; os.makedirs(OUT,exist_ok=True)
st,r=call("GET",f"/v1/analyticsReportRequests/{REQ}/reports?limit=200")
if "data" not in r: print("REPORT LIST FAILED",st,json.dumps(r)[:200]); sys.exit(1)
names=[(x["id"],x["attributes"]["name"],x["attributes"].get("category")) for x in r["data"]]
print("available reports:", len(names))
for rid,name,cat in names:
    if not any(name.startswith(p) for p in WANT_PREFIXES): continue
    st,inst=call("GET",f"/v1/analyticsReports/{rid}/instances?limit=10")
    insts=inst.get("data",[])
    if not insts: print(f"  {name}: no instances yet"); continue
    # newest instance
    best=sorted(insts,key=lambda i:i["attributes"].get("processingDate",""))[-1]
    st,segs=call("GET",f"/v1/analyticsReportInstances/{best['id']}/segments?limit=10")
    n=0
    for s in segs.get("data",[]):
        url=s["attributes"]["url"]
        data=urllib.request.urlopen(url,timeout=60).read()
        try: data=gzip.decompress(data)
        except Exception: pass
        fn=os.path.join(OUT, name.replace(" ","_")+f"_{n}.csv"); open(fn,"wb").write(data); n+=1
    print(f"  {name} [{best['attributes'].get('granularity')}] {best['attributes'].get('processingDate')}: {n} segments")
