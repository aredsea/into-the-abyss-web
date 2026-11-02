"""Offline structural and editorial lint for the r21 pilot. Exit 1 on errors.

Proper-name checking validates the explicit reviewed inventory against canonical
terms/stats, finds omitted known names, and flags naming-pattern candidates.
It is NOT a general Korean named-entity recognizer. See report limitations.
"""
from collections import Counter, defaultdict
from pathlib import Path
import argparse
import hashlib
import itertools
import json
import re
import unicodedata

from dialogue_r21_build import ROOT, CANON, IDS, STAGES, EVENTS, ENDING_FRAGMENTS, display_fields, lexicon, mentioned_names

ROOT_KEYS = {'speech', 'schema_version', 'character_id', 'name', 'stage_order', 'dungeon_bands', 'stage_rule',
             'integration', 'sources', 'proper_nouns', 'inn', 'dungeon', 'transitions'}
MBTI = {''.join(v) for v in itertools.product('IE', 'NS', 'TF', 'JP')}
ALIGNMENTS = ['질서 선', '질서 중립', '질서 악', '중립 선', '중립', '중립 악', '혼돈 선', '혼돈 중립', '혼돈 악']
FORMAL = re.compile(r'(?:니다|니까|시오|십시오|시다)$')
POLITE = re.compile(r'(?:요|죠)$')
EMOJI = re.compile('[\U0001F000-\U0001FAFF\u2600-\u27BF\uFE0F\u200D\u20E3]')


def normalized(s):
    s = unicodedata.normalize('NFC', s)
    return re.sub(r'[\W_]+', '', s)


def sentences(line):
    return [s.strip(' .!?…“”‘’\"\'') for s in re.split(r'(?<=[.!?])\s+', line) if s.strip(' .!?…')]


