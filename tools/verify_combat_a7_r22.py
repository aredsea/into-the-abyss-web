from pathlib import Path
import json,subprocess,sys,time
R=Path(__file__).resolve().parents[1]; OUT=R/'verification/data-r21/a7-suite'; OUT.mkdir(exist_ok=True)
tests=sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced'])
selected=sys.argv[1:]; results=json.loads((OUT/'results.json').read_text(encoding='utf-8')) if selected and (OUT/'results.json').exists() else []
for name in ['import']+tests:
 if selected and name not in selected: continue
 args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if name.startswith('ui_') or name in ['motion_r9_integration','motion_r18_integration'] else ['--headless']),'--script',f'res://tests/{name}.gd']
 start=time.monotonic(); log=OUT/(name+'.log')
 with log.open('wb') as f:
  p=subprocess.Popen([sys.executable,'tools/godot_r17.py',*args],cwd=R,stdout=f,stderr=subprocess.STDOUT)
  try: code=p.wait(timeout=600)
  except subprocess.TimeoutExpired:
   subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True); code=124
 text=log.read_text(encoding='utf-8',errors='replace')
 errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 row={'test':name,'exit':code,'errors':errors,'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors}
 results=[r for r in results if r['test']!=name]+[row]
 (OUT/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(row,ensure_ascii=True),flush=True)
sys.exit(0 if all(r['passed'] for r in results) else 1)
