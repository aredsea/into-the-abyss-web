"""Validate the complete latest suite after the documented fixture-only repair.

Reuse passed tests only when product code is byte-identical. The two failed
battle inputs and the three renamed gear readers must have fresh passing runs.
"""
from pathlib import Path
import json,hashlib,re
R=Path(__file__).resolve().parents[1];S=R/'verification/parity-r23/suite-gear-round3';A=S/'fixture-collision'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
initial=read(A/'initial-code-lock.json');repaired=read(A/'repaired-code-lock.json')
current={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['project/game','project/ui','project/tests'] for p in (R/folder).glob('*.gd')}
assert current==repaired,'Changes after the affected-test rerun began'
changed={p for p in initial if initial[p]!=repaired[p]}
assert changed==set(read(A/'repair-plan.json')['changed_test_files'])
assert all(p.startswith('project/tests/gear_r23') for p in changed)
assert (S/'group-exits.json').exists(),'Original full suite is still running'
assert read(S/'local-server-result.json')['exit']==0,'Owned local server did not finish normally'
rows=[read(p) for p in sorted((S/'rows').glob('*.json'))]
extras={'balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit'}
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
assert {r['test'] for r in rows}==expected
assert all(r['passed'] and r['exit']==0 and not r['errors'] for r in rows)
for row in rows:
 text=(S/(row['test']+'.log')).read_text(encoding='utf-8',errors='replace')
 assert not [l for l in text.splitlines() if ('SCRIPT ERROR:' in l or l.startswith('ERROR:')) and 'root certificate store' not in l],row['test']
for n in read(A/'repair-plan.json')['affected_tests']:
 row=read(S/'rows'/(n+'.json'));assert row['passed']
 assert (S/(n+'.log')).stat().st_mtime>(A/'initial-code-lock.json').stat().st_mtime
for n,meta in read(A/'final-fixture-schemas.json').items():
 p=R/'verification/parity-r23'/n
 assert hashlib.sha256(p.read_bytes()).hexdigest()==meta['sha256'],n
 assert meta['required_key'] in read(p)
log=(S/'npm-test.log').read_text(encoding='utf-8')
assert 'GEAR R23 SERVER {"checks":259,"failures":0,"cases":36}' in log
assert not re.search(r'FAILURES [1-9]|"failures":[1-9]',log)
(S/'results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
(S/'code-lock.json').write_text(json.dumps(current,indent=2),encoding='utf-8')
(A/'repair-result.json').write_text(json.dumps({'groups':len(rows),'passed':len(rows),'failed':0,'affected_tests_rerun':read(A/'repair-plan.json')['affected_tests'],'product_code_unchanged':True,'repaired_code_lock_unchanged':True,'original_group_exits':read(S/'group-exits.json'),'method':'Combine the complete full-run rows and five fresh affected-test reruns. Preserve failed first-pass logs; source/UI product files are identical throughout.'},indent=2),encoding='utf-8')
(S/'final-verification.json').write_text(json.dumps({'project_exit':0,'npm_exit':0,'code_lock_unchanged':True},indent=2),encoding='utf-8')
print(json.dumps({'groups':len(rows),'failed':0,'affected_reruns':5,'code_lock_unchanged':True}))
