"""Run required regressions using one workspace-contained, disposable Godot slot."""
from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/en-r24'
HEADLESS = ['en_r24_test', 'dialogue_player_r21_test', 'dialogue_roster_r21_test',
            'finish_locale_data_audit', 'world_test', 'state_test', 'route_test',
            'expansion_test', 'motion_test', 'motion_asset_test', 'art_test', 'export_licenses']
WINDOWED = ['ui_battle_r17_test', 'ui_battle_r18_test', 'ui_battle_r19_test',
            'ui_battle_r20_test', 'motion_r9_integration', 'motion_r18_integration', 'ui_en_r24_test']

def cleanup():
    base = (ROOT / 'verification/ui-r17').resolve()
    assert base.is_relative_to(ROOT.resolve())
    for slot in ['en-r24', 'en-r24-scan']:
        for prefix in ['runtime-', 'runtime-local-', 'tmp-']:
            target = (base / (prefix + slot)).resolve()
            assert target.parent == base and target.name == prefix + slot
            assert target.name not in ['runtime', 'runtime-local', 'tmp']
            if target.exists():
                shutil.rmtree(target)
                print('Removed', target.name, flush=True)
    for name in ['adeline.txt', 'altan.txt', 'bargut.txt']:
        target = (OUT / name).resolve()
        assert target.parent == OUT.resolve()
        if target.exists(): target.unlink()

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    selected = sys.argv[1:]
    jobs = [('import', ['--headless', '--editor', '--import', '--quit'])]
    jobs += [(n, ['--headless', '--script', 'res://tests/' + n + '.gd']) for n in HEADLESS]
    jobs += [(n, ['--position', '-10000,-10000', '--script', 'res://tests/' + n + '.gd']) for n in WINDOWED]
    results = []
    for name, args in jobs:
        if selected and name not in selected: continue
        start = time.monotonic()
        try:
            p = subprocess.run([sys.executable, 'tools/godot_r17.py', *args], cwd=ROOT,
                               env={**os.environ, 'R23_RUNTIME_SLOT': 'en-r24', 'PYTHONIOENCODING': 'utf-8'},
                               capture_output=True, timeout=900)
            text = (p.stdout + p.stderr).decode('utf-8', errors='replace'); code = p.returncode
        except subprocess.TimeoutExpired as exc:
            text = ((exc.stdout or b'') + (exc.stderr or b'')).decode('utf-8', errors='replace'); code = 124
        (OUT / (name + '.log')).write_text(text, encoding='utf-8')
        errors = [l for l in text.splitlines() if ('SCRIPT ERROR:' in l or l.startswith('ERROR:'))
                  and 'root certificate store' not in l]
        summary = [l for l in text.splitlines() if re.search('CHECKS|checks|FAILURES|failures|AUDIT', l)][-4:]
        result = {'test': name, 'exit': code, 'errors': errors, 'passed': code == 0 and not errors,
                  'summary': summary, 'seconds': round(time.monotonic() - start, 2)}
        results.append(result)
        destination = OUT / 'regression.json'
        existing = json.loads(destination.read_text(encoding='utf-8')) if destination.exists() else []
        existing = [r for r in existing if r['test'] != name] + [result]
        destination.write_text(json.dumps(existing, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print(json.dumps(result, ensure_ascii=False), flush=True)
    return int(any(not r['passed'] for r in results))

if __name__ == '__main__':
    if sys.argv[1:] == ['--cleanup']:
        cleanup()
    else:
        try: code = main()
        finally: cleanup()
        raise SystemExit(code)
