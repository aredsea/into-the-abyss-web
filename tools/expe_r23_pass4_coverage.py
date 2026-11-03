"""New probes only; cumulative coverage uses the immutable third-pass evidence."""
from pathlib import Path
import json,re,bisect,hashlib,subprocess,os
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';D=O/'expe-pass4-coverage';D.mkdir(exist_ok=True)
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
 with (D/('instrumented.log' if instrument else 'canonical.log')).open('wb') as f:p=subprocess.run(['node','tools/expe_r23_pass4_oracle.mjs'],cwd=R,env=env,stdout=f,stderr=subprocess.STDOUT)
 if p.returncode:raise SystemExit(p.returncode)
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
a=read(O/'expe-pass4-oracle.json');b=read(O/'expe-pass4-instrumented-oracle.json');assert a==b,'Instrumentation changed output'
new=read(O/'expe-pass4-coverage-raw.json');old=read(O/'expe-pass3-coverage-raw.json')
calls=set();branches=set();new_calls=set();new_branches=set()
for g in new.values():new_calls.update(g['calls']);new_branches.update(g['branches'])
for g in old.values():calls.update(g['calls']);branches.update(g['branches'])
calls.update(new_calls);branches.update(new_branches)
ledger=read(O/'expe-pass4-start-ledger.json');rows=[]
for r in ledger['rows']:
 if r['status']=='같음':continue
 src=r['source'];name=Path(src['file']).name;m=meta[name];key=f'{name}:{src["start"]}'
 entries={k:v for k,v in m['branches'].items() if src['start']<=v['line']<=src['end']}
 before=r['pass3_evidence']['entered']
 rows.append({'id':r['id'],'source':src,'called':key in calls,'new_called':key in new_calls,'groups':[k for k,g in new.items() if key in g['calls']],
 'entries':len(entries),'before':before,'entered':sum(k in branches for k in entries),'new_entries':[k for k in entries if k in new_branches and k not in {x for g in old.values() for x in g['branches']}],
 'remaining_entries':[dict(key=k,**v) for k,v in entries.items() if k not in branches]})
report={'instrumentation_output_equal':True,'method':'Cumulative actual function/then/else/do entries, not native parity or exhaustive condition coverage. Third-pass evidence preserved; only remaining rows targeted.',
 'rows':rows,'reviewed':len(rows),'new_called':sum(r['new_called'] for r in rows),'entries':sum(r['entries'] for r in rows),'before':sum(r['before'] for r in rows),'entered':sum(r['entered'] for r in rows)}
(O/'expe-pass4-coverage.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
errors={k:[x for x in v if isinstance(x,dict) and x.get('ok') is False] for k,v in a.items()};errors={k:v for k,v in errors.items() if v}
(O/'expe-pass4-probe-errors.json').write_text(json.dumps(errors,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['rows','method']}));print(json.dumps({'probe_errors':{k:len(v) for k,v in errors.items()}}))
