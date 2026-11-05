**EN-R24 — 4차 다듬기 완료**

30명 전체 **14,216개** 영어 표시 필드를 인물별로 읽고 **1,268개**를 수정했다. 독립 검수 지적과 표본 밖의 주어·관사·전치사·목적어 생략, 잘못된 축약, 신체 부위·회계·문서 용어 직역을 고쳤다. 인물별 짧은 말투와 격식, 부정적 선택지의 의미는 유지했다.

| 항목 | 최종 결과 |
| --- | ---: |
| 검토 인물 / 영어 표시 필드 | 30명 / 14,216개 |
| 달라진 영어 필드(중복 제외) | 1,268개 |
| 검수 보고서에 열거된 항목 / 수정 | 62건 / 62건 |
| 실제 영어 표시의 한국어 잔존 | 0개 |
| 3명씩 10묶음 언어·대사 검사 | 20회 / 실패 0 |
| 전체 필수 회귀 검사 | 20종 / 실패 0 |
| 최종 로그의 집계 가능 검사 | 291,453개 / 실패 0 |
| 영어 UI 장면 / 검사 | 1,680개 / 161,220개 / 실패 0 |
| 한국어 원문 바이트 복원 / 일치 | 30개 / 30개 |
| 보호 기준 파일 / 변경 | 2,481개 / 0개 |
| 원본 자산 / 불일치 | 96개 / 0개 |
| 갱신한 한·영 표본 | 300줄 |

지시서 요약은 검수 지적을 67건이라고 했지만, `review-luna.md`에 실제 열거된 것은 **틀림 11·어색 40·권함 11 = 62건**이다. 전부 반영했다. 나머지 5건은 경로·내용이 보고서에 없어 개별 항목으로 확인할 수 없다. 토베의 찬 손끝, 에르데네의 쓰러진 동료, 할드리크의 보증 이름처럼 제안과 문맥이 다른 곳은 한국어 장면을 따라 수정했다.

제품 변경은 `project/data/dialogue-r21/*.json` 30개의 기존 `en.display` 값뿐이다. 한국어·필드 경로·id·장면 구조·선택지 순서·호감 수치·`en.speech`·저장 형식은 유지했다. 영어 필드를 제거해 복원한 원본 바이트와 기준 SHA-256이 모두 일치한다. 외부 번역 서비스와 보조 에이전트는 사용하지 않았다. git 명령, Web export, `docs/`, 다른 작업 공간, 사용자 저장 파일은 수정하지 않았다.

검사 보조 `project/tests/ui_scroll_r24.gd`도 수정했다. 최초 전체 UI 실행은 검사 항목 실패 0이었으나, 1px로 잘린 표시 영역에 기존 1px 안쪽 여백을 적용하면 음수 사각형으로 교차 검사를 해 엔진 오류 14건이 났다. 여백 적용 후 빈 영역인지 먼저 확인하게 고쳤다. 기존 1px 허용 오차와 실제 겹침 판정은 유지했다. 경계 사례 10개와 전체 영어 UI를 다시 통과했다. 원래 오류 로그는 `verification/en-r24/polish-checks/ui-en-before-scroll-helper-fix.log`에 보존했다. 이 검사 파일은 초기 보호 기준 2,481개 목록에 없으므로 별도 변경으로 기록했다. 제품 규칙과 원본 자산은 변경하지 않았다.

필수 검사는 import, en_r24, dialogue_player/roster, finish_locale_data_audit, world/state/route/expansion/motion/motion_asset/art/export_licenses, ui_battle_r17/r18/r19/r20, motion_r9/r18, ui_en_r24이다. 기대값을 변경하지 않았다. 모든 명령은 지정된 Godot 래퍼로 실행했다. 루트 인증서 저장소를 읽지 못한다는 기존 환경 메시지는 로그에 남지만 시험 실패나 스크립트 오류는 없다. 생성한 격리 runtime 슬롯은 정리했다.

최종 영어 UI 검사에서 1,680개 장면을 자동 확인했다. 새로 생성된 캡처 중 30개를 직접 열어 확인했다. 수동 화면 검토 범위와 관찰 결과는 시각 검토 기록에 적었다. 모든 장면을 수동으로 보았다는 뜻은 아니다.

변경 경로, 인물별 수정 수, **인물마다 대표 전후 예시 5개(총 150개)**는 [polish-diff.md](verification/en-r24/polish-diff.md)에 있다. [전체 변경 내역](verification/en-r24/polish-edits-final.json), [검수 지적 처리](verification/en-r24/polish-review-items.json), [300줄 표본](verification/en-r24/sample.md), [최종 요약](verification/en-r24/polish-summary.json), [원문·자산 보존](verification/en-r24/polish-protection.json), [묶음 검사](verification/en-r24/polish-checks/batch-results.json), [전체 회귀](verification/en-r24/regression.json), [실제 표시 언어 감사](verification/finish-r24/authored-language-audit.json), [대사 시험](verification/en-r24/dialogue-test.json), [UI 시험](verification/en-r24/ui-test.json), [시각 검토](verification/en-r24/polish-visual-review.json).

재검사: `python tools/en_r24.py audit`, `python tools/en_r24.py sample`, `python verification/en-r24/verify-polish4.py`.
