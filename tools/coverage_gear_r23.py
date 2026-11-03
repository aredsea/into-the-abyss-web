"""Source function/then/else/do entry probes; never substitute coverage for parity."""
from pathlib import Path
import re,bisect,json,hashlib,subprocess,time
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
D=O/'gear-coverage-round3';D.mkdir(exist_ok=True)
I=D/'instrumented';I.mkdir(exist_ok=True)
SRC=Path('C:/Clauede Code/dungeon-bot/bot/src')
TOKEN=re.compile(r'--\[(=*)\[[\s\S]*?\]\1\]|--[^\n]*|\[(=*)\[[\s\S]*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
meta={}
for name in ['71-shop.lua','72-guild.lua','73-inn.lua','74-affection.lua','81-gear.lua','82-smithy.lua']:
 p=SRC/name;s=p.read_text(encoding='utf-8');mask=TOKEN.sub(lambda m:''.join('\n' if c=='\n' else ' ' for c in m[0]),s)
 starts=[0]+[m.end() for m in re.finditer('\n',s)];changes=[];calls={};branches={}
 for t in re.finditer(r'\bfunction\s*(?:[\w.:]+\s*)?\([^)]*\)',mask):
  line=bisect.bisect_right(starts,t.start());key=f'{name}:{line}'
  calls[key]={'line':line,'offset':t.start()};changes.append((t.end(),f' B.__r23_gear_cov.calls["{key}"]=true; '))
 for t in re.finditer(r'\b(?:then|else|do)\b',mask):
  line=bisect.bisect_right(starts,t.start());key=f'{name}:{line}:{t.start()}'
  branches[key]={'line':line,'offset':t.start(),'token':t[0]};changes.append((t.end(),f' B.__r23_gear_cov.branches["{key}"]=true; '))
 for off,insert in sorted(changes,reverse=True):s=s[:off]+insert+s[off:]
 s='B.__r23_gear_cov=B.__r23_gear_cov or {calls={},branches={}}\n'+s
 (I/name).write_text(s,encoding='utf-8');meta[name]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'calls':calls,'branches':branches}
