#!/usr/bin/env python3
"""Public App Store sweep: our rank per keyword per storefront, ratings, and
competitor scale. Date-free by design (always 'now'). Writes aso-YYYY-MM-DD.json
next to this script so weekly runs accumulate their own history."""
import json, os, time, datetime as dt, urllib.request, urllib.parse
APP=6761796877
HERE=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(HERE, f"aso-{dt.date.today()}.json")
def get(url):
    for i in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent":"Mozilla/5.0"}), timeout=20) as r:
                return json.load(r)
        except Exception:
            time.sleep(2+i*2)
    return {}
KW={'en':["sleep tracker","bedtime","sleep habit tracker","sleep routine","bedtime reminder","sleep streak","sleep schedule","wind down"],
 'ja':["睡眠記録","就寝時間","睡眠習慣","睡眠管理","睡眠アプリ"],
 'ko':["수면 기록","취침 시간","수면 습관","수면 관리","수면 앱"],
 'de':["schlaf tracker","schlafenszeit","schlafgewohnheit","schlaf routine","schlaf app"],
 'nl':["slaap tracker","bedtijd","slaapgewoonte","slaapritme","slaap app"],
 'sv':["sömn tracker","läggdags","sömnvanor","sömnrutin","sömn app"],
 'es':["rastreador de sueño","hora de dormir","hábitos de sueño","rutina de sueño","dormir temprano","app para dormir"],
 'pt':["monitor de sono","hora de dormir","hábitos de sono","rotina de sono","dormir cedo","app para dormir"],
 'fr':["suivi du sommeil","heure du coucher","habitudes de sommeil","routine du soir","app sommeil"],
 'it':["monitoraggio sonno","abitudini del sonno","routine del sonno","dormire presto","app sonno"]}
CC={'us':'en','gb':'en','ca':'en','au':'en','sg':'en','ph':'en','vn':'en','nl':'nl','jp':'ja','kr':'ko','de':'de','at':'de','se':'sv','es':'es','mx':'es','ar':'es','br':'pt','fr':'fr','it':'it','dz':'fr'}
res={'generated':str(dt.date.today()),'ratings':{},'ranks':{}}
for cc in CC:
    d=get(f"https://itunes.apple.com/lookup?id={APP}&country={cc}")
    r=(d.get('results') or [{}])[0]
    res['ratings'][cc]={'count':r.get('userRatingCount'),'avg':r.get('averageUserRating')}
for cc,lang in CC.items():
    res['ranks'][cc]={}
    for term in KW[lang]:
        d=get(f"https://itunes.apple.com/search?term={urllib.parse.quote(term)}&country={cc}&entity=software&limit=200")
        items=d.get('results',[])
        pos=next((i+1 for i,a in enumerate(items) if a.get('trackId')==APP), None)
        res['ranks'][cc][term]={'pos':pos,'top3':[(a.get('trackName','')[:28],a.get('userRatingCount',0)) for a in items[:3]]}
        time.sleep(0.35)
    print(cc, {t:v['pos'] for t,v in res['ranks'][cc].items() if v['pos']}, flush=True)
json.dump(res, open(OUT,'w'), ensure_ascii=False)
print("saved", OUT)
