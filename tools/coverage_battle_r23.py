"""Replay R23 oracles with Boolean entry probes, leaving canonical files read-only.

The token mask and entry-key format follow the R22b auditor so its remaining
branch keys can be compared directly. Coverage is evidence of execution only.
"""
from pathlib import Path
import re,bisect,json,hashlib,subprocess,sys,time,os
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
D=O/'coverage';D.mkdir(exist_ok=True);I=D/'instrumented';I.mkdir(exist_ok=True)
SRC=Path('C:/Clauede Code/dungeon-bot/bot/src')
TOKEN=re.compile(r'--\[(=*)\[[\s\S]*?\]\1\]|--[^\n]*|\[(=*)\[[\s\S]*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
meta={}
for p in SRC.glob('*.lua'):
 if p.name not in ['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','26-start.lua','27-compose.lua','29-persona-skill.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','40-fx.lua','50-render.lua','51-raid.lua','71-shop.lua','78-battle-item.lua','80-press.lua','81-gear.lua']:continue
 s=p.read_text(encoding='utf-8');masked=TOKEN.sub(lambda m:''.join('\n' if c=='\n' else ' ' for c in m[0]),s)
 starts=[0]+[x.end() for x in re.finditer('\n',s)];changes=[];branches={};calls={}
 for t in re.finditer(r'\bfunction\s*(?:[\w.:]+\s*)?\([^)]*\)',masked):
  line=bisect.bisect_right(starts,t.start());key=f'{p.name}:{line}'
  changes.append((t.end(),f' B.__r23_cov.calls["{key}"]=true; '));calls[key]={'line':line,'offset':t.start()}
 for t in re.finditer(r'\b(?:then|else|do)\b',masked):
  line=bisect.bisect_right(starts,t.start());key=f'{p.name}:{line}:{t.start()}'
  changes.append((t.end(),f' B.__r23_cov.branches["{key}"]=true; '));branches[key]={'line':line,'offset':t.start(),'token':t[0]}
 for offset,insert in sorted(changes,reverse=True):s=s[:offset]+insert+s[offset:]
 (I/p.name).write_text(s,encoding='utf-8')
 meta[p.name]={'source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'calls':calls,'branches':branches}
(D/'instrumentation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
cases=['main','enemy','state','display','compose','clock','batch','round3','round4'];runs=[]
for key in cases:
 name='oracle_battle_r23'+('' if key=='main' else '_'+key)+'.mjs'
 if key in ['round3','round4']:name='oracle_battle_r23_'+key+'_loader.mjs'
 code=(R/'tools'/name).read_text(encoding='utf-8')
 code=code.replace('const {mkSim}=await import(', 'const {mkSim:mkSimBase}=await import(',1)
 # Replace the source read used in rule loading, leaving the original-file
 # provenance hash reads separate. The compose loader stores these in raw.
 code=code.replace("fs.readFileSync(path.join(root,'bot/src',f),'utf8')",f"fs.readFileSync(path.join('{I.as_posix()}',f),'utf8')")
 pos=code.index('const files=')
 wrapper=f'''const mkSim=async(o)=>{{const sim=await mkSimBase({{...o,extra:'B.__r23_cov={{calls={{}},branches={{}}}}\\n'+o.extra}});const original=sim.L;return {{...sim,L:async(code)=>{{const pack=await original('B.__r23_cov={{calls={{}},branches={{}}}};local __result=(function()\\n'+code+'\\nend)();return {{result=__result,coverage=B.__r23_cov}}');fs.writeFileSync('verification/parity-r23/coverage/{key}.json',JSON.stringify(pack.coverage));return pack.result;}}}};}};\n'''
 code=code[:pos]+wrapper+code[pos:]
 for stem in ['oracle','enemy-oracle','state-oracle','display-oracle','compose-oracle','clock-oracle','batch-oracle','round3-oracle','round4-oracle']:
  code=code.replace(f"'verification/parity-r23/{stem}.json'",f"'verification/parity-r23/coverage/{key}-oracle.json'")
 script=D/(key+'.mjs');script.write_text(code,encoding='utf-8');start=time.monotonic()
 with (D/(key+'.log')).open('wb') as log:p=subprocess.run(['node',str(script)],cwd=R,stdout=log,stderr=subprocess.STDOUT)
 row={'case':key,'exit':p.returncode,'seconds':round(time.monotonic()-start,2)};runs.append(row);print(json.dumps(row),flush=True)
 if p.returncode:raise SystemExit(p.returncode)
 original=json.loads((O/('oracle.json' if key=='main' else key+'-oracle.json')).read_text(encoding='utf-8'))
 observed=json.loads((D/(key+'-oracle.json')).read_text(encoding='utf-8'))
 original.pop('provenance',None);observed.pop('provenance',None)
 if original!=observed:raise AssertionError('Instrumentation changed oracle result: '+key)
retained=[
 ('retained-p2','oracle_combat_p2_r22.mjs','p2-oracle.json',{}),
 ('retained-a6','oracle_combat_a6_mixed.mjs','a6-mixed-oracle.json',{}),
 ('retained-p3','oracle_combat_p3_mixed.mjs','p3-mixed-oracle.json',{}),
 ('retained-a7','oracle_combat_a7_gear.mjs','a7-gear-oracle.json',{}),
 ('retained-a7b','oracle_combat_a7_gear_balanced.mjs','a7-gear-balanced-oracle.json',{}),
 ('retained-a8','oracle_combat_a8_r22.mjs','a8-oracle.json',{}),
 ('retained-a9-10','oracle_combat_a9_native.mjs','a9-native-10-oracle.json',{'A9_ENEMY_LEVEL':'10'}),
 ('retained-a9-40','oracle_combat_a9_native.mjs','a9-native-40-oracle.json',{'A9_ENEMY_LEVEL':'40'}),
 ('retained-unit-a6','oracle_combat_a6_r22.mjs','a6-oracle.json',{}),
 ('retained-unit-p3','oracle_combat_p3_r22.mjs','p3-oracle.json',{}),
]
for key,name,expected,env in retained:
 code=(R/'tools'/name).read_text(encoding='utf-8')
 code=code.replace('const {mkSim}=await import(', 'const {mkSim:mkSimBase}=await import(',1)
 code=re.sub(r"fs.readFileSync\(path.join\((?:root|source),'bot/src',f\),'utf8'\)",lambda m:f"fs.readFileSync(path.join('{I.as_posix()}',f),'utf8')",code)
 pos=code.index('const files=')
 wrapper=f'''const mkSim=async(o)=>{{const sim=await mkSimBase({{...o,extra:'B.__r23_cov={{calls={{}},branches={{}}}}\\n'+o.extra}});const original=sim.L;return {{...sim,L:async(code)=>{{const pack=await original('B.__r23_cov={{calls={{}},branches={{}}}};local __result=(function()\\n'+code+'\\nend)();return {{result=__result,coverage=B.__r23_cov}}');fs.writeFileSync('verification/parity-r23/coverage/{key}.json',JSON.stringify(pack.coverage));return pack.result;}}}};}};\n'''
 code=code[:pos]+wrapper+code[pos:]
 code=code.replace("fs.writeFileSync('verification/data-r21/",f"fs.writeFileSync('verification/parity-r23/coverage/{key}-")
 script=D/(key+'.mjs');script.write_text(code,encoding='utf-8');start=time.monotonic()
 with (D/(key+'.log')).open('wb') as log:p=subprocess.run(['node',str(script)],cwd=R,stdout=log,stderr=subprocess.STDOUT,env={**os.environ,**env})
 row={'case':key,'exit':p.returncode,'seconds':round(time.monotonic()-start,2),'expected':expected};runs.append(row);print(json.dumps(row),flush=True)
 if p.returncode:raise SystemExit(p.returncode)
 original=json.loads((R/'verification/data-r21'/expected).read_text(encoding='utf-8'))
 observed=json.loads((D/(key+'-'+expected)).read_text(encoding='utf-8'))
 original.pop('provenance',None);observed.pop('provenance',None)
 if original!=observed:raise AssertionError('Fresh source output changed: '+key)
calls={};branches={}
for key in cases+[r[0] for r in retained]:
 v=json.loads((D/(key+'.json')).read_text(encoding='utf-8'));calls.update(v['calls'] if isinstance(v['calls'],dict) else {});branches.update(v['branches'] if isinstance(v['branches'],dict) else {})
baseline=json.loads((O/'battle-baseline.json').read_text(encoding='utf-8'));rows=[]
for group in baseline['groups']:
 for item in group['items']:
  src=item['source'];file=Path(src['file']).name;fn=meta.get(file,{})
  keys={k:v for k,v in fn.get('branches',{}).items() if src['start']<=v['line']<=src['end']}
  missing=[b for b in item['unverified_branches'] if b['key'] not in branches]
  rows.append({'id':item['id'],'called':file+':'+str(src['start']) in calls,'explicit_entries':len(keys),'entered':sum(k in branches for k in keys),'baseline_missing':len(item['unverified_branches']),'baseline_missing_now_entered':[b for b in item['unverified_branches'] if b['key'] in branches],'remaining_entries':[dict(key=k,**v) for k,v in keys.items() if k not in branches],'remaining_baseline':missing})
report={'method':'Boolean function/then/else/do entries; original output must be unchanged. Fresh 6320-battle oracle outputs must equal existing references. Not full condition coverage or parity.','runs':runs,'called_functions':sum(r['called'] for r in rows),'baseline_missing_entries':sum(r['baseline_missing'] for r in rows),'newly_entered_baseline_entries':sum(len(r['baseline_missing_now_entered']) for r in rows),'rows':rows}
(O/'coverage.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['rows','runs']}))
