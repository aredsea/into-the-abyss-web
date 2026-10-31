"""Run all R18 evidence under the isolated Godot wrapper. No git commands."""
from pathlib import Path
import json,subprocess,sys
r=Path(__file__).resolve().parents[1]; out=r/'verification/ui-r18'; out.mkdir(exist_ok=True)
mode=sys.argv[1]
jobs={
 'checks':[('import',['--headless','--editor','--import','--quit'])]+[(t,['--headless','--script',f'res://tests/{t}.gd']) for t in ['world_test','state_test','route_test','expansion_test','balance_probe','motion_test','motion_asset_test','art_test','export_licenses']],
 'render':[('r18-render',['--position','-10000,-10000','--script','res://tests/ui_battle_r18_test.gd'])],
 'input':[('input',['--position','-10000,-10000','--script','res://tests/ui_battle_r17_test.gd'])],
 'state':[('state-integration',['--position','-10000,-10000','--script','res://tests/motion_r18_integration.gd'])],
 'motion':[('motion-integration',['--position','-10000,-10000','--script','res://tests/motion_r9_integration.gd'])],
 'export':[('export',['--headless','--export-release','Web','../docs/index.html'])],
}[mode]
results=[]
for name,args in jobs:
 try:
  p=subprocess.run([sys.executable,str(r/'tools/godot_r17.py'),*args],cwd=r,capture_output=True,encoding='utf-8',errors='replace',timeout=600)
  log=p.stdout+p.stderr; code=p.returncode
 except subprocess.TimeoutExpired as exc:
  log=str(exc.stdout)+str(exc.stderr);code=124
 (out/f'{name}.log').write_text(log,encoding='utf-8')
 errors=[line for line in log.splitlines() if ('ERROR:' in line or 'SCRIPT ERROR' in line) and 'root certificate store' not in line]
 results.append({'test':name,'exit_code':code,'engine_errors':errors,'summary':[l for l in log.splitlines() if any(k in l.lower() for k in ['checks','failures','passed','licenses','balance','cases'])]})
 print(name,'exit',code,'errors',len(errors),flush=True)
 if code or errors:
  print(log[-12000:],flush=True);break
 (out/f'{mode}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
(out/f'{mode}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
sys.exit(0 if len(results)==len(jobs) and all(x['exit_code']==0 and not x['engine_errors'] for x in results) else 1)
