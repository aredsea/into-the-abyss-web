import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
out = root / 'verification/en-r24'
s = json.loads((out / 'summary.json').read_text(encoding='utf-8'))
a = json.loads((out / 'authored-language-audit.json').read_text(encoding='utf-8'))
runtime = json.loads((root / 'verification/finish-r24/authored-language-audit.json').read_text(encoding='utf-8'))
visual = json.loads((out / 'visual-review-round2.json').read_text(encoding='utf-8'))
assert s['regression_runs'] == 20 and not s['regression_failed']
assert runtime['fields'] == s['fields']
lines = [
    '**EN-R24 — 미완료 / 누적 12명 번역 및 검증**', '',
    '이번 실행에서 베렌가·비앙카·콜레트·에르데네·펠리스·게르다·군힐트·할드리크·헤드비히 '
    '**9명·4,238개 문구**를 직접 번역했다. 기존 3명·1,398개를 합쳐 **12명·5,636개**다. '
    '**남은 18명·8,580개는 번역하지 못했다. 지시된 27명 전체 번역을 완료하지 못했으며 배포 언어 게이트는 미통과다.**', '',
    '| 항목 | 결과 |', '| --- | ---: |',
    f'| 완료 캐릭터 | {s["characters_complete"]} / {s["characters_total"]} |',
    f'| 번역 문구 | {s["translated"]:,} / {s["fields"]:,} |',
    f'| 실제 영어 표시 감사의 한국어 잔존 | {runtime["untranslated"]:,} |',
    '| 각 신규 3명 묶음의 한국어 잔존 | 0 |',
    f'| 전체 회귀 검사 | {s["regression_runs"]}개 실행, 실패 {s["regression_failed"]} |',
    f'| 로그에서 집계한 검사 | {s["counted_checks"]:,}개, 실패 0 |',
    f'| 영어 UI 장면 | {s["ui_scenes"]}개 |',
    f'| 영어 UI 검사 | {s["ui_checks"]:,}개, 실패 {s["ui_failures"]} |',
    f'| 보호 파일 | {s["protected_files"]:,}개, 변경 {len(s["protected_changes"])} |',
    f'| 원본 자산 해시 | {s["asset_hash_entries"]}개, 불일치 {len(s["asset_hash_changes"])} |', '',
    '대사 데이터 변경은 `project/data/dialogue-r21/{berenga,bianca,colette,erdene,felice,gerda,gunhild,haldric,hedwig}.json` '
    '9개에 `en.display`와 `en.speech`를 추가한 것이다. 기존 표시 연결을 그대로 사용한다. '
    '**30개 파일 모두 영어 필드를 제거하면 최초 한국어 원본 바이트의 SHA-256이 정확히 복원된다.** '
    '한국어 문자열·장면 구조·id·선택지 순서·호감 수치와 저장 형식은 바꾸지 않았다. '
    '기존 3명과 미번역 18명의 제품 JSON은 이번에 수정하지 않았다.', '',
    '`project/ui/town_screen_r21.gd`의 탐색 대사 표시에서는 영어 본문을 먼저 해석한 뒤 길이에 맞춰 '
    '행 높이와 스크롤 내용 높이를 계산하고 라벨 줄 간격도 반영하도록 수정했다. 캡처에서 베렌가의 긴 전환 문구 끝이 잘리는 것을 '
    '확인한 데 따른 표시 수정이며, 한국어의 기존 행 높이와 게임 규칙은 그대로다. '
    '영어 UI 시험에 본문 전체가 라벨과 스크롤 내용 영역에 포함되는지도 추가했다. '
    '보이는 줄 수 검사에서 최초 148건을 검출했고 수정 후 0건으로 재검사했다. '
    '수정 전 근거는 `verification/en-r24/ui-test-before-line-spacing-fix.json`에 남겼다.', '',
    '베렌가는 따뜻하고 수다스러운 존대, 비앙카는 우아한 질문과 거래 어휘, 콜레트는 간결한 격식체, '
    '에르데네는 큰 목소리의 직설적인 구어, 펠리스는 빠른 안내와 수다, 게르다는 냉소와 징조 앞의 진지함, '
    '군힐트는 호령과 칭찬 앞의 머뭇거림, 할드리크는 건조한 계약 문장, 헤드비히는 정확한 선언체를 옮겼다. '
    '가까워져도 각자의 거절·두려움·믿음·이름과 이해관계가 지워지지 않게 했다. '
    '고유명사는 기존 사전의 Gunhild von Halen, Graben, Colette de Cadell, Felice da Torva, '
    "Interpreters' Lane, Murena Isle, Alt Valley, Golden Register, Council of Ten 등을 확인해 사용했다. "
    '고립의 해는 사전의 기존 설명 문장에 쓰인 Year of Isolation을 따랐다. '
    '새 인물·설정·성적 장면을 추가하지 않았다. 외부 번역 서비스·API와 보조 에이전트는 사용하지 않았다.', '',
    '검사는 베렌가/비앙카/콜레트, 에르데네/펠리스/게르다, 군힐트/할드리크/헤드비히의 '
    '3명 묶음마다 실제 영어 표시 언어 스캔과 영어 선택·원문 보존·저장 왕복 시험, '
    'dialogue_player 및 dialogue_roster 시험을 실행했다. 각 묶음에서 한국어 잔존과 시험 실패는 모두 0이다. '
    '표현을 다듬은 뒤 전체 회귀 검사를 다시 실행했다.', '',
    '`project/tests/en_r24_test.gd`와 `ui_en_r24_test.gd`는 기존 3명만 검사하던 기본 목록을 '
    '영어 필드가 있는 모든 인물을 검사하도록 넓혔다. 기대값을 낮추거나 미번역을 영어로 간주하지 않았다. '
    'import, world/state/route/expansion/motion/motion_asset/art/export_licenses, '
    'ui_battle_r17/r18/r19/r20, motion_r9/r18, 영어 대사 및 화면 시험을 직접 재실행했다. '
    '루트 인증서 저장소를 읽지 못한다는 환경 메시지는 로그에 남았으며, 별도로 집계한 스크립트 오류는 0이다. '
    '언어 감사 프로세스의 정상 종료를 전체 영어화 성공으로 해석하지 않는다.', '',
    '[300줄 한·영 표본](verification/en-r24/sample.md)은 seed 20261104, 중복 없는 무작위 추출이다. '
    '**모집단은 번역된 12명·5,636개 문구만**이다. 300줄을 원문과 직접 대조했고 어색한 표현을 수정한 뒤 '
    '같은 seed로 다시 생성했다. 30명 전체의 최종 표본은 아직 만들 수 없다.', '',
    f'영어 360/430px 장면 캡처 {visual["reviewed_captures"]}개를 인물별 원래 해상도 대조 이미지로 열어 확인했다. '
    + visual['review_ko'], '',
    '근거: [summary.json](verification/en-r24/summary.json), '
    '[regression.json](verification/en-r24/regression.json), '
    '[원문 보존·번역 감사](verification/en-r24/authored-language-audit.json), '
    '[실제 표시 감사](verification/finish-r24/authored-language-audit.json), '
    '[dialogue-test.json](verification/en-r24/dialogue-test.json), '
    '[ui-test.json](verification/en-r24/ui-test.json), '
    '[표본 검토](verification/en-r24/sample-review-round2.json). '
    '묶음별 근거는 `verification/en-r24/batch-*-results.json` 및 해당 로그에 있다.', '',
    '| 캐릭터 | 표시 문구 | 번역 | 미번역 |', '| --- | ---: | ---: | ---: |',
]
for row in a['files']:
    lines.append(f'| {row["id"]} | {row["fields"]} | {row["translated"]} | {row["untranslated"]} |')
lines += ['', '재검사:', '', '```powershell',
          'python tools/en_r24.py audit', 'python tools/en_r24.py sample',
          'python tools/en_r24_verify.py', '```', '',
          '`audit`는 남은 8,580개 때문에 종료 코드 1이 정상적인 현재 결과다. '
          '다음 번역 대상은 `hildegard.json`이며 이후 표의 미번역 18명을 이어가야 한다. '
          '이번에 만든 runtime-en-r24, runtime-local-en-r24, tmp-en-r24 슬롯은 정리했다. '
          'Web export·`docs/`·다른 작업 공간·사용자 저장 파일은 수정하지 않았다.', '']
(root / 'EN-R24.md').write_text('\n'.join(lines), encoding='utf-8')
print('EN-R24.md written')
