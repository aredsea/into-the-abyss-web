"""Run every project test and existing full-battle parity audits, without export."""
from pathlib import Path
import subprocess,sys,json,time,os,uuid
R=Path(__file__).resolve().parents[1]
O=R/'verification/parity-r23'/os.environ.get('R23_SUITE_NAME','suite');O.mkdir(parents=True,exist_ok=True)
(O/'rows').mkdir(exist_ok=True)
extras=['balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
tests=['import']+sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras)
selected=sys.argv[1:]
if selected:
 unknown=set(selected)-set(tests)
 if unknown:raise SystemExit('Unknown tests: '+', '.join(sorted(unknown)))
 tests=selected
for name in tests:
 if selected and name not in selected:continue
 if name.startswith('cloud_') or name in ['ui_cloud_r22_test','town_combat_r21_round14_test','town_r21_round11_test']:
  request={'id':str(uuid.uuid4()),'archive':name=='cloud_archive_r22_test'}
  (O.parent/'cloud-control.json').write_text(json.dumps(request),encoding='utf-8')
  ready=False
  for _ in range(100):
   result_file=O.parent/'cloud-control-result.json'
   try:response=json.loads(result_file.read_text(encoding='utf-8'))
   except (FileNotFoundError,json.JSONDecodeError):response={}
   if response.get('id')==request['id']:
    if not response.get('ok'):raise RuntimeError(response)
    ready=True;break
   time.sleep(.1)
  if not ready:raise RuntimeError('Start serve.mjs with tools/cloud_battle_r23_preload.mjs')
 args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if name.startswith(('ui_','motion_r')) else ['--headless']),'--script',f'res://tests/{name}.gd']
 start=time.monotonic()
 with (O/(name+'.log')).open('wb') as f:
  env={**os.environ,'ABYSS_TEST_SERVER':os.environ.get('ABYSS_TEST_SERVER') or 'http://127.0.0.1:8787'}
  p=subprocess.Popen([sys.executable,'tools/godot_r17.py',*args],cwd=R,stdout=f,stderr=subprocess.STDOUT,env=env)
  try:code=p.wait(timeout=900)
  except subprocess.TimeoutExpired:
   subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);code=124
 log=(O/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 row={'test':name,'exit':code,'errors':errors,'seconds':round(time.monotonic()-start,2),'passed':code==0 and not errors}
 (O/'rows'/(name+'.json')).write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(row,ensure_ascii=True),flush=True)
results=[json.loads(p.read_text(encoding='utf-8')) for p in sorted((O/'rows').glob('*.json'))]
(O/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
scope=[r for r in results if not selected or r['test'] in selected]
sys.exit(0 if len(scope)==len(selected or tests) and all(r['passed'] for r in scope) else 1)
