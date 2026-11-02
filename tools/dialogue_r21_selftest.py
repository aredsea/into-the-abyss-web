"""Adversarial checks: real malformed payloads must fail the dialogue validator."""
from copy import deepcopy
import json
from pathlib import Path
import argparse
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
    mutation('two-line-opening', lambda d: d['inn'][0]['lines'].pop(), '3..5 lines')
    mutation('four-response-lines', lambda d: d['inn'][0]['choices'][0].__setitem__('response', ['네, 들었어요.'] * 4), '1..3 lines')
    mutation('extra-stage-scene', lambda d: d['inn'].append(deepcopy(d['inn'][0])), 'extra scenes')
    mutation('missing-address-terms', lambda d: d['speech'].pop('address_terms'), 'schema mismatch')
    mutation('wrong-address-declaration', lambda d: d['speech']['address_terms'].__setitem__('player_to_companion', '선생님'), 'address declaration mismatch')
    for text in ['테이리스는 편한 데 앉아요.', '테이리스 님, 괜찮아요?', '테이리스 씨 씨 대신 테이리스로 부를게요.']:
        mutation('inconsistent-player-title-' + text, lambda d, t=text: d['inn'][0]['choices'][0].__setitem__('text', t), 'player address inconsistent')
    mutation('undeclared-companion-vocative', lambda d: d['dungeon'][0]['variants'].__setitem__(0, '대장님, 출발할까요?'), 'undeclared companion address')
    mutation('undeclared-player-vocative', lambda d: d['inn'][0]['choices'][0].__setitem__('text', '선생님, 같이 봐요.'), 'undeclared player address')
    mutation('undeclared-role-title', lambda d: d['inn'][0]['choices'][0].__setitem__('text', '사제님, 같이 봐요.'), 'undeclared player address')
    mutation('undeclared-role-title-with-particle', lambda d: d['inn'][0]['choices'][0].__setitem__('text', '사제님이 먼저 골라 주세요.'), 'undeclared player address')
    mutation('vowel-title-wrong-particle', lambda d: d['inn'][0]['choices'][0].__setitem__('text', '테이리스 씨이 먼저 골라 주세요.'), 'address particle mismatch')
    baseline = run(ROOT / 'project/data/dialogue-r21')
    checks.append({'name': 'real-second-pass-corpus-passes', 'passed': baseline['error_count'] == 0})
    for cid in IDS:
        d = read_json(ROOT / f'project/data/dialogue-r21/{cid}.json')
        errors, metrics = validate(d, cid, dictionary)
        checks.append({'name': cid + '-declared-register-and-intentional-trailing',
                       'passed': not errors and metrics['ending_deviation_ratio'] == 0})
    for cid, wrong in [('hildegard', '같이 가요.'), ('haldric', '지금 갑니다.'), ('erdene', '지금 갑니다.'),
                       ('gerda', '지금 갑니다.'), ('urda', '혼자 갈 거야.'), ('saya', '혼자 가겠소.')]:
        d = read_json(ROOT / f'project/data/dialogue-r21/{cid}.json')
        d['inn'][0]['lines'][0] = wrong
        errors, _ = validate(d, cid, dictionary)
        checks.append({'name': cid + '-reject-wrong-register', 'passed': any('speech endings violated' in e['message'] for e in errors)})
    from dialogue_r21_round2 import player_title
    for cid, before, after in [('hildegard','힐데가가 고르면 돼요.','힐데가 경이 고르면 돼요.'),
                               ('marceline','마르셀린이 고르면 돼요.','마르셀린 씨가 고르면 돼요.')]:
        checks.append({'name':cid+'-title-particle-conversion','passed':player_title(before,cid)==after})
    d = read_json(ROOT/'project/data/dialogue-r21/hildegard.json')
    d['inn'][0]['choices'][0]['text'] = '힐데가 경가 먼저 정해 주세요.'
    errors, _ = validate(d, 'hildegard', dictionary)
    checks.append({'name':'consonant-title-wrong-particle','passed':any('address particle mismatch' in e['message'] for e in errors)})
    for cid in ['gunhild', 'bargut']:
        for line in ['그 말은 내 뜻이 아니다.', '여기서 다시 만나는군.']:
            d = read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
            d['inn'][0]['lines'][0] = line
            errors, _ = validate(d, cid, dictionary)
            checks.append({'name':cid+'-accept-shared-ending-'+line, 'passed':not errors})
        for line in ['지금 함께 가겠습니다.', '같이 가겠소.']:
            d = read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
            d['inn'][0]['lines'][0] = line
            errors, _ = validate(d, cid, dictionary)
            checks.append({'name':cid+'-reject-formal-or-hao-'+line,
                           'passed':any('speech endings violated' in e['message'] for e in errors)})
    for cid in ['hedwig', 'altan']:
        for line in ['이 말이 정확히 들립니까?', '그 비용도 직접 냅니까?']:
            d = read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
            d['inn'][0]['lines'][0] = line
            errors, _ = validate(d, cid, dictionary)
            checks.append({'name':cid+'-accept-bieup-formal-question-'+line, 'passed':not errors})
        d = read_json(ROOT/f'project/data/dialogue-r21/{cid}.json')
        d['inn'][0]['lines'][0] = '그것은 내 뜻이 아니다.'
        errors, _ = validate(d, cid, dictionary)
        checks.append({'name':cid+'-reject-anida-as-formal',
                       'passed':any('speech endings violated' in e['message'] for e in errors)})
    result = {'checks': len(checks), 'failures': sum(not c['passed'] for c in checks), 'results': checks}
    parser = argparse.ArgumentParser()
    parser.add_argument('--report', type=Path, default=ROOT / 'verification/dialogue-r21/selftest.json')
    args = parser.parse_args()
    write_json(args.report, result)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return int(bool(result['failures']))


if __name__ == '__main__':
    raise SystemExit(main())
