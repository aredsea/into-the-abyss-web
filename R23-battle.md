# R23-battle 9차 보고

전투 218행(기존212 + expe 이관6): 같음199·호스트 제외3·남음16(일부12/미확인4). 기존 전투14행을 같음으로 올리고 이관6행도 같음으로 처리했다. 기존 남음30→16. 전 기능 완료는 아니다.

신규 검사 14,717개 실패0: 원본 Lua 직접 대조 11,987, native 화면/재개 2,720, 실제 로컬 클라우드 10개. 누적 신규 검사 108,516개. 전체 프로젝트 131/131그룹(import 포함) 실패0. 기존6320판·219785기록 차이0.

원본 Lua19개를 함수/then/else/do 진입 Boolean으로 계측하고37묶음을 새로 실행했다. 계측 전후 oracle 출력과 보존6320판 원본 trace가 같았다. 함수209/212 호출(나머지3은 기존 호스트 제외), 기준 미도달 진입157/157 도달(8차142). 진입 도달은 조건 조합 전수나 native 전체 등가 증명이 아니다. coverage/에는 전체 oracle 중복 사본 없음.

직접 대조: Bargut48, persona772, extra_hit192, 단일/전체 적 공격16, 아이템5250, blank_unit1056·비율56, dispatch384·act1216, item handler960, 편성204·의뢰189, 적 차례652, damaged992개. 아이템5250에는 효과2220·대상1540·메뉴1452·버튼14·행동자7·이름17이 포함된다.

실제 전투에는 Bargut 성공/실패·persona 컷인/공격/지원·추가 타격의 원문·필드·사건 순서를 보완했다. 치명 taunt 로그가 맞은 뒤 사라지던 차이도 수정했다. Sorel의 피격 회복은 살아 있는 개인 소유자 순서,25% HP/2회 제한,원본 회복 시각·로그를 따르며 시전자 사망 효과 정리도 연결했다.

아이템은 정본 순서·이름·설명·무재고/대상 불가·현재 행동자 장비 배율을 사용한다. 붕대가 유지해야 하는 침묵·재생·x 효과까지 지우던 차이를 수정했다. 메뉴와 선택 아이템을 기존 selected_action으로 저장하여 다시 연다. persona regen의 생성 행동은 기존 effect.order로 보존한다. 저장 스키마나 서버를 늘리지 않고 /v1/account→/v1/save 실제 왕복을 확인했다.

같음은 행에 적은 함수 계약의 직접 대조 범위다. CombatHooks·CombatControls·CombatParty는 source-shaped 함수 API이며 일부 callback은 spy로 호출 경계를 관찰했다. 해당 API가 native의 모든 상위 호출자를 대체했다고 주장하지 않는다. blank_unit도 원본 모양 경계 비교다. 새 커널의 증거를 fresh/battle_start/run/strike/행동 패널 같은 부모 행으로 전파하지 않았다. 이관 H.it은 프로토콜960개, 별도 실제 효과2220개와 실제 화면 저장 재개·클라우드 왕복을 함께 근거로 삼았다.

수정 근거19행(기존 중복 포함), 신규 수정 근거16행, 누적90행. 함수 포트·누락 API 보완도 포함하며 숫자 버그16개라는 뜻은 아니다. 원래 모듈8개를 보존하고 최종 core1028입력으로 재생하니 관찰 차이821개(Bargut48/persona772/적 공격1)와 extra_hit API 부재 guard192개였다. 전체 옛 빌드를 재현한 수치는 아니다. 별도로 실제 실행한 붕대 보존96개 실패 및 옛 G.lv fallback2개 실패가 수정 뒤 통과했다. 붕대 수정 전 파일 SHA는 중간 lock과 일치한다.