def validate(data, expected_id=None, dictionary=None):
    """No I/O, so mutation checks can exercise every rule without editing data."""
    errors = []
    metrics = {'inn_scenes': 0, 'choices': 0, 'dungeon_variants': 0, 'transition_scenes': 0,
               'missing_stages': 0, 'missing_events_bands': 0, 'missing_transitions': 0,
               'display_lines': 0, 'companion_lines': 0, 'max_line_chars': 0,
               'max_dungeon_chars': 0, 'ending_sentences': 0, 'ending_deviations': [],
               'proper_noun_candidates': [], 'intentional_trailing_lines': []}
    dictionary = set(dictionary if dictionary is not None else lexicon())

    def require(ok, path, message):
        if not ok:
            errors.append({'path': path, 'message': message})
        return bool(ok)

    def obj(node, keys, path):
        return require(isinstance(node, dict) and set(node) == set(keys), path, 'object keys/schema mismatch')

    def string(value, path):
        return require(type(value) is str and bool(value.strip()) and '\n' not in value, path, 'expected nonempty single line')

    def lines(value, lo, hi, path):
        if not require(isinstance(value, list) and lo <= len(value) <= hi, path, f'expected {lo}..{hi} lines'):
            return False
        return all(string(v, f'{path}/{i}') for i, v in enumerate(value))

    if not obj(data, ROOT_KEYS, '/'):
        return errors, metrics
    cid = data['character_id']
    require(cid in IDS and (expected_id is None or cid == expected_id), '/character_id', 'wrong character id')
    require(data['schema_version'] == 1 and type(data['schema_version']) is int, '/schema_version', 'expected version 1')
    require(data['name'] == IDS.get(cid), '/name', 'canonical character name mismatch')
    require(data['stage_order'] == STAGES, '/stage_order', 'stage order mismatch')
    require(data['dungeon_bands'] == {'low': STAGES[:3], 'middle': STAGES[3:6], 'high': STAGES[6:]}, '/dungeon_bands', 'dungeon stage grouping mismatch')
    require(data['stage_rule'] == {
        'source': 'bot/src/74-affection.lua:3-35',
        'algorithm': 'a<=-60 / a<=-20 / a<20 / a<50 / a<80 / a<100 / a<150 / 나머지',
        'minimum': -100, 'maximum': 200, 'soft_cap': 100, 'positive_scale_above_cap': 0.4},
        '/stage_rule', 'canonical affection rule mismatch')
    speech_keys = {'register', 'address', 'stage_relaxation', 'extension', 'source_quote', 'sources', 'allowed_endings', 'ending_exceptions'}
    if obj(data['speech'], speech_keys, '/speech'):
        for k in ['register', 'address', 'stage_relaxation', 'extension', 'source_quote']:
            string(data['speech'][k], '/speech/' + k)
        expected = ['하십시오체'] if cid == 'hildegard' else ['하십시오체', '해요체'] if cid == 'marceline' else ['해요체']
        require(data['speech']['allowed_endings'] == expected, '/speech/allowed_endings', 'register declaration mismatch')
        require(data['speech']['ending_exceptions'] == ENDING_FRAGMENTS.get(cid, []), '/speech/ending_exceptions', 'unreviewed speech ending exception')
    integration_keys = {'status', 'inn_action', 'daily_limit_key', 'aff_semantics', 'seen_semantics',
                        'transition_semantics', 'dungeon_semantics', 'relationship_scope'}
    if obj(data['integration'], integration_keys, '/integration'):
        for k, v in data['integration'].items():
            string(v, '/integration/' + k)
        require(data['integration']['inn_action'] == 'talk', '/integration/inn_action', 'only talk authored')
    for key in ['sources', 'proper_nouns', 'inn', 'dungeon', 'transitions']:
        require(isinstance(data[key], list), '/' + key, 'expected list')
    if any(not isinstance(data[k], list) for k in ['sources', 'proper_nouns', 'inn', 'dungeon', 'transitions']):
        return errors, metrics
    for i, src in enumerate(data['sources']):
        if obj(src, {'file', 'line_start', 'line_end'}, f'/sources/{i}'):
            require(type(src['file']) is str and (CANON / src['file']).is_file(), f'/sources/{i}/file', 'missing source')
            require(type(src['line_start']) is int and type(src['line_end']) is int
                    and 0 < src['line_start'] <= src['line_end'], f'/sources/{i}', 'invalid line range')
    ids = set()
    structurally_safe = True
    stages = Counter()
    for i, scene in enumerate(data['inn']):
        path = f'inn/{i}'
        if not obj(scene, {'id', 'stage', 'situation', 'lines', 'choices', 'seen'}, path):
            structurally_safe = False
            continue
        string(scene['id'], path + '/id')
        require(scene['id'] not in ids, path + '/id', 'duplicate scene id')
        ids.add(scene['id'])
        require(scene['stage'] in STAGES, path + '/stage', 'unknown stage')
        stages[scene['stage']] += 1
        structurally_safe &= string(scene['situation'], path + '/situation')
        structurally_safe &= lines(scene['lines'], 2, 5, path + '/lines')
        structurally_safe &= string(scene['seen'], path + '/seen')
        if not require(isinstance(scene['choices'], list) and len(scene['choices']) == 3, path + '/choices', 'exactly three choices required'):
            structurally_safe = False
            continue
        affs = []
        choice_ids = set()
        for j, c in enumerate(scene['choices']):
            cp = f'{path}/choices/{j}'
            if not obj(c, {'id', 'text', 'response', 'aff', 'reason'}, cp):
                structurally_safe = False
                continue
            string(c['id'], cp + '/id')
            require(c['id'] not in choice_ids, cp + '/id', 'duplicate choice id')
            choice_ids.add(c['id'])
            structurally_safe &= string(c['text'], cp + '/text')
            structurally_safe &= lines(c['response'], 1, 3, cp + '/response')
            string(c['reason'], cp + '/reason')
            require(type(c['aff']) is int and -3 <= c['aff'] <= 3, cp + '/aff', 'aff must be integer -3..3')
            affs.append(c['aff'])
            metrics['choices'] += 1
        require(any(type(x) is int and x > 0 for x in affs) and 0 in affs
                and any(type(x) is int and x < 0 for x in affs), path, 'positive/neutral/negative choice required')
    metrics['inn_scenes'] = len(data['inn'])
    metrics['stage_counts'] = dict(stages)
    for stage in STAGES:
        need = 2 if stage in STAGES[:2] else 4
        if not require(stages[stage] >= need, '/inn', f'{stage}: fewer than {need} scenes'):
            metrics['missing_stages'] += 1
    coverage = Counter()
    for i, scene in enumerate(data['dungeon']):
        path = f'dungeon/{i}'
        if not obj(scene, {'id', 'event', 'band', 'variants'}, path):
            structurally_safe = False
            continue
        require(scene['id'] not in ids, path + '/id', 'duplicate scene id')
        ids.add(scene['id'])
        require(scene['event'] in EVENTS, path + '/event', 'unknown event')
        require(scene['band'] in ['low', 'middle', 'high'], path + '/band', 'unknown band')
        coverage[(scene['event'], scene['band'])] += 1
        structurally_safe &= lines(scene['variants'], 2, 3, path + '/variants')
        if isinstance(scene['variants'], list):
            metrics['dungeon_variants'] += len(scene['variants'])
    for event, band in itertools.product(EVENTS, ['low', 'middle', 'high']):
        if not require(coverage[(event, band)] == 1, '/dungeon', f'{event}/{band}: missing or duplicate event-band'):
            metrics['missing_events_bands'] += 1
    transitions = Counter()
    for i, scene in enumerate(data['transitions']):
        path = f'transitions/{i}'
        if not obj(scene, {'id', 'from', 'to', 'direction', 'situation', 'lines'}, path):
            structurally_safe = False
            continue
        require(scene['id'] not in ids, path + '/id', 'duplicate scene id')
        ids.add(scene['id'])
        pair = (scene['from'], scene['to'])
        transitions[pair] += 1
        valid_pair = all(s in STAGES for s in pair) and abs(STAGES.index(pair[0]) - STAGES.index(pair[1])) == 1
        require(valid_pair, path, 'transition must cross one adjacent boundary')
        if valid_pair:
            require(scene['direction'] == ('up' if STAGES.index(pair[1]) > STAGES.index(pair[0]) else 'down'), path, 'direction mismatch')
        structurally_safe &= string(scene['situation'], path + '/situation')
        structurally_safe &= lines(scene['lines'], 1, 5, path + '/lines')
    for a, b in zip(STAGES, STAGES[1:]):
        for pair in [(a, b), (b, a)]:
            if not require(transitions[pair] == 1, '/transitions', f'{pair}: missing or duplicate boundary'):
                metrics['missing_transitions'] += 1
    metrics['transition_scenes'] = len(data['transitions'])
    if not structurally_safe:
        return errors, metrics
    seen_lines = defaultdict(list)
    sentence_locations = defaultdict(list)
    mentioned = set()
    for path, text, companion in display_fields(data):
        metrics['display_lines'] += 1
        metrics['companion_lines'] += int(companion)
        metrics['max_line_chars'] = max(metrics['max_line_chars'], len(text))
        limit = 40 if path.startswith('dungeon/') else 64
        if path.startswith('dungeon/'):
            metrics['max_dungeon_chars'] = max(metrics['max_dungeon_chars'], len(text))
        require(len(text) <= limit, path, f'line exceeds {limit} characters ({len(text)})')
        require(text == text.strip() and '  ' not in text, path, 'stray whitespace')
        require('그녀' not in text, path, 'forbidden translated pronoun')
        require(not re.search(r'[A-Za-z]+', text), path, 'English word or internal temperament code')
        require(not any(re.search(r'(?<![A-Za-z])' + code + r'(?![A-Za-z])', text, re.I) for code in MBTI), path, 'temperament code')
        require(not any(re.search(r'(?<![가-힣])' + re.escape(a) + r'(?![가-힣])', text) for a in ALIGNMENTS), path, 'alignment label')
        require(not EMOJI.search(text), path, 'emoji')
        seen_lines[normalized(text)].append(path)
        # Count repeats of complete sentences; fragments and lone discourse markers
        # are not autonomous sentences, but whole-line equality is still checked.
        is_trailing = text in {e['text'] for e in ENDING_FRAGMENTS.get(cid, [])}
        if is_trailing:
            metrics['intentional_trailing_lines'].append(path)
        for s in sentences(text):
            if len(normalized(s)) >= 4:
                sentence_locations[normalized(s)].append(path)
            if companion:
                if is_trailing and s == sentences(text)[-1]:
                    continue
                metrics['ending_sentences'] += 1
                okay = bool(FORMAL.search(s)) if cid == 'hildegard' else bool(POLITE.search(s)) if cid == 'teiris' else bool(FORMAL.search(s) or POLITE.search(s))
                if not okay:
                    metrics['ending_deviations'].append({'path': path, 'sentence': s})
        mentioned.update(mentioned_names(text, dictionary))
        for candidate in re.findall(r'([가-힣]{2,12})(?:에서 태어|에서 왔|라는 도시|라는 마을|이라는 가문)', text):
            if candidate not in dictionary:
                metrics['proper_noun_candidates'].append({'path': path, 'candidate': candidate})
    metrics['duplicate_lines'] = [{'locations': ps} for ps in seen_lines.values() if len(ps) > 1]
    metrics['duplicate_sentences'] = [{'sentence': s, 'locations': ps} for s, ps in sentence_locations.items() if len(ps) > 1]
    require(not metrics['duplicate_lines'], '/', 'duplicate displayed lines')
    require(not metrics['duplicate_sentences'], '/', 'duplicate complete sentences')
    metrics['ending_deviation_ratio'] = round(len(metrics['ending_deviations']) / max(1, metrics['ending_sentences']), 6)
    require(not metrics['ending_deviations'], '/speech', 'declared speech endings violated; review required')
    require(all(type(n) is str and n in dictionary for n in data['proper_nouns']), '/proper_nouns', 'name absent from canonical terms/stats')
    require(len(data['proper_nouns']) == len(set(data['proper_nouns'])), '/proper_nouns', 'duplicate inventory name')
    require(set(data['proper_nouns']) == mentioned, '/proper_nouns', 'known names missing from inventory, or unused inventory entry')
    require(not metrics['proper_noun_candidates'], '/proper_nouns', 'unrecognized naming-pattern candidate')
    metrics['proper_nouns'] = sorted(mentioned)
    return errors, metrics


