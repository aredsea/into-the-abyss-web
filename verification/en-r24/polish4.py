"""Local, reviewable English-only editorial journal. No translation service."""
from pathlib import Path
import hashlib, json, re, sys

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / 'tools'))
from en_r24 import load, write_en
from dialogue_r21_build import display_fields
BASE = OUT / 'polish-baseline.json'
JOURNAL = OUT / 'polish-revisions.json'

def snapshot():
    assert not BASE.exists()
    data = {}
    for path in sorted((ROOT / 'project/data/dialogue-r21').glob('*.json')):
        raw = json.loads(path.read_text(encoding='utf-8'))
        data[path.stem] = raw['en']
    BASE.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    JOURNAL.write_text('[]\n', encoding='utf-8')
    print('Saved English baseline:', len(data), 'characters')

def dump(cid, start=0, end=99999, bilingual=False):
    _, data = load(cid)
    print(cid, json.dumps(data['en'].get('speech', {}), ensure_ascii=False))
    for i,(key,ko,_) in enumerate(display_fields(data)):
        if start <= i < end:
            print(f'{i} {data["en"]["display"][key]}'+(f' / {ko}' if bilingual else ''))

def apply(cid, edits, reason='whole-character polish'):
    path, data = load(cid)
    fields = list(display_fields(data))
    journal = json.loads(JOURNAL.read_text(encoding='utf-8'))
    for key,new in edits.items():
        if isinstance(key,int) or key.isdecimal(): key = fields[int(key)][0]
        before = data['en']['display'][key]
        if before == new:
            continue
        assert new.strip() and not re.search('[가-힣ㄱ-ㅎㅏ-ㅣ]',new)
        ko = next(k for p,k,_ in fields if p == key)
        journal.append(dict(id=cid,path=key,korean=ko,before=before,after=new,reason=reason))
        data['en']['display'][key] = new
    write_en(path,data['en'])
    JOURNAL.write_text(json.dumps(journal, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
    print(cid, len(edits), 'edits')

def suggestions():
    report = (OUT / 'review-luna.md').read_text(encoding='utf-8')
    cid = None; rows=[]
    for line in report.splitlines():
        if line.startswith('### '): cid = line.split()[1].lower()
        if not line.startswith('- **`'): continue
        key = re.search(r'`([^`]+)`',line)[1]
        severity = re.search(r'· (틀림|어색|권함)',line)[1]
        current = re.search(r'현재: “(.*?)”',line)[1]
        proposed = re.search(r'제안: “(.*?)”',line)
        rows.append(dict(id=cid,path=key,severity=severity,review_before=current,proposed=proposed[1] if proposed else None))
    (OUT / 'polish-review-items.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(len(rows),'review items', {s:sum(r['severity']==s for r in rows) for s in ['틀림','어색','권함']})

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    if sys.argv[1]=='snapshot': snapshot(); suggestions()
    elif sys.argv[1]=='dump': dump(sys.argv[2],int(sys.argv[3]) if len(sys.argv)>3 else 0,int(sys.argv[4]) if len(sys.argv)>4 else 99999,'--ko' in sys.argv)
