"""Remove only this lane's known temporary runtime slots; keep base runtime."""
from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];base=(R/'verification/ui-r17').resolve();O=R/'verification/reskin-r24'
rows=[]
for slot in ['reskin-main','reskin-test-1','reskin-test-2','reskin-test-3']:
 for prefix in ['runtime-','runtime-local-','tmp-']:
  target=(base/(prefix+slot)).resolve()
  assert target.parent==base and target.name not in ['runtime','runtime-local','tmp']
  if target.exists():
   size=sum(p.stat().st_size for p in target.rglob('*') if p.is_file());shutil.rmtree(target);rows.append({'path':str(target.relative_to(R)),'bytes':size,'removed':not target.exists()})
for name in ['reskin_r24_edit.py','reskin_r24_refine.py','reskin_r24_finish_ui.py']:
 target=(R/'tools'/name).resolve();assert target.parent==(R/'tools').resolve()
 if target.exists():target.unlink()
target=(O/'tmp').resolve();assert target.parent==O.resolve()
if target.exists():shutil.rmtree(target)
for p in O.rglob('*.log'):
 raw=p.read_bytes()
 if raw.startswith(b'\xff\xfe'):p.write_text(raw.decode('utf-16'),encoding='utf-8')
for p in [O/'design-detector.json']:
 raw=p.read_bytes()
 if raw.startswith(b'\xff\xfe'):p.write_text(raw.decode('utf-16'),encoding='utf-8')
out={'slots':rows,'reclaimed_bytes':sum(r['bytes'] for r in rows),'temporary_slots_remaining':[str(p.relative_to(R)) for p in base.glob('runtime-reskin-*')],'base_runtime_preserved':True,'free_bytes':shutil.disk_usage(R).free}
(O/'cleanup.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps({k:v for k,v in out.items() if k!='slots'},ensure_ascii=False))
