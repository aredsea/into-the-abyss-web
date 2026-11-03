"""Recheck every test that predates the final code/input revision."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,time
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'suite-round6-final'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
# Run only after the first suite has ended and shut down its local server.
assert (S/'local-server-result.json').exists()
archive=S/'first-pass';archive.mkdir(exist_ok=True)
for p in list(S.iterdir()):
 if p==archive:continue
 if p.is_file():shutil.copyfile(p,archive/p.name)
 elif p.name=='rows':shutil.copytree(p,archive/p.name,dirs_exist_ok=True)
locked={str(p.relative_to(R)).replace('\\','/'):sha(p) for folder in ['project/game','project/tests'] for p in (R/folder).glob('*.gd')}
last_edit=max((R/p).stat().st_mtime for p in locked)
rows=[read(p) for p in (S/'rows').glob('*.json')]
rerun=[];already=[]
for row in rows:
 start=(S/'rows'/(row['test']+'.json')).stat().st_mtime-row['seconds']
 if not row['passed'] or start<=last_edit+2 or (row['test']=='import' or row['test'].startswith('battle_r23_round6')):rerun.append(row['test'])
 else:already.append(row['test'])
plan={'last_code_edit':last_edit,'sha256':locked,'rerun':sorted(rerun),'already_final':sorted(already),'final_input_sha256':{str(p.relative_to(R)).replace('\\','/'):sha(p) for p in O.glob('battle-round6*-oracle.json')}}
(S/'final-recheck-plan.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
print(json.dumps({'rerun':len(rerun),'already_final':len(already),'tests':sorted(rerun)}),flush=True)
code=subprocess.call([sys.executable,'tools/verify_battle_r23_round6.py',*[n for n in sorted(rerun) if n!='import']],cwd=R)
assert code==0,code
assert all(sha(R/p)==h for p,h in locked.items())
assert all(sha(R/p)==h for p,h in plan['final_input_sha256'].items())
for name in rerun:
 row=read(S/'rows'/(name+'.json'));assert row['passed'],name
 assert (S/'rows'/(name+'.json')).stat().st_mtime-row['seconds']>last_edit+2,name
print(json.dumps({'final_recheck_passed':True,'rerun':len(rerun),'already_final':len(already)}),flush=True)
