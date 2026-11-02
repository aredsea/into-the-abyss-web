"""Second-pass authored corpus compiler. Round-one JSON remains immutable evidence."""
from copy import deepcopy
import hashlib
import json
import re
from dialogue_r21_build import (ROOT, CANON, OUT, IDS, STAGES, EVENTS, REGISTERS,
    ENDING_FRAGMENTS, READ_SOURCES, source_span, section_rows, display_fields,
    read_json, write_json, replace_at, lexicon, mentioned_names)

TITLES = {'hildegard': '힐데가 경', 'marceline': '마르셀린 씨', 'teiris': '테이리스 씨',
          'naran': '나란 씨', 'haldric': '할드리크 부대장', 'erdene': '에르데네 씨',
          'bianca': '비앙카 씨', 'saya': '사야 씨', 'gerda': '게르다 씨',
          'judith': '유디트 씨', 'levia': '레비아 씨', 'urda': '우르다 사제님'}
TITLES.update({'lynette':'리네트 씨', 'felice':'펠리스 씨', 'sorel':'소렐 씨', 'tika':'티카 씨',
               'hedwig':'헤드비히 씨', 'berenga':'베렌가 씨', 'gunhild':'군힐트 씨', 'bargut':'바르굿 씨', 'altan':'알탄 씨'})
TITLES.update({'selva':'셀바 씨','ornel':'오르넬 씨','zahar':'자하르 씨','jorund':'요르드 씨',
               'lavinia':'라비니아 씨','tove':'토베 씨','miko':'미코 씨','adeline':'아델린 씨','colette':'콜레트 씨'})
VOICE = {
 'hildegard': '반듯한 하십시오체. 명령을 입에 올렸다가 부탁으로 고친다. 가까워지면 맡기고 쉬는 법을 배운다.',
 'marceline': '낮은 존댓말. 남부터 챙기다가 사적인 안부에도 소설에서 읽은 절차를 찾는다. 교리서라는 변명은 가까워질수록 서툴러진다.',
 'teiris': '정중한 해요체. 노트와 질문, 조금 늦은 유행어. 마음을 짚을 때는 조용하고 짧아진다.',
 'naran': '빠른 해요체. 질문으로 값을 떠보고 농담으로 뒤집는다. 가까워지면 무료라는 말을 붙이기조차 잊는다.',
 'haldric': '건조한 하오체. 조항을 먼저 찾고 죽은 것이 무서우면 읽는 속도가 빨라진다. 유대부터 두려움을 직접 말한다.',
 'erdene': '큰 목소리의 해체와 해요체. 앞장서려다가 부담 큰 부탁 앞에서 숨을 고른다. 친해지면 멈춰 달라는 말도 듣는다.',
 'bianca': '우아한 해요체. 칭찬 뒤 질문으로 정보를 얻는다. 지칠수록 부드러워지고 가까워지면 보고하지 않을 말을 스스로 고른다.',
 'saya': '짧은 해요체. 단문을 나눠 말하고 말보다 손이 먼저 간다. 뜨개질과 신세 이야기는 관계가 깊어지며 직접 밝힌다.',
 'gerda': '냉소 섞인 해체와 해요체. 징조 앞에서는 갑자기 진지해진다. 가까워지면 비꼼 대신 부탁을 남긴다.',
 'judith': '자신만만한 해요체. 마법 얘기에서는 질문과 말이 빨라진다. 가까워져도 오만함은 남지만 계획에 사람을 넣는다.',
 'levia': '조심스러운 해요체. 싫은 것을 에둘러 말하다가, 관계가 깊어지며 그만하고 싶다는 뜻부터 전한다.',
 'urda': '느긋한 하오체와 해요체. 국과 농담으로 먼저 자리를 내주고, 가까워지면 설교 대신 흔들린 속내를 말한다.'}


