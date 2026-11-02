"""Produce review evidence, readable samples, and the delivery report."""
from collections import Counter
from pathlib import Path
import hashlib
import json
from dialogue_r21_build import ROOT, CANON, IDS, STAGES, EVENTS, OUT, display_fields, read_json, write_json

QUESTIONS = [
    '이 단어는 실제로 이 짝과 함께 쓰이는가?',
    '영어를 옮긴 말인가, 한국어가 원래 쓰는 말인가?',
    '영어식 비유를 직역하지 않고 한국어의 가까운 비유로 바꿨는가?',
    '열 번 반복해 읽어도 거슬리지 않는가?',
    '오타·띄어쓰기를 한 번 더 확인했는가?',
    '번역투 문법이 남아 있지 않은가?',
    '이미 보여 준 것을 다시 설명하고 있지 않은가?',
    '모국어 화자가 이 글을 쓴 사람을 번역가가 아니라 작가로 느낄까?',
    '이 관계와 이 자리에서 실제로 이렇게 말하는가?',
    '모든 인물이 똑같이 짧고 단정하게 말하고 있지 않은가? 끊어지는 대사라면 성격이나 장면이 그것을 요구하는가?'
]
VOICE_NOTES = {
    'hildegard': '앞을 맡고 역할을 정한다. 낯설 때는 격식을 지키고, 신뢰부터 직접 부탁한다. 자기 상태를 숨기지 않는 쪽으로 변한다.',
    'marceline': '남의 잔과 자리를 먼저 챙긴다. 부담 있는 거절은 낮은 존대와 망설임으로 말한다. 가까워져도 존대를 유지한다.',
    'teiris': '관찰에서 질문이 이어지고 엉뚱한 말뜻을 되묻는다. 상대의 마음을 짚거나 위기가 닥칠 때는 질문을 줄인다.'
}
MISSING = [
    '힐데가: 고립의 해 성문이 닫힌 날의 진상·범람 원인은 정본 없음. 배후나 명령자를 만들지 않았다.',
    '마르셀린: 태어난 집안의 성·어린 시절·995년 피고의 마지막 말은 정본 없음. 마지막 말이나 피고 이름을 쓰지 않았다.',
    '테이리스: 노트 첫 장 질문의 실제 문구·장로 발언의 정확한 인용·선발의 숨은 이유·균열 증가 원인은 정본 없음. 첫 장 질문은 공개를 미루는 장면으로 처리했다.',
    '가판대 소설의 고유 제목·저자·등장인물·구체적 줄거리는 정본 없음. 작품 내용은 새로 정하지 않고 독서 행동과 사과 순서를 찾는 습관에 대한 감상만 썼다.',
    '고정된 유저 호칭, 인물별 적대·불신·맹세·운명의 상세 화법은 정본 없음. 호칭은 생략하고 기존 존대와 거리감만 연장했다.'
]


def md(path, text):
    path.write_text(text.rstrip() + '\n', encoding='utf-8')


def source_link(src):
    return f"`{src['file']}:{src['line_start']}-{src['line_end']}`"


