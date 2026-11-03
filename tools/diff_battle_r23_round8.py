from pathlib import Path
import json,collections,sys
P=Path(__file__).resolve().parents[1]/'verification/parity-r23'
a=json.loads((P/('battle-round8-'+(sys.argv[1] if len(sys.argv)>1 else 'latest')+'.json')).read_text(encoding='utf-8'))
def diff(g,e,path=''):
 if isinstance(g,dict) and isinstance(e,dict):
  for k in sorted(g.keys()|e.keys()):
   if k not in g or k not in e:yield path+'.'+k,g.get(k,'MISSING'),e.get(k,'MISSING')
   else:yield from diff(g[k],e[k],path+'.'+k)
 elif isinstance(g,list) and isinstance(e,list):
  if len(g)!=len(e):yield path+'.length',len(g),len(e)
  for i,(x,y)in enumerate(zip(g,e)):yield from diff(x,y,path+f'[{i}]')
 elif g!=e:yield path,g,e
seen=collections.Counter();paths=collections.Counter()
for r in a['rows']:
 if r['ok']:continue
 op=r['label'].split('/')[1];seen[op]+=1
 ds=list(diff(r['got'],r['want']))
 for p,g,e in ds:paths[(op,p)]+=1
 if seen[op]<=2:print(r['label'],ds[:18])
print('checks',a['checks'],'failures',len(a['failures']),dict(seen))
print(paths.most_common(22))
