"""Export with measured before/after budgets and retain exact engine logs."""
from pathlib import Path
import subprocess,sys,json,hashlib,re
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round3'
sizes=O/'export-sizes.json'
data=json.loads(sizes.read_text(encoding='utf-8')) if sizes.exists() else {'round2_pck_bytes':json.loads((O/'baseline.json').read_text(encoding='utf-8'))['pck_bytes'],'merged_unfiltered_pck_bytes':(R/'docs/index.pck').stat().st_size}
sizes.write_text(json.dumps(data,indent=2),encoding='utf-8')
cmd=[sys.executable,str(R/'tools/godot_r17.py'),'--headless','--export-release','Web','../docs/index.html']
p=subprocess.run(cmd,cwd=R,capture_output=True,encoding='utf-8',errors='replace',timeout=240)
log=p.stdout+p.stderr;(O/'export-after.log').write_text(log,encoding='utf-8')
errors=[line for line in log.splitlines() if ('SCRIPT ERROR:' in line or 'ERROR:' in line) and 'root certificate store' not in line]
assert not errors,errors
assert p.returncode==0,p.returncode
data.update(pck_bytes=(R/'docs/index.pck').stat().st_size,pck_sha256=hashlib.sha256((R/'docs/index.pck').read_bytes()).hexdigest())
data['increase_from_round2_bytes']=data['pck_bytes']-data['round2_pck_bytes']
data['reduction_from_unfiltered_bytes']=data['merged_unfiltered_pck_bytes']-data['pck_bytes']
data['budget_bytes']=15000000
data['excluded_png_slot_remaps']=len(re.findall(r'savepack.*portraits-r21/slots/.*\.png',log))
data['atlas_remaps']=len(re.findall(r'savepack.*portraits-r21-web/slots/.*\.tres',log))
assert data['increase_from_round2_bytes']<=data['budget_bytes'],data
assert data['excluded_png_slot_remaps']==0,data
assert data['atlas_remaps']==300,data
sizes.write_text(json.dumps(data,indent=2),encoding='utf-8');print(json.dumps(data))
subprocess.run([sys.executable,str(R/'tools/update_version.py')],cwd=R,check=True)
