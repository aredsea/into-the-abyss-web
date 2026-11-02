"""Run the required suite, recording full logs and surfacing engine script errors."""
from pathlib import Path
import json, subprocess, sys, time, re
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'verification/data-r21'; OUT.mkdir(parents=True,exist_ok=True)
HEADLESS=['world_test','state_test','route_test','expansion_test','motion_test','motion_asset_test','art_test','export_licenses','data_r21_test','dungeon_r21_test','enemy_regression_r21_test','enemy_action_r21_test','enemy_review_r21_test','combat_p2_r22_test','combat_p2_r22_trace','combat_a6_r22_test']
HEADLESS+=['combat_a6_mixed_audit','combat_p3_r22_test','combat_p3_mixed_audit']
WINDOWED=['ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test','motion_r9_integration','motion_r18_integration','ui_data_r21_test']
cases=[('import',['--headless','--editor','--import','--quit'])]+[(n,['--headless','--script',f'res://tests/{n}.gd']) for n in HEADLESS]+[(n,['--position','-10000,-10000','--script',f'res://tests/{n}.gd']) for n in WINDOWED]
selected=sys.argv[1:]
if selected: cases=[(n,a) for n,a in cases if n in selected]
results=[]
for name,args in cases:
 start=time.monotonic()
 try:
  with (OUT/(name+'.log')).open('wb') as handle:
   p=subprocess.run([sys.executable,'tools/godot_r17.py',*args],cwd=ROOT,stdout=handle,stderr=subprocess.STDOUT,timeout=900)
  log=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace'); code=p.returncode
 except subprocess.TimeoutExpired as e:
  log=(e.stdout or b'').decode('utf-8',errors='replace')+'\nTIMEOUT'; code=-1
 (OUT/(name+'.log')).write_text(log,encoding='utf-8')
 # Windows sandbox lacks the OS certificate store; no network is used by tests.
 errors=[l for l in log.splitlines() if ('SCRIPT ERROR:' in l or l.startswith('ERROR:')) and 'root certificate store' not in l]
 row={'test':name,'exit_code':code,'engine_errors':errors,'seconds':round(time.monotonic()-start,2),'finished_at':time.time(),'passed':code==0 and not errors}
 results.append(row)
 print(json.dumps(row,ensure_ascii=False),flush=True)
 (OUT/('suite-'+('-'.join(selected) if selected else 'all')+'.json')).write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
sys.exit(0 if all(r['passed'] for r in results) else 1)
