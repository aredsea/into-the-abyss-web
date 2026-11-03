"""Final affected-UI pass. Three isolated native runtimes; one result writer."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import subprocess,os,sys,json,time,re,threading
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23/ui-phase4'
sys.stdout.reconfigure(encoding='utf-8')
# Native runtime data stay isolated; immutable engines share existing bytes.
for index in range(1,4):
    target=R/f'verification/ui-r17/runtime-ui4-{index}/engine';target.mkdir(parents=True,exist_ok=True)
    assert target.resolve().is_relative_to(R.resolve())
    for source in (R/'verification/ui-r17/runtime/engine').glob('*.exe'):
        dest=target/source.name
        if dest.exists() and not dest.samefile(source):dest.unlink()
        if not dest.exists():os.link(source,dest)
if (O/'ui-recheck.json').exists() and not (O/'ui-recheck-environment.json').exists():
    (O/'ui-recheck-environment.json').write_bytes((O/'ui-recheck.json').read_bytes())
reg=json.loads((O/'ui-regression.json').read_text(encoding='utf-8'))
if not (O/'ui-regression-full-initial.json').exists():(O/'ui-regression-full-initial.json').write_text(json.dumps(reg,indent=2)+'\n',encoding='utf-8')
names=sorted(p.stem for p in (R/'project/tests').glob('*_test.gd') if p.stem.startswith('ui_') and not p.stem.startswith(('ui_battle','ui_cloud')))+['settings_r22_test']
if sys.argv[1:]:names=[n for n in names if n in sys.argv[1:]]
lock=threading.Lock();slots={}
def execute(name):
    with lock:
        ident=threading.get_ident()
        if ident not in slots:slots[ident]='ui4-'+str(len(slots)+1)
        slot=slots[ident]
    env={**os.environ,'PYTHONIOENCODING':'utf-8','R23_RUNTIME_SLOT':slot}
    pure=name in ['ui_rules_r23_test','ui_remaining_r23_test','ui_semantics_r23_test','ui_phase4_r23_test','ui_phase4_edges_r23_test','settings_r22_test']
    cmd=[sys.executable,'tools/godot_r17.py',*(['--headless'] if pure else ['--position','-10000,-10000']),'--script',f'res://tests/{name}.gd']
    start=time.monotonic();log=O/('ui-recheck-'+name+'.log')
    with log.open('wb') as f:
        p=subprocess.Popen(cmd,cwd=R,env=env,stdout=f,stderr=subprocess.STDOUT)
        try:code=p.wait(timeout=900)
        except subprocess.TimeoutExpired:subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);code=124
    s=log.read_text(encoding='utf-8',errors='replace');errors=[x for x in s.splitlines() if ('SCRIPT ERROR:' in x or x.startswith('ERROR:')) and 'root certificate store' not in x]
    return {'test':name,'exit':code,'errors':errors,'environment_diagnostics':[x for x in s.splitlines() if 'root certificate store' in x],'summary':[x for x in s.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS|parity|battles|TESTS:',x)][-4:],'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors,'log':log.relative_to(R).as_posix(),'runtime_slot':slot}
completed=[]
with ThreadPoolExecutor(max_workers=3) as pool:
    for future in as_completed([pool.submit(execute,n) for n in names]):
        row=future.result();completed.append(row);reg=[r for r in reg if r['test']!=row['test']]+[row]
        (O/'ui-regression.json').write_text(json.dumps(reg,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        (O/'ui-recheck.json').write_text(json.dumps(completed,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        print(json.dumps({k:row[k] for k in ['test','exit','passed','seconds','runtime_slot']})+' errors='+str(len(row['errors'])),flush=True)
sys.exit(0 if all(r['passed'] for r in reg) else 1)
