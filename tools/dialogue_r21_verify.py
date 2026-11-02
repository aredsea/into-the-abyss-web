"""Run the required existing Godot checks through the isolated wrapper only."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/dialogue-r21'
HEADLESS = ['world_test', 'state_test', 'route_test', 'expansion_test',
            'motion_test', 'motion_asset_test', 'art_test', 'export_licenses']
WINDOWED = ['ui_battle_r17_test', 'ui_battle_r18_test', 'ui_battle_r19_test',
            'ui_battle_r20_test', 'motion_r9_integration', 'motion_r18_integration']


def summarize():
    results = json.loads((OUT / 'regression.json').read_text(encoding='utf-8'))
    total_checks = 0
    for r in results:
        output = (OUT / f"godot-{r['name']}.log").read_text(encoding='utf-8')
        r['environment_errors'] = [s for s in r['error_lines'] if s == 'ERROR: Failed to read the root certificate store.']
        r['unclassified_errors'] = [s for s in r['error_lines'] if s not in r['environment_errors']]
        matches = re.findall(r'(\d+)\s+(?:checks|CHECKS)', output)
        if not matches:
            matches = re.findall(r'CHECKS[: ]+([0-9]+)', output)
        r['checks'] = int(matches[0]) if matches else None
        total_checks += r['checks'] or 0
        failure_counts = re.findall(r'FAILURES[: ]+(\d+)', output, re.I)
        if not failure_counts:
            failure_counts = re.findall(r'(\d+)\s+failures', output, re.I)
        r['assertion_failures'] = sum(map(int, failure_counts))
    before = json.loads((OUT / 'protected-before.json').read_text(encoding='utf-8'))
    after = protected()
    changes = [p for p in sorted(set(before) | set(after)) if before.get(p) != after.get(p)]
    (OUT / 'protected-diff.json').write_text(json.dumps(changes, ensure_ascii=False, indent=2), encoding='utf-8')
    result = {'runs': len(results), 'nonzero_exits': sum(bool(r['exit_code']) for r in results),
              'counted_assertions': total_checks, 'assertion_failures': sum(r['assertion_failures'] for r in results),
              'environment_error_occurrences': sum(len(r['environment_errors']) for r in results),
              'unclassified_errors': sum(len(r['unclassified_errors']) for r in results),
              'protected_changes': changes, 'results': results}
    (OUT / 'regression-summary.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    return result


def protected():
    paths = [*ROOT.glob('*.md'), ROOT / 'ASSET-HASHES.json']
    paths += [p for folder in ['project', 'tools'] for p in (ROOT / folder).rglob('*')
              if p.is_file() and '.godot' not in p.parts
              and '__pycache__' not in p.parts and p.suffix != '.uid'
              and 'dialogue-r21' not in p.parts and not p.name.startswith('dialogue_r21_')]
    return {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in paths if p.name != 'DIALOGUE-R21.md'}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    before = protected()
    (OUT / 'protected-before.json').write_text(json.dumps(before, indent=2), encoding='utf-8')
    jobs = [('import', ['--headless', '--editor', '--import', '--quit'])]
    jobs += [(n, ['--headless', '--script', f'res://tests/{n}.gd']) for n in HEADLESS]
    jobs += [(n, ['--position', '-10000,-10000', '--script', f'res://tests/{n}.gd']) for n in WINDOWED]
    results = []
    for name, args in jobs:
        start = time.monotonic()
        command = [sys.executable, 'tools/godot_r17.py', *args]
        try:
            p = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=240)
            output = (p.stdout + p.stderr).decode('utf-8', errors='replace')
            code = p.returncode
        except subprocess.TimeoutExpired as e:
            output = ((e.stdout or b'') + (e.stderr or b'')).decode('utf-8', errors='replace')
            code = -1
        (OUT / f'godot-{name}.log').write_text(output, encoding='utf-8')
        results.append({'name': name, 'command': command, 'exit_code': code,
                        'seconds': round(time.monotonic() - start, 2),
                        'error_lines': [l for l in output.splitlines() if 'ERROR:' in l or 'SCRIPT ERROR' in l]})
        (OUT / 'regression.json').write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
        print(name, code, results[-1]['seconds'], flush=True)
    after = protected()
    changes = [p for p in sorted(set(before) | set(after)) if before.get(p) != after.get(p)]
    (OUT / 'protected-diff.json').write_text(json.dumps(changes, ensure_ascii=False, indent=2), encoding='utf-8')
    print('protected_changes', len(changes), flush=True)
    result = summarize()
    return int(bool(result['nonzero_exits'] or result['assertion_failures'] or result['unclassified_errors'] or changes))


if __name__ == '__main__':
    if '--summarize' in sys.argv:
        r = summarize()
        print(json.dumps({k: v for k, v in r.items() if k != 'results'}, ensure_ascii=False, indent=2))
    else:
        raise SystemExit(main())