초기 새 시험의 중복 character ID를 UID로 쓰던 fixture를 분리해 source와 같은 입력을 옮겼다. 클라우드 fixture는 금지 stats.crit 키를 제거하고 JSON 정수/실수의 수치 비교를 사용했다. 기대값을 바꾸거나 실패 사례를 버리지 않았다. 아이템 행동의 per-action RNG 재시드는 기존6320판 회귀가 보여 준 필요 조건대로 유지했다. v1은 붕대 경계 추가로 폐기했고, v2의 기존 battle_r23_test는 이름 없는 persona_skill 객체를 넘겨 새 기록 경로에서 오류를 냈다. 정본 기술 정의에서 누락 이름을 구하도록 제품을 고쳐 해당 시험과1028개 core를 재통과했다. 보급품 제목/안내/버튼도 의미 API에 연결한 뒤 v3 전체를 처음부터 실행했다. v2의 A8대조는4864판까지 차이0에서900초 제한으로 종료되어,5120판 시험의 시간 제한만1800초로 늘렸다. 최종 제품/시험/입력과 실행기 SHA 불변, 중간 실패·취소 실행을 최종 통과 수에 섞지 않았다.

| 묶음 | 같음 | 제외 | 남음 |
| --- | ---: | ---: | ---: |
| 30인 개인 기술·개별 특성 | 31 | 0 | 0 |
| CTB·공격·종결·전투 버튼 | 27 | 2 | 6 |
| 적 방어·반격·소환·단계 | 30 | 0 | 0 |
| 전투 보급품 (expe 이관) | 6 | 0 | 0 |
| 전투 사건 연출·HUD·대상·로그 | 38 | 0 | 3 |
| 전투 상태·능력치·편성 | 40 | 1 | 6 |
| 종족·출신·직업 시너지 | 13 | 0 | 0 |
| 페르소나 단일 연구 기술 | 14 | 0 | 1 |

같음 승격: P1539, P1542, P1616, P1619, P1674, P1688, P1692, P1720, P1721, P1722, P2115, P2220, P2280, P3331, P3332, P3337, P3338, P3340, P3344, P3492.

연구 저장 P1688/P1692는 공통 규칙의 호스트 제외 기준으로 재판정했다. 상태·금화·ready/dirty/busy·한영 문구 16038개(저장594입력/성공256)는 직접 비교했다. 남겨 두었던 B.pend_busy/getChatLength와 B.pend_hard/addChat 및 AI 반응 프롬프트는 RisuAI 전용이다(01-game.lua:204/222,29-persona-skill.lua:215). 이 호스트 부분을 게임 상태 미구현과 혼동하지 않는다. 기존 검사를 재사용했으므로 신규 검사 수에는 더하지 않았다. 근거: battle-round9-host-contract.json.

남은16행과 구체적인 이유:

