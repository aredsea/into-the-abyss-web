# R23-gear — 3차 장비·시설 함수 대조

남은 **40행 전부 재검토**, 이번 같음 **+3행**, 수정 근거 **5행**(새 수정 표기 4행, 기존 수정행 추가 해결 1행). 누적 **77행 중 같음 40행·수정 29행·남음 37행**. 수정과 같음은 겹친다. 원본 전 기능 완료는 아니다.

전체 프로젝트 **112그룹 / 실패 0**, 서버 npm test **12,932항목 / 실패 0**. 이번 직접 대조 **2,412항목**, 실제 화면 **116항목**, 합계 **2,528항목 / 실패 0**. 누적 R23 직접/화면 대조 **13,538항목**(서버 신규 259 별도). 전투 **6,320/6,320판 · 219,785기록 일치**.

행 id·원본 위치·이전 판정·새 근거·남은 사유는 [gear.json](verification/parity-r23/gear.json)에 이어 기록했다. 이전 [2차 ledger](verification/parity-r23/round2-gear.json), [2차 보고](verification/parity-r23/round2-report.md)를 보존했다. [요약 수치](verification/parity-r23/summary-round3.json).

## 바꾼 규칙과 직접 근거

- **P3540**: gear_restrict의 비테이블 장착 입력 반환을 false에서 원본 nil로 수정했다. 처음 6개 반환 차이를 실제로 확인한 후 통과했다. 원본은 구문상 유효한 미등록 코드를 잠깐 dk_bag에 쓸 수 있고 다음 bag_load에서 거른다. raw 쓰기·조회 필터를 구분해 비교했으며 native 복구 전체 계약이 다르므로 일부를 유지했다.
- **P3684**: fx_clear를 원본 두 필드(forge_fx/proc_fx) 제거로 이식했다. native smithy_fx는 두 필드의 계산된 뷰다. 기존 탭 변경·다음 작업·완료·퇴장·restore의 빈 대입이 모두 같은 제거 경로를 쓴다. 무효/빈/정상 이펙트의 반환·그 외 필드 보존, 실제 가공→탭 변경을 비교했다.
- **P3686**: 원본 C/Lua %g의 여섯 유효 숫자·짝수 반올림·지수 전환·음수 0·최소 subnormal·최대 double·inf/nan을 직접 비교했다. 입력은 Lua string.pack의 IEEE 8바이트를 보존했다. native 가공 확률 레이블이 이 함수를 사용한다. 정수인 현행 확률표만으로 일반 포맷 일치를 주장하지 않았다.
- **P2946**: 상수 true인 원본 act_visible을 직접 이식하고 native 여관 표시/실행 경로에 연결했다. 알 수 없는 행동/id 등 96입력 반환과 실제 일반 행동 네 버튼을 확인했다. 부모 여관의 보내기·AI 계약으로 판정을 확장하지 않았다.
- **P2981**: source-shaped aff_add_source의 테이블 초기화·알 수 없는 cid·숫자/16진 문자열·0 증감·선택적 chron_aff 부수 효과·g 참조를 비교했다. native 보유 동료 증감이 이 함수를 사용한다. 공개 native aff_add의 owned 제한과 고정 대화 전이 큐는 남아 일부다.

신규 소스 실행기 [gear_r23_round3.mjs](tools/gear_r23_round3.mjs), [직접 시험](project/tests/gear_r23_round3_test.gd), [화면 시험](project/tests/ui_gear_r23_round3_test.gd). 제품 변경은 `project/game/facilities_world_r22.gd`, `project/game/gear_rules_r22.gd`, `project/game/smithy_rules_r22.gd`, `project/game/town_rules_r21.gd`, `project/game/town_world_r21.gd`, `project/ui/facilities_screen_r22.gd`, `project/ui/town_screen_r21.gd`.

## 원본 분기 계측

[계측 결과](verification/parity-r23/gear-coverage-round3.json), [러너](tools/coverage_gear_r23.py). 실제 원본 여섯 실행 묶음에서 **77/77함수 호출**, 행별 명시 진입 합계 **314/320**, 기존 미도달 **43/43곳 도달**. 중첩 함수 범위가 겹치는 진입은 합계에 중복될 수 있다. 조건의 모든 값 조합이나 native 같음 수치가 아니다.

