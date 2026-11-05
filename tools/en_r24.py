"""Add English prose without changing the original JSON prefix or save format."""
from pathlib import Path
import hashlib
import json
import re
import random
import sys
from dialogue_r21_build import display_fields

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'verification/en-r24'

def load(cid):
    path = ROOT / 'project/data/dialogue-r21' / (cid + '.json')
    return path, json.loads(path.read_text(encoding='utf-8'))

def append(cid, lines, start=0):
    path, data = load(cid)
    fields = list(display_fields(data))
    values = lines.splitlines()
    assert start + len(values) <= len(fields), (cid, start, len(values), len(fields))
    english = data.get('en', {'display': {}})
    for (key, source, _), text in zip(fields[start:], values):
        assert text.strip() and not re.search('[가-힣ㄱ-ㅎㅏ-ㅣ]', text), (key, text)
        assert sorted(re.findall(r'\{\{.*?\}\}', source)) == sorted(re.findall(r'\{\{.*?\}\}', text)), key
        english['display'][key] = text
    write_en(path, english)
    print(cid, 'translated', len(english['display']), '/', len(fields))

def write_en(path, english):
    raw = path.read_bytes()
    # All original bytes, including Korean strings and original whitespace, survive.
    marker = b',\n  "en": '
    if marker in raw:
        prefix = raw[:raw.rfind(marker)]
    else:
        assert raw.rstrip().endswith(b'}')
        prefix = raw.rstrip()[:-1].rstrip()
    payload = json.dumps(english, ensure_ascii=False, indent=2)
    payload = payload.replace('\n', '\n  ')
    path.write_bytes(prefix + marker + payload.encode('utf-8') + b'\n}\n')

def audit(ids=None):
    baseline = json.loads((OUT / 'baseline.json').read_text(encoding='utf-8'))
    rows = []; issues = []
    for cid in ids or [p.stem for p in sorted((ROOT / 'project/data/dialogue-r21').glob('*.json'))]:
        path, data = load(cid); english = data.pop('en', {})
        digest = hashlib.sha256(json.dumps(data, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
        assert digest == baseline['files'][path.name]['canonical_sha256'], cid + ': source changed'
        raw = path.read_bytes()
        marker = b',\n  "en": '
        original = raw[:raw.rfind(marker)] + b'\n}\n' if marker in raw else raw
        assert hashlib.sha256(original).hexdigest() == baseline['files'][path.name]['sha256'], cid + ': original bytes changed'
        fields = list(display_fields(data)); translated = english.get('display', {})
        missing = [k for k, t, _ in fields if not translated.get(k) or re.search('[가-힣ㄱ-ㅎㅏ-ㅣ]', translated[k])]
        extra = set(translated) - {k for k, _, _ in fields}
        assert not extra, extra
        for k, t, _ in fields:
            if k in translated:
                assert sorted(re.findall(r'\{\{.*?\}\}', t)) == sorted(re.findall(r'\{\{.*?\}\}', translated[k])), (cid, k)
        rows.append({'id': cid, 'fields': len(fields), 'translated': len(translated), 'untranslated': len(missing), 'source_unchanged': True, 'original_bytes_reconstruct_exactly': True})
        issues.extend({'id': cid, 'field': k} for k in missing)
    result = {'fields': sum(r['fields'] for r in rows), 'translated': sum(r['translated'] for r in rows), 'untranslated': len(issues), 'files': rows, 'missing': issues}
    target = OUT / ('audit-' + '-'.join(ids) + '.json' if ids else 'authored-language-audit.json')
    target.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in result.items() if k not in ['files', 'missing']}))
    return result

def sample():
    rows = []
    for path in sorted((ROOT / 'project/data/dialogue-r21').glob('*.json')):
        data = json.loads(path.read_text(encoding='utf-8'))
        for key, source, _ in display_fields(data):
            english = data.get('en', {}).get('display', {}).get(key)
            if english: rows.append((path.stem, key, source, english))
    chosen = random.Random(20261104).sample(rows, 300)
    complete = len({r[0] for r in rows}) == 30 and len(rows) == 14216
    scope = ('All 30 characters and all 14,216 display fields.' if complete else
             f'The {len(rows):,} translated fields only. Other fields may remain untranslated.')
    lines = ['# EN-R24 bilingual sample (300 lines)', '',
             f'Scope: {scope} Seed: 20261104; sampling without replacement.', '',
             '| # | Character / field | Korean (unchanged) | English |', '| --- | --- | --- | --- |']
    def escape(s): return s.replace('|', '\\|').replace('\n', '<br>')
    for i, (cid, key, ko, en) in enumerate(chosen, 1):
        lines.append(f'| {i} | {cid} / {key} | {escape(ko)} | {escape(en)} |')
    (OUT / 'sample.md').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    (OUT / 'sample-index.json').write_text(json.dumps([{'id': c, 'path': k} for c, k, _, _ in chosen], indent=2) + '\n', encoding='utf-8')
    print('sample', len(chosen), 'from', len(rows), 'translated fields')

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    if sys.argv[1] == 'dump':
        _, data = load(sys.argv[2]); start = int(sys.argv[3]) if len(sys.argv) > 3 else 0
        end = int(sys.argv[4]) if len(sys.argv) > 4 else 99999
        for i, (key, source, _) in enumerate(display_fields(data)):
            if start <= i < end: print(f'{i}\t{source}')
    elif sys.argv[1] == 'audit': raise SystemExit(bool(audit(sys.argv[2:] or None)['untranslated']))
    elif sys.argv[1] == 'sample': sample()
    elif sys.argv[1] == 'append': append(sys.argv[2], Path(sys.argv[3]).read_text(encoding='utf-8'), int(sys.argv[4]) if len(sys.argv) > 4 else 0)