- P1553 B.fresh: 초기화 48편성과 carry 소생 조건은 비교. 기본/옛 편성·dm·로그·q·first를 포함한 fresh 전체 반환은 남음.
- P1587 B.again: 동일 편성 재시도의 bn 증가와 rg/qid/place/sid 이전 계약을 새 원본 fixture로 비교하지 않음.
- P1589 B.redo: 같은 bn으로 재시작하며 난이도·편성·출처를 유지하는 전체 반환을 새 대조하지 않음.
- P1594 B.load: 저장 매체 차이는 사유에서 제거. 원본 VER2 기록을 native에서 불러와 같은 다음 행동/소지·장착·진행으로 재개하는 직접 왕복 대조와 손상 입력 결과 비교가 아직 없음. 원본 migrate 대조 및 native 자체 restore 통과만으로 전체 load/save 행을 승격하지 않음.
- P1595 B.save: 저장 매체 차이는 사유에서 제거. 원본 VER2 기록을 native에서 불러와 같은 다음 행동/소지·장착·진행으로 재개하는 직접 왕복 대조와 손상 입력 결과 비교가 아직 없음. 원본 migrate 대조 및 native 자체 restore 통과만으로 전체 load/save 행을 승격하지 않음.
- P1620 B.battle_start: 편성→전투 시작→scene/보상/식별자 저장까지의 G 변경 전체를 새 대조하지 않음.
- P1746 B.strike: 72가지 직접 strike와 기존 장비/사제/생존 회귀는 통과. 반환 ls/tags, 모든 구원 소유자 순서 및 필드 시간 이력은 남음.
- P1811 B.e_attack: 기존256+추가16개 단일/전체 공격 기록에서 치명 taunt 원문/시간을 수정. 여러 개인/장비 반격 훅을 섞은 모든 사건·반환·시간 순서 직접 대조는 남음.
- P1812 B.e_attack_all: 단일/전체 256입력의 대상별 시각·사망·보호자 상태·tags·피격 후 효과 비교. 다중 반격/장비 훅 혼합의 전체 사건/로그 대조는 남음.
- P1813 B.enemy_turn: 100종 각 행동·건강/손상652개 조합 편성의 차례 전체 상태·사건·로그·다음 RNG 직접 일치. fl 없는 옛 고정 적 차례 전체와 다중 개인/장비 훅 혼합 직접 대조는 남음.
- P1825 B.finish: 256개 직접 원본 모양 정산에서 결과문·부상자·EXP·로그·종료 이벤트·cur/q·재호출 일치. 실제 native world의 모든 의뢰 rg/qmult·출처 연결과 저장 재개 뒤 nd/마지막 일격 기록 복구는 남음.
- P1831 B.run: 6320판 진행 결과는 비교. guard 80·모든 시작/라운드/사망·자동 방출의 전체 상태 경계는 남음.
- P1682 B.ps_guild_tab: 기존 길드 UI는 유지. 모든 prefix/suffix·dirty/ready·강화 상한/부족 금화 표시의 의미상 출력 전체는 새 대조하지 않음.
- P2351 sbtn: 버튼 MP/설명·disabled·선택 상태의 의미상 출력 전체를 새 직접 대조하지 않음.
- P2353 B.r_act: 기술 조건 회귀는 통과. 행동/아이템/대상 선택·취소·버튼 배열의 전체 새 대조는 남음.
- P2359 B.render: 기존 native 화면/오버플로 회귀는 유지. 모든 원본 상태에서 HUD·대상·로그·카메라의 의미상 전체 출력 대조는 남음.

fresh/retry/redo/save/load/battle_start와 run·연구 화면의 새 원본 경계는 source-only 파일에 관측했다. Godot 직접 결과가 없는 관측을 같음으로 세지 않았다. 특히 저장/원정 출처/연구 대화의 실제 연계는 일부 소관 밖 파일이지만, 금지된 원정·시설·서버를 수정하지 않고 남은 이유를 보존했다.

9차 재개 검증: v3의 combat_p3_r22_test와 enemy_review_r21_test에서 빈 기록 객체의 ev 접근 오류를 확인했다. 중단 직전 추가된 ensure_record 경로로 오류가 사라졌다. 이어 소렐 2건은 Lua의 cs=100에 대응하는 native fixture의 line이 맞지 않아 실패했다. 제품 산식과 원본 기대값은 유지하고 시험 입력의 line을 int로 맞춘 뒤 497개가 통과했다. 84736개 개인 기술 검사와 새 core1028·damaged992개도 통과했다. 이후 최종 v4 전체 검사를 새로 실행했다. 최종 수치는 v4 단일 실행만 사용한다.

Windows root certificate store 진단만 기존 실행기의 환경 메시지 예외로 처리한다. SCRIPT ERROR와 그 밖의 ERROR는 종료 코드가 0이어도 실패로 센다. 원본 기대값은 변경하지 않았다.

렌더는 한영5크기20장을 생성하고 그중4장을 직접 열었다. 보급품 제목/안내·원문·불가 이유·수량·선택 강조·MP 표시를 확인했다. 작은 높이에서 목록은 기존처럼 스크롤되고 영어 적 이름 일부는 기존 말줄임이 남는다. 영어 화면의 기존 차례 제목과 미선택 확인 버튼 일부는 한국어다. 이번 아이템 의미 API의 한영 문자열 대조와 전체 화면 번역 완료는 구분한다. 실기기/Web/WASM·전수 프레임은 확인하지 않았다. 확인 파일·SHA·관찰은 battle-round9-visual-review.json.

