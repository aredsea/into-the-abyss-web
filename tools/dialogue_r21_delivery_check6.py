"""Verify delivery evidence, exact allowed changes, and offline replay."""
from copy import deepcopy
from collections import Counter
import subprocess
import sys
from dialogue_r21_build import ROOT, OUT, CANON, IDS, read_json, write_json, display_fields, replace_at
from dialogue_r21_round5 import digest, at, structural


def main():
    checks = []
    def check(name, ok):
        checks.append(dict(name=name, passed=bool(ok)))
    edits = read_json(OUT / 'edits6-applied.json')
    refs = read_json(OUT / 'kreview-5.json')
    baseline = read_json(OUT / 'baseline6.json')
    review = (OUT / 'review-6.md').read_text(encoding='utf8')
    hashes = {cid + '.json': digest(ROOT / f'project/data/dialogue-r21/{cid}.json') for cid in IDS}
    proc = subprocess.run([sys.executable, '-X', 'utf8', 'tools/dialogue_r21_build.py'], cwd=ROOT, capture_output=True)
    check('offline-rebuild-exit', proc.returncode == 0)
    check('offline-rebuild-byte-identical', hashes == {cid + '.json': digest(ROOT / f'project/data/dialogue-r21/{cid}.json') for cid in IDS})
    check('review-all-20-ids', {e['id'] for e in edits if e['status'] == '반영'} == {e['id'] for e in refs})
    check('edits-27-unique-paths', len(edits) == len({(e['character_id'], e['path']) for e in edits}) == 27)
    for e in edits:
        check(e['id'] + '-real-edit-and-report', e['before'] != e['after'] and all(s in review for s in [e['id'], e['before'], e['after'], e['reason']]))
        if e['id'].startswith('KR5-'):
            ref = next(r for r in refs if r['id'] == e['id'])
            check(e['id'] + '-reference-exact', ref['after5'] == e['before'] and ref['scene_id'] == e['scene_id'])
    totals = Counter()
    for cid in IDS:
        before = read_json(OUT / f'draft6/{cid}.json')
        after = read_json(ROOT / f'project/data/dialogue-r21/{cid}.json')
        check(cid + '-frozen-source', digest(OUT / f'draft6/{cid}.json') == baseline['data'][cid + '.json'])
        expected = deepcopy(before)
        paths = {p for p, _, _ in display_fields(before)}
        for e in edits:
            if e['character_id'] == cid:
                check(e['id'] + '-before-and-after-exact', e['path'] in paths and at(before, e['path']) == e['before'] and at(after, e['path']) == e['after'])
                replace_at(expected, e['path'], e['after'])
        check(cid + '-only-declared-text-changes', expected == after)
        check(cid + '-structure-aff-register-metadata', structural(before) == structural(after))
        totals.update(inn=len(after['inn']), choices=sum(len(s['choices']) for s in after['inn']), dungeon=sum(len(s['variants']) for s in after['dungeon']), transitions=len(after['transitions']))
    check('content-counts-preserved', dict(totals) == dict(inn=840, choices=2520, dungeon=2520, transitions=420))
    lint = read_json(OUT / 'check6.json')
    check('lint-zero-and-current', lint['error_count'] == 0 and lint['input_sha256'] == hashes)
    for group, root in [('protected', ROOT), ('historical', ROOT), ('canon', CANON)]:
        check(group + '-all-unchanged', all((root / p).is_file() and digest(root / p) == h for p, h in baseline[group].items()))
    for file in ['selftest6.json', 'selftest6-registers.json']:
        check(file, read_json(OUT / file)['failures'] == 0)
    regression = read_json(OUT / 'regression6/regression-summary.json')
    check('godot-15-zero-failures', regression['runs'] == 15 and not any(regression[k] for k in ['nonzero_exits', 'assertion_failures', 'unclassified_errors', 'protected_changes']))
    images = read_json(OUT / 'regression-images6.json')
    check('six-current-image-hashes', len(images) == 6 and all(digest(ROOT / i['file']) == i['sha256'] for i in images))
    report = (ROOT / 'DIALOGUE-R21.md').read_bytes()
    check('report-six-first-history-exact', report.startswith('# 6차\n'.encode('utf8')) and report.endswith((OUT / 'original-report5.md').read_bytes()))
    patterns = ['수정 전', '조금 멈', '끝에 걷', '기다리던 다른 얼굴', '마른 뒤에도 조금 더 얘기']
    pattern_counts = {}
    for pattern in [*patterns, '쉽게 중복']:
        counts = []
        for folder in [OUT / 'draft6', ROOT / 'project/data/dialogue-r21']:
            counts.append(sum((t.count('쉽게') > 1) if pattern == '쉽게 중복' else (pattern in t)
                              for cid in IDS for _, t, _ in display_fields(read_json(folder / f'{cid}.json'))))
        pattern_counts[pattern] = dict(before=counts[0], after=counts[1])
    check('target-phrase-residue-zero', all(v['after'] == 0 for v in pattern_counts.values()))
    result = dict(checks=len(checks), failures=sum(not c['passed'] for c in checks),
                  edited_fields=len(edits), edited_characters=len({e['character_id'] for e in edits}),
                  totals=dict(totals), preserved_counts={k: len(baseline[k]) for k in ['protected', 'historical', 'canon']},
                  pattern_counts=pattern_counts, results=checks)
    write_json(OUT / 'delivery-check6.json', result)
    print({k: v for k, v in result.items() if k not in ['results', 'pattern_counts']})
    for c in checks:
        if not c['passed']:
            print('FAIL', c['name'])
    return int(bool(result['failures']))


if __name__ == '__main__':
    raise SystemExit(main())
