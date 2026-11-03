"""Produce valid native mirror specimens, then use the unchanged server validator."""
from pathlib import Path
import subprocess,sys,shutil,json
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
with (O/'expe-pass3-save-probe.log').open('wb') as f:
 p=subprocess.run([sys.executable,'tools/godot_r17.py','--headless','--script','res://../verification/parity-r23/expe-pass3-save-probe.gd'],cwd=R,stdout=f,stderr=subprocess.STDOUT,timeout=180)
assert p.returncode==0
log=(O/'expe-pass3-save-probe.log').read_text(encoding='utf-8')
assert 'SCRIPT ERROR:' not in log
assert not [s for s in log.splitlines() if s.startswith('ERROR:') and 'root certificate store' not in s]
assert not json.loads((O/'expe-pass3-results.json').read_text(encoding='utf-8'))['failures']
shutil.copyfile(O/'expe-pass3-save-specimens.json',O/'expe-pass3-cloud-save-specimens.json')
raise SystemExit(subprocess.call(['node','tools/validate_expe_r23_pass3_saves.mjs'],cwd=R))