원본 이미지96개 해시 일치, docs249/assets1784/server30개 해시 및 파일 목록 불변. 사용자 저장을 열거나 지우지 않았고 Web export/버전 갱신 없음. 재개 지시가 명시한 git status/diff만 읽기 전용으로 사용했다. dubious ownership은 명령별 safe.directory로 처리했으며 전역 설정이나 저장소 상태를 바꾸는 git 명령은 실행하지 않았다. 새 비교 파일은 battle- 접두이며 각40MB 미만이다. coverage/에 남아 있던 옛 oracle 사본23개는 provenance를 제외한 전체 JSON이 정본과 같음을 확인한 뒤 정리했다(218593871바이트). 완료된 격리 시험 폴더는 경로 검증 후 정리하며 기본 runtime은 남긴다.

행별 원본 id·위치·이전 상태·새 시험·제품 파일:줄·범위·남은 이유: verification/parity-r23/battle.json. expe.json은 수정하지 않고6행 원문/이력을 복사하여 expe 이관을 표시했다.

재실행: oracle_battle_r23_round9_loader.mjs (R23_ROUND9_PACK=core/items/state/control/handlers/start/enemyturn/damaged) → coverage_battle_r23.py → verify_battle_r23_round9.py (R23_FINAL_SUITE=suite-round9-final-v4) → prepare_battle_r23_round9_before.py 및 보존 모듈 재생 → 렌더 확인 → report_battle_r23_round9.py.

이번 제품 파일:

- project/game/battle_source_state_r23.gd
- project/game/battle_stats_r23.gd
- project/game/battle_v3.gd
- project/game/combat_attack_r23.gd
- project/game/combat_controls_r23.gd
- project/game/combat_events_r22.gd
- project/game/combat_hooks_r23.gd
- project/game/combat_item_data_r23.gd
- project/game/combat_items_r23.gd
- project/game/combat_party_r23.gd
- project/game/dungeon_enemy_r21.gd
- project/game/persona_combat_r22.gd
- project/game/persona_world.gd
- project/game/personal_rules_r22.gd
- project/game/trait_rules_r22.gd
- project/ui/battle_screen.gd

이번 시험/도구:

- project/tests/battle_r23_round9_control_test.gd
- project/tests/battle_r23_round9_core_test.gd
- project/tests/battle_r23_round9_damaged_test.gd
- project/tests/battle_r23_round9_enemyturn_test.gd
- project/tests/battle_r23_round9_handlers_test.gd
- project/tests/battle_r23_round9_items_test.gd
- project/tests/battle_r23_round9_start_test.gd
- project/tests/battle_r23_round9_state_test.gd
- project/tests/cloud_battle_r23_round9_test.gd
- project/tests/enemy_review_r21_test.gd
- project/tests/town_r21_round9_test.gd
- project/tests/ui_battle_r23_round9_test.gd
- project/tests/ui_town_r21_round9_test.gd
- tools/audit_battle_r23_round9_host.py
- tools/cleanup_battle_r23_round9_runtime.py
- tools/coverage_battle_r23.py
- tools/godot_r17.py
- tools/oracle_battle_r23_round9_control.lua
- tools/oracle_battle_r23_round9_core.lua
- tools/oracle_battle_r23_round9_damaged.lua
- tools/oracle_battle_r23_round9_enemyturn.lua
- tools/oracle_battle_r23_round9_handlers.lua
- tools/oracle_battle_r23_round9_items.lua
- tools/oracle_battle_r23_round9_loader.mjs
- tools/oracle_battle_r23_round9_start.lua
- tools/oracle_battle_r23_round9_state.lua
- tools/prepare_battle_r23_round9_before.py
- tools/report_battle_r23_round9.py
- tools/run_battle_r23.py
- tools/sync_combat_items_r23.py
- tools/town_r21_round9_compare.py
- tools/town_r21_round9_contacts.py
- tools/town_r21_round9_report.py
- tools/town_r21_round9_web.py
- tools/verify_battle_r23_round9.py
