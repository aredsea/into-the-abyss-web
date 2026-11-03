# R23-battle 6차 작업 보고

대상 212행. 이번 같음 +23, 누적 같음 153, 남음 59. 이번 수정 근거 8행, 누적 수정 근거 54행(같음과 중복). 원본 전 기능 완료는 아니다.

신규 대조 11,157개 / 실패 0. 누적 신규 대조 58,934개 / 실패 0. 기존 6,320판 · 219,785기록 / 차이 0. 전체 프로젝트 116/116그룹 / 실패 0.

검증 순서는 전체 검사 → 수치·상태 수정 후 영향받은 111그룹 재검사 → 마지막 기술명 누락 방어 한 줄의 동치 확인과 관련 4그룹 최종 코드 검사다. 마지막 변경은 w.skills[id].name을 get("name", "")으로 바꾼 조회 한 줄뿐임을 이전 해시로 역검증했다. 기존 통과 실행은 해당 조회에 도달하지 않았거나 name이 존재했으므로 반환값·상태·RNG·시각이 같다. 이름 없는 입력은 enemy_action/enemy_regression, 최종 표시 연결은 tiles 검사로 확인했다. 이 단계별 근거는 final-recheck-plan.json/name_guard_supplement와 name-guard-before/에 보존했다.

첫 5,120판 검사에서 펠리체 소생 뒤 페르소나 치명 버프가 남은 2판의 차이를 발견했다. pscrit를 추가한 동일 96입력에서 39실패를 재현하고 수정 후 0실패를 확인했으며, 최종 5,120판도 모두 일치했다. 처음 시도한 기술명 방어 치환이 반영되지 않았던 문제도 실제 파일의 조회 줄을 확인해 수정했다.

Windows root certificate store 진단만 환경 메시지로 제외했으며 Script error와 다른 ERROR는 실패로 셌다. 사용자 저장을 열지 않았고 Godot는 격리된 tools/godot_r17.py로만 실행했다.

## 구현과 근거

- 원본 기록 편성: 30인/페르소나/미지·빈 칸의 정의와 기술 목록, pend/pid 재탐색·취소, 옛 EDEF·16칸 잔존 정의 제거, VER2 필드 이관과 carry 경계. Battle.combat_display_frame은 정의를 생략하면 원본 기록을 복제·이관·bind하여 표시한다. 기존 native 저장/restore 규칙은 유지한다.
- 표시: 일반 적·보스·레이드 필드·아군 타일 HTML 전체. 직접 호출과 Battle.combat_display_tile 연결을 함께 대조했다. 피해 문구·정산 장소/적 목록의 ko/en 반환도 비교했다. r17~r20 장면 배치는 대체하지 않았다.
- 실제 개인 훅: 펠리체 소생의 보호막·DOT 유지/해제 범위·동률 우선순위·HP 이력/로그/T, 마르셀린 구원의 HP=1→회복·고정 보호막/로그/시각. source 최대 HP=0 방어 경계도 비교했다.
- 실제 적 차례: buff/debuff/heal/protect/special·종료 훅을 분리해 원본 전체 기록을 남긴다. 누락 amount와 지속 기본값, aura·미지 stat/target, 대상 없음, 숨기, 침묵 후보 없음/10직업/실제 RNG·의존성 주입 RNG=1 경계를 포함한다.

함수 194/212 호출, 기준 미검증 진입 100/157 도달(이전 90). 23종 원본 oracle은 계측 전후 출력이 같았다. 함수/then/else/do 진입 계측이며 단락 조건의 모든 조합 전수 검증을 뜻하지 않는다. 행별 이전 상태·원본 위치·라벨·제품 파일:줄·남은 이유: verification/parity-r23/battle.json.

## 실패 확인과 한계

