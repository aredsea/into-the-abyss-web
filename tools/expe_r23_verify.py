"""All executable project checks through the isolated launcher; no export/git."""
from pathlib import Path
import subprocess,sys,json,time,re,os
root=Path(__file__).resolve().parents[1]
folder=root/'verification/parity-r23';folder.mkdir(exist_ok=True)
audits=['combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
tests=sorted(p.stem for p in (root/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration'])
selected=sys.argv[1:]
report=folder/Path(os.environ.get('EXPE_R23_RESULT','expe-regression.json')).name
results=json.loads(report.read_text(encoding='utf-8')) if selected and report.exists() else []
for name in selected or ['import',*tests,*audits]:
    args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if name.startswith('ui_') or name in ['motion_r9_integration','motion_r18_integration'] else ['--headless']),'--script',f'res://tests/{name}.gd']
    start=time.monotonic();logfile=folder/(name+'.log')
    with logfile.open('wb') as log:
        p=subprocess.Popen([sys.executable,'tools/godot_r17.py',*args],cwd=root,stdout=log,stderr=subprocess.STDOUT)
        try:code=p.wait(timeout=1200 if name in audits or name=='dialogue_player_r21_test' else 600)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);code=124
    log=logfile.read_text(encoding='utf-8',errors='replace')
    errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
    summaries=[s[:800] for s in log.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|TESTS:|parity |full battles',s)][-3:]
    row={'test':name,'exit':code,'errors':errors,'summary':summaries,'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors}
    results=[r for r in results if r['test']!=name]+[row]
    report.write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({**row,'errors':errors[:4]},ensure_ascii=True),flush=True)
sys.exit(0 if all(r['passed'] for r in results) else 1)
