"""Emit the selected semantic spot-checks alongside mechanical counts."""
from dialogue_r21_build import ROOT, OUT, IDS, read_json
from dialogue_r21_round5 import at
from dialogue_r21_report5 import md


def main():
    edits=read_json(OUT/'edits5-applied.json')
    decisions={d['id']:d for d in read_json(OUT/'decisions5.json')}
    def kr(key):
        d=decisions[key]
        return (d['character_id'],d['path'])
    def changed_word(word):
        return next((e['character_id'],e['path']) for e in edits if word in e['before'] and word not in e['after'] and not e['path'].endswith('/reason'))
    samples=[
        ('소재 비유', [('bianca','inn/18/choices/0/text'),kr('KR-019')], '보수와 함께 있고 싶은 마음을 각각 직접 말한다. 사야의 뜨개질은 실물 소재로 남기되 뜬 자리라는 추상 결합을 풀었다.'),
        ('원칙 요약', [('felice','inn/2/lines/2'),('gunhild','inn/3/seen')], '수다/보증, 앞장섬/전부 맡음이라는 명제를 확인 책임과 역할 부탁으로 풀었다.'),
        ('감정·뜻 재해설', [kr('KR-207'),kr('KR-209')], '미코의 작은 잔 이유와 토베의 배고프면 먹는다는 반복을 다음 행동으로 잇는다. 도입 3줄과 반응 줄 수를 그대로 지켰다.'),
        ('부정 되받기', [kr('KR-108'),('bargut','inn/20/lines/2')], '티카의 더듬음과 바르굿의 필요한 거리감은 보존하고 같은 뜻을 부정으로 다시 설명하는 문형을 줄였다.'),
        ('먼저', [changed_word('먼저'),('ornel','inn/9/choices/2/text')], '행동 순서가 뜻을 가르지 않는 부사는 줄였다. 실제 구조·전투의 선후관계와 먼저 손대지 말라는 거절은 남겼다.'),
        ('오늘은', [changed_word('오늘은')], '오늘이라는 시간 한정이 없어도 장면이 성립하는 반복부터 덜었다. 오늘/내일 약속 구분은 보존했다.'),
        ('사적 문서어', [kr('KR-010'),kr('KR-110')], '간격 확보는 떨어져 있기로, 이후 대화/문서는 이 뒤 나눌 얘기로 바꿨다. 하오체·하십시오체를 낮추지 않았다.'),
        ('선택지 진단', [kr('KR-211'),kr('KR-213')], '우울·예민이라는 평가를 빼고 거리 침범 또는 서운함을 듣지 않는 발화로 감점 원인을 구체화했다. aff를 바꾸지 않았다.'),
        ('시적 여운·낯선 결합', [kr('KR-009'),kr('KR-201')], '늘이라는 말에 오늘 한 번이 남는다는 추상 결합과 기억하고 나온다는 동사 결합을 장면의 행동으로 고쳤다.'),
        ('표기·조사', [kr('KR-203'),kr('KR-204'),kr('KR-115')], '그만두다, 결론을 내리다, 이름을 걸다의 표기를 대조했다. 같은 오류는 전체 후보 검색에서도 잔존 0이다.'),
        ('같이·함께', [kr('KR-107'),('bianca','inn/18/choices/0/text')], '직접 함께 있자는 제안으로 바꾸면서 이 단어의 합계는 증가했다. 비유·명제의 감소와 낱말 총량 감소는 서로 다른 지표다.'),
    ]
    lines=['# 5차 패턴 표본 대조', '',
        '기계 집계는 patterns5.json의 동일 정규식으로 재현한다. 후보를 모두 오용으로 세지 않는다. 아래는 편집 근거와 장면을 사람이 대조한 대표 표본이다.',
        '문/줄 후보는 낱말 앞 한글 경계를 확인해 질문·때문 같은 부분 문자열을 제외했다. 따라서 작업 중 임시 집계와 최종 표의 분모가 다르다.', '']
    for name,refs,note in samples:
        lines += ['## '+name,'',note,'','| 위치 | 전 | 후 |','|---|---|---|']
        for cid,path in refs:
            before=at(read_json(OUT/f'draft5/{cid}.json'),path)
            after=at(read_json(ROOT/f'project/data/dialogue-r21/{cid}.json'),path)
            lines.append(f'| `{cid}/{path}` | {before} | {after} |')
        lines += ['']
    lines += ['## 남긴 용례를 확인한 근거', '',
        '- 베렌가의 망자 이름책과 이름 낭독, 군힐트의 할렌 가문, 에르데네의 이름은 정본 사연이다. 이름 낱말을 일괄 삭제하지 않았다.',
        '- 소렐의 장부·약값·할인은 거래 장면의 실물과 요구다. 알탄의 영수증 두 장·서명·사본 대조도 실제 거래 내용으로 남겼다.',
        '- 헤드비히의 학술원·선언·실제 서명과 콜레트의 인장·서약은 화법과 인물의 핵심 소재다. 밥을 먹는 일까지 증빙으로 부르는 부분과 구별했다.',
        '- 토베의 입구 의자, 바르굿의 거리·신호, 셀바의 식탁 그릇은 물리적 위치를 말하므로 자리 낱말만으로 오용으로 보지 않았다.',
        '- 적대·불신의 거절과 원치 않는 접촉을 막는 부정형은 필요한 발화다. 실제 오해가 있는 장면은 무조건 긍정문으로 바꾸지 않았다.',
        '- 전이 장면의 관계 통지는 기능상 직접 설명이 남는다. 뜻/마음/기분 검색의 잔존 수를 감정 재해설 오류 수로 주장하지 않는다.', '',
        '## 최종 문맥 보정', '',
        '주 편집자의 중간 9명 대조 5필드와 교차 finalizer의 미코·콜레트 4필드 지적을 적용했다. 아델린 전이 중복과 콜레트 편집용 근거까지 함께 보정했다. 상세 원문과 이유는 tools/dialogue_r21_5_finalizer.json 및 finalizer-corrections5.json에 있다.',
        '검토 범위·한계는 finalizer-notes5.md에 보존한다. 기계 검사는 자연스러움의 독립 승인이나 의미 완전성 보증이 아니다.', '']
    md(OUT/'pattern-audit5.md',lines)


if __name__=='__main__':
    main()
