"""Run project entry-point tests, at most three isolated Godot processes."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import subprocess,os,json,time,sys,re,threading
R=Path(__file__).resolve().parents[1];O=R/'verification/reskin-r24/tests';O.mkdir(parents=True,exist_ok=True)
names=['import']+sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration'])
selected=sys.argv[1:]
if selected:names=[n for n in names if n in selected]
else:names=[n for n in names if n!='ui_reskin_r24_test']
rows=json.loads((O/'results.json').read_text(encoding='utf-8')) if (O/'results.json').exists() else []
slots={};lock=threading.Lock()
def run(name):
 with lock:
  thread=threading.get_ident()
  if thread not in slots:slots[thread]=len(slots)+1
  slot=slots[thread]
 start=time.monotonic();env={**os.environ,'PYTHONIOENCODING':'utf-8','R23_RUNTIME_SLOT':'reskin-test-'+str(slot+int(os.environ.get('RESKIN_SLOT_BASE','1'))-1)}
 native=name.startswith('ui_') or name.endswith('_integration')
 args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if native else ['--headless']),'--script','res://tests/'+name+'.gd']
 with (O/(name+'.log')).open('wb') as log:
  try:p=subprocess.run([sys.executable,'tools/godot_r17.py',*args],cwd=R,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=1200);code=p.returncode
  except subprocess.TimeoutExpired:code=124
 text=(O/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 return {'test':name,'exit':code,'errors':errors,'summary':[s for s in text.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS|TESTS:|cases',s)][-4:],'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors}
with ThreadPoolExecutor(max_workers=int(os.environ.get('RESKIN_WORKERS','3'))) as pool:
 for future in as_completed([pool.submit(run,n) for n in names]):
  row=future.result();rows=[r for r in rows if r['test']!=row['test']]+[row];(O/'results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row,ensure_ascii=True),flush=True)
print('TEST GROUPS',len(names),'FAILED',sum(not r['passed'] for r in rows if r['test'] in names))
