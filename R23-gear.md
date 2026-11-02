# R23-gear — 2차 장비·시설 함수 대조

남은 **46행 전부 재검토**, 이번 같음 승격 **6행**, 수정 **11행**(새 수정 표기 9행·기존 수정행 추가 해결 2행). 누적 **77행 중 같음 37행·수정 25행·남음 40행**. 수정 수는 상태와 겹친다. 부모 검사 통과를 자식 함수의 같음 근거로 쓰지 않았다.

전체 Godot **89그룹 / 실패 0**, 서버 `npm test` **12,932항목 / 실패 0**. R23 직접 대조 **11,010항목 / 실패 0**(이번 추가 7,685, 서버 신규 259 별도). 전투 **6,320/6,320판**, 행동 기록 **219,785개** 일치. 전체 검사 실패 0을 달성했으나 기능 대조표의 남은 40행까지 완료한 것은 아니다.

- 행별 원본 위치·이전 판정·근거·남은 이유: [gear.json](verification/parity-r23/gear.json). [1차 상태](verification/parity-r23/round1-gear.json)와 [1차 보고](verification/parity-r23/round1-report.md)는 보존했다.
- 전체 명령·결과: [suite/results.json](verification/parity-r23/suite/results.json), [npm-test.log](verification/parity-r23/npm-test.log), [검사 러너](tools/gear_r23_verify.py).
- 원본 직접 실행: 기존 세 oracle 및 [round2](tools/gear_r23_round2.mjs), [선행 콜백](tools/gear_r23_predecessors.mjs). 원본 파일을 수정하지 않고 Wasmoon/lua_sim에서 실행했다. work_of/pct/work_note/cut에는 관찰용 export만 붙였다.

## 이번 수정

서버는 최신 지시서의 예외대로 `validate.js`에서 **items.charm_potion**(선택 정수 0~99), **commerce_r21.pietro_buys**(선택 정수 0~MAX_SAFE_INTEGER)만 허용했다. 옛 저장은 필드 없이 통과한다. 임의 아이템/commerce 키, 객체·문자열·소수·음수·범위 초과·비유한 수, 잘못된 장비 참조를 거부한다. 다른 위치의 아이템 허용 목록과 보안 로직은 변경하지 않았다. package.json에는 신규 시험 실행만 연결했다.

실제 상점 저장을 변경 없이 POST·PUT·GET하고 변조 거절 뒤 내용·revision 보존을 확인했다. **36 HTTP 사례·259단언** 통과. [수정 전](verification/parity-r23/cloud-boundary-before-round2.json)의 두 거부 경로가 [수정 후](verification/parity-r23/cloud-boundary.json) 모두 통과한다. 실제 사용자 저장은 제거·덮어쓰지 않았다. 덤을 보유한 실제 native 전투/재개 저장도 서버에 왕복했다. 비전투 보너스가 전투 inventory로 섞이는 실패 2단언을 재현해 시설 facade의 최소 연결로 분리하고 record_battle 때 계정 수량을 보존했다. 전투·원정 파일과 서버 전투 허용 목록은 수정하지 않았다.

JSON 재개 후 UID가 float가 되면 기존 Array.has(int)가 장착 참조를 찾지 못해 가방/판매 대상에 장착품이 섞이는 문제를 찾았다. 허용된 facilities_world_r22에서 wearer를 숫자 비교로 고쳤다. 가방에 없는 장착 UID의 재장착·다른 소유자에게 이전도 원본처럼 거부한다. **38개 원본 거래 fixture**에서 가방·장착·금화·재시도·실제 JSON 재개, 0/1999/2000 한도·중복 코드를 대조했다. UID·legacy RNG·overflow·시제품 보관 이관은 유지했다.

대장간 work_of/work_note/cut/제련·가공 콜백을 이식해 실제 완료 영수증 source_note에 연결했다. 원본 **1,030종 전부**, 성공/실패·0/1/10 단계, 빈 목록·1/7/8/9/20개·혼합 작업·알 수 없는 코드를 비교했다. work_of는 입력 표 정체성을 유지한다. 전체 영수증은 보존하고 영어 요약에만 원본의 8개 제한을 적용한다. 이 반환 일치를 부모 H.sm의 AI 전송 완료로 확대하지 않았다.

