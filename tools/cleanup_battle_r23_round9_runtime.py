"""Remove completed round 8/9 isolated test homes, preserving the default home."""
from pathlib import Path
import json
import shutil

root = Path(__file__).resolve().parents[1]
runtime_root = (root / 'verification/ui-r17').resolve()
names = ['before9', 'final-0', 'final-1', 'final-2', 'final-3',
         'r8before', 'r8can', 'r8check', 'r8grade', 'r8gradebefore',
         'r8prelock', 'r8repair', 'round9-fix', 'round9-ui-fix']
targets = [runtime_root / (prefix + name)
           for prefix in ['runtime-', 'runtime-local-'] for name in names]
for target in targets:
    assert target.resolve().parent == runtime_root
    assert target.resolve().is_relative_to(root.resolve())
    assert not target.is_symlink()
removed = []
for target in targets:
    if not target.exists():
        continue
    size = sum(p.stat().st_size for p in target.rglob('*') if p.is_file())
    shutil.rmtree(target)
    removed.append({'path': target.relative_to(root).as_posix(), 'bytes': size})
report = root / 'verification/parity-r23/battle-round9-resume-runtime-cleanup.json'
previous = json.loads(report.read_text(encoding='utf-8'))['removed'] if report.exists() else []
report.write_text(
    json.dumps({'removed': previous + removed, 'bytes': sum(r['bytes'] for r in previous + removed)}, indent=2),
    encoding='utf-8')
print(json.dumps({'removed': len(removed), 'bytes': sum(r['bytes'] for r in removed)}))
