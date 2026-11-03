"""Run executable project tests in three isolated engine slots (no export)."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import subprocess,os,json,time,sys,re,threading
R=Path(__file__).resolve().parents[1];O=R/'verification/look-r24/regression';O.mkdir(parents=True,exist_ok=True)
names=sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration','balance_probe'])
selected=[n for n in sys.argv[1:] if n!='--fresh']
if selected:names=[n for n in names if n in selected]
else:names=[n for n in names if ('cloud' not in n or n=='ui_cloud_r22_test') and n not in ['town_combat_r21_round14_test','town_r21_round11_test']]
path=O/'regression.json';rows=json.loads(path.read_text(encoding='utf-8')) if path.exists() else []
done={r['test'] for r in rows if r['passed']}
if '--fresh' in sys.argv:done=set()
todo=[n for n in names if selected or n not in done]
def run(name):
 start=time.monotonic();env={**os.environ,'PYTHONIOENCODING':'utf-8','R23_RUNTIME_SLOT':'look-r24-worker-'+str(threading.get_ident())}
 native=name.startswith('ui_') and name not in ['ui_rules_r23_test','ui_remaining_r23_test'] or name.endswith('_integration')
 args=['--position','-10000,-10000'] if native else ['--headless']
 with (O/(name+'.log')).open('wb') as log:
  try:
   p=subprocess.run([sys.executable,'tools/godot_r17.py',*args,'--script','res://tests/'+name+'.gd'],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=900);code=p.returncode
  except subprocess.TimeoutExpired:code=124
 text=(O/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 return {'test':name,'exit':code,'errors':errors,'summary':[s for s in text.splitlines() if re.search('CHECKS|checks|FAILURES|failures|PASS|TESTS:',s)][-3:],'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors}
with ThreadPoolExecutor(max_workers=3) as pool:
 for future in as_completed([pool.submit(run,n) for n in todo]):
  row=future.result();rows=[r for r in rows if r['test']!=row['test']]+[row];path.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row,ensure_ascii=True),flush=True)
print('TEST GROUPS',len(names),'FAILED',sum(not r['passed'] for r in rows if r['test'] in names))
sys.exit(any(not r['passed'] for r in rows if r['test'] in names))
