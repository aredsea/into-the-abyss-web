"""Compile hand-authored UTF-8 dialogue; no network/model dependency at runtime."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
CANON = Path('C:/Clauede Code/dungeon-bot')
OUT = ROOT / 'verification/dialogue-r21'
STAGES = ['적대', '불신', '낯섦', '신뢰', '유대', '깊은 인연', '맹세', '운명']
EVENTS = dict(zip(['departure', 'floor_entry', 'discovery', 'battle_start', 'victory',
                  'elite_boss_before', 'boss_defeat', 'ally_low_hp', 'ally_down',
                  'self_wounded', 'rest', 'sealed_cache', 'return', 'defeat'],
                 ['원정 출발', '층 진입', '탐색 발견', '전투 시작', '승리', '정예·보스 앞',
                  '보스 격파', '아군 위기', '동료 쓰러짐', '본인 부상', '휴식', '봉인 보관함', '귀환', '패배']))
IDS = {'hildegard': '힐데가', 'marceline': '마르셀린', 'teiris': '테이리스',
       'naran': '나란', 'haldric': '할드리크', 'erdene': '에르데네', 'bianca': '비앙카',
       'saya': '사야', 'gerda': '게르다', 'judith': '유디트', 'levia': '레비아', 'urda': '우르다'}
REGISTERS = {cid: (['하십시오체'] if cid == 'hildegard' else
                  ['하십시오체', '해요체'] if cid == 'marceline' else
                  ['하오체'] if cid == 'haldric' else
                  ['하오체', '해요체'] if cid == 'urda' else
                  ['해체', '해요체'] if cid in ['erdene', 'gerda'] else ['해요체']) for cid in IDS}
ENDING_FRAGMENTS = {
    'hildegard': [{'text': '출발 전에 한 잔씩 마시도록…….', 'reason': '명령조를 내다가 고쳐 말하는 중단. 한국어 지침 5.3 및 인물 정본.'}],
    'marceline': [{'text': '이럴 때는 옆에 앉아도 되는 순서라고…….', 'reason': '책에서 익힌 순서를 말하려다 스스로 멈춤. 한국어 지침 5.3.'},
                  {'text': '말이 너무 셌습니다. 서약에 비춰 보면…….', 'reason': '서약문으로 사과하려다 자기 말로 고침. 한국어 지침 5.3·5.5.'}],
    'teiris': []}
READ_SOURCES = ['docs/KOREAN-WRITING.md', 'design/PERSONALITY-CAST.md', 'design/PERSONALITY.md',
                'design/GAP-MOE.md', 'design/COMPANIONS.md', 'design/NPCS.md', 'design/stats.json',
                'world/wiki/terms.json', 'world/wiki/고립의 해.md', 'world/wiki/사절 논쟁.md',
                'world/wiki/이단 심문소 확대.md', 'world/wiki/인장 서약.md',
                'bot/src/74-affection.lua', 'bot/src/73-inn.lua', 'bot/src/89-memory.lua', 'bot/src/77-explore.lua']


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def section_rows(path):
    section = None
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        if line.startswith('@'):
            section = line[1:]
        else:
            yield section, line.split('|')


def source_span(file, needle, end_section=False):
    lines = (CANON / file).read_text(encoding='utf-8').splitlines()
    start = next(i for i, s in enumerate(lines) if needle in s)
    end = start
    if end_section:
        end = next((i - 1 for i in range(start + 1, len(lines)) if lines[i].startswith('### ')), len(lines) - 1)
    return {'file': file, 'line_start': start + 1, 'line_end': end + 1}


def lexicon():
    stats = read_json(CANON / 'design/stats.json')
    terms = read_json(CANON / 'world/wiki/terms.json')
    result = set(k for k in terms if not k.startswith('_'))
    for c in stats['companions']:
        result.update(c.get(k, '') for k in ['name', 'full_name', 'nation'])
    # These dictionary topics are ordinary nouns or grammatical homographs,
    # rather than proper names; do not identify 주신 in 물어 주신 as a deity.
    result -= {'', '용', '주신', '종족', '엘프', '인간', '수인', '악마', '하프엘프'}
    result.update(Path(f).stem for f in READ_SOURCES if f.startswith('world/wiki/') and f.endswith('.md'))
    return sorted(result, key=lambda s: (-len(s), s))


def mentioned_names(text, dictionary):
    particles = r'(?:이|가|은|는|을|를|의|에|에서|에게|도|와|과|만|부터|까지|라고|이라는|에는|에서는|와는|에도|로|으로|보다)?'
    return {n for n in dictionary if re.search(r'(?<![가-힣])' + re.escape(n) + particles + r'(?![가-힣])', text)}


def display_fields(data):
    """Yield (path, text, companion speech?) for every in-game textual field."""
    for i, s in enumerate(data['inn']):
        base = f'inn/{i}'
        yield base + '/situation', s['situation'], False
        for j, line in enumerate(s['lines']):
            yield base + f'/lines/{j}', line, True
        for j, c in enumerate(s['choices']):
            yield base + f'/choices/{j}/text', c['text'], False
            for k, line in enumerate(c['response']):
                yield base + f'/choices/{j}/response/{k}', line, True
        yield base + '/seen', s['seen'], True
    for i, s in enumerate(data['dungeon']):
        for j, line in enumerate(s['variants']):
            yield f'dungeon/{i}/variants/{j}', line, True
    for i, s in enumerate(data['transitions']):
        yield f'transitions/{i}/situation', s['situation'], False
        for j, line in enumerate(s['lines']):
            yield f'transitions/{i}/lines/{j}', line, True


def replace_at(data, path, value):
    keys = path.split('/')
    node = data
    for k in keys[:-1]:
        node = node[int(k)] if isinstance(node, list) else node[k]
    key = int(keys[-1]) if isinstance(node, list) else keys[-1]
    node[key] = value


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    dictionary = lexicon()
    revisions = read_json(ROOT / 'tools/dialogue_r21_revisions.json') if (ROOT / 'tools/dialogue_r21_revisions.json').exists() else []
    cast_lines = (CANON / 'design/PERSONALITY-CAST.md').read_text(encoding='utf-8').splitlines()
    generated = {}
    applied = []
    for cid, name in IDS.items():
        cast = source_span('design/PERSONALITY-CAST.md', '### ' + name + ' (', True)
        companion = source_span('design/COMPANIONS.md', f'. {name}:', True)
        quote = next(s.removeprefix('- 말투(발현): ') for s in cast_lines[cast['line_start']:cast['line_end']] if s.startswith('- 말투(발현):'))
        progression = next(s.split(': ', 1)[1] for s in cast_lines[cast['line_start']:cast['line_end']] if s.startswith('- 낯섦 →'))
        register = {'hildegard': '반듯한 하십시오체. 명령조가 나오면 스스로 고치며 신뢰부터 부탁을 늘린다.',
                    'marceline': '하십시오체를 중심으로 해요체를 섞는 낮은 존댓말. 가까워져도 존대를 유지한다.',
                    'teiris': '정중한 해요체. 호기심이 동하면 질문이 겹치고 정곡을 짚을 때는 조용해진다.'}[cid]
        data = {'speech': {'register': register, 'address': '호칭은 대체로 생략한다. 정본에 고정된 유저 호칭은 없음.',
                           'stage_relaxation': progression,
                           'extension': '적대·불신과 맹세·운명별 고유 화법은 정본 없음. 기본 존대와 경계·신뢰의 정도만 연장한다.',
                           'source_quote': quote, 'sources': [cast, companion],
                           'allowed_endings': ['하십시오체'] if cid == 'hildegard' else ['하십시오체', '해요체'] if cid == 'marceline' else ['해요체'],
                           'ending_exceptions': ENDING_FRAGMENTS[cid]},
                'schema_version': 1, 'character_id': cid, 'name': name,
                'stage_order': STAGES,
                'dungeon_bands': {'low': STAGES[:3], 'middle': STAGES[3:6], 'high': STAGES[6:]},
                'stage_rule': {'source': 'bot/src/74-affection.lua:3-35',
                               'algorithm': 'a<=-60 / a<=-20 / a<20 / a<50 / a<80 / a<100 / a<150 / 나머지',
                               'minimum': -100, 'maximum': 200, 'soft_cap': 100, 'positive_scale_above_cap': 0.4},
                'integration': {'status': '콘텐츠만 작성, 실행 훅 미연결',
                                'inn_action': 'talk', 'daily_limit_key': 'character_id + talk + day',
                                'aff_semantics': '선택지 aff는 감속 전 원시 정수. 기존 talk +1을 대체하며 중복 가산하지 않는다.',
                                'seen_semantics': '같은 장면 재노출 때 lines 대신 seen을 쓰고 기존 choices를 표시한다. 하루 제한은 유지한다.',
                                'transition_semantics': '인접 경계별 상승·하락 장면. 여러 경계를 넘으면 최종 도착 경계 한 장면만 표시한다.',
                                'dungeon_semantics': '이벤트가 확인된 경우에만 표시. 대상·발견물·부상·휴식 결과를 대사로 확정하지 않는다.',
                                'relationship_scope': '동료로서의 신뢰와 일상. 성적·친밀 장면 제외.'},
                'sources': [cast, companion], 'proper_nouns': [], 'inn': [], 'dungeon': [], 'transitions': []}
        stage_counts = {}
        for stage, row in section_rows(ROOT / f'tools/dialogue_r21_{cid}.txt'):
            assert len(row) == 6, (cid, stage, row)
            situation, lines, *tail = row
            count = stage_counts.get(stage, 0) + 1
            stage_counts[stage] = count
            choices = []
            for j, raw in enumerate(tail[:3]):
                text, response, reason = raw.split('~')
                choices.append({'id': f'c{j+1}', 'text': text, 'response': response.split('^'),
                                'aff': [2, 0, -2][j], 'reason': reason})
            # Rotation prevents the first option from becoming a universal correct answer.
            shift = (len(data['inn']) + list(IDS).index(cid)) % 3
            choices = choices[shift:] + choices[:shift]
            data['inn'].append({'id': f'{cid}-inn-{STAGES.index(stage):02d}-{count:02d}',
                                'stage': stage, 'situation': situation, 'lines': lines.split('~'),
                                'choices': choices, 'seen': tail[3]})
        for who, row in section_rows(ROOT / 'tools/dialogue_r21_dungeon.txt'):
            if who != cid:
                continue
            event, *groups = row
            for band, text in zip(['low', 'middle', 'high'], groups):
                data['dungeon'].append({'id': f'{cid}-{event}-{band}', 'event': event,
                                        'band': band, 'variants': text.split('~')})
        for who, row in section_rows(ROOT / 'tools/dialogue_r21_transitions.txt'):
            if who != cid:
                continue
            pair, situation, lines = row
            before, after = pair.split('>')
            data['transitions'].append({'id': f'{cid}-stage-{STAGES.index(before)}-{STAGES.index(after)}',
                                        'from': before, 'to': after,
                                        'direction': 'up' if STAGES.index(after) > STAGES.index(before) else 'down',
                                        'situation': situation, 'lines': lines.split('~')})
        write_json(OUT / 'draft' / f'{cid}.json', data)
        for rev in [r for r in revisions if r['character_id'] == cid]:
            hits = [p for p, text, _ in display_fields(data) if text == rev['before']]
            assert len(hits) == 1, (rev, hits)
            replace_at(data, hits[0], rev['after'])
            applied.append({**rev, 'path': hits[0]})
        game_text = '\n'.join(s for _, s, _ in display_fields(data))
        data['proper_nouns'] = sorted(mentioned_names(game_text, dictionary))
        write_json(ROOT / f'project/data/dialogue-r21/{cid}.json', data)
        generated[cid] = data
    write_json(OUT / 'edits-applied.json', applied)
    write_json(OUT / 'source-manifest.json', [{'file': f, 'sha256': hashlib.sha256((CANON / f).read_bytes()).hexdigest(),
                                             'lines': len((CANON / f).read_text(encoding='utf-8').splitlines())} for f in READ_SOURCES])
    print(json.dumps({cid: {'inn': len(d['inn']), 'dungeon_variants': sum(len(s['variants']) for s in d['dungeon']),
                            'transitions': len(d['transitions'])} for cid, d in generated.items()}, ensure_ascii=False))


if __name__ == '__main__':
    from dialogue_r21_round2 import build
    build()