네 선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 실제 원본 래퍼에서 호출했다. **24경계·72단언**에서 이후 native 장비 효과/호출 순서를 대조했다. native는 기록한 선행 콜백 직후 상태부터 실행하므로 임의 GH 콜백 ABI 전체를 검증한 것은 아니다.

수정 전 증거는 [round2-before.log](verification/parity-r23/round2-before.log)와 보존된 1차 결과에 있다. 빈 Lua 표의 JSON 배열 정규화·시험용 일괄판매 호출명 수정은 제품 결함 수에 넣지 않았다. 원본 수치/기대값을 바꿔 맞추지 않았다.

## 남은 차이와 검사 환경

남은 40행의 이유는 아래 표에 기록했다. dk_bag 채팅 변수와 UID 전체 JSON 저장, HTML 반환과 native 화면, AI pending/addChat/보내기와 고정 대화·영수증의 계약 차이가 남는다. 알 수 없는 cid의 G.aff/chron_aff 부작용도 native 보유 동료 제한과 다르다. 일반 %g 정밀도/지수 표기, 영입 역순 목록·최근 만남/대기 안내도 미완료다. 한국어/영어·0/1/30인 원본 화면 24개, 호스트 예외/호감 콜백을 round2-oracle.json에 보존했으며 원본 관찰만으로 native 같음을 세지 않았다.

직접 연 화면은 [shop-bonus-390x844.png](verification/parity-r23/render/shop-bonus-390x844.png): 덤 이름·보유 수와 구입 버튼 부재를 확인했다. 다른 회귀 이미지를 모두 직접 열었다고 주장하지 않는다.

지정 test/serve.mjs를 18787에 격리해 클라우드 시험을 실행했다. 기존 r21-d-town 의존성은 읽기만 했으며 npm용 모듈은 자기 worktree의 node_modules에 복사했다. TEMP/TMP/TMPDIR도 자기 worktree 안이다. npm 첫 실행은 로컬 wrangler 모듈 부재로 중단되어 복사 후 전체를 재실행했다. 검사 후 자신이 띄운 서버를 종료했다. Windows 인증서 저장소 진단은 기존 러너와 같은 환경 예외이며 assertion/script 오류는 제외하지 않았다.

변경한 기존 파일: [summary.json](verification/parity-r23/summary.json). 금지된 기존 파일 변경 **0개**. 원본 자산 **96/96개 해시 유지**([직접 검사](verification/parity-r23/asset-hashes-round2.json)). Web export·docs·전투·원정·대사 데이터·원본 초상/픽셀을 수정하지 않았고 Git 명령/커밋을 실행하지 않았다.

## 행별 결과

