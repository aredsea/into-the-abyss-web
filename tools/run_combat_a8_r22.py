from pathlib import Path
import subprocess,sys,json,time
R=Path(__file__).resolve().parents[1]
folder=R/'verification/data-r21/a8-suite';folder.mkdir(exist_ok=True)
(folder/'rows').mkdir(exist_ok=True)
if (folder/'results.json').exists():
 for existing in json.loads((folder/'results.json').read_text(encoding='utf-8')):
  target=folder/'rows'/(existing['test']+'.json')
  if not target.exists():target.write_text(json.dumps(existing,indent=2),encoding='utf-8')
tests=sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit'])
selected=sys.argv[1:]
if selected==['regression']:selected=['import']+[n for n in tests if n not in ['combat_a8_audit','persona_combat_a8_test','persona_save_a8_test','ui_combat_a8_test']]
results=json.loads((folder/'results.json').read_text(encoding='utf-8')) if selected and (folder/'results.json').exists() else []
for name in ['import']+tests:
 if selected and name not in selected:continue
 args=['--headless','--editor','--import','--quit'] if name=='import' else [*(['--position','-10000,-10000'] if name.startswith('ui_') or name.startswith('motion_r') else ['--headless']),'--script',f'res://tests/{name}.gd']
 start=time.monotonic()
 with (folder/(name+'.log')).open('wb') as f:
  run=subprocess.run([sys.executable,'tools/godot_r17.py',*args],cwd=R,stdout=f,stderr=subprocess.STDOUT)
 text=(folder/(name+'.log')).read_text(encoding='utf-8',errors='replace')
 errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 row={'test':name,'exit':run.returncode,'errors':errors,'seconds':round(time.monotonic()-start,2),'passed':run.returncode==0 and not errors}
 (folder/'rows'/(name+'.json')).write_text(json.dumps(row,ensure_ascii=False,indent=2),encoding='utf-8')
 results=[json.loads(p.read_text(encoding='utf-8')) for p in sorted((folder/'rows').glob('*.json'))]
 (folder/'results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps(row,ensure_ascii=True),flush=True)
sys.exit(0 if all(r['passed'] for r in results) else 1)
