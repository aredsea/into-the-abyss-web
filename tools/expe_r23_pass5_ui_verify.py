from expe_r23_pass5_project import Visible,O
import json
native=json.loads((O/'expe-pass5-ui-observations.json').read_text(encoding='utf-8'))
lua=json.loads((O/'expe-pass5-ui-lua.json').read_text(encoding='utf-8'))
rows=[]
assert len(native)==len(lua)
for i,(n,s)in enumerate(zip(native,lua)):
 expected=Visible(s['html']).result()
 # Decimal meter paint is compared to the source's three-decimal CSS fraction.
 actual=n['visible']
 for a,e in zip(actual['bars'],expected['bars']):
  if abs(a['ratio']-e['ratio'])<1e-9:a['ratio']=e['ratio']
 rows.append({'index':i,'kind':n['kind'],'lang':n['lang'],'passed':actual==expected,'native':actual,'source':expected})
(O/'expe-pass5-ui-direct-results.json').write_text(json.dumps({'checks':len(rows),'failures':sum(not r['passed']for r in rows),'rows':rows},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(rows),'failures':sum(not r['passed']for r in rows)}))
raise SystemExit(0 if all(r['passed']for r in rows)else 1)
