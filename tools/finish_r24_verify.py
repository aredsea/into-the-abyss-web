"""Full project regression, <=3 temporary engine slots, actual local cloud service."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor,as_completed
import subprocess,os,sys,json,re,time,threading,shutil
R=Path(__file__).resolve().parents[1];O=R/'verification/finish-r24';O.mkdir(exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
extras={'export_licenses','motion_r9_integration','motion_r18_integration','balance_probe','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
names=sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras)
cloud=[n for n in names if 'cloud' in n or n in ['town_combat_r21_round14_test','town_r21_round11_test']]
selected=[n for n in sys.argv[1:] if not n.startswith('--')]
if '--cloud' in sys.argv:
    source=(R/'tools/look_r24_cloud.py').read_text(encoding='utf-8').replace('verification/look-r24/cloud','verification/finish-r24/cloud').replace('verification/look-r24/tmp','.p6tmp')
    source=source.replace("'tools/godot_r17.py','--headless','--script'","'tools/godot_r17.py',*(['--position','-10000,-10000'] if name.startswith('ui_') else ['--headless']),'--script'")
    sys.argv=[sys.argv[0],*(selected or cloud)]
    exec(compile(source,str(R/'tools/look_r24_cloud.py'),'exec'),{'__file__':str(R/'tools/look_r24_cloud.py'),'__name__':'__main__'})
    raise SystemExit()
rows=json.loads((O/'regression.json').read_text(encoding='utf-8')) if (O/'regression.json').exists() else []
names=[n for n in names if n in selected] if selected else ['import']+[n for n in names if n not in cloud]
if '--affected' in sys.argv:names=[n for n in names if n not in cloud and (n.startswith('ui_') or n in ['finish_r24_test','expe_pass2_r23_test','expe_pass6_r23_test','town_r21_round10_test','town_r21_round11_test'])]
slot_ids={};lock=threading.Lock()
def run(name):
    with lock:
        ident=threading.get_ident()
        if ident not in slot_ids:slot_ids[ident]=len(slot_ids)
        slot='finish-r24-'+str(slot_ids[ident])
    native=name.startswith('ui_') and name not in ['ui_rules_r23_test','ui_remaining_r23_test'] or name.endswith('_integration')
    args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if native else ['--headless']),'--script','res://tests/'+name+'.gd']
    start=time.monotonic()
    with (O/(name+'.log')).open('wb') as log:
        p=subprocess.Popen([sys.executable,'tools/godot_r17.py',*args],cwd=R,env={**os.environ,'R23_RUNTIME_SLOT':slot,'PYTHONIOENCODING':'utf-8'},stdout=log,stderr=subprocess.STDOUT)
        try:code=p.wait(timeout=1200)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);code=124
    text=(O/(name+'.log')).read_text(encoding='utf-8',errors='replace')
    errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
    return {'test':name,'exit':code,'passed':code==0 and not errors,'errors':errors,'summary':[s for s in text.splitlines() if re.search('CHECKS|checks|FAILURES|failures|PASS|TESTS:',s)][-4:],'seconds':round(time.monotonic()-start,2)}
def save(row):
    global rows
    rows=[r for r in rows if r['test']!=row['test']]+[row]
    (O/'regression.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in row.items() if k!='errors'},ensure_ascii=True),flush=True)
try:
    if 'import' in names:save(run('import'));names.remove('import')
    with ThreadPoolExecutor(max_workers=3) as pool:
        for f in as_completed([pool.submit(run,n) for n in names]):save(f.result())
finally:
    # Delete only this run's specifically named, workspace-contained slots.
    base=(R/'verification/ui-r17').resolve()
    for i in slot_ids.values():
        for prefix in ['runtime-','runtime-local-','tmp-']:
            p=(base/(prefix+'finish-r24-'+str(i))).resolve()
            assert p.parent==base and p.name not in ['runtime','runtime-local','tmp']
            if p.exists():shutil.rmtree(p)
failed=[r['test'] for r in rows if not r['passed'] and r['test'] in names+['import']]
print('FAILED',failed,flush=True);raise SystemExit(bool(failed))
