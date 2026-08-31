#!/usr/bin/env python3
"""Weekly SleepLock data pull. All windows are RELATIVE: computed from today,
ending yesterday. Never hardcode dates here — that is how tooling rots.
Outputs JSON to stdout."""
import json, sys, time, datetime as dt, urllib.request, urllib.parse

AF="https://api.appfigures.com/v2"
H={"Authorization":"Bearer pat_cG2ZgCg9Ik6yEkM4JS1iKDwbzsx7sPPD","X-Client-Key":"2978a2642dbc48098156bd78b8bb04f1"}
P="338567480194"  # Appfigures product id for SleepLock

today=dt.date.today(); yday=today-dt.timedelta(days=1)
wk_start=yday-dt.timedelta(days=6)              # this week: 7 days ending yesterday
prev_start=wk_start-dt.timedelta(days=7); prev_end=wk_start-dt.timedelta(days=1)
LIFE_START="2026-06-01"                          # app first tracked

def get(path):
    req=urllib.request.Request(AF+path)
    for k,v in H.items(): req.add_header(k,v)
    for i in range(3):
        try:
            with urllib.request.urlopen(req,timeout=30) as r: return json.load(r)
        except Exception as e:
            time.sleep(2+2*i)
    return {}

out={"generated":str(today),"window":{"start":str(wk_start),"end":str(yday)},
     "prev_window":{"start":str(prev_start),"end":str(prev_end)}}
out["daily"]=get(f"/reports/sales?products={P}&group_by=date&granularity=daily&start_date={LIFE_START}&end_date={yday}")
out["week_by_country"]=get(f"/reports/sales?products={P}&group_by=country&start_date={wk_start}&end_date={yday}")
out["prev_by_country"]=get(f"/reports/sales?products={P}&group_by=country&start_date={prev_start}&end_date={prev_end}")
out["life_by_country"]=get(f"/reports/sales?products={P}&group_by=country&start_date={LIFE_START}&end_date={yday}")
out["subs_week"]=get(f"/reports/subscriptions?products={P}&group_by=date&granularity=daily&start_date={wk_start}&end_date={yday}")
out["subs_life"]=get(f"/reports/subscriptions?products={P}&start_date={LIFE_START}&end_date={yday}")
json.dump(out, open(sys.argv[1],"w"))
print("window", wk_start, "->", yday)
# quick sanity: daily keys must include dates from this week (window actually moved)
days=sorted(out["daily"].keys())
print("daily span:", days[0] if days else None, "->", days[-1] if days else None, "rows:", len(days))