원본 소스는 읽기만 하고 worktree에 계측 사본을 만들었다. probe 없는 실행과 probe 실행의 전체 결과를 그대로 비교했다. Lua pairs의 상회 직업 버튼 순서는 새 Wasmoon마다 달라져 그 단일 테이블의 열거 순서를 두 실행에 똑같이 고정했다. 결과 HTML을 사후 정렬해 맞추지 않았다. 상수 true인 act_visible의 false 거절 진입은 원본을 바꿔 만들지 않았다. 나머지 이미 완료된 함수의 일부 미도달 진입은 이번 승격 근거로 삼지 않았다.

## 실패 기록과 한계

[수정 전](verification/parity-r23/round3-before.log)은 미구현 경계 API 네 guard 실패와 gear_restrict 반환 6차이를 포함한다. 처음 추가한 fixture의 미등록 코드 재조회 차이 1건은 raw/조회 매체 혼동이어서 제품 결함 수에 넣지 않았다. `%g` 초기 입력은 JSON/문자열 변환에서 double 정밀도를 잃거나 음수 0이 사라졌다. Lua IEEE 바이트를 사용한 뒤 전체 입력이 통과했다. 마지막 chron_aff fixture가 뒤의 source 화면 실행에 의해 변한 관찰 배열도 복사해서 격리했다. 초안의 GDScript 정적 has_method 호출·Lua Boolean map 키 직렬화 실패는 fixture 오류이며 통과 검사나 제품 버그 수로 세지 않았다. 실제 원본 숫자·확률·기대 문구를 바꿔 맞추지 않았다.

남은 **37행**은 dk_bag 호스트 읽기/쓰기·예외와 native UID/전체 JSON 저장, 임의 선행 GH 콜백의 전체 합성 ABI, 시제품 삭제 대신 보존하는 이관, HTML 반환과 native Controls, pending/addChat/보내기와 고정 대화/영수증의 차이다. 계측에서 원본 분기를 실행했어도 이 계약을 native에 구현한 것으로 세지 않았다. 원본 호스트·AI 기능 전체 완료에는 이 차이를 해소하는 구현이 추가로 필요하다. 행별 사유는 아래와 ledger에 있다.

## 최종 검사와 보존

[전체 검사](verification/parity-r23/suite-gear-round3/results.json), [서버 npm 로그](verification/parity-r23/suite-gear-round3/npm-test.log), [코드 잠금](verification/parity-r23/suite-gear-round3/code-lock.json), [종료 결과](verification/parity-r23/suite-gear-round3/final-verification.json). 모든 *_test, 필수 integration/export_licenses, 전투 여덟 묶음을 포함한다.

최초 전체 검사에서 장비·전투가 공유하던 oracle.json/round3-oracle.json의 충돌로 전투 두 시험에 Script error가 났다. 장비 fixture를 gear-* 이름으로 격리하고 장비 시험 세 개의 참조를 바꿨다. 전투 두 fixture는 실제 원본 Lua에서 복구했다. 영향을 받은 다섯 시험은 모두 다시 실행해 통과했다. 다른 통과 그룹은 제품 코드가 동일함을 검증해 유지했다. 최초 검사기의 코드 잠금도 시험 참조 변경을 감지해 중단됐으며 이 결과를 최종 성공으로 간주하지 않았다. [실패 로그와 수정 전후 잠금](verification/parity-r23/suite-gear-round3/fixture-collision/), [최종 검증기](tools/finalize_gear_r23_round3.py)가 제품 코드 불변·수정 후 다섯 시험 통과·전체 112그룹의 최신 결과를 검증한다. 예전 gear 출처의 공용 oracle 경로는 최신 ledger에서 gear-* 경로로 바로잡았다.

클라우드는 실제 node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs를 고유 loopback 포트에서 실행했다. 자신이 띄운 서버만 종료했고 npm/임시 파일/모듈은 자기 worktree에 격리했다.

직접 연 이미지는 [대장간 390×844](verification/parity-r23/render-round3/smithy-process-390x844.png), [여관 360×780](verification/parity-r23/render-round3/inn-actions-360x780.png)다. 다섯 등급 확률·가공 버튼·여관 네 행동 버튼과 작은 폭 레이블을 확인했다. 다른 회귀 이미지를 모두 열었다고 주장하지 않는다.

docs·원본 자산·데이터·서버·전투/원정 코드의 시작 manifest 대비 변경 **0개**, 원본 이미지 해시 **96/96 일치**([해시 결과](verification/parity-r23/asset-hashes-round3.json)). Web export·버전 갱신·Git 명령·커밋 없음. 사용자 저장을 읽거나 지우거나 덮어쓰지 않았고 저장 schema는 바꾸지 않았다. Windows root certificate store 진단만 환경 메시지로 제외하고 다른 ERROR/Script error는 실패로 처리했다.

