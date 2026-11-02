"""All project test suites, excluding fixture generators and balance probes."""
from pathlib import Path
import json, re, subprocess, sys, time
R = Path(__file__).resolve().parents[1]
O = R / 'verification/town-r21/round11'
O.mkdir(parents=True, exist_ok=True)
names = sorted(p.stem for p in (R/'project/tests').glob('*.gd')
               if p.stem.endswith('_test') or p.stem in ['export_licenses', 'motion_r9_integration', 'motion_r18_integration', 'balance_probe'])
selected = set(sys.argv[1:])
rows = json.loads((O/'regression.json').read_text(encoding='utf-8')) if selected and (O/'regression.json').exists() else []
jobs = [('import', ['--headless', '--editor', '--import', '--quit'])]
for n in names:
    native = n.startswith('ui_') or n in ['motion_r9_integration', 'motion_r18_integration']
    jobs.append((n, (['--position', '-10000,-10000'] if native else ['--headless']) + ['--script', f'res://tests/{n}.gd']))
for name, args in jobs:
    if selected and name not in selected: continue
    start = time.monotonic()
    try:
        p = subprocess.run([sys.executable, 'tools/godot_r17.py', *args], cwd=R, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=240)
        log = p.stdout.decode('utf-8', errors='replace'); code = p.returncode
    except subprocess.TimeoutExpired as e:
        log = (e.stdout or b'').decode('utf-8', errors='replace')+'\nTIMEOUT'; code = 124
    (O/(name+'.log')).write_text(log, encoding='utf-8')
    errors = [s for s in log.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:') or s.startswith('FAIL:')) and 'root certificate store' not in s]
    summary = [s for s in log.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS|TESTS:|Exported', s)][-3:]
    row = dict(name=name, exit_code=code, errors=errors, summary=summary, seconds=round(time.monotonic()-start, 2))
    rows = [r for r in rows if r['name'] != name]+[row]
    (O/'regression.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
    print(name, 'PASS' if not code and not errors else 'FAIL', row['seconds'], json.dumps([s[:180] for s in summary],ensure_ascii=True), flush=True)
print('GROUPS', len(rows), 'FAILED', sum(bool(r['exit_code'] or r['errors']) for r in rows), flush=True)
sys.exit(1 if any(r['exit_code'] or r['errors'] for r in rows) else 0)
