# R23-gear — 장비·시설 함수 대조

담당 **77행 전부 검토**, 같음 승격 **31행**, 수정 **16행**, 남음 **46행**. 수정 수는 승격/남음과 겹친다(수정 후 같음 11, 수정했지만 남음 5). 기존 ‘일부/미확인’에서 부모 화면 통과만으로 승격하지 않았다.

전체 프로젝트 검사 **86그룹 / 실패 1그룹·3단언**, 새 대조 **3,325항목 / 실패 0**. 유지 전투 **6,320/6,320판**, 일치 기록 **219,785개**. 이 검사 수치는 아래 클라우드 저장 형식의 미해결 차이를 해소했다는 뜻이 아니다.

**완료 기준 미달:** 전체 검사 실패 0을 충족하지 못했다. 실패 그룹과 실제 단언은 suite/results.json에 보존했다. 서버 수정 금지 범위 안에서 새 상점 필드를 지원시킬 수 없어 이 통합 과제를 남긴다.

- 행별 기계 판독 근거: [gear.json](verification/parity-r23/gear.json). 이전 id·상태·원본 위치·판정 사유를 그대로 포함.
- 검사 명령·로그: [tools/gear_r23_verify.py](tools/gear_r23_verify.py), [suite/results.json](verification/parity-r23/suite/results.json).
- 원본 직접 실행: `node tools/gear_r23_oracle.mjs`, `node tools/gear_r23_hooks.mjs`, `node tools/gear_r23_facilities.mjs`. Lua는 Wasmoon/lua_sim에서 실행했고 원본 파일은 수정하지 않았다. 채팅 변수/렌더링/전송 같은 호스트 경계만 fixture로 격리했다. 성적 장면·행동은 옮기지 않았다.

## 고친 동작

파서가 끝 개행을 코드 일부로 잘못 받던 것을 Lua와 맞췄다. `gear_roll(..., false, ...)`는 레벨 보정을 생략하며, 소수 제련 단계 비용을 정수로 잘라 계산하지 않는다. 비정상 equip 표의 읽기를 보호했고, 빈/알 수 없는 아이콘 입력은 원본처럼 nil로 돌려준다. 파티 호감은 중복 출전 id를 한 번만 더하고 실제 상승량 표를 반환한다. 원본의 호감 반올림/표시와 일반 여관용 gd_tier를 분리했다. 의뢰 조회/첫 일치 제거를 길드 거절 동선에 연결했고 한국어/영어 UI/영어 문맥 제목을 직접 비교했다.

상점은 거래 전 피에트로 호감, 영구 거래 횟수, 원본 RNG, 덤 99개 상한, 메시지 및 재로드 후 다음 거래를 따르도록 연결했다. 보유한 비매품은 상점 목록에만 표시하며 구입 버튼을 만들지 않는다. 대장간을 나갈 때 결과 이펙트/선택 탭을 지워 원본과 맞췄다. 일반 여관의 현재 호감은 원본처럼 내림 표시한다(99.95 → 99).

수정 전 재현은 `before.json`(264실패 중 누락 API/같은 원인의 반복을 포함), `aff-party-before.json`(5실패), `aff-fmt-before.json`(1실패), `facility-before.json`(1실패), `inn-tier-before.json`(2실패), `inn-display-before.json`(2실패), `titles-before.json`(3실패), `icons-before.json`(2실패)에 남겼다. 첫 검증 과정의 빈 Lua 표 → JSON 배열 직렬화와 GDScript StringName 키 문제는 시험 입력에서 정규화했으며, 이를 제품 결함 수로 세지 않았다. 원본 수치/기대값을 바꿔 맞춘 항목은 없다.

## 남은 차이와 저장 보존

**클라우드 통합이 필요하다.** 실제 새 상점 저장을 보호된 서버 validator에 넣으면 `items.charm_potion`을 거부하고, 해당 값이 없는 거래 저장은 `commerce.pietro_buys`를 거부한다. [cloud-boundary.json](verification/parity-r23/cloud-boundary.json)에 기록했다. 두 필드를 제거한 복사본은 원인 진단용으로만 사용했고, 사용자 저장/실제 업로드에서 제거하지 않았다. [작업 지시서](../r21-gear-brief.md)의 “금지: 전투 파일, 원정(expedition_*), 서버, 대사 데이터.”에 따라 서버를 수정하지 않았다. 새 상점 저장의 클라우드 호환을 완료했다고 보고하지 않는다.

