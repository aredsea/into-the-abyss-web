"""Fourth pass local-only web export and size evidence."""
from pathlib import Path
import subprocess,sys,json,hashlib
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round4'
if (V/'export-sizes.json').exists() and not (V/'export-sizes-lossless.json').exists():
    (V/'export-sizes-lossless.json').write_bytes((V/'export-sizes.json').read_bytes())
    (V/'export-after-lossless.log').write_bytes((V/'export-after.log').read_bytes())
# Measure the actual pack contribution, including imported texture encoding.
# This deliberately incomplete export is budget evidence only, never the delivered build.
preset=R/'project/export_presets.cfg';original=preset.read_bytes();text=original.decode('utf-8');lines=text.splitlines()
for i,line in enumerate(lines):
    if line.startswith('exclude_filter='):lines[i]=line[:-1]+',assets/ui-r21/bg-*"'
budget=V/'budget-no-background';budget.mkdir(exist_ok=True)
try:
    preset.write_text('\n'.join(lines)+'\n',encoding='utf-8')
    before=subprocess.run([sys.executable,str(R/'tools/godot_r17.py'),'--headless','--export-release','Web','../verification/town-r21/round4/budget-no-background/index.html'],cwd=R,capture_output=True,encoding='utf-8',errors='replace',timeout=240)
    (V/'export-background-excluded.log').write_text(before.stdout+before.stderr,encoding='utf-8')
    assert before.returncode==0
finally:preset.write_bytes(original)
without=(budget/'index.pck').stat().st_size
p=subprocess.run([sys.executable,str(R/'tools/godot_r17.py'),'--headless','--export-release','Web','../docs/index.html'],cwd=R,capture_output=True,encoding='utf-8',errors='replace',timeout=240)
log=p.stdout+p.stderr;(V/'export-after.log').write_text(log,encoding='utf-8')
errors=[x for x in log.splitlines() if ('ERROR:' in x or 'SCRIPT ERROR:' in x) and 'root certificate store' not in x]
assert p.returncode==0 and not errors,(p.returncode,errors)
baseline=json.loads((V/'baseline.json').read_text(encoding='utf-8'));pack=json.loads((V/'background-pack.json').read_text(encoding='utf-8'))
size=(R/'docs/index.pck').stat().st_size
data={'before_pck_bytes':baseline['pck_bytes'],'round3_reported_pck_bytes':61934348,'after_pck_bytes':size,'increase_bytes':size-baseline['pck_bytes'],'increase_from_round3_report_bytes':size-61934348,'same_code_without_background_pck_bytes':without,'background_pck_bytes':size-without,'background_webp_bytes':pack['bytes'],'background_budget':10000000,'sha256':hashlib.sha256((R/'docs/index.pck').read_bytes()).hexdigest(),'errors':errors}
assert 0<size-without<=10000000 and pack['bytes']<=10000000,data
(V/'export-sizes.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
subprocess.run([sys.executable,str(R/'tools/update_version.py')],cwd=R,check=True)
print(json.dumps(data))
