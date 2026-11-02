from pathlib import Path
import subprocess,sys,json,time
R=Path(__file__).resolve().parents[1]
OUT=R/'verification/data-r21/a9-suite';OUT.mkdir(exist_ok=True)
(OUT/'rows').mkdir(exist_ok=True)
extras=['export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
tests=['import']+sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras)
selected=sys.argv[1:]
for name in tests:
 if selected and name not in selected:continue
 args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if name.startswith(('ui_','motion_r')) else ['--headless']),'--script',f'res://tests/{name}.gd']
 start=time.monotonic()
 with (OUT/(name+'.log')).open('wb') as f:
  p=subprocess.Popen([sys.executable,'tools/godot_r17.py',*args],cwd=R,stdout=f,stderr=subprocess.STDOUT)
  try:code=p.wait(timeout=900)
  except subprocess.TimeoutExpired:
   subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);code=124
 log=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 row={'test':name,'exit':code,'errors':errors,'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors}
 (OUT/'rows'/(name+'.json')).write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(row,ensure_ascii=True),flush=True)
results=[json.loads(p.read_text(encoding='utf-8')) for p in sorted((OUT/'rows').glob('*.json'))]
(OUT/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
sys.exit(0 if all(r['passed'] for r in results) else 1)
