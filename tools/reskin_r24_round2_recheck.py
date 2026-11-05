"""Focused rechecks after preparing missing fixtures, isolated from the suite."""
from pathlib import Path
import subprocess,os,json,sys,time,re
R=Path(__file__).resolve().parents[1];O=R/'verification/reskin-r24/round2/tests';P=O/'focused-results.json'
rows=json.loads(P.read_text(encoding='utf-8')) if P.exists() else []
for name in sys.argv[1:]:
    start=time.monotonic();native=name.startswith('ui_') or name.endswith('_integration')
    args=['--position','-10000,-10000'] if native else ['--headless']
    with (O/(name+'-focused.log')).open('wb') as log:
        p=subprocess.run([sys.executable,'tools/godot_r17.py',*args,'--script','res://tests/'+name+'.gd'],cwd=R,env={**os.environ,'R23_RUNTIME_SLOT':os.environ.get('RESKIN_RECHECK_SLOT','reskin-main'),'PYTHONIOENCODING':'utf-8'},stdout=log,stderr=subprocess.STDOUT,timeout=2400)
    text=(O/(name+'-focused.log')).read_text(encoding='utf-8',errors='replace')
    errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
    row={'test':name,'exit':p.returncode,'errors':errors,'passed':p.returncode==0 and not errors,'seconds':round(time.monotonic()-start,2),'summary':[s[:400] for s in text.splitlines() if re.search(r'CHECKS|checks|FAILURES|failures|PASS',s)][-4:]}
    rows=[r for r in rows if r['test']!=name]+[row];P.write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row,ensure_ascii=True),flush=True)