def speech(cid):
    name = IDS[cid]
    cast = source_span('design/PERSONALITY-CAST.md', '### ' + name + ' (', True)
    comp = source_span('design/COMPANIONS.md', '. ' + name + ':', True)
    text = (CANON / cast['file']).read_text(encoding='utf-8').splitlines()[cast['line_start']:cast['line_end']]
    return {'register': VOICE[cid], 'address': '동료는 유저 직접 호칭을 생략한다. 유저는 동료를 ' + TITLES[cid] + '(으)로 부른다. 이번 콘텐츠의 편집 규약이며 정본 고정 호칭은 없음.',
            'address_terms': {'companion_to_player': [], 'player_to_companion': TITLES[cid]},
            'stage_relaxation': next(s.split(': ', 1)[1] for s in text if s.startswith('- 낯섦 →')),
            'extension': '적대·불신·맹세·운명의 상세 화법은 정본 없음. 기존 화계 안에서 경계와 자발적인 부탁의 정도를 연장한다.',
            'source_quote': next(s.removeprefix('- 말투(발현): ') for s in text if s.startswith('- 말투(발현):')),
            'sources': [cast, comp], 'allowed_endings': REGISTERS[cid],
            'ending_exceptions': ENDING_FRAGMENTS.get(cid, [])}


def parse_inn(cid, data):
    counts = {}
    for stage, row in section_rows(ROOT / f'tools/dialogue_r21_2_{cid}.txt'):
        assert len(row) == 6, (cid, stage, row)
        situation, lines, *tail = row
        counts[stage] = counts.get(stage, 0) + 1
        choices = []
        for j, raw in enumerate(tail[:3]):
            text, response, reason = raw.split('~')
            choices.append({'id': f'c{j+1}', 'text': text, 'response': response.split('^'),
                            'aff': [2, 0, -2][j], 'reason': reason})
        shift = (len(data['inn']) + list(IDS).index(cid)) % 3
        choices = choices[shift:] + choices[:shift]
        data['inn'].append({'id': f'{cid}-inn-{STAGES.index(stage):02d}-{counts[stage]:02d}',
                            'stage': stage, 'situation': situation, 'lines': lines.split('~'),
                            'choices': choices, 'seen': tail[3]})


def player_title(text, cid):
    """A new title changes the final consonant and therefore its particles."""
    title = TITLES[cid]
    coda = (ord(title[-1]) - ord('가')) % 28 != 0
    particles = {'이':'이' if coda else '가', '가':'이' if coda else '가',
                 '은':'은' if coda else '는', '는':'은' if coda else '는',
                 '을':'을' if coda else '를', '를':'을' if coda else '를',
                 '과':'과' if coda else '와', '와':'과' if coda else '와'}
    return re.sub(re.escape(IDS[cid]) + r'([이가은는을를과와])?(?=\s|[의에께도만]|$)',
                  lambda m: title + particles.get(m[1], ''), text)


