"""R19 verification runner, using only the isolated Godot wrapper."""
from pathlib import Path
import json,subprocess,sys,shutil
r=Path(__file__).resolve().parents[1]; out=r/'verification/ui-r20'; out.mkdir(exist_ok=True)
mode=sys.argv[1]
jobs={
 'checks':[('import',['--headless','--editor','--import','--quit'])]+[(t,['--headless','--script',f'res://tests/{t}.gd']) for t in ['world_test','state_test','route_test','expansion_test','balance_probe','motion_test','motion_asset_test','art_test','export_licenses']],
 'render':[('r19-render',['--position','-10000,-10000','--script','res://tests/ui_battle_r19_test.gd'])],
 'input':[('r17-input',['--position','-10000,-10000','--script','res://tests/ui_battle_r17_test.gd'])],
 'state':[('r18-integration',['--verbose','--position','-10000,-10000','--script','res://tests/motion_r18_integration.gd'])],
 'motion':[('r9-integration',['--position','-10000,-10000','--script','res://tests/motion_r9_integration.gd'])],
 'r18':[('r18-render',['--position','-10000,-10000','--script','res://tests/ui_battle_r18_test.gd'])],
 'r20':[('r20-render',['--position','-10000,-10000','--script','res://tests/ui_battle_r20_test.gd'])],
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
 (out/f'{mode}.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 if code or errors:
  print(log[-10000:],flush=True);break
snapshots={'input':[('verification/ui-r17/battle-input-results.json','r17-input-results.json'),('verification/ui-r17/ink-text-results.json','ink-text-results.json')], 'motion':[('verification/ui-r17/motion-r9/results.json','r9-results.json')], 'state':[('verification/ui-r18/state-integration/results.json','r18-integration-results.json')], 'r18':[('verification/ui-r18/r18-results.json','r18-results.json')], 'render':[('verification/ui-r19/r19-results.json','r19-results.json')]}
for src,dst in snapshots.get(mode,[]):
 if (r/src).exists(): shutil.copyfile(r/src,out/dst)
sys.exit(0 if len(results)==len(jobs) and all(x['exit_code']==0 and not x['engine_errors'] for x in results) else 1)
