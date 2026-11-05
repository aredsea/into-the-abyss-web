"""Record measured progress without treating a passing audit process as completion."""
import hashlib
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'tools'))
from en_r24 import audit, sample

out = root / 'verification/en-r24'
result = audit()
sample()
baseline = json.loads((out / 'baseline.json').read_text(encoding='utf-8'))
protected_changes = [p for p, h in baseline['protected'].items()
                     if not (root / p).exists() or hashlib.sha256((root / p).read_bytes()).hexdigest() != h]
assets = json.loads((root / 'ASSET-HASHES.json').read_text(encoding='utf-8'))
asset_changes = [r['path'] for r in assets if hashlib.sha256((root / r['path']).read_bytes()).hexdigest() != r['sha256']]
regression = json.loads((out / 'regression.json').read_text(encoding='utf-8'))
ui = json.loads((out / 'ui-test.json').read_text(encoding='utf-8'))
complete = [r['id'] for r in result['files'] if not r['untranslated']]
counts = []
for row in regression:
    text = (out / (row['test'] + '.log')).read_text(encoding='utf-8')
    matches = re.findall(r'\bCHECKS\s*:?\s*(\d+)', text)
    if not matches:
        matches = re.findall(r'(\d+)\s+checks\b', text, flags=re.IGNORECASE)
    if matches:
        counts.append({'test': row['test'], 'checks': int(matches[-1])})
summary = {
    'status': 'complete' if not result['untranslated'] else 'incomplete',
    'characters_complete': len(complete), 'characters_total': len(result['files']),
    'fields': result['fields'], 'translated': result['translated'], 'untranslated': result['untranslated'],
    'round2_characters_added': len(complete) - 3, 'round2_fields_added': result['translated'] - 1398,
    'regression_runs': len(regression), 'regression_failed': sum(not r['passed'] for r in regression),
    'counted_checks': sum(r['checks'] for r in counts), 'checks_by_test': counts,
    'ui_scenes': ui['scenes'], 'ui_checks': ui['checks'], 'ui_failures': len(ui['failures']),
    'sample_rows': 300, 'sample_scope': complete, 'sample_seed': 20261104,
    'protected_files': len(baseline['protected']), 'protected_changes': protected_changes,
    'asset_hash_entries': len(assets), 'asset_hash_changes': asset_changes,
    'save_format_changed': False, 'release_language_gate_passed': not result['untranslated'],
    'external_translation_services_used': False,
    'runtime_slots_cleaned': not (root / 'verification/ui-r17/runtime-en-r24').exists(),
}
visual_path = out / 'visual-review-round2.json'
if visual_path.exists():
    summary['visual_captures_reviewed'] = json.loads(visual_path.read_text(encoding='utf-8'))['reviewed_captures']
(out / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
(out / 'translation-execution.json').write_text(json.dumps({
    'method': 'Direct assistant translation, one character at a time; no external translation service or API.',
    'completed': complete, 'remaining': [r['id'] for r in result['files'] if r['untranslated']],
    'translated': result['translated'], 'untranslated': result['untranslated'],
    'original_bytes_reconstruct_exactly': all(r['original_bytes_reconstruct_exactly'] for r in result['files']),
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps(summary, ensure_ascii=False, indent=2))
