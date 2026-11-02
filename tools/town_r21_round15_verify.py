"""Run the required native regression groups without exports or git operations."""
from pathlib import Path
import json
import subprocess
import sys
import time

root = Path(__file__).resolve().parents[1]
out = root / 'verification/town-r21/round15'
out.mkdir(parents=True, exist_ok=True)
headless = ['world_test', 'state_test', 'route_test', 'expansion_test', 'motion_test',
            'motion_asset_test', 'art_test', 'export_licenses']
native = ['ui_battle_r17_test', 'ui_battle_r18_test', 'ui_battle_r19_test',
          'ui_battle_r20_test', 'motion_r9_integration', 'motion_r18_integration']
rows = []
for name in ['import', *headless, *native]:
    args = ['--headless', '--editor', '--import', '--quit'] if name == 'import' else [
        *(['--position', '-10000,-10000'] if name in native else ['--headless']),
        '--script', f'res://tests/{name}.gd']
    started = time.monotonic()
    with (out / f'{name}.log').open('w', encoding='utf-8') as log:
        result = subprocess.run([sys.executable, 'tools/godot_r17.py', *args], cwd=root,
                                stdout=log, stderr=subprocess.STDOUT, timeout=600)
    lines = (out / f'{name}.log').read_text(encoding='utf-8').splitlines()
    errors = [line for line in lines if ('SCRIPT ERROR:' in line or line.startswith(('ERROR:', 'FAIL:')))
              and 'root certificate store' not in line]
    row = dict(name=name, exit_code=result.returncode, errors=errors,
               summary=[line for line in lines if any(key in line for key in ['PASS', 'CHECKS', 'FAILURES', 'TESTS:'])][-4:],
               seconds=round(time.monotonic() - started, 3))
    rows.append(row)
    (out / 'regression.json').write_text(json.dumps(rows, indent=2), encoding='utf-8')
    print(json.dumps(row), flush=True)
sys.exit(int(any(row['exit_code'] or row['errors'] for row in rows)))
