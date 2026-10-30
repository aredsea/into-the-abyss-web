"""Repeatable pass-two checks. Every engine/runtime/output path is in this tree."""
from pathlib import Path
import json, subprocess, sys
root = Path(__file__).resolve().parents[1]
out = root / 'verification/ui-r17'
runner = [sys.executable, str(root / 'tools/godot_r17.py')]
mode = sys.argv[1]
jobs = {
    'checks': [('import-final', ['--headless', '--editor', '--import', '--quit'])] +
              [(t, ['--headless', '--script', f'res://tests/{t}.gd']) for t in
               ['world_test', 'state_test', 'route_test', 'expansion_test', 'balance_probe', 'motion_test', 'motion_asset_test', 'art_test', 'export_licenses']],
    'review': [('input', ['--position', '-10000,-10000', '--script', 'res://tools/review_ui_r17.gd'])],
    'motion': [('motion-integration', ['--position', '-10000,-10000', '--script', 'res://tests/motion_r9_integration.gd'])],
    'export': [('export', ['--headless', '--export-release', 'Web', '../docs/index.html'])],
}[mode]
if mode == 'export' and not (out / 'pass2-build-before.json').exists():
    (out / 'pass2-build-before.json').write_text(json.dumps({'pck_bytes': (root / 'docs/index.pck').stat().st_size}), encoding='utf-8')
results = []
for name, args in jobs:
    p = subprocess.run(runner + args, cwd=root, capture_output=True, encoding='utf-8', errors='replace', timeout=600)
    text = p.stdout + p.stderr
    (out / f'{name}.log').write_text(text, encoding='utf-8')
    errors = [line for line in text.splitlines() if ('ERROR:' in line or 'SCRIPT ERROR' in line) and 'root certificate store' not in line]
    results.append({'test': name, 'exit_code': p.returncode, 'engine_errors': errors, 'output': text.splitlines()})
    print(name, 'exit', p.returncode, 'errors', len(errors), flush=True)
    if p.returncode or errors:
        print(text[-6000:], flush=True)
        break
(out / f'pass2-{mode}.json').write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
if mode == 'checks':
    (out / 'existing-tests.json').write_text(json.dumps(results[1:], ensure_ascii=False, indent=2), encoding='utf-8')
sys.exit(0 if len(results) == len(jobs) and all(not r['exit_code'] and not r['engine_errors'] for r in results) else 1)
