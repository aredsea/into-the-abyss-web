"""Recheck only consumers started before the final formatter fix.

The complete main suite is preserved. A fresh engine loads scripts on each run;
completed tests which neither load the changed script nor predate the fix can
be retained. Import and all possibly affected early consumers are rerun.
"""
from pathlib import Path
import json,re,hashlib,shutil,subprocess,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
S=O/'suite-expe-pass3-final';M=O/'suite-expe-pass3-main'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
fix=read(O/'expe-pass3-format-fix.json');assert sha(R/fix['file'])==fix['sha256']
old_lock=read(O/'expe-pass3-code-lock.json')
changed=[p for p,h in old_lock.items() if not (R/p).is_file() or sha(R/p)!=h]
assert set(changed)=={fix['file'],'project/tests/battle_r23_test.gd'},changed
archive=M if M.exists() else S
assert read(archive/'code-lock-result.json')['changed']==changed
assert read(archive/'server-result.json')['exit']==0
rows=[read(p) for p in (archive/'rows').glob('*.json')]
assert len(rows)==111
assert all(r['passed'] or r['test']=='battle_r23_test' for r in rows),[r for r in rows if not r['passed']]
graph={};hashes={}
for p in (R/'project').rglob('*.gd'):
 if '.godot' in p.parts:continue
 key=p.relative_to(R/'project').as_posix();graph[key]=set(re.findall(r'res://([A-Za-z0-9_./-]+\.gd)',p.read_text(encoding='utf-8')));hashes[key]=sha(p)
def closure(key,seen=None):
 seen=set() if seen is None else seen
 if key in seen:return seen
 seen.add(key)
 for dep in graph.get(key,[]):closure(dep,seen)
 return seen
selected=set(fix['new_tests']);audit=[]
for row in rows:
 name=row['test']
 if name=='import':continue
 deps=closure('tests/'+name+'.gd');loaded_changes=[p for p in changed if p.removeprefix('project/') in deps];affected=bool(loaded_changes)
 # copy2 preserves row modification times even if Windows refuses to rename
 # an open directory. Subtract measured duration plus 5s conservatively;
 # this also includes tests running across the fix instant.
 stat=(archive/'rows'/(name+'.json')).stat();birth_ns=stat.st_mtime_ns-int((row['seconds']+5)*1e9)
 cutoff=max(((R/p).stat().st_mtime_ns for p in loaded_changes),default=fix['mtime_ns'])
 early=birth_ns<=cutoff+2_000_000_000
 if affected and early:selected.add(name)
 audit.append({'test':name,'loads_changed_script':affected,'loaded_changes':loaded_changes,'conservative_start_ns':birth_ns,'completed_row_mtime_ns':stat.st_mtime_ns,'measured_seconds':row['seconds'],'fix_mtime_ns':cutoff,'conservative_early':early,'rerun':name in selected,
  'retention_reason':'rerun' if name in selected else 'fresh engine started after fix' if affected else 'changed script absent from complete literal GDScript dependency closure'})
for p in [S.resolve(),M.resolve()]:assert p.is_relative_to(R.resolve())
if not M.exists():shutil.copytree(S,M)
shutil.copytree(M,S,dirs_exist_ok=True)
shutil.copyfile(O/'expe-pass3-code-lock.json',O/'expe-pass3-main-code-lock.json')
proof={'changed_existing':changed,'new_tests':fix['new_tests'],'selected':sorted(selected),'retained_main_groups':110-len(selected-set(fix['new_tests'])),
 'main_suite':'verification/parity-r23/suite-expe-pass3-main','audit':audit,'dependency_graph':{k:sorted(v) for k,v in graph.items()},'dependency_hashes':hashes,
 'method':'Conservative transitive literal .gd resource references. Start lower bound = preserved completion-row mtime minus measured duration minus 5s, compared with fix mtime plus 2s grace. New engines per test; affected early/running tests and new test rerun; import rerun. Main code-lock rejection is expected, not suppressed.'}
(O/'expe-pass3-refinement.json').write_text(json.dumps(proof,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'recheck':len(selected),'tests':sorted(selected)}),flush=True)
raise SystemExit(subprocess.call([sys.executable,'tools/verify_expe_r23_pass3.py',*sorted(selected)],cwd=R))
