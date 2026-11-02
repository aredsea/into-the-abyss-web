"""Required isolated local Web export, with full process evidence."""
from pathlib import Path
import subprocess,sys,json,hashlib
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round5'
p=subprocess.run([sys.executable,str(R/'tools/godot_r17.py'),'--headless','--export-release','Web','../docs/index.html'],cwd=R,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,encoding='utf-8',errors='replace',timeout=240)
(V/'export.log').write_text(p.stdout,encoding='utf-8')
errors=[s for s in p.stdout.splitlines() if ('ERROR:' in s and 'root certificate store' not in s) or 'SCRIPT ERROR:' in s]
assert p.returncode==0 and not errors,(p.returncode,errors)
q=subprocess.run([sys.executable,str(R/'tools/update_version.py')],cwd=R,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,encoding='utf-8',errors='replace',timeout=30)
(V/'version.log').write_text(q.stdout,encoding='utf-8');assert q.returncode==0,q.stdout
version=json.loads((R/'docs/version.json').read_text(encoding='utf-8'))
baseline=json.loads((V/'baseline.json').read_text(encoding='utf-8'))
report={'exit_code':p.returncode,'errors':errors,'before_pck_bytes':baseline['pck_bytes'],'after_pck_bytes':(R/'docs/index.pck').stat().st_size,'version':version}
(V/'export-results.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
