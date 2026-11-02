import json,sys
from pathlib import Path
r=json.loads(Path('verification/data-r21/'+(sys.argv[1] if len(sys.argv)>1 else 'p3-mixed-audit.json')).read_text(encoding='utf-8'))
seen=set()
print('equal',r['equal_battles'],'/',r['battles'])
for x in r['reports']:
 d=x['first_difference']
 if not d: continue
 k=(tuple(x['party']),tuple(d['fields']))
 if k in seen: continue
 seen.add(k)
 print(x['party'],x['foe'],x['bn'],'step',d['step'],d['input'])
 print({f:(d['source'].get(f),d['actual'].get(f)) for f in d['fields']})
