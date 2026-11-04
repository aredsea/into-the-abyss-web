"""Snapshot the inherited work before continuing; no git mutation."""
from pathlib import Path
import hashlib,json,shutil
R=Path(__file__).resolve().parents[1]
O=R/'verification/finish-r24/round4'
O.mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
if not (O/'baseline.json').exists():
    files={p.relative_to(R).as_posix():sha(p) for root in ['project/game','project/ui','project/tests','project/data','server','tools','docs'] for p in (R/root).rglob('*') if p.is_file() and not any(x in p.parts for x in ['node_modules','.wrangler','__pycache__'])}
    (O/'baseline.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf-8')
    for pack in ['expe','gear','ui','battle']:
        original=R/f'verification/parity-r23/{pack}.json'
        data=json.loads(original.read_text(encoding='utf-8'))
        compact={'ledger':pack,'original_sha256':sha(original),'rows':[{k:v for k,v in row.items() if k in ['id','source','status','new_status','fixed','remaining_reason']} for row in data['rows']]}
        (O/f'{pack}-before.json').write_text(json.dumps(compact,ensure_ascii=False,indent=2),encoding='utf-8')
    shutil.copyfile(R/'FINISH-R24.md',O/'round3-report.md')
print('ROUND4 BASELINE',len(json.loads((O/'baseline.json').read_text(encoding='utf-8'))))
