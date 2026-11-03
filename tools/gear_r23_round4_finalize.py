"""Keep the first run, merge successful targeted retries, and prove the tiny UI delta."""
from pathlib import Path
import json,hashlib,difflib
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';S=O/'gear-suite-round4'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
original=read(S/'results.json');initial_lock=read(S/'code-lock.json')
assert {r['test'] for r in original if not r['passed']}=={'combat_a8_audit','ui_gear_r23_round4_test'}
ui_path='project/ui/facilities_screen_r22.gd'
before=(O/'gear-round4-before-element-fix.gd').read_text(encoding='utf-8')
after=(R/ui_path).read_text(encoding='utf-8')
old='source_t("무속성" if c.el=="none" else PanelNumbers.DATA.els.get(c.el,"무속성"))'
new='source_u("무속성") if c.el=="none" else source_t(PanelNumbers.DATA.els.get(c.el,"무속성"))'
assert before.count(old)==1 and before.replace(old,new)==after
assert hashlib.sha256((O/'gear-round4-before-element-fix.gd').read_bytes()).hexdigest()==initial_lock[ui_path]
changed=[p for p,h in initial_lock.items() if hashlib.sha256((R/p).read_bytes()).hexdigest()!=h]
assert changed==[ui_path],changed
retry_dirs=[O/'gear-ui-round4-retry',O/'gear-a8-round4-retry']
retries=[read(p) for d in retry_dirs for p in (d/'rows').glob('*.json')]
must={'ui_gear_r23_round4_test','ui_gear_r23_round3_test','ui_gear_r23_test','ui_facilities_r22_test','ui_town_r21_round3_test','ui_remaining_native_r23_test','ui_remaining_r23_test','ui_persona_town_round8_test','ui_town_r21_round10_test','ui_town_r21_round11_test','ui_town_r21_round4_test','combat_a8_audit'}
assert {r['test'] for r in retries}==must
assert all(r['passed'] for r in retries),[r for r in retries if not r['passed']]
a8=read(O/'gear-a8-round4-retry/gear-retry-result.json');assert a8['exit']==0
assert a8['test_sha256']==hashlib.sha256((R/'project/tests/combat_a8_audit.gd').read_bytes()).hexdigest()
merged={r['test']:r for r in original}
for r in retries:merged[r['test']]={**r,'retry_source':'gear-a8-round4-retry' if r['test']=='combat_a8_audit' else 'gear-ui-round4-retry'}
assert len(merged)==len(original) and all(r['passed'] for r in merged.values())
npm=read(S/'npm-retry-result.json');assert npm['exit']==0
lock={p:hashlib.sha256((R/p).read_bytes()).hexdigest() for p in initial_lock}
(O/'gear-round4-final-code-lock.json').write_text(json.dumps(lock,indent=2),encoding='utf-8')
(O/'gear-round4-final-suite.json').write_text(json.dumps(sorted(merged.values(),key=lambda r:r['test']),indent=2),encoding='utf-8')
delta=list(difflib.unified_diff(before.splitlines(),after.splitlines(),fromfile='initial/'+ui_path,tofile='final/'+ui_path,lineterm=''))
result={'project_exit':0,'npm_exit':0,'initial_failed_groups':2,'initial_failed_tests':['combat_a8_audit','ui_gear_r23_round4_test'],'full_run_code_lock_unchanged':False,'final_delta_verified':True,'delta_file':ui_path,'delta':delta,'retry_groups':len(retries),'groups':len(merged),'failed':0,'npm_initial_failed':True,'npm_retry_checks':npm['checks'],'rationale':'The sole product delta after the full run began is the original UI-pack translation of Levia none-element text; complete affected facility/town UI tests were rerun. Original A8 repeated unchanged after process exit -1. All non-UI product/test inputs retain the original lock.'}
(O/'gear-round4-adjudication.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='delta'}))