def build():
    dictionary = lexicon()
    base = read_json(OUT / 'round1/hildegard.json')
    edits = []
    for cid in VOICE:
        pilot = cid in ['hildegard', 'marceline', 'teiris']
        data = read_json(OUT / f'round1/{cid}.json') if pilot else deepcopy(base)
        data['character_id'], data['name'] = cid, IDS[cid]
        data['speech'] = speech(cid)
        data['sources'] = data['speech']['sources']
        if pilot:
            # Each row supplies an opening, then replacement positive/negative
            # choices and three scene-specific response continuations.
            rows = list(section_rows(ROOT / f'tools/dialogue_r21_2_{cid}.txt'))
            assert len(rows) == len(data['inn']) == 28
            for i, (_, row) in enumerate(rows):
                assert len(row) == 6, (cid, i, row)
                opening, pos, neutral, neg, pos_tail, neg_tail = row
                s = data['inn'][i]
                old = deepcopy(s)
                s['lines'].insert(0, opening)
                assert 3 <= len(s['lines']) <= 5
                for c in s['choices']:
                    if c['aff'] == 2:
                        c['text'], response = pos.split('~')
                        c['response'] = [response, pos_tail]
                    elif c['aff'] == -2:
                        c['text'], response = neg.split('~')
                        c['response'] = [response, neg_tail]
                        c['reason'] = '악의 없는 제안이나 실무적인 배려가 본인이 지금 바라는 것과 어긋난다. 구체적인 차이는 반응에 담았다.'
                    else:
                        c['response'].append(neutral)
                    c['text'] = player_title(c['text'], cid)
                for key in ['lines', 'choices']:
                    edits.append({'character_id': cid, 'path': f'inn/{i}/{key}', 'before': old[key], 'after': deepcopy(s[key]),
                                  'rule': '5.2·5.4·5.5', 'reason': '상황을 연 뒤 본론으로 잇고, 인물의 습관과 선택의 어긋남을 반응에 드러냄.'})
            # Individually flagged unclear/overlapping expressions.
            corrections = {'오늘도 일이 없어도 곁에 좀 앉아 있겠습니다.': '오늘은 볼일이 없어도 곁에 좀 앉아 있겠습니다.',
                           '그렇게 앉는 연습은 오래 해도 좋겠습니다.': '아무 일도 맡지 않고 쉬는 시간을 더 가져 보고 싶습니다.'}
            for path, text, _ in list(display_fields(data)):
                if text in corrections:
                    replace_at(data, path, corrections[text])
        else:
            data['inn'], data['dungeon'], data['transitions'] = [], [], []
            parse_inn(cid, data)
            negative_tails = [row[0] for who, row in section_rows(ROOT / 'tools/dialogue_r21_2_negative.txt') if who == cid]
            assert len(negative_tails) == 28, cid
            for s, tail in zip(data['inn'], negative_tails):
                c = next(c for c in s['choices'] if c['aff'] == -2)
                if len(c['response']) == 1:
                    c['response'].append(tail)
            for who, row in section_rows(ROOT / 'tools/dialogue_r21_2_dungeon.txt'):
                if who != cid:
                    continue
                event, *groups = row
                assert event in EVENTS and len(groups) == 3
                for band, text in zip(['low', 'middle', 'high'], groups):
                    data['dungeon'].append({'id': f'{cid}-{event}-{band}', 'event': event, 'band': band, 'variants': text.split('~')})
            for who, row in section_rows(ROOT / 'tools/dialogue_r21_2_transitions.txt'):
                if who != cid:
                    continue
                pair, situation, lines = row
                a, b = map(int, pair.split('>'))
                data['transitions'].append({'id': f'{cid}-stage-{a}-{b}', 'from': STAGES[a], 'to': STAGES[b],
                                            'direction': 'up' if b > a else 'down', 'situation': situation, 'lines': lines.split('~')})
        write_json(OUT / 'draft2' / f'{cid}.json', data)
        editfile = ROOT / 'tools/dialogue_r21_2_edits.json'
        for rev in read_json(editfile) if editfile.exists() else []:
            if rev['character_id'] != cid:
                continue
            paths = [p for p, t, _ in display_fields(data) if t == rev['before'] and ('path' not in rev or p == rev['path'])]
            assert len(paths) == 1, (rev, paths)
            replace_at(data, paths[0], rev['after'])
            edits.append({**rev, 'path': paths[0]})
        data['proper_nouns'] = sorted(mentioned_names('\n'.join(t for _, t, _ in display_fields(data)), dictionary))
        write_json(ROOT / f'project/data/dialogue-r21/{cid}.json', data)
    write_json(OUT / 'edits2-applied.json', edits)
    write_json(OUT / 'source-manifest2.json', [{'file': f, 'sha256': hashlib.sha256((CANON / f).read_bytes()).hexdigest()} for f in READ_SOURCES])
    print('round2 characters', len(IDS), 'editorial records', len(edits))


if __name__ == '__main__':
    build()
