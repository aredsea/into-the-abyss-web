"""Recheck every test that may have loaded an earlier round5 revision."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,time
R=Path(__file__).resolve().parents[1];S=R/'verification/parity-r23/suite-round5-final'
files=[p for d in ['project/game','project/tests'] for p in (R/d).glob('*.gd')]
locked={str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
last_edit=max(p.stat().st_mtime for p in files)
last=0
while not (S/'local-server-result.json').exists():
 if time.monotonic()-last>30:
  print(json.dumps({'waiting_first_suite':len(list((S/'rows').glob('*.json')))}),flush=True);last=time.monotonic()
 time.sleep(.5)
rows=[json.loads(p.read_text(encoding='utf-8')) for p in (S/'rows').glob('*.json')]
needed=[r['test'] for r in rows if r['test']!='import' and (not r['passed'] or (S/'rows'/(r['test']+'.json')).stat().st_mtime-r['seconds']<=last_edit+2)]
archive=S/'first-pass';archive.mkdir(exist_ok=True)
for p in S.glob('*.json'):shutil.copyfile(p,archive/p.name)
for r in rows:
 shutil.copyfile(S/'rows'/(r['test']+'.json'),archive/(r['test']+'.json'))
 if r['test'] in needed or r['test']=='import':shutil.copyfile(S/(r['test']+'.log'),archive/(r['test']+'.log'))
plan={'method':'Recheck all tests starting no later than the last final code edit + 2s. Tests starting later loaded the final code. Import is always rechecked.','last_code_edit':last_edit,'sha256':locked,'rerun':sorted(needed),'already_final':[r['test'] for r in rows if r['test'] not in needed and r['test']!='import']}
(S/'final-recheck-plan.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
print(json.dumps({'rerun':len(needed),'already_final':len(plan['already_final'])}),flush=True)
assert all(hashlib.sha256((R/f).read_bytes()).hexdigest()==h for f,h in locked.items())
code=subprocess.call([sys.executable,'tools/verify_battle_r23_round5.py',*sorted(needed)],cwd=R)
assert all(hashlib.sha256((R/f).read_bytes()).hexdigest()==h for f,h in locked.items())
raise SystemExit(code)