(D/'instrumentation.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2),encoding='utf-8')
cases=[('main','gear_r23_oracle.mjs','gear-oracle.json'),('hooks','gear_r23_hooks.mjs','hooks.json'),('facilities','gear_r23_facilities.mjs','facility-contracts.json'),('round2','gear_r23_round2.mjs','gear-round2-oracle.json'),('predecessors','gear_r23_predecessors.mjs','predecessors.json'),('round3','gear_r23_round3.mjs','gear-round3-oracle.json')]
runs=[];all_calls={};all_branches={}
for key,name,output in cases:
 start=time.monotonic();values=[]
 for observed in [False,True]:
  tag=key+('-instrumented' if observed else '-ordinary')
  code=(R/'tools'/name).read_text(encoding='utf-8')
  if key=='round3':
   code=code.replace('getChatVar,setChatVar=host_get,host_set',"do local g=game('shop');g.items.level_scroll=1;g.ui.sel='';edge(g,'sh','target_persona','scroll invalid selection')end\ngetChatVar,setChatVar=host_get,host_set")
  if observed:
   pos=code.index('const root=')
   hook=f"""const originalRead=fs.readFileSync.bind(fs);
fs.readFileSync=(p,...args)=>{{const s=String(p).replaceAll('\\\\','/');const name=s.split('/').pop();if(s.startsWith('C:/Clauede Code/dungeon-bot/bot/src/')&&{json.dumps(list(meta))}.includes(name))return originalRead('{I.as_posix()}/'+name,...args);return originalRead(p,...args);}};
"""
   code=code[:pos]+hook+code[pos:]
  code=code.replace('const {mkSim}=await import(', 'const {mkSim:mkSimBase}=await import(',1)
  pos=code.index('const {sim,L}=')
  # pairs order of the shop class-map is unspecified in Lua and varies between
  # fresh Wasmoon states. Pin that single host enumeration in BOTH executions.
  # No output is sorted or normalized after execution.
  stable="local __old_pairs=pairs;local __by=B.gear().by;pairs=function(t)if t~=__by then return __old_pairs(t)end;local keys={};for k in __old_pairs(t)do keys[#keys+1]=k end;table.sort(keys);local n=0;return function()n=n+1;local k=keys[n];if k~=nil then return k,t[k]end end end;"
  wrapper=f"""const mkSim=async(options)=>{{const obj=await mkSimBase(options);return {{...obj,L:async(code)=>{{const pack=await obj.L('B.__r23_gear_cov={{calls={{}},branches={{}}}};{stable}local __r=(function()\\n'+code+'\\nend)();pairs=__old_pairs;return {{result=__r,coverage=B.__r23_gear_cov}}');fs.writeFileSync('{D.as_posix()}/{tag}-coverage.json',JSON.stringify(pack.coverage));return pack.result;}}}};}};
"""
  code=code[:pos]+wrapper+code[pos:]
  code=code.replace("root+'/verification/parity-r23/",f"root+'/verification/parity-r23/gear-coverage-round3/{tag}-")
  code=code.replace("const dir=root+'/verification/parity-r23';","const dir=root+'/verification/parity-r23/gear-coverage-round3';")
  code=code.replace("fs.writeFileSync(dir+'/",f"fs.writeFileSync(dir+'/{tag}-")
  script=R/'.p6tmp'/('_gear_r23_coverage_'+tag+'.mjs');script.write_text(code,encoding='utf-8')
  with (D/(tag+'.log')).open('wb') as log:p=subprocess.run(['node',str(script)],cwd=R,stdout=log,stderr=subprocess.STDOUT)
  if p.returncode:raise RuntimeError((D/(tag+'.log')).read_text(encoding='utf-8'))
  actual=json.loads((D/(tag+'-'+output)).read_text(encoding='utf-8'))
  if isinstance(actual,dict):actual.pop('provenance',None)
  values.append(actual)
 if values[0]!=values[1]:raise AssertionError('Instrumentation changed output: '+key)
 cov=json.loads((D/(key+'-instrumented-coverage.json')).read_text(encoding='utf-8'))
 all_calls.update(cov['calls'] if isinstance(cov['calls'],dict) else {});all_branches.update(cov['branches'] if isinstance(cov['branches'],dict) else {})
 row={'case':key,'exit':p.returncode,'output_unchanged':True,'seconds':round(time.monotonic()-start,2)};runs.append(row);print(json.dumps(row),flush=True)
ledger=json.loads((O/'round2-gear.json').read_text(encoding='utf-8'));ids={r['id'] for r in ledger['rows']}
audit=json.loads((R.parent/'r21-parity/verification/parity-r21/audit-r22b.json').read_text(encoding='utf-8'))
baseline=[item for g in audit['remaining_work'] for item in g['items'] if item['id'] in ids]
assert len(baseline)==len(ids)==77
(D/'assigned-baseline.json').write_text(json.dumps(baseline,ensure_ascii=False,indent=2),encoding='utf-8')
rows=[]
for r in baseline:
 src=r['source'];name=Path(src['file']).name;fn=meta[name];keys={k:v for k,v in fn['branches'].items() if src['start']<=v['line']<=src['end']}
 rows.append({'id':r['id'],'source':src,'previous_status':r['status'],'called':f"{name}:{src['start']}" in all_calls,'explicit_entries':len(keys),'entered':sum(k in all_branches for k in keys),'remaining_entries':[dict(key=k,**v) for k,v in keys.items() if k not in all_branches],'baseline_missing':len(r['unverified_branches']),'newly_entered_baseline':[b for b in r['unverified_branches'] if b['key'] in all_branches]})
report={'method':'Boolean source function/then/else/do entries. Output equality is mandatory. Not full condition-combination coverage or native parity. Parent coverage does not promote children.','runs':runs,'functions':77,'called':sum(r['called'] for r in rows),'explicit_entries':sum(r['explicit_entries'] for r in rows),'entered':sum(r['entered'] for r in rows),'baseline_missing':sum(r['baseline_missing'] for r in rows),'newly_entered_baseline':sum(len(r['newly_entered_baseline']) for r in rows),'rows':rows}
for name,v in meta.items():assert hashlib.sha256((SRC/name).read_bytes()).hexdigest()==v['sha256']
(O/'gear-coverage-round3.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['rows','runs']},ensure_ascii=True))
