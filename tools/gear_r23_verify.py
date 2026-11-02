"""All assertion suites and all eight retained combat comparisons. No export/git."""
from pathlib import Path
import subprocess,sys,json,time,re,os
root=Path(__file__).resolve().parents[1]
out=root/'verification/parity-r23/suite';out.mkdir(parents=True,exist_ok=True)
(out/'rows').mkdir(exist_ok=True)
extras=['balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
tests=['import']+sorted(p.stem for p in (root/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras)
selected=sys.argv[1:];results=[]
if selected and (out/'results.json').exists():results=json.loads((out/'results.json').read_text(encoding='utf-8'))
env=os.environ.copy();env['ABYSS_TEST_SERVER']='http://127.0.0.1:18787'
env['ABYSS_NODE_MODULES']=str(root.parent/'r21-d-town/server/abyss-save')
env['TEMP']=env['TMP']=env['TMPDIR']=str(root/'.p6tmp')
for name in tests:
 if selected and name not in selected:continue
 args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if name.startswith(('ui_','motion_r')) else ['--headless']),'--script',f'res://tests/{name}.gd']
 start=time.monotonic()
 command=[sys.executable,'tools/godot_r17.py',*args]
 # This suite needs a freshly seeded inactive account, rather than an old fixture
 # pointing at another in-memory D1 instance. Reuse the existing canonical runner.
 if name=='cloud_archive_r22_test':command=['node','server/abyss-save/test/godot-r14.mjs',name]
 with (out/(name+'.log')).open('wb') as log:
  p=subprocess.Popen(command,cwd=root,env=env,stdout=log,stderr=subprocess.STDOUT)
  try:code=p.wait(timeout=1800)
  except subprocess.TimeoutExpired:
   subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);code=124
 if name=='cloud_archive_r22_test':
  actual=root/'verification/town-r21/round14'/f'{name}.log'
  if actual.exists():(out/(name+'.log')).write_bytes(actual.read_bytes())
 text=(out/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 errors=[line for line in text.splitlines() if ('SCRIPT ERROR:' in line or line.startswith('ERROR:')) and 'root certificate store' not in line]
 summary=[line for line in text.splitlines() if re.search('CHECKS|FAILURES|checks|failures|full battles|GEAR AUDIT|AUDIT|PASS',line)][-3:]
 row={'test':name,'exit':code,'errors':errors,'seconds':round(time.monotonic()-start,2),'summary':summary,'passed':code==0 and not errors}
 (out/'rows'/f'{name}.json').write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
 results=[r for r in results if r['test']!=name]+[row]
 (out/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({**row,'errors':errors[:4]},ensure_ascii=True),flush=True)
sys.exit(0 if all(r['passed'] for r in results) else 1)
