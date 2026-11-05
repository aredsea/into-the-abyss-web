"""Record the original suite plus the successful targeted oracle/copy reruns."""
import os, subprocess, time
from polish4 import *
sys.path.insert(0,str(ROOT/'tools'))
from en_r24_verify import cleanup
sys.stdout.reconfigure(encoding='utf-8')
try:
 p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--script','res://../verification/en-r24/scroll-overlap-regression.gd'],cwd=ROOT,env={**os.environ,'R23_RUNTIME_SLOT':'en-r24'},capture_output=True,timeout=90)
 log=(p.stdout+p.stderr).decode('utf-8',errors='replace')
 (OUT/'polish-checks/scroll-overlap-regression.log').write_text(log,encoding='utf-8')
 errors=[s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
 assert p.returncode==0 and not errors and 'SCROLL OVERLAP CHECKS 10 FAILURES 0' in log
finally:
 cleanup()
checks=OUT/'polish-checks'
started=min(p.stat().st_mtime for p in checks.glob('*-finish_locale_data_audit.log'))
reg=json.loads((OUT/'regression.json').read_text(encoding='utf-8'))
assert len(reg)==20 and all(r['passed'] and not r['errors'] for r in reg)
assert all((OUT/(r['test']+'.log')).stat().st_mtime>=started for r in reg)
batches=json.loads((checks/'batch-results.json').read_text(encoding='utf-8'))
assert len(batches)==20 and all(r['passed'] for r in batches)
result=dict(started=started,freshness_boundary='first completed trio language scan; all full-suite logs must be newer',finished=time.time(),trio_checks=20,trio_failures=0,full_regressions=20,full_failures=0,all_final_logs_fresh=True,initial_ui_engine_errors=14,initial_ui_assertion_failures=0,scroll_oracle_boundary_checks=10,scroll_oracle_failures=0,targeted_retests=['en_r24_test','finish_locale_data_audit','ui_en_r24_test'],test_helper='project/tests/ui_scroll_r24.gd',threshold_unchanged='same one-pixel inset; only positive-area inset rectangles are intersected')
(checks/'run.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result))
