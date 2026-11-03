from pathlib import Path
import json,sys,collections
sys.stdout.reconfigure(encoding='utf-8')
O=Path(__file__).resolve().parents[1]/'verification/parity-r23'
def diff(a,b,path=''):
 if isinstance(a,dict) and isinstance(b,dict):
  return sum((diff(a.get(k,'<ABSENT>'),b.get(k,'<ABSENT>'),path+'/'+k) for k in sorted(a.keys()|b.keys())),[])
 if isinstance(a,list) and isinstance(b,list):
  return [(path+'/length',len(a),len(b))] if len(a)!=len(b) else sum((diff(x,y,path+'/'+str(i)) for i,(x,y) in enumerate(zip(a,b))),[])
 if isinstance(a,(int,float)) and not isinstance(a,bool) and isinstance(b,(int,float)) and not isinstance(b,bool):
  return [] if abs(a-b)<1e-7 else [(path,a,b)]
 return [] if type(a)==type(b) and a==b else [(path,a,b)]
j=json.loads((O/('battle-round7-'+(sys.argv[1] if sys.argv[1:] else 'latest')+'.json')).read_text(encoding='utf-8'))
seen=set();counts=collections.Counter();paths=collections.Counter()
for r in j['rows']:
 op=r['label'].split('/')[1]
 if not r['ok']:
  counts[op]+=1;d=diff(r['got'],r['want']);paths.update(x[0] for x in d)
  if op not in seen:seen.add(op);print(r['label'],json.dumps(d[:14],ensure_ascii=False))
print('FAILURES',dict(counts));print('PATHS',paths.most_common(18))
