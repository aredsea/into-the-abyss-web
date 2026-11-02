"""UTF-8 subprocess logs and exact exit codes; only isolated local test fixtures."""
from pathlib import Path
import json, subprocess, sys, time
R=Path(__file__).resolve().parents[1]
O=R/'verification/town-r21/round13'
O.mkdir(parents=True,exist_ok=True)
for name in sys.argv[1:]:
    native=name.startswith('ui_')
    args=['python','tools/godot_r17.py',*(['--position','-10000,-10000'] if native else ['--headless']),'--script',f'res://tests/{name}.gd']
    start=time.monotonic()
    with (O/(name+'.log')).open('wb') as log:
        result=subprocess.run(args,cwd=R,stdout=log,stderr=subprocess.STDOUT,timeout=1800)
    lines=(O/(name+'.log')).read_text(encoding='utf-8',errors='replace').splitlines()
    errors=[s for s in lines if ('SCRIPT ERROR:' in s or s.startswith('ERROR:') or s.startswith('FAIL:')) and 'root certificate store' not in s]
    report={'name':name,'exit_code':result.returncode,'errors':errors,'seconds':round(time.monotonic()-start,2),'summary':[s for s in lines if 'CHECKS' in s or 'FAILURES' in s][-3:]}
    (O/(name+'-execution.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps(report,ensure_ascii=True),flush=True)
    if result.returncode or errors:sys.exit(1)
