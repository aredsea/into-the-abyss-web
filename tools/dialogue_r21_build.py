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
IDS.update({'lynette':'리네트', 'felice':'펠리스', 'sorel':'소렐', 'tika':'티카',
            'hedwig':'헤드비히', 'berenga':'베렌가', 'gunhild':'군힐트', 'bargut':'바르굿', 'altan':'알탄'})
REGISTERS = {cid: (['하십시오체'] if cid == 'hildegard' else
                  ['하십시오체', '해요체'] if cid == 'marceline' else
                  ['하오체'] if cid == 'haldric' else
                  ['하오체', '해요체'] if cid == 'urda' else
                  ['해체', '해요체'] if cid in ['erdene', 'gerda'] else ['해요체']) for cid in IDS}
REGISTERS.update({cid:['하십시오체'] for cid in ['hedwig','altan']})
REGISTERS.update({cid:['해체'] for cid in ['gunhild','bargut']})
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
    from dialogue_r21_round3 import build
    build()


if __name__ == '__main__':
    main()
