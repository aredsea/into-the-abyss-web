"""Adversarial checks: real malformed payloads must fail the dialogue validator."""
from copy import deepcopy
import json
from pathlib import Path
from dialogue_r21_build import ROOT, IDS, read_json, write_json, lexicon
from dialogue_r21_check import validate, run, MBTI, ALIGNMENTS


def main():
    fixture = read_json(ROOT / 'project/data/dialogue-r21/teiris.json')
    dictionary = lexicon()
    checks = []

    def mutation(name, mutate, expected_fragment):
        data = deepcopy(fixture)
        mutate(data)
        errors, _ = validate(data, 'teiris', dictionary)
        okay = any(expected_fragment in e['message'] for e in errors)
        checks.append({'name': name, 'passed': okay, 'expected_error': expected_fragment})

    for code in sorted(MBTI):
        mutation('temperament-' + code, lambda d, c=code: d['inn'][0]['lines'].__setitem__(0, c + '라고 해요.'), 'temperament code')
    for name in ALIGNMENTS:
        mutation('alignment-' + name, lambda d, n=name: d['inn'][0]['lines'].__setitem__(0, n + ' 이라고 해요.'), 'alignment label')
    for name, line, message in [
        ('English', '오늘은 book을 읽어요.', 'English word'),
        ('translated-pronoun', '그녀가 여기에 있어요.', 'translated pronoun'),
        ('emoji-face', '여기 있어요. 😀', 'emoji'),
        ('emoji-symbol', '여기 있어요. ☀', 'emoji'),
        ('wrong-register', '지금 바로 갑시다.', 'speech endings violated'),
        ('new-proper-name', '카르자라는 도시에서 왔어요.', 'naming-pattern'),
        ('newline', '오늘은\n여기에요.', 'single line')]:
        mutation(name, lambda d, t=line: d['inn'][0]['lines'].__setitem__(0, t), message)
    mutation('missing-root-key', lambda d: d.pop('speech'), 'schema mismatch')
    mutation('unknown-root-key', lambda d: d.__setitem__('bogus', True), 'schema mismatch')
    mutation('missing-stage', lambda d: d.__setitem__('inn', [s for s in d['inn'] if s['stage'] != '운명']), '운명: fewer')
    mutation('missing-event-band', lambda d: d['dungeon'].pop(), 'missing or duplicate event-band')
    mutation('missing-transition', lambda d: d['transitions'].pop(), 'missing or duplicate boundary')
    mutation('wrong-transition-direction', lambda d: d['transitions'][0].__setitem__('direction', 'down'), 'direction mismatch')
    mutation('wrong-band-mapping', lambda d: d['dungeon_bands'].__setitem__('high', ['유대']), 'grouping mismatch')
    mutation('missing-choice', lambda d: d['inn'][0]['choices'].pop(), 'three choices')
    mutation('empty-response', lambda d: d['inn'][0]['choices'][0].__setitem__('response', []), '1..3 lines')
    mutation('missing-seen', lambda d: d['inn'][0].pop('seen'), 'schema mismatch')
    for value in [4, -4, 1.5, True]:
        mutation('invalid-aff-' + str(value), lambda d, v=value: d['inn'][0]['choices'][0].__setitem__('aff', v), 'aff must be integer')
    mutation('long-dungeon-line', lambda d: d['dungeon'][0]['variants'].__setitem__(0, '가' * 41), 'line exceeds 40')
    mutation('duplicate-line', lambda d: d['dungeon'][0]['variants'].__setitem__(1, d['dungeon'][0]['variants'][0]), 'duplicate displayed')
    mutation('duplicate-sentence', lambda d: d['dungeon'][0]['variants'].__setitem__(1, d['dungeon'][0]['variants'][0] + ' 오늘 봐요.'), 'duplicate complete')
    mutation('unknown-name-inventory', lambda d: d['proper_nouns'].append('카르자'), 'name absent')
    mutation('missing-known-name', lambda d: d.__setitem__('proper_nouns', []), 'known names missing')
    mutation('unreviewed-ending-exception', lambda d: d['speech']['ending_exceptions'].append({'text': '반말이야.', 'reason': '임의 허용'}), 'unreviewed speech')
    mutation('altered-affection-rule', lambda d: d['stage_rule'].__setitem__('soft_cap', 101), 'affection rule mismatch')
    mutation('missing-source', lambda d: d['sources'][0].__setitem__('file', 'missing.md'), 'missing source')
    baseline = run(ROOT / 'project/data/dialogue-r21')
    checks.append({'name': 'real-pilot-passes', 'passed': baseline['error_count'] == 0})
    for cid in IDS:
        d = read_json(ROOT / f'project/data/dialogue-r21/{cid}.json')
        errors, metrics = validate(d, cid, dictionary)
        checks.append({'name': cid + '-declared-register-and-intentional-trailing',
                       'passed': not errors and metrics['ending_deviation_ratio'] == 0})
    result = {'checks': len(checks), 'failures': sum(not c['passed'] for c in checks), 'results': checks}
    write_json(ROOT / 'verification/dialogue-r21/selftest.json', result)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return int(bool(result['failures']))


if __name__ == '__main__':
    raise SystemExit(main())