## 이번 재검토 40행

|행|2차 → 3차|이번 처리|근거 또는 남은 이유|
|---|---|---|---|
|P3532|일부 → 일부|대조|dk_bag 채팅 변수 읽기와 native UID 저장/가져오기 매체는 다르다. 문자열 필터 결과만 직접 일치; 호스트 getChatVar 실패/저장 재개 전체 계약은 동일 판정하지 않음. 2차 원본 실행에서 getChatVar 예외는 빈 목록, setChatVar 예외는 호출자 전파임을 관측. native에는 이 호스트 API가 없어 전체 일치는 아님.|
|P3533|일부 → 일부|대조|문자열 직렬화는 일치. native 저장은 world_store의 전체 JSON과 UID를 쓰므로 setChatVar 부작용/저장 매체 전체 계약은 다름. 2차 원본 실행에서 getChatVar 예외는 빈 목록, setChatVar 예외는 호출자 전파임을 관측. native에는 이 호스트 API가 없어 전체 일치는 아님.|
|P3536|일부 → 일부|대조|코드 배열 연산은 일치. native는 UID 및 overflow 보존 경로를 쓰고 알 수 없는 원본 토큰도 이관 기록에 남겨 전체 저장 계약은 다름.|
|P3537|일부 → 일부|대조|첫 동일 코드 제거는 일치. native의 개별 UID 선택·중복 코드 정체성 및 실제 영구 저장 부작용은 원본 dk_bag 계약과 구분해야 함.|
|P3540|일부 → 일부|수정|무효 장착 테이블의 반환 false→nil을 원본처럼 수정. 원본 raw 쓰기와 재조회 필터를 분리해 비교했다. native UID 저장의 부적합 장착 검증/가방 회수 전체 계약은 여전히 다름.|
|P3549|일부 → 일부|대조|가방에 없는 장착 UID의 재장착/다른 소유자에게 이전을 원본처럼 거부하도록 수정. bag/self/other/duplicate·JSON 재개는 대조. 코드 기반 반환·dk_bag 쓰기와 native UID 선택/저장 매체는 다름.|
|P3552|일부 → 일부|대조|JSON 재개 후 UID int/float 차이로 장착품이 가방에 중복 노출되던 wearer를 수정. 0/1999/2000 경계·해제·재개는 대조. 코드 기반 반환/채팅 변수와 native UID 저장은 다름.|
|P3553|일부 → 일부|대조|재개 후 장착품을 미장착으로 오인하는 wearer를 수정. 판매·재시도·JSON 재개는 대조. 원본 코드 선택/반환·채팅 변수 쓰기와 native UID 저장은 다름.|
|P3554|일부 → 일부|대조|재개 후 일반 장착품을 판매 대상으로 읽는 wearer를 수정. 0/1999/2000개 일괄판매·금화·가방·장착/재개는 대조. legacy 보존·코드↔UID 저장은 별도 계약.|
|P3555|일부 → 일부|대조|원본 활성 equip/items 정리와 1회 이관은 일치. 삭제될 시제품을 gear_r22_prototypes에 추가 보관하므로 전체 저장 JSON은 의도적으로 다름(사용자 저장 보존).|
|P3639|일부 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3644|일부 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3647|일부 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3659|일부 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3684|일부 → 같음|수정|fx_return / fx_state / native source effect slots|
|P3686|일부 → 같음|수정|pct (exact IEEE inputs, C %g output) / native rate labels|
|P3687|일부 → 일부|대조|원본 빈 장비/+10/성공/실패 제련 탭 HTML을 수집. native 제련 카드 전체 문자열/반환은 다름.|
|P3689|일부 → 일부|대조|원본 레벨·가공 확률·비용·결과 HTML을 수집. native 탭 전체 반환/아이템 카드/문구 계약은 다름.|
|P3691|일부 → 일부|대조|제련/가공/작업 있음·없음 화면과 실제 native 버튼 검사를 수행. 원본 HTML 반환 및 AI 완료 안내와 native 영수증은 다름.|
|P3693|일부 → 일부|대조|원본 선택 탭 CSS/HTML 헬퍼를 화면 fixture로 실행. native 버튼 반환은 다름.|
|P3701|일부 → 일부|대조|가공·완료·거절/잘못된 인덱스·탭·퇴장 이펙트의 상태를 비교/수정. 원본 sm_work/pend_hard 전체 문구와 native 영수증·UID 저장은 다름.|
|P2826|일부 → 일부|대조|원본은 portrait 함수 부재/문자열 유효성에 따라 HTML 카드 자체를 생략한다. native는 자산 기반 NPC 카드이며 원본 HTML 반환·NPC_G 호스트 문맥과 같은 계약은 아님.|
|P2828|일부 → 일부|대조|구입 규칙·스크롤·품절과 보유한 비매품 표시를 검증. 원본 HTML 전체 문구/필터/반환을 native 화면과 동일 판정하지 않음.|
|P2841|일부 → 일부|대조|새 상점 필드의 서버 저장은 해결. 접두 버튼 전체 메시지·pend_hard/addChat과 native 영수증의 계약 차이는 남음.|
|P2892|일부 → 일부|대조|원본 의뢰 카드 HTML·버튼·진행 표시 반환을 보존한 source fixture는 있음. native 의뢰 카드 전체 반환은 다름.|
|P2896|일부 → 일부|대조|의뢰판 원본 HTML과 native 의뢰판의 전체 문구/버튼/반환을 직접 동일 대조하지 않음. 경제/채우기 비교를 이 로컬 렌더 함수에 전파하지 않음.|
|P2900|일부 → 일부|대조|recruit_cell은 원본 HTML 문자열 헬퍼. native 소개 화면의 레이블/레이아웃 반환과 동일하지 않음.|
|P2901|일부 → 일부|대조|최근 만남·대기 상태 원본 HTML을 수집. native 최근 영입 카드·AI 보내기 안내/잠금은 전체 계약이 다름.|
|P2902|일부 → 일부|대조|원본 보유 동료 역순/도감/최근 표시 HTML을 수집. native 목록의 전체 순서·반환·문구 대조는 남음.|
|P2904|일부 → 일부|대조|원본 빈/1인/30인/자금 부족/대기 소개 탭을 실행. native 경제 규칙과 화면 검사는 통과하나 전체 HTML/AI 대기 계약은 다름.|
|P2907|일부 → 일부|대조|원본 board/recruit/loredana 화면 반환을 수집. native 별도 페이지/잠금 방식과 전체 HTML 반환은 동일하지 않음.|
|P2909|일부 → 일부|대조|원본 탭 버튼 HTML 헬퍼. native 페이지 버튼과 반환 형식/상태 필드가 다름.|
|P2912|일부 → 일부|대조|실제 영입 금화·후보·RNG·레벨·호감은 일치. 원본 pending 첫 만남 지시·addChat의 보내기/실패 안내를 native 고정 대화로 대체하므로 전체 함수 계약은 다름.|
|P2921|일부 → 일부|대조|addChat true/false 양쪽을 원본에서 실행. native에는 이 Risu addChat 콜백이 없어 호스트 전송 반환 계약을 동일 판정하지 않음.|
|P2922|일부 → 일부|대조|수락/거절/포기/갱신/영입의 경제 시험과 새 find/remove 연결은 통과. 원본 접두 버튼 UI·AI pending/연구 전송 계약 전체는 다름.|
|P2946|일부 → 같음|수정|act_visible / native ordinary action controls|
|P2954|일부 → 일부|대조|보유 동료 없음·선택 동료·원본 gd_tier 음수 표시·현재 호감의 내림 표시를 확인/수정. HTML 전체 문구와 원본 AI 대화 동선은 native 고정 대화와 다름.|
|P2961|일부 → 일부|대조|일반 행동의 비용/호감/하루 제한·재개 및 host chat 실패 후 확정은 비교. pending_at/pend_soft/AI 지시·보내기 전체 계약은 native에 없음. act_visible은 정본에서 상수 true여서 73-inn.lua:98의 거절 then은 도달 불가. 이를 인위적으로 원본을 바꿔 실행하지 않았다.|
|P2976|일부 → 일부|대조|원본 일반 여관 addChat 성공/false 콜백을 실행. native 호스트에는 같은 전송 콜백/반환이 없음.|
|P2981|일부 → 일부|수정|source-shaped aff_add_source에서 잘못된 aff 테이블 초기화, 알 수 없는 cid, 16진 문자열, 선택적 chron_aff 호출 순서·동일 g 참조를 직접 비교했고 보유 동료의 실제 native 증감에도 연결했다. native 공개 aff_add의 owned 제한과 대화 전이 큐는 남아 전체 함수 같음으로 세지 않음.|