기존 UID·legacy RNG·코드 공유 강화·overflow·시제품 보관 이관은 유지했다. 원본 dk_bag 채팅 변수와 native 전체 JSON/UID 저장의 차이는 별도 계약으로 남겼다. 4개 GH 래퍼의 선행 콜백 분기는 새 독립 fixture에서 직접 관측하지 않아 승격하지 않았다. 원본 HTML 반환·AI pending 지시·Risu addChat/보내기 계약과 native 화면/고정 대화/영수증은 그대로 ‘일부’다. 30인 JSON 대화를 원본 AI 대화와 같음 처리하지 않았다.

로컬 클라우드 서버는 지정 `server/abyss-save/test/serve.mjs`를 사용했다. 이미 사용 중인 8787 프로세스는 건드리지 않고 `node -r ./tools/gear_r23_cloud_port.cjs server/abyss-save/test/serve.mjs`로 18787에 격리했다. `ABYSS_NODE_MODULES`는 `../r21-d-town/server/abyss-save`, TEMP/TMP/TMPDIR는 이 worktree의 `.p6tmp`로 두었다. Miniflare는 기존 r21-d-town 의존성을 읽기만 했다. 보관 계정 시험은 기존 godot-r14 러너로 같은 실제 Worker/D1에 새 fixture를 만들어 재실행했다. 시험 서버는 검사 후 종료했다. Windows root certificate store 진단은 기존 검증 도구와 동일하게 제외했다.

직접 연 새 화면: `verification/parity-r23/render/shop-bonus-360x780.png`, `shop-bonus-390x844.png`. 390 화면에서 덤 이름·보유 수·구입 버튼 부재를 확인했다. 나머지 회귀 화면은 자동 레이아웃/입력 시험 결과이며 전부 직접 열었다고 주장하지 않는다.

금지된 기존 파일 변경 **0개**. Web export·docs·서버·전투·원정·대사 데이터·원본 초상/픽셀 파일을 수정하지 않았고 Git 명령/커밋을 실행하지 않았다. 바뀐 기존 파일은 [summary.json](verification/parity-r23/summary.json)에 있다.

## 행별 결과