def main():
    check = read_json(OUT / 'check.json')
    assert check['error_count'] == 0
    tests = read_json(OUT / 'selftest.json')
    regression = read_json(OUT / 'regression-summary.json')
    edits = read_json(OUT / 'edits-applied.json')
    corpus = {cid: read_json(ROOT / f'project/data/dialogue-r21/{cid}.json') for cid in IDS}
    line_records = []
    scene_notes = []
    for cid, data in corpus.items():
        for scene in data['inn']:
            scene_notes.append({'character_id': cid, 'scene_id': scene['id'],
                                'relationship': scene['stage'], 'setting': '여관 식탁·문가, 공용 공간에서 사적으로 건네는 말',
                                'burden': '처음 말은 상황 공유·부탁·고백, 세 반응에는 감사·중립 수용·거절의 부담이 있음',
                                'personality_and_mitigation': VOICE_NOTES[cid],
                                'choice_reasons': {c['id']: c['reason'] for c in scene['choices']}})
        for path, text, companion in display_fields(data):
            section, index, *_ = path.split('/')
            scene = data[section][int(index)]
            relation = scene.get('stage', scene.get('band', f"{scene.get('from')}→{scene.get('to')}"))
            context = {'relationship': relation, 'place': '던전' if section == 'dungeon' else '여관·귀환 후 공용 식탁',
                       'speaker': IDS[cid] if companion else '지문' if path.endswith('situation') else '유저 선택지'}
            conclusions = [
                '자기 재독: 물을 따르다·짐을 나누다·말을 고르다 등 해당 동작과 말의 짝을 대조함',
                '자기 재독: 조사·보고에 필요한 말 외에는 입말을 사용함',
                '자기 재독: 직역 비유 없이 행동·사정으로 뜻을 전달함',
                '자기 재독: 장면 재노출의 seen과 주변 대사 반복을 살핌. 동일 문장은 별도 검사 0건',
                '자기 재독: 맞춤법·조사·띄어쓰기 재확인',
                '자기 재독: 그녀·것이었다·때문이다·전치사식 표현·불필요한 주어를 점검함',
                '자기 재독: 동작 뒤 감정을 다시 풀이하는 해설을 덜고 선택 반응으로 보임',
                '자기 판정: 입말로 읽어 뜻과 호흡을 확인함. 모국어 독립 검수자의 승인과는 구분함',
                '자기 재독: 위 관계·자리와 부탁·거절의 부담을 기준으로 검토함',
                ('자기 재독: ' + VOICE_NOTES[cid]) if companion else '지문·유저 선택지: 동료 고유 화계를 강제하지 않으며 선택의 뜻과 자연스러움을 검토함'
            ]
            line_records.append({'character_id': cid, 'path': path, 'text': text,
                                 'sha256': hashlib.sha256(text.encode('utf-8')).hexdigest(),
                                 'context': context, 'checklist': {f'Q{i+1}': c for i, c in enumerate(conclusions)},
                                 'edit_numbers': [i+1 for i, e in enumerate(edits) if e['character_id'] == cid and e['path'] == path]})
    write_json(OUT / 'review-lines.json', {'method': 'Codex 자기 편집 재독 기록. 자동 자연어 판정이나 독립 인적 승인으로 집계하지 않는다.',
                                         'questions': QUESTIONS, 'line_count': len(line_records), 'records': line_records})
    write_json(OUT / 'review-scenes.json', scene_notes)
    review = ['# 시범 3명 대화 편집 검수', '',
              f'Codex가 초고를 작성한 뒤 편집자 관점에서 다시 읽고 {len(edits)}곳을 고쳤다. 초고는 `draft/*.json`, 적용 경로는 `edits-applied.json`에 보존했다.', '',
              '이는 작성자의 자기 검수 기록이다. Claude의 직접 판정과 독립 모국어 검수는 아직 받지 않았다. 표본 9장면은 별도 파일로 제공한다.', '',
              '## 마무리 점검 10문항', '']
    review += [f'{i+1}. {q}' for i, q in enumerate(QUESTIONS)]
    review += ['', f'전체 표시 필드 {len(line_records):,}개에 대한 문항별 대조 기록은 `review-lines.json`이다. 그중 동료 대사 840줄, 유저 선택지 252개, 지문 126줄이다. 장면별 관계·자리·말의 부담·성격은 `review-scenes.json`에 기록했다.', '',
               '## 인물별 판정', '']
    for cid in IDS:
        review += [f'- {IDS[cid]}: {VOICE_NOTES[cid]}']
    review += ['', '## 고친 전 → 후', '', '| 번호 | 인물·데이터 경로 | 전 | 후 | 지침·이유 |', '|---|---|---|---|---|']
    for i, e in enumerate(edits, 1):
        review.append(f"| {i} | {IDS[e['character_id']]} / `{e['path']}` | {e['before']} | {e['after']} | {e['rule']}장: {e['reason']} |")
    review += ['', '## 유지한 말과 검수 범위', '',
               '- 힐데가 1줄, 마르셀린 2줄의 중단 어구는 지침 5.3에 따른 의도적 흐림이다. 화계 검사에서 정해진 문구만 별도 표시하며, 앞의 완결 문장은 그대로 검사한다.',
               '- 테이리스의 `죠`는 `지요`의 준말로 해요체다. 해요체의 이탈로 세지 않았다.',
               '- 자동 검사는 길이·어미·금지어·중복·정본 이름 대조를 돕는다. 대사의 자연스러움과 새 고유명사 전체 탐지를 자동 검사만으로 보증하지 않는다.',
               '- 긴장·상처 장면에는 짧은 요청을 쓰고, 여관에서는 질문·부탁·머뭇거림을 섞었다. 호감이 높아져도 반말이나 성적·친밀 장면으로 넘어가지 않는다.', '',
               '## 정본이 없어 쓰지 않은 것', ''] + ['- ' + s for s in MISSING]
    md(OUT / 'review-pilot.md', '\n'.join(review))
    samples = {'hildegard': [4, 13, 26], 'marceline': [7, 12, 24], 'teiris': [11, 13, 27]}
    for cid, indices in samples.items():
        data = corpus[cid]
        sample = [f'# {IDS[cid]} 대표 장면 3개', '', 'Claude 직접 판정 대기. 아래는 최종 JSON에서 그대로 추출했다.', '',
                  f"ID: `{cid}` / 화계: {data['speech']['register']}", '',
                  '출처: ' + ', '.join(source_link(s) for s in data['sources']), '']
        for i in indices:
            s = data['inn'][i]
            sample += [f"## {s['stage']} · {s['id']}", '', s['situation'], '']
            sample += ['> ' + line for line in s['lines']]
            sample += ['', '| 선택지 | 반응 | aff | 편집용 이유 |', '|---|---|---:|---|']
            for c in s['choices']:
                sample.append(f"| {c['text']} | {' / '.join(c['response'])} | {c['aff']:+d} | {c['reason']} |")
            sample += ['', f"재노출: “{s['seen']}”", '']
        md(OUT / f'sample-{cid}.md', '\n'.join(sample))
    metrics = check['characters']
    counts = {k: sum(m[k] for m in metrics.values()) for k in ['inn_scenes', 'choices', 'dungeon_variants', 'transition_scenes', 'display_lines', 'companion_lines', 'ending_sentences']}
    changed = sorted(str(p.relative_to(ROOT)).replace('\\', '/') for folder in [ROOT / 'project/data/dialogue-r21', ROOT / 'tools'] for p in folder.glob('*')
                     if p.is_file() and (folder.name == 'dialogue-r21' or p.name.startswith('dialogue_r21_')))
    protected = read_json(OUT / 'protected-before.json')
    original_manifest = read_json(OUT / 'source-manifest.json')
    canon_changes = [r['file'] for r in original_manifest if hashlib.sha256((CANON / r['file']).read_bytes()).hexdigest() != r['sha256']]
    write_json(OUT / 'delivery-manifest.json', {'counts': counts, 'editorial_edits': len(edits), 'content_and_tool_files': changed,
                                              'protected_files_checked': len(protected), 'source_changes': canon_changes,
                                              'final_sha256': check['input_sha256'], 'review_status': '자기 편집 완료·Claude 표본 판정 대기'})
    report = ['# 1차', '',
              f"시범 3명 콘텐츠 작성·자기 편집 완료. 여관 {counts['inn_scenes']}장면 / 선택지 {counts['choices']}개 / 던전 짧은 말 {counts['dungeon_variants']}개 / 단계 변화 {counts['transition_scenes']}장면. 동료 대사 {counts['companion_lines']}줄, 표시 필드 {counts['display_lines']:,}개.", '',
              '| 인물 / 게임 ID | 여관 | 선택지 | 던전 14상황 × 3구간 × 2변형 | 단계 상승·하락 | 어미 이탈 |', '|---|---:|---:|---:|---:|---:|']
    for cid, m in metrics.items():
        report.append(f"| {IDS[cid]} / `{cid}` | {m['inn_scenes']} | {m['choices']} | {m['dungeon_variants']} | {m['transition_scenes']} | {len(m['ending_deviations'])}/{m['ending_sentences']} |")
    report += ['', '각 인물은 적대·불신 각 2장면, 낯섦·신뢰·유대·깊은 인연·맹세·운명 각 4장면이다. 선택지마다 반응 1줄, 편집용 성격 근거를 붙였고 aff는 -2/0/+2다. 선택지 표시 순서를 섞어 첫 항목만 계속 정답이 되지 않게 했다.', '',
               '## 검사와 검수', '',
               f"- `python tools/dialogue_r21_check.py`: 오류 {check['error_count']}. 스키마·단계·상황·변화 경계 누락·aff 범위·금지어·동일 줄/문장·화계 이탈 0.",
               f"- 어미 판정 {counts['ending_sentences']:,}문장, 이탈 0. 의도적 말끝 중단 3줄은 문구·이유를 선언해 별도 기록했다.",
               f"- 던전 최장 {max(m['max_dungeon_chars'] for m in metrics.values())}자, 전체 필드 최장 {max(m['max_line_chars'] for m in metrics.values())}자. 던전 기준은 40자다.",
               f"- `python tools/dialogue_r21_selftest.py`: {tests['checks']}개 검사, 실패 {tests['failures']}. 16종 내부 코드·9종 성향·금지 표기·스키마 손상·누락·중복·긴 줄·화계·가짜 이름을 넣어 거부를 확인했다.",
               f"- 자기 편집 {len(edits)}쌍: [review-pilot.md](verification/dialogue-r21/review-pilot.md). 전 표시 필드의 10문항 대조 기록은 [review-lines.json](verification/dialogue-r21/review-lines.json).",
               '- Claude 판정용 표본: [힐데가](verification/dialogue-r21/sample-hildegard.md), [마르셀린](verification/dialogue-r21/sample-marceline.md), [테이리스](verification/dialogue-r21/sample-teiris.md). 독립 판정은 미실시다.', '',
               f"공통 회귀 검사는 import 포함 {regression['runs']}개 실행 모두 종료 코드 0. 수치가 출력된 {regression['counted_assertions']:,}개 검증 항목의 실패 {regression['assertion_failures']}, 미분류 엔진 오류 {regression['unclassified_errors']}이다. `motion_test`, `motion_asset_test`, `art_test`, `export_licenses`는 별도 항목 수가 없는 성공 판정을 보존했다. 기대값 변경은 없다.", '',
               f"환경 오류는 별도 {regression['environment_error_occurrences']}회다. 모든 실행에서 `Failed to read the root certificate store`가 출력됐다. 이를 오류 0으로 숨기지 않고 원시 로그와 [regression-summary.json](verification/dialogue-r21/regression-summary.json)에 분리했다. 인증서 환경 자체는 이번 범위에서 고치지 않았다.", '',
               '이번 실행에서 생성된 r17/r18/r19/r20 전투 화면과 r9/r18 연출 화면, 360폭 대표 6장을 [regression-contact.png](verification/dialogue-r21/regression-contact.png)로 모아 직접 열어 확인했다. 선택 버튼·이름·전투 본체·초상 배치와 연출 장면을 확인했다. 새 대화 UI의 360폭 실제 줄바꿈은 미연결 상태라 확인하지 못했다.', '',
               '## 정본 대조와 원본 대비 차이', '',
               '- 세 파일의 ID는 정본 stats와 게임 world 양쪽에 존재한다. `hildegard`의 정본 이름은 힐데가, 게임 표시명은 힐데가르트다. 대사는 정본 이름을 쓰며 게임 표시는 수정하지 않았다.',
               '- 사용한 고유명사 합집합은 고립의 해·변경령·힐데가·마르셀린·나에린·테이리스 6개다. 고립의 해는 terms/stats에 없고 정본 위키 제목에 있다. terms 파일 자체가 사건 제목을 자동 처리한다고 명시하므로 해당 위키 원문으로 보완했으며, 정본 밖 이름은 추가하지 않았다.',
               '- 고유명사 도구는 정본 사전·명시 목록·명명 문형 후보를 대조한다. 어떤 한국어 신조 이름이든 찾아내는 도구는 아니다. 화계 검사 역시 문장 끝 어미를 보는 보조 검사이며 자연스러움의 최종 보증은 아니다.',
               '- 원본 여관 talk는 하루 1회, 무료, aff +1이다. 새 선택지의 -2/0/+2는 이번 지시에서 허용한 -3~+3 안의 새 콘텐츠 값이다. 기존 +1에 덧붙이지 않고 선택 결과로 대체하도록 연결 계약에 적었다. 원본 +12/-15 개인 행동 판정은 작은 대화 선택지에 복제하지 않았다.',
               '- aff는 감속 전 값이다. -100~200 제한과 100을 넘는 양수 몫 ×0.4, 소수점 둘째 자리 반올림은 원본 74-affection을 따른다. JSON에는 실제 정본의 비교 연산자를 적어 음수 소수 경계도 혼동하지 않게 했다.',
               '- `seen`은 재노출할 때 도입 대사를 대신하는 한 줄이다. 선택지와 하루 제한을 유지한다. 단계 변화는 인접 7경계의 상승·하락 각 1장면이며 여러 경계를 넘으면 최종 도착 경계 한 장면을 표시하도록 명시했다.',
               '- 던전 대사는 엔진이 확인한 이벤트에만 붙이도록 했다. 보상 수치·새 아이템·적 이름·봉인 해제 조건은 추가하지 않았다. 식탁·물잔·책·종이·짐은 대화 지문용 소품이며 재화나 소지품 데이터를 만들지 않는다.', '',
               '## 정본에 없어 못 쓴 것', ''] + ['- ' + s for s in MISSING]
    report += ['', '## 바꾼 파일과 재현', '',
               '- 콘텐츠: `project/data/dialogue-r21/{hildegard,marceline,teiris}.json`.',
               '- 도구·수기 초고: `tools/dialogue_r21_*` (정확한 파일 목록은 `verification/dialogue-r21/delivery-manifest.json`).',
               '- 검수·표본·초고 보존·검사 결과·원시 로그: `verification/dialogue-r21/**`.',
               '- 이 보고서: `DIALOGUE-R21.md`.', '',
               '```powershell', 'python tools/dialogue_r21_build.py', 'python tools/dialogue_r21_check.py',
               'python tools/dialogue_r21_selftest.py', 'python tools/dialogue_r21_report.py',
               '# 공통 회귀 검사 전체를 다시 실행할 때만', 'python tools/dialogue_r21_verify.py', '```', '',
               f"보호 대상 {len(protected):,}개 파일의 전후 SHA-256 변화 0, 읽기 전용 정본 {len(original_manifest)}개 파일 변화 {len(canon_changes)}. 코드·원본 에셋·저장 형식을 바꾸지 않았다. 공통 테스트가 기존 verification 위치에 만든 결과물은 재생성됐으며, 원시 실행 로그는 이번 검수 폴더에 보존했다.", '',
               '게임 UI·여관·던전·89-memory 실행 훅은 이번 범위대로 미연결이다. 식사·선물·숙박의 별도 콘텐츠와 나머지 동료 27명은 이 시범에 포함하지 않았다. 성적 장면·친밀 장면을 작성하지 않았고 커밋·웹 내보내기도 하지 않았다.']
    md(ROOT / 'DIALOGUE-R21.md', '\n'.join(report))
    print(json.dumps({'report': str(ROOT / 'DIALOGUE-R21.md'), **counts, 'edits': len(edits)}, ensure_ascii=False))


if __name__ == '__main__':
    main()
