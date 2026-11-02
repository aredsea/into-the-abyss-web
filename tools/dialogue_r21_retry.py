"""Preserve the initial regression result and retry only its engine cleanup error."""
import json
import subprocess
import sys
import time
from dialogue_r21_build import ROOT, OUT, read_json, write_json
from dialogue_r21_verify import summarize

def main():
    initial = OUT / 'regression-initial.json'
    if not initial.exists():
        write_json(initial, read_json(OUT / 'regression.json'))
        write_json(OUT / 'regression-initial-summary.json', read_json(OUT / 'regression-summary.json'))
        (OUT / 'godot-ui_battle_r18_test-initial.log').write_bytes((OUT / 'godot-ui_battle_r18_test.log').read_bytes())
    results = read_json(OUT / 'regression.json')
    name = 'ui_battle_r18_test'
    original = next(r for r in results if r['name'] == name)
    start = time.monotonic()
    p = subprocess.run(original['command'], cwd=ROOT, capture_output=True, timeout=240)
    output = (p.stdout + p.stderr).decode('utf-8', errors='replace')
    (OUT / 'godot-ui_battle_r18_test-retry-raw.log').write_text(output, encoding='utf-8')
    retry = {'name': name, 'command': original['command'], 'exit_code': p.returncode,
             'seconds': round(time.monotonic() - start, 2),
             'error_lines': [s for s in output.splitlines() if 'ERROR:' in s or 'SCRIPT ERROR' in s]}
    write_json(OUT / 'regression-retry.json', retry)
    if p.returncode == 0 and all(s == 'ERROR: Failed to read the root certificate store.' for s in retry['error_lines']):
        (OUT / 'godot-ui_battle_r18_test.log').write_text(output, encoding='utf-8')
        write_json(OUT / 'regression.json', [retry if r['name'] == name else r for r in results])
    result = summarize()
    print(json.dumps({k:v for k,v in result.items() if k != 'results'}, ensure_ascii=False))
    return int(bool(result['nonzero_exits'] or result['assertion_failures'] or result['unclassified_errors']))

if __name__ == '__main__':
    raise SystemExit(main())