|행|이전 → 현재|처리|근거 또는 남은 이유|
|---|---|---|---|
|P3508|일부 → 같음|대조|project/tests/gear_r23_test.gd::catalog|
|P3514|미확인 → 같음|대조|project/tests/gear_r23_test.gd::catalog|
|P3515|미확인 → 같음|수정|project/tests/gear_r23_test.gd::icons|
|P3522|미확인 → 같음|수정|project/tests/gear_r23_test.gd::parse|
|P3524|미확인 → 같음|수정|project/tests/gear_r23_test.gd::roll|
|P3532|일부 → 일부|대조|dk_bag 채팅 변수 읽기와 native UID 저장/가져오기 매체는 다르다. 문자열 필터 결과만 직접 일치; 호스트 getChatVar 실패/저장 재개 전체 계약은 동일 판정하지 않음.|
|P3533|일부 → 일부|대조|문자열 직렬화는 일치. native 저장은 world_store의 전체 JSON과 UID를 쓰므로 setChatVar 부작용/저장 매체 전체 계약은 다름.|
|P3536|일부 → 일부|대조|코드 배열 연산은 일치. native는 UID 및 overflow 보존 경로를 쓰고 알 수 없는 원본 토큰도 이관 기록에 남겨 전체 저장 계약은 다름.|
|P3537|일부 → 일부|대조|첫 동일 코드 제거는 일치. native의 개별 UID 선택·중복 코드 정체성 및 실제 영구 저장 부작용은 원본 dk_bag 계약과 구분해야 함.|
|P3540|일부 → 일부|대조|코드 어댑터의 재배치/가방 가득 참 결과는 일치. 실제 native 저장 검증은 부적합 장착을 거부하는 경로도 있어 전 경로 자동 회수와 동일 판정하지 않음.|
|P3544|미확인 → 같음|수정|project/tests/gear_r23_test.gd::cost|
|P3549|일부 → 일부|대조|코드 어댑터 상태·가방 반환은 일치. native equip은 UID 및 이미 다른 사람이 착용한 물건의 이동도 지원하므로 원본의 가방 소유 조건과 전체 계약이 다름.|
|P3552|일부 → 일부|대조|코드 어댑터의 빈 슬롯/가득 찬 가방 및 실제 native 2000개 한도 시험은 통과. UID↔코드 영구 저장·오래된 장비 경로는 별도 계약.|
|P3553|일부 → 일부|대조|코드 어댑터의 판매 금화·제거·중복 재시도는 일치. 실제 native UID 선택과 저장 부작용 전체를 코드 기반 반환과 같음으로 세지 않음.|
|P3554|일부 → 일부|대조|코드 어댑터의 common 집계·가방 보존은 일치. native UID/legacy RNG 장비의 일괄판매 전체 경로는 별도 계약.|
|P3555|일부 → 일부|대조|원본 활성 equip/items 정리와 1회 이관은 일치. 삭제될 시제품을 gear_r22_prototypes에 추가 보관하므로 전체 저장 JSON은 의도적으로 다름(사용자 저장 보존).|
|P3566|일부 → 같음|수정|project/tests/gear_r23_test.gd::eq_of|
|P3567|일부 → 같음|수정|project/tests/gear_r23_test.gd::refresh|
|P3571|미확인 → 같음|대조|project/tests/gear_r23_hooks_test.gd::gear_init|
|P3599|미확인 → 같음|대조|project/tests/gear_r23_hooks_test.gd::gear_dotchain|
|P3603|미확인 → 같음|대조|project/tests/gear_r23_hooks_test.gd::gear_echo|
|P3605|미확인 → 같음|대조|project/tests/gear_r23_hooks_test.gd::gear_dot|
|P3639|미확인 → 일부|대조|장비 본체 상태/콜백/RNG 및 전투 대조는 통과. 원본 o_damaged가 존재할 때의 선행 GH 콜백 분기를 새 독립 fixture에서 직접 관측하지 않았으므로 승격하지 않음.|
|P3644|미확인 → 일부|대조|e<5 조기 반환을 새 fixture로 확인. 원본 o_attacked 선행 GH 콜백의 전체 반환/순서 분기는 독립 관측 증거가 남음.|
|P3647|미확인 → 일부|대조|적 차례 조기 반환·만료·adv 및 저장 상태 재개는 확인. 원본 o_turn_end 선행 GH 콜백 분기는 독립 관측 증거가 남음.|
|P3659|미확인 → 일부|대조|고갈/비고갈·MP 최대/부족 경계는 일치. 원본 o_aa 선행 GH 콜백 분기를 독립 fixture에서 직접 관측하지 않았음.|
|P3666|일부 → 같음|대조|project/tests/gear_r23_test.gd::process_fallback + facilities_r22 all ten classes|
|P3667|미확인 → 같음|대조|project/tests/gear_r23_test.gd::party_classes|
|P3670|미확인 → 같음|대조|project/tests/gear_r23_test.gd::drop_boundaries + gear_boundary_r22 drop|
|P3674|일부 → 같음|대조|project/tests/gear_r23_test.gd::process_fallback + gear_r22 process|
|P3677|일부 → 같음|대조|project/tests/gear_r23_test.gd::labels|
|P3678|일부 → 같음|대조|project/tests/gear_r23_test.gd::legend_context|
|P3680|일부 → 같음|대조|project/tests/gear_r23_test.gd::smithy_list / native_smithy_list|
|P3681|미확인 → 같음|대조|project/tests/gear_r23_test.gd::smithy_list / native_smithy_list|
|P3683|일부 → 일부|대조|빈/1/8/9개 작업의 완료·잠금 여부는 native와 비교. 원본 {forge,proc} 작업 표 반환과 native 단일 작업 배열/영수증 표현은 다름.|
|P3684|미확인 → 일부|수정|탭/완료/퇴장 시 이펙트 제거를 비교하고 퇴장 누락을 수정. 원본 forge_fx/proc_fx 두 필드와 native smithy_fx 한 필드 전체 계약은 구분.|
|P3686|미확인 → 일부|대조|원본 %g 확률 문자열은 화면 fixture에 보존. native str 기반 확률 표시의 모든 정밀도/지수 표기 계약은 직접 비교하지 않음.|
|P3687|일부 → 일부|대조|원본 빈 장비/+10/성공/실패 제련 탭 HTML을 수집. native 제련 카드 전체 문자열/반환은 다름.|
|P3689|일부 → 일부|대조|원본 레벨·가공 확률·비용·결과 HTML을 수집. native 탭 전체 반환/아이템 카드/문구 계약은 다름.|
|P3691|일부 → 일부|대조|제련/가공/작업 있음·없음 화면과 실제 native 버튼 검사를 수행. 원본 HTML 반환 및 AI 완료 안내와 native 영수증은 다름.|
|P3693|미확인 → 일부|대조|원본 선택 탭 CSS/HTML 헬퍼를 화면 fixture로 실행. native 버튼 반환은 다름.|
|P3697|일부 → 일부|대조|원본 제련 성공/실패·가공 목록을 0/1/8/9개로 실행하고 AI 지시를 보존. native는 전체 영수증을 보여 주며 동일한 영어 AI 작업 지시 문자열을 보내지 않음.|
|P3698|미확인 → 일부|대조|원본 8개 초과 목록의 and N more 절단 분기를 직접 실행. native 영수증은 전 항목을 보존/표시하여 같은 절단 계약이 아님.|
|P3699|미확인 → 일부|대조|원본 제련 성공/실패 영어 지시 콜백을 실행. native 영수증 문자열/호스트 AI 전송 계약은 다름.|
|P3700|미확인 → 일부|대조|원본 가공 코드→영어 이름 지시 콜백을 실행. native 영수증 문자열/호스트 AI 전송 계약은 다름.|
|P3701|일부 → 일부|수정|가공·완료·거절/잘못된 인덱스·탭·퇴장 이펙트의 상태를 비교/수정. 원본 sm_work/pend_hard 전체 문구와 native 영수증·UID 저장은 다름.|
|P2826|미확인 → 일부|대조|원본은 portrait 함수 부재/문자열 유효성에 따라 HTML 카드 자체를 생략한다. native는 자산 기반 NPC 카드이며 원본 HTML 반환·NPC_G 호스트 문맥과 같은 계약은 아님.|
|P2828|일부 → 일부|대조|구입 규칙·스크롤·품절과 보유한 비매품 표시를 검증. 원본 HTML 전체 문구/필터/반환을 native 화면과 동일 판정하지 않음.|
|P2836|일부 → 일부|수정|거래 전 호감·횟수·덤·상한·메시지 및 로컬 재개는 일치하도록 수정. 보호된 서버는 items.charm_potion 및 commerce.pietro_buys를 거부한다(cloud-boundary.json). 서버 수정 금지 범위의 통합 과제.|
|P2841|일부 → 일부|수정|경제 결과와 후처리 연결은 수정/검증. 원본 접두 버튼 상태/전체 UI 메시지·pend_hard/addChat 계약은 native 버튼/영수증과 다르며 새 상점 필드는 서버 허용 목록 확장이 필요.|
|P2870|미확인 → 같음|수정|project/tests/gear_r23_facilities_test.gd::source Korean / English UI quest title|
|P2871|미확인 → 같음|수정|project/tests/gear_r23_facilities_test.gd::source English context quest title|
|P2872|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_find / guild_find_missing|
|P2873|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_remove / guild_remove_state / guild_remove_missing|
|P2877|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_base|
|P2886|일부 → 같음|대조|project/tests/gear_r23_test.gd::guild_fill / guild_fill_counters|
|P2890|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_candidates + recruit_r21 exact candidates|
|P2891|미확인 → 같음|수정|project/tests/gear_r23_test.gd::guild_tier + source gd_tier is used by ordinary inn|
|P2892|미확인 → 일부|대조|원본 의뢰 카드 HTML·버튼·진행 표시 반환을 보존한 source fixture는 있음. native 의뢰 카드 전체 반환은 다름.|
|P2896|미확인 → 일부|대조|의뢰판 원본 HTML과 native 의뢰판의 전체 문구/버튼/반환을 직접 동일 대조하지 않음. 경제/채우기 비교를 이 로컬 렌더 함수에 전파하지 않음.|
|P2900|미확인 → 일부|대조|recruit_cell은 원본 HTML 문자열 헬퍼. native 소개 화면의 레이블/레이아웃 반환과 동일하지 않음.|
|P2901|미확인 → 일부|대조|최근 만남·대기 상태 원본 HTML을 수집. native 최근 영입 카드·AI 보내기 안내/잠금은 전체 계약이 다름.|
|P2902|미확인 → 일부|대조|원본 보유 동료 역순/도감/최근 표시 HTML을 수집. native 목록의 전체 순서·반환·문구 대조는 남음.|
|P2904|일부 → 일부|대조|원본 빈/1인/30인/자금 부족/대기 소개 탭을 실행. native 경제 규칙과 화면 검사는 통과하나 전체 HTML/AI 대기 계약은 다름.|
|P2907|미확인 → 일부|대조|원본 board/recruit/loredana 화면 반환을 수집. native 별도 페이지/잠금 방식과 전체 HTML 반환은 동일하지 않음.|
|P2909|미확인 → 일부|대조|원본 탭 버튼 HTML 헬퍼. native 페이지 버튼과 반환 형식/상태 필드가 다름.|
|P2912|미확인 → 일부|대조|실제 영입 금화·후보·RNG·레벨·호감은 일치. 원본 pending 첫 만남 지시·addChat의 보내기/실패 안내를 native 고정 대화로 대체하므로 전체 함수 계약은 다름.|
|P2921|일부 → 일부|대조|addChat true/false 양쪽을 원본에서 실행. native에는 이 Risu addChat 콜백이 없어 호스트 전송 반환 계약을 동일 판정하지 않음.|
|P2922|일부 → 일부|대조|수락/거절/포기/갱신/영입의 경제 시험과 새 find/remove 연결은 통과. 원본 접두 버튼 UI·AI pending/연구 전송 계약 전체는 다름.|
|P2946|미확인 → 일부|대조|원본 act_visible은 항상 true이며 native 일반 행동 4개가 존재한다. native 대화 선택/잠금과 원본 표시 함수의 직접 반환 대응 증거는 남음.|
|P2954|일부 → 일부|수정|보유 동료 없음·선택 동료·원본 gd_tier 음수 표시·현재 호감의 내림 표시를 확인/수정. HTML 전체 문구와 원본 AI 대화 동선은 native 고정 대화와 다름.|
|P2961|일부 → 일부|대조|일반 행동의 비용/호감/하루 제한·재개 및 host chat 실패 후 확정은 비교. pending_at/pend_soft/AI 지시·보내기 전체 계약은 native에 없음.|
|P2976|미확인 → 일부|대조|원본 일반 여관 addChat 성공/false 콜백을 실행. native 호스트에는 같은 전송 콜백/반환이 없음.|
|P2979|미확인 → 같음|대조|project/tests/gear_r23_test.gd::aff_r2|
|P2981|일부 → 일부|대조|영입한 동료의 호감 증감은 직접/기존 Lua fixture와 일치. 원본은 알 수 없는 cid도 G.aff에 기록하고 chron_aff를 부르지만 native는 owned만 허용하고 고정 대화 전이 큐를 추가하므로 전체 계약이 다름.|
|P2984|일부 → 같음|수정|project/tests/gear_r23_test.gd::aff_party_delta / aff_party_state + dialogue_player_r21 synergy|
|P2985|미확인 → 같음|수정|project/tests/gear_r23_test.gd::aff_fmt / aff_fmt_invalid|
