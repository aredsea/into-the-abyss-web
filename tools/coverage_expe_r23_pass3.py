"""Run canonical oracle twice and require unchanged outputs with entry probes."""
from pathlib import Path
import re,bisect,json,hashlib,subprocess,sys,os
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';D=O/'expe-pass3-coverage';D.mkdir(exist_ok=True)
SRC=Path('C:/Clauede Code/dungeon-bot/bot/src')
TOKEN=re.compile(r'--\[(=*)\[[\s\S]*?\]\1\]|--[^\n]*|\[(=*)\[[\s\S]*?\]\2\]|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'')
meta={}
for name in re.findall(r"'([\w-]+\.lua)'",(R/'tools/expe_r23_pass3_oracle.mjs').read_text(encoding='utf-8').split('const instrument=')[0]):
 p=SRC/name;s=p.read_text(encoding='utf-8');masked=TOKEN.sub(lambda m:''.join('\n' if c=='\n' else ' ' for c in m[0]),s)
 starts=[0]+[m.end() for m in re.finditer('\n',s)];changes=[];calls={};branches={}
 for m in re.finditer(r'\bfunction\s*(?:[\w.:]+\s*)?\([^)]*\)',masked):
  line=bisect.bisect_right(starts,m.start());key=f'{name}:{line}'
  changes.append((m.end(),f' B.__expe_cov.calls["{key}"]=true; '));calls[key]={'line':line,'offset':m.start()}
 for m in re.finditer(r'\b(?:then|else|do)\b',masked):
  line=bisect.bisect_right(starts,m.start());key=f'{name}:{line}:{m.start()}'
  changes.append((m.end(),f' B.__expe_cov.branches["{key}"]=true; '));branches[key]={'line':line,'offset':m.start(),'token':m[0]}
 for offset,insert in sorted(changes,reverse=True):s=s[:offset]+insert+s[offset:]
 (D/name).write_text(s,encoding='utf-8');meta[name]={'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'calls':calls,'branches':branches}
(D/'instrumentation.json').write_text(json.dumps(meta,indent=2),encoding='utf-8')
for instrument in [False,True]:
 env={**os.environ,**({'EXPE_PROBE_DIR':str(D)} if instrument else {})}
 with (D/('instrumented.log' if instrument else 'canonical.log')).open('wb') as f:p=subprocess.run(['node','tools/expe_r23_pass3_oracle.mjs'],cwd=R,env=env,stdout=f,stderr=subprocess.STDOUT)
 if p.returncode:raise SystemExit(p.returncode)
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
canonical=read(O/'expe-pass3-oracle.json');observed=read(O/'expe-pass3-instrumented-oracle.json')
assert canonical==observed,'Entry probes changed outputs'
cov=read(O/'expe-pass3-coverage-raw.json');calls=set();branches=set()
for g in cov.values():calls.update(g['calls']);branches.update(g['branches'])
items=read(O/'expe-pass3-assigned-items.json');ledger=read(O/'expe-pass2-ledger.json');remaining={r['id'] for r in ledger['rows'] if r['status']!='\uac19\uc74c'}
rows=[]
for item in items:
 if item['id'] not in remaining:continue
 src=item['source'];name=Path(src['file']).name;m=meta.get(name,{})
 entries={k:v for k,v in m.get('branches',{}).items() if src['start']<=v['line']<=src['end']}
 key=f'{name}:{src["start"]}'
 rows.append({'id':item['id'],'source':src,'called':key in calls,'groups':[k for k,g in cov.items() if key in g['calls']],
 'explicit_entries':len(entries),'entered':sum(k in branches for k in entries),'remaining_entries':[dict(key=k,**v) for k,v in entries.items() if k not in branches],
 'baseline_unverified':item['unverified_branches'],'baseline_now_entered':[b for b in item['unverified_branches'] if b['key'] in branches]})
report={'method':'Actual Lua function/then/else/do entry probes in copies. Identical instrumented and canonical outputs required. Entry coverage is not complete condition coverage or native parity.',
 'instrumentation_output_equal':True,'rows':rows,'remaining_rows':len(rows),'called':sum(r['called'] for r in rows),'entries':sum(r['explicit_entries'] for r in rows),
 'entered':sum(r['entered'] for r in rows),'baseline_unverified':sum(len(r['baseline_unverified']) for r in rows),'baseline_now_entered':sum(len(r['baseline_now_entered']) for r in rows)}
(O/'expe-pass3-coverage.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['rows','method']}))
