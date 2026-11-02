"""Re-run any suite process that could have loaded code before the final edit."""
from pathlib import Path
import os,sys,subprocess,time,json,hashlib,shutil
R=Path(__file__).resolve().parents[1];S=R/'verification/parity-r23/suite-round3-final'
files=[p for f in ['project/game','project/tests'] for p in (R/f).glob('*.gd')]
locked={str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
lock_time=max(p.stat().st_mtime for p in files)
(S/'final-code-lock.json').write_text(json.dumps({'last_code_edit':lock_time,'sha256':locked},indent=2),encoding='utf-8')
last=0
while not (S/'local-server-result.json').exists():
 if time.monotonic()-last>30:
  print(json.dumps({'waiting_for_first_suite':len(list((S/'rows').glob('*.json')))}),flush=True);last=time.monotonic()
 time.sleep(.5)
rows=[json.loads(p.read_text(encoding='utf-8')) for p in (S/'rows').glob('*.json')]
needed=[]
for r in rows:
 p=S/'rows'/(r['test']+'.json')
 if r['test']!='import' and (not r['passed'] or p.stat().st_mtime-r['seconds']<=lock_time+2):needed.append(r['test'])
archive=S/'first-pass';archive.mkdir(exist_ok=True)
for name in ['results.json','tested-code.json','local-server-result.json','plan.json','group-exits.json']:
 if (S/name).exists():shutil.copyfile(S/name,archive/name)
for r in rows:
 shutil.copyfile(S/'rows'/(r['test']+'.json'),archive/(r['test']+'.json'))
for name in ['import',*needed]:
 shutil.copyfile(S/(name+'.log'),archive/(name+'.log'))
(S/'final-recheck-plan.json').write_text(json.dumps({'method':'All tests starting no later than last final code edit + 2 seconds are rerun. Later tests already loaded final code. Import is always rerun after all first-pass engines exit.','code_lock_time':lock_time,'rerun':sorted(needed),'already_final':[r['test'] for r in rows if r['test'] not in needed and r['test']!='import']},indent=2),encoding='utf-8')
print(json.dumps({'rerun_on_locked_code':len(needed),'already_final':len(rows)-len(needed)-1}),flush=True)
assert all(hashlib.sha256((R/n).read_bytes()).hexdigest()==h for n,h in locked.items()),'Code changed after lock'
if not needed:raise SystemExit(0)
result=subprocess.call([sys.executable,'tools/verify_battle_r23_round3.py',*sorted(needed)],cwd=R)
assert all(hashlib.sha256((R/n).read_bytes()).hexdigest()==h for n,h in locked.items()),'Code changed during recheck'
raise SystemExit(result)