|행|최초 → 현재|처리|근거 또는 남은 이유|
|---|---|---|---|
|P3508|일부 → 같음|대조|project/tests/gear_r23_test.gd::catalog|
|P3514|미확인 → 같음|대조|project/tests/gear_r23_test.gd::catalog|
|P3515|미확인 → 같음|수정|project/tests/gear_r23_test.gd::icons|
|P3522|미확인 → 같음|수정|project/tests/gear_r23_test.gd::parse|
|P3524|미확인 → 같음|수정|project/tests/gear_r23_test.gd::roll|
|P3532|일부 → 일부|대조|dk_bag 채팅 변수 읽기와 native UID 저장/가져오기 매체는 다르다. 문자열 필터 결과만 직접 일치; 호스트 getChatVar 실패/저장 재개 전체 계약은 동일 판정하지 않음. 2차 원본 실행에서 getChatVar 예외는 빈 목록, setChatVar 예외는 호출자 전파임을 관측. native에는 이 호스트 API가 없어 전체 일치는 아님.|
|P3533|일부 → 일부|대조|문자열 직렬화는 일치. native 저장은 world_store의 전체 JSON과 UID를 쓰므로 setChatVar 부작용/저장 매체 전체 계약은 다름. 2차 원본 실행에서 getChatVar 예외는 빈 목록, setChatVar 예외는 호출자 전파임을 관측. native에는 이 호스트 API가 없어 전체 일치는 아님.|
|P3536|일부 → 일부|대조|코드 배열 연산은 일치. native는 UID 및 overflow 보존 경로를 쓰고 알 수 없는 원본 토큰도 이관 기록에 남겨 전체 저장 계약은 다름.|
|P3537|일부 → 일부|대조|첫 동일 코드 제거는 일치. native의 개별 UID 선택·중복 코드 정체성 및 실제 영구 저장 부작용은 원본 dk_bag 계약과 구분해야 함.|
|P3540|일부 → 일부|대조|코드 어댑터의 재배치/가방 가득 참 결과는 일치. 실제 native 저장 검증은 부적합 장착을 거부하는 경로도 있어 전 경로 자동 회수와 동일 판정하지 않음.|
|P3544|미확인 → 같음|수정|project/tests/gear_r23_test.gd::cost|
|P3549|일부 → 일부|수정|가방에 없는 장착 UID의 재장착/다른 소유자에게 이전을 원본처럼 거부하도록 수정. bag/self/other/duplicate·JSON 재개는 대조. 코드 기반 반환·dk_bag 쓰기와 native UID 선택/저장 매체는 다름.|
|P3552|일부 → 일부|수정|JSON 재개 후 UID int/float 차이로 장착품이 가방에 중복 노출되던 wearer를 수정. 0/1999/2000 경계·해제·재개는 대조. 코드 기반 반환/채팅 변수와 native UID 저장은 다름.|
|P3553|일부 → 일부|수정|재개 후 장착품을 미장착으로 오인하는 wearer를 수정. 판매·재시도·JSON 재개는 대조. 원본 코드 선택/반환·채팅 변수 쓰기와 native UID 저장은 다름.|
|P3554|일부 → 일부|수정|재개 후 일반 장착품을 판매 대상으로 읽는 wearer를 수정. 0/1999/2000개 일괄판매·금화·가방·장착/재개는 대조. legacy 보존·코드↔UID 저장은 별도 계약.|
|P3555|일부 → 일부|대조|원본 활성 equip/items 정리와 1회 이관은 일치. 삭제될 시제품을 gear_r22_prototypes에 추가 보관하므로 전체 저장 JSON은 의도적으로 다름(사용자 저장 보존).|
|P3566|일부 → 같음|수정|project/tests/gear_r23_test.gd::eq_of|
|P3567|일부 → 같음|수정|project/tests/gear_r23_test.gd::refresh|
|P3571|미확인 → 같음|대조|project/tests/gear_hooks_r22_test.gd|
|P3599|미확인 → 같음|대조|project/tests/gear_hooks_r22_test.gd|
|P3603|미확인 → 같음|대조|project/tests/gear_hooks_r22_test.gd|
|P3605|미확인 → 같음|대조|project/tests/gear_hooks_r22_test.gd|
|P3639|미확인 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3644|미확인 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3647|미확인 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3659|미확인 → 일부|대조|선행 GH 콜백의 무변경/상태 변경/사망·고갈 분기를 원본 래퍼에서 실제 호출하고 경계 이후 native 장비 효과/호출 순서를 대조했다. native 실행은 기록한 선행 콜백 직후부터 시작하므로 임의 GH 콜백 ABI/전체 소유자 합성 계약을 같음으로 세지 않음.|
|P3666|일부 → 같음|대조|project/tests/gear_r23_test.gd::process_fallback + facilities_r22 all ten classes|
|P3667|미확인 → 같음|대조|project/tests/gear_r23_test.gd::party_classes|
|P3670|미확인 → 같음|대조|project/tests/gear_r23_test.gd::drop_boundaries + gear_boundary_r22 drop|
|P3674|일부 → 같음|대조|project/tests/gear_r23_test.gd::process_fallback + gear_r22 process|
|P3677|일부 → 같음|대조|project/tests/gear_r23_test.gd::labels|
|P3678|일부 → 같음|대조|project/tests/gear_r23_test.gd::legend_context|
|P3680|일부 → 같음|대조|project/tests/gear_r23_test.gd::smithy_list / native_smithy_list|
|P3681|미확인 → 같음|대조|project/tests/gear_r23_test.gd::smithy_list / native_smithy_list|
|P3683|일부 → 같음|수정|project/tests/gear_r23_round2_test.gd::work_of|
|P3684|미확인 → 일부|수정|탭/완료/퇴장 시 이펙트 제거를 비교하고 퇴장 누락을 수정. 원본 forge_fx/proc_fx 두 필드와 native smithy_fx 한 필드 전체 계약은 구분.|
|P3686|미확인 → 일부|대조|원본 %g 확률 문자열은 화면 fixture에 보존. native str 기반 확률 표시의 모든 정밀도/지수 표기 계약은 직접 비교하지 않음.|
|P3687|일부 → 일부|대조|원본 빈 장비/+10/성공/실패 제련 탭 HTML을 수집. native 제련 카드 전체 문자열/반환은 다름.|
|P3689|일부 → 일부|대조|원본 레벨·가공 확률·비용·결과 HTML을 수집. native 탭 전체 반환/아이템 카드/문구 계약은 다름.|
|P3691|일부 → 일부|대조|제련/가공/작업 있음·없음 화면과 실제 native 버튼 검사를 수행. 원본 HTML 반환 및 AI 완료 안내와 native 영수증은 다름.|
|P3693|미확인 → 일부|대조|원본 선택 탭 CSS/HTML 헬퍼를 화면 fixture로 실행. native 버튼 반환은 다름.|
|P3697|일부 → 같음|수정|project/tests/gear_r23_round2_test.gd::work_note|
|P3698|미확인 → 같음|수정|project/tests/gear_r23_round2_test.gd::work_cut|
|P3699|미확인 → 같음|수정|project/tests/gear_r23_round2_test.gd::work_forge_note through work_note|
|P3700|미확인 → 같음|수정|project/tests/gear_r23_round2_test.gd::work_process_note / work_gear_label|
|P3701|일부 → 일부|수정|가공·완료·거절/잘못된 인덱스·탭·퇴장 이펙트의 상태를 비교/수정. 원본 sm_work/pend_hard 전체 문구와 native 영수증·UID 저장은 다름.|
|P2826|미확인 → 일부|대조|원본은 portrait 함수 부재/문자열 유효성에 따라 HTML 카드 자체를 생략한다. native는 자산 기반 NPC 카드이며 원본 HTML 반환·NPC_G 호스트 문맥과 같은 계약은 아님.|
|P2828|일부 → 일부|대조|구입 규칙·스크롤·품절과 보유한 비매품 표시를 검증. 원본 HTML 전체 문구/필터/반환을 native 화면과 동일 판정하지 않음.|
|P2836|일부 → 같음|수정|project/tests/gear_r23_bonus_resume_test.gd|
|P2841|일부 → 일부|수정|새 상점 필드의 서버 저장은 해결. 접두 버튼 전체 메시지·pend_hard/addChat과 native 영수증의 계약 차이는 남음.|
|P2870|미확인 → 같음|수정|project/tests/gear_r23_facilities_test.gd::source Korean / English UI quest title|
|P2871|미확인 → 같음|수정|project/tests/gear_r23_facilities_test.gd::source English context quest title|
|P2872|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_find / guild_find_missing|
|P2873|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_remove / guild_remove_state / guild_remove_missing|
|P2877|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_base|
|P2886|일부 → 같음|대조|project/tests/gear_r23_test.gd::guild_fill / guild_fill_counters|
|P2890|미확인 → 같음|대조|project/tests/gear_r23_test.gd::guild_candidates + recruit_r21 exact candidates|
|P2891|미확인 → 같음|수정|project/tests/ui_gear_r23_test.gd::source gd_tier is used by ordinary inn|
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
