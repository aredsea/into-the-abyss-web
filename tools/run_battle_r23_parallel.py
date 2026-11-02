"""Run independent tests in four isolated Godot homes; rendering stays serial."""
from pathlib import Path
import subprocess,sys,os,json,time
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'/os.environ.get('R23_SUITE_NAME','suite-round2-final');O.mkdir(parents=True,exist_ok=True)
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
tests=sorted(p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras)
if sys.argv[1:]:
 unknown=set(sys.argv[1:])-set(tests)
 if unknown:raise SystemExit('Unknown tests: '+', '.join(sorted(unknown)))
 tests=[n for n in tests if n in sys.argv[1:]]
old={}
for p in (R/'verification/parity-r23/suite-final/rows').glob('*.json'):
 j=json.loads(p.read_text(encoding='utf-8'));old[j['test']]=j['seconds']
groups=[[],[],[],[]];cost=[0,0,0,0]
for name in sorted(tests,key=lambda n:old.get(n,10),reverse=True):
 i=0 if name.startswith(('ui_','motion_r','cloud_')) or name in ['town_combat_r21_round14_test','town_r21_round11_test'] else min(range(1,4),key=lambda k:cost[k])
 groups[i].append(name);cost[i]+=old.get(name,10)
plan={str(i):{'tests':ns,'estimated_seconds':round(cost[i])} for i,ns in enumerate(groups)}
(O/'plan.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
(O/'tested-code.json').write_text(json.dumps({str(p.relative_to(R)).replace('\\','/'):__import__('hashlib').sha256(p.read_bytes()).hexdigest() for folder in ['project/game','project/tests'] for p in (R/folder).glob('*.gd')},indent=2),encoding='utf-8')
# Final import is sequential, before any engine runtime reads the project cache.
env={**os.environ,'R23_SUITE_NAME':O.name}
if subprocess.call([sys.executable,'tools/run_battle_r23.py','import'],cwd=R,env=env):raise SystemExit(1)
runs=[];files=[]
for i,names in enumerate(groups):
 f=(O/f'group-{i}.log').open('wb');files.append(f)
 e={**env,'R23_RUNTIME_SLOT':f'final-{i}'}
 p=subprocess.Popen([sys.executable,'tools/run_battle_r23.py',*sorted(names)],cwd=R,env=e,stdout=f,stderr=subprocess.STDOUT)
 runs.append(p)
 print(json.dumps({'group':i,'pid':p.pid,'tests':len(names),'estimated_seconds':round(cost[i])}),flush=True)
seen=set()
while any(p.poll() is None for p in runs):
 for p in sorted((O/'rows').glob('*.json')):
  if p.name in seen:continue
  try:j=json.loads(p.read_text(encoding='utf-8'))
  except json.JSONDecodeError:continue
  seen.add(p.name);print(json.dumps({'completed':len(seen),'test':j['test'],'passed':j['passed']}),flush=True)
 time.sleep(1)
for f in files:f.close()
codes=[p.returncode for p in runs]
(O/'group-exits.json').write_text(json.dumps(codes),encoding='utf-8')
print(json.dumps({'group_exits':codes}),flush=True)
raise SystemExit(0 if all(c==0 for c in codes) else 1)

