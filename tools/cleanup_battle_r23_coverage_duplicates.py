"""Remove obsolete coverage oracle copies only after verifying canonical equality."""
from pathlib import Path
import gc
import hashlib
import json

R = Path(__file__).resolve().parents[1]
O = R / 'verification/parity-r23'
D = (O / 'coverage').resolve()
removed = []
for p in sorted(D.glob('*oracle*.json')):
    assert p.resolve().parent == D
    if p.name.startswith('retained-'):
        # The first remaining suffix matching a retained canonical reference wins.
        candidates = [q for q in (R / 'verification/data-r21').glob('*oracle.json')
                      if p.name.endswith('-' + q.name)]
        canonical = max(candidates, key=lambda q: len(q.name))
    else:
        canonical = O / ('oracle.json' if p.name == 'main-oracle.json' else p.name)
    before = json.loads(p.read_text(encoding='utf-8'))
    expected = json.loads(canonical.read_text(encoding='utf-8'))
    for data in [before, expected]:
        if isinstance(data, dict):
            data.pop('provenance', None)
    assert before == expected, f'Preserving nonduplicate evidence: {p.name}'
    del before, expected
    gc.collect()
    removed.append({'file': p.relative_to(R).as_posix(), 'bytes': p.stat().st_size,
                    'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
                    'canonical': canonical.relative_to(R).as_posix(),
                    'comparison': 'Parsed full JSON equality excluding top-level provenance only'})
    p.unlink()
    print('Removed verified duplicate:', p.name, flush=True)
assert not list(D.glob('*oracle*.json'))
(O / 'battle-round9-coverage-duplicate-cleanup.json').write_text(
    json.dumps({'removed': removed, 'bytes_reclaimed': sum(r['bytes'] for r in removed)}, indent=2),
    encoding='utf-8')