펠리체 변경 전 동일 96입력에서 39차이를 확인했다. 이전 적 지원 분기를 별도 보존해 1,984입력을 재생했다: 1972실패, 유닛 출력 차이 636개, 누락 amount 오류 guard 128개. 이는 이전 전체 엔진 빌드의 실행이 아니라 이전 turn 분기의 추출 재생이다. 새 API 부재 guard와 fixture 작성 중 오류는 기존 제품 수치 버그 수로 세지 않았다.

첫 전체 검사는 일부 독립 전투의 기록장 미초기화 오류를 발견했다. 변경 전 시작한 검사는 first-pass/에 보존하고, 마지막 코드/입력으로 필요한 검사를 재실행했다. final-recheck-plan.json·최종 code/input SHA·전체 로그를 suite-round6-final/에 남겼다. 클라우드는 고유 loopback 포트의 실제 serve.mjs/D1 서버로 실행하고 종료를 확인했다.

새 큰 대조 파일은 battle- 접두사를 사용하고 세 파일로 분할했다(각 50 MB 미만). 기존 round5-oracle.json은 이미 52 MB였으며 새 계측 사본은 compact JSON으로 50 MB 미만에 저장한다. 원본 선언 데이터만 제품 상수로 동기화했고 기대값을 규칙으로 복사하지 않았다.

초기 보호 해시 목록의 이름이 관측 출력 이름과 충돌해 보존되지 않았다. 따라서 이번 작업 시작부터의 해시 불변을 그 목록으로 주장하지 않는다. 별도 보호 manifest를 만든 이후 검증 구간의 docs/assets/server 해시 불변과 원본 이미지 96개 해시 일치를 확인했다. docs/server에는 이전 5차 manifest와 다른 기존 파일 6개가 있었으며 이번 작업에서 쓰지 않았다. Web export·버전 갱신·커밋 없음.

새 HTML/정의/VER2 대조는 원본 기록 호환 경계이며 native 저장의 전면 이관이나 최상위 B.render/버튼 전체 일치로 확대하지 않는다. 개인·적 지원 훅은 명시한 중립/무장비 입력의 전체 부수 출력이고, 장비/혼합 전투는 기존 6,320판의 수치·RNG 회귀로 별도 확인했다. 이미지 검토는 battle-round6-visual-review.json. Web/WASM·실기기·전수 스크린샷은 확인하지 않았다.

## 바꾼 제품 파일

- project/game/battle_source_data_r23.gd
- project/game/battle_source_state_r23.gd
- project/game/battle_v3.gd
- project/game/combat_display_r22.gd
- project/game/combat_text_r23.gd
- project/game/combat_tiles_r23.gd
- project/game/dungeon_enemy_r21.gd
- project/game/personal_rules_r22.gd

## 남은 행

- 30인 개인 기술·개별 특성: 같음 27, 남음 4.
- CTB·공격·종결·전투 버튼: 같음 15, 남음 20.
- 적 방어·반격·소환·단계: 같음 18, 남음 12.
- 전투 사건 연출·HUD·대상·로그: 같음 38, 남음 3.
- 전투 상태·능력치·편성: 같음 36, 남음 11.
- 종족·출신·직업 시너지: 같음 12, 남음 1.
- 페르소나 단일 연구 기술: 같음 7, 남음 8.

남은 핵심: 채팅 호스트 load/save/press·VER2의 native 전체 저장 재개, 시작/재시작/종결의 전체 상태, fire/chain·공격/소환/단계 전환의 전 부수 출력, 남은 개인 기술, 행동 패널과 최상위 렌더. 각 행의 구체적인 이전 사유를 ledger에 유지했다.

재실행: 세 oracle_battle_r23_round6*_loader.mjs → sync_battle_state_r23.py / sync_battle_text_r23.py → coverage_battle_r23.py → verify_battle_r23_round6.py(필요 시 finalize_battle_r23_round6.py) → 이미지 검토 → report_battle_r23_round6.py. 5차 보고/ledger는 R23-battle-round5.md와 battle-round5.json에 보존했다.
