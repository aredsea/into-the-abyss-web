"""Sequential rechecks in the retained default home, independent of suite slots."""
from pathlib import Path
import sys,subprocess,os,time,json,re
R=Path(__file__).resolve().parents[1];O=R/os.environ.get('R24_FINISH_OUTPUT','verification/finish-r24');O.mkdir(exist_ok=True)
rows=json.loads((O/'focused-results.json').read_text(encoding='utf-8')) if (O/'focused-results.json').exists() else []
for name in sys.argv[1:]:
    start=time.monotonic();args=['--position','-10000,-10000'] if name.startswith('ui_') else ['--headless']
    with (O/(name+'-focused.log')).open('wb') as log:
        code=subprocess.call([sys.executable,'tools/godot_r17.py',*args,'--script','res://tests/'+name+'.gd'],cwd=R,env={**os.environ,'R23_RUNTIME_SLOT':'','PYTHONIOENCODING':'utf-8'},stdout=log,stderr=subprocess.STDOUT)
    text=(O/(name+'-focused.log')).read_text(encoding='utf-8',errors='replace')
    errors=[s for s in text.splitlines() if ('SCRIPT ERROR:' in s or s.startswith('ERROR:')) and 'root certificate store' not in s]
    row={'test':name,'exit':code,'errors':errors,'passed':code==0 and not errors,'summary':[s for s in text.splitlines() if re.search('CHECKS|checks|FAILURES|failures|PASS',s)][-3:],'seconds':round(time.monotonic()-start,2)};rows=[r for r in rows if r['test']!=name]+[row]
    (O/'focused-results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(row,ensure_ascii=True),flush=True)
raise SystemExit(any(not r['passed'] for r in rows))
