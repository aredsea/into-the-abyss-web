import json
import os
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / 'tools'))
from en_r24_verify import cleanup

ids = sys.argv[1:]
assert ids and all(re.fullmatch('[a-z]+', cid) for cid in ids)
out = root / 'verification/en-r24'
results = []
try:
    for name in ['finish_locale_data_audit', 'en_r24_test', 'dialogue_player_r21_test', 'dialogue_roster_r21_test']:
        args = [sys.executable, 'tools/godot_r17.py', '--headless', '--script', f'res://tests/{name}.gd']
        if name in ['finish_locale_data_audit', 'en_r24_test']:
            args += ['--', ','.join(ids)]
        proc = subprocess.run(args, cwd=root, capture_output=True,
                              env={**os.environ, 'R23_RUNTIME_SLOT': 'en-r24', 'PYTHONIOENCODING': 'utf-8'}, timeout=900)
        log = (proc.stdout + proc.stderr).decode('utf-8', errors='replace')
        (out / ('batch-' + '-'.join(ids) + '-' + name + '.log')).write_text(log, encoding='utf-8')
        errors = [line for line in log.splitlines() if ('SCRIPT ERROR:' in line or line.startswith('ERROR:')) and 'root certificate store' not in line]
        passed = proc.returncode == 0 and not errors
        if name == 'finish_locale_data_audit':
            audit = json.loads((out / 'batch-language-audit.json').read_text(encoding='utf-8'))
            passed = passed and audit['untranslated'] == 0
            (out / ('batch-' + '-'.join(ids) + '-language.json')).write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding='utf-8')
        if name == 'en_r24_test':
            (out / ('batch-' + '-'.join(ids) + '-dialogue.json')).write_bytes((out / 'dialogue-test.json').read_bytes())
        row = {'test': name, 'exit': proc.returncode, 'passed': passed, 'errors': errors,
               'summary': [line for line in log.splitlines() if re.search('CHECKS|checks|FAILURES|failures|AUDIT', line)]}
        results.append(row)
        print(json.dumps(row, ensure_ascii=False), flush=True)
finally:
    cleanup()
(out / ('batch-' + '-'.join(ids) + '-results.json')).write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
raise SystemExit(int(any(not row['passed'] for row in results)))
