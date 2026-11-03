"""Repeat the unchanged full A8 test after its unexplained early process exit."""
from pathlib import Path
import os,subprocess,json,hashlib
R=Path(__file__).resolve().parents[1];S=R/'verification/parity-r23/gear-a8-round4-retry';S.mkdir(exist_ok=True)
env={**os.environ,'R23_SUITE_NAME':S.name,'R23_RUNTIME_SLOT':'gear-a8-round4'}
code=subprocess.call(['python','tools/run_battle_r23.py','combat_a8_audit'],cwd=R,env=env)
result={'exit':code,'reason':'Initial full-suite A8 process exited 4294967295 after progress 3584 / 5120, with gaps 0 and no script error. Repeated original test unchanged in a separate runtime.','test_sha256':hashlib.sha256((R/'project/tests/combat_a8_audit.gd').read_bytes()).hexdigest()}
(S/'gear-retry-result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
raise SystemExit(code)