def run(data_dir):
    results = {}
    errors = []
    dictionary = lexicon()
    files = sorted(data_dir.glob('*.json'))
    if {p.stem for p in files} != set(IDS):
        errors.append({'path': str(data_dir), 'message': 'expected exactly three pilot files'})
    cross_lines = defaultdict(list)
    cross_sentences = defaultdict(list)
    game_people = {p['id']: p for p in json.loads((ROOT / 'project/data/world.json').read_text(encoding='utf-8'))['companions']}
    canon_people = {p['id']: p for p in json.loads((CANON / 'design/stats.json').read_text(encoding='utf-8'))['companions']}
    name_differences = []
    for path in files:
        try:
            data = json.loads(path.read_text(encoding='utf-8'))
            local_errors, metrics = validate(data, path.stem, dictionary)
        except (ValueError, TypeError, KeyError, IndexError) as e:
            local_errors, metrics = [{'path': '/', 'message': 'invalid schema: ' + str(e)}], {}
        errors += [{'file': path.name, **e} for e in local_errors]
        results[path.stem] = metrics
        if not local_errors:
            for location, text, _ in display_fields(data):
                cross_lines[normalized(text)].append(path.stem + '/' + location)
                for s in sentences(text):
                    if len(normalized(s)) >= 4:
                        cross_sentences[normalized(s)].append(path.stem + '/' + location)
        if path.stem in IDS:
            if path.stem not in game_people or path.stem not in canon_people:
                errors.append({'file': path.name, 'message': 'id not present in both canonical and game companion data'})
            elif game_people[path.stem]['name'] != canon_people[path.stem]['name']:
                name_differences.append({'id': path.stem, 'game': game_people[path.stem]['name'], 'canon': canon_people[path.stem]['name']})
    global_dups = [{'sentence': s, 'locations': locs} for s, locs in cross_sentences.items()
                   if len({p.split('/')[0] for p in locs}) > 1]
    if global_dups:
        errors.append({'path': '/', 'message': 'sentences repeated across characters'})
    terms_stats = set(json.loads((CANON / 'world/wiki/terms.json').read_text(encoding='utf-8')))
    for p in canon_people.values():
        terms_stats.update(p.get(k, '') for k in ['name', 'full_name', 'nation'])
    supplemental_names = sorted({n for r in results.values() for n in r.get('proper_nouns', []) if n not in terms_stats})
    return {'errors': errors, 'error_count': len(errors), 'characters': results,
            'cross_character_duplicates': global_dups, 'game_canon_name_differences': name_differences,
            'terms_stats_absent_but_canonical_wiki_present': supplemental_names,
            'input_sha256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
            'limits': {'dungeon_chars': 40, 'other_line_chars': 64},
            'limitations': ['고유명사 검사는 검수한 명시 목록·정본 사전·명명 문형 후보 검사다. 임의의 한국어 신조 고유명사를 모두 찾지는 못한다.',
                            '화계 검사는 문장 끝 어미에 대한 보조 검사다. 발화 의도·위계·자연스러움은 편집 검수와 표본 판정이 필요하다.',
                            '40자 제한은 글자 수 검사다. 이번 작업에는 대사 UI 연결이 없어 실제 360 화면 줄바꿈은 확인하지 않았다.']}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--data-dir', type=Path, default=ROOT / 'project/data/dialogue-r21')
    parser.add_argument('--report', type=Path, default=ROOT / 'verification/dialogue-r21/check.json')
    args = parser.parse_args()
    report = run(args.data_dir)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return int(bool(report['errors']))


if __name__ == '__main__':
    raise SystemExit(main())
