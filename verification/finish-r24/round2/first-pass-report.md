# FINISH-R24

화면 신고 2건 수정. 전체 144그룹 통과·실패 0. 원본 전투 6,320/6,320판·219,785기록 일치. 메뉴 스모크의 언어·자리표시자 0건. **고정 대사 영어 미지원 14,216개 때문에 전체 언어 0건 완료 기준은 미달이다.**

잔여 80행 재검토: 같음 승격 8행, 이번 수정 근거 17행(승격과 중복), 남음 72행(전투 이관 15 포함). **원본 기능 전체 일치까지 완료한 것은 아니다.** 남은 실제 화면/입력/저장 차이는 아래와 각 JSON의 `finish`에 기록했다.

| 대조표 | 처리 | 같음 승격 | 수정 근거 | 남음 | 전투 이관(남음에 포함) |
|---|---:|---:|---:|---:|---:|
| expe | 31 | 0 | 2 | 31 | 8 |
| gear | 14 | 0 | 2 | 14 | 4 |
| ui | 35 | 8 | 13 | 27 | 3 |

연대기는 원본처럼 영어 사실을 저장하되, 옛 list/queue를 삭제·재작성하지 않고 표시 때 한국어/영어를 고른다. 첫 만남·길드 영입·의뢰·레벨·층/구역 보스·퇴각/실패·호감·전설 장비 사건을 처리한다. 페르소나 이름은 표시 경로에서 실제 이름으로 치환하며 빈 이름/옛 `{{user}}`는 당신/You로 표시한다. 내부 원본 호환 helper와 저장 문자열은 유지했다.

메뉴/패널 스모크의 한영 206개 상태·19,258개 문자열, 데이터 63개 파일·75,762개 문자열과 UI 스크립트를 스캔했다. 데이터 안 원본 `{{user}}` 계약은 보존하고 표시에서 치환한다. 계정 코드·PIN·사용자 자유 입력은 번역하지 않는다. 스모크 스캔은 명시된 fixture 상태를 덮는다. 별도 authored-language-audit.json에서 기존 여관/응답/탐색/관계 고정 대사 14,216개 표시 필드를 실제 English 표시 함수로 검사했고 14,216개에 한국어가 남았다. 이 문구의 영어 정본/번역 묶음은 없으며, 원문을 지우거나 임의의 영어 요약으로 바꾸지 않았다. 따라서 전 데이터 언어 결함 0건으로 보고하지 않는다.

새 보상은 가방이 차면 원본대로 버린다. 기존 overflow·수량 초과 장비는 보존하고 재개 시험을 넣었다. 원본 gear_restrict처럼 만석일 때 옛 부적합 장착을 무조건 해제하지 않는다. 코드/UID 두 저장 매체 자체는 차이로 세지 않았다.

검사 기대값 변경: expedition_r22_test·expe_pass4_r23_test·town_combat_r21_round14_test의 신규 만석 보존 기대를 정본의 버림으로 교체하고 옛 overflow 보존 검사는 유지/추가했다. town_r21_round10_test·round11_test의 한국어 fallback 기대는 명시적 native 영어 번역으로 바꿨으며, 미등록 단어가 변수 전용 틀에 잘못 잡히지 않는 검사는 유지했다. 도감 원본 영어 화면의 고정 한국어 필터/무속성 표시는 원본 U/T 사전을 적용한 표시 기대값으로 따로 비교한다(source_locale_r24.gd). 고정 대사는 원문 유지 검사를 그대로 유지하며, 일반 UI 틀로 부분 번역하지 않는다. 영어 미지원은 별도 전수 목록으로 남겼다. UI 글자 검사는 고정 16px 대신 실제 스타일 여백과 줄바꿈 크기로 고쳤고 터치 높이/영역 검사는 유지했다. 전투 기대값은 바꾸지 않았다.

실제 `server/abyss-save/test/serve.mjs`/D1로 클라우드 8그룹을 실행했다. 실행 시에만 빈 포트·dev registry 비활성화를 적용하며 서버 파일은 바꾸지 않았다. UI 검사는 native 렌더링으로 돌리도록 실행기를 바로잡아 재실행했다. 종료 130은 기존 private stdin SIGINT 종료 경로다. Windows 인증서 저장소 진단만 환경 메시지로 분리했고 다른 ERROR/Script error는 실패로 처리했다.

390×844·1280×800 after와 직접 열어 본 검토표는 [visual-review.json](verification/finish-r24/visual-review.json), 원본 이미지는 96/96 해시 일치다. 시안의 배치·색·서체 및 초상/적 도트 바이트를 유지했다. 새 그림·Web export·docs/server 수정·git 명령 없음.

검증 파일: [전체 검사](verification/finish-r24/all-tests.json) · [신규 직접 대조](verification/finish-r24/unit-results.json) · [원본 oracle](verification/finish-r24/oracle.json) · [언어 스캔](verification/finish-r24/locale-scan.json) · [행별 근거](verification/finish-r24/row-audit.json) · [보호 경계](verification/finish-r24/boundaries.json).

남은 항목:

- P2757 · 장소별 제목/본문, 출전자 없음, 원본 전체 시설 버튼 순서와 고정 마을 바로가기의 정보·순서가 아직 다르다.
- P2758 · 시설 이동·영수증·없는 의뢰·무효 scene을 함께 처리하는 최상위 handler의 전체 직접 대조가 남는다.
- P2784 · 의뢰 정산의 st.rg 우선/의뢰 fallback·미종료 전투·엘리트 입고·재정산을 실제 단일 진입점으로 모두 대조하지 못했다.
- P2792 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3016 · SO.face의 사용자 아바타는 호스트 제외. 일반 문자열 provider의 표시와 native Texture provider의 fallback 전체는 미대조다.
- P3020 · 클래스 정보 없는 옛 저장에서 native는 참전 버튼을 막는다. 원본의 활성 버튼과 실제 차이가 남는다.
- P3032 · 출정 전체의 picker/고정 슬롯/별도 스크롤과 보조 출발 버튼이 원본의 전체 정보·버튼 순서와 다르다.
- P3037 · 원본의 새 전투 엔진 부재 fresh(T.bn) fallback 입력을 native에서 만드는 경로가 없다.
- P3041 · go/back의 모든 scene·무효 입력·engine 부재를 합친 handler의 전체 관찰 대조가 남는다.
- P3079 · 원본 카드 안 cached percentile 표시와 native 별도 순위 화면 진입의 정보 위치·상태가 다르다.
- P3145 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3182 · 연속 전투의 적 이름 중복 제거 last/log·정예 장비 log 및 sid/bn/over/dn 불일치 전체 입력은 미대조다.
- P3195 · 정상 장비의 0/1999/2000/2001칸 삽입·버림·옛 overflow 재개는 수정·직접 일치. 추가 probe에서 원본은 구문 유효한 미등록 코드 zz99.1.1을 성공 목록으로 반환하지만 native는 거절하므로 전체 승격하지 않는다(known-code-gaps.json).
- P3202 · 만석 신규 장비 버림은 수정·대조했다. 전체 승리/퇴각/패배 보상 조합과 원본 canonical stage 저장 입력까지의 함수 전체 대조는 남는다.
- P3223 · sid/bn 불일치·legacy stage·snapshot 검증을 합친 정산 경계 전체는 미대조다.
- P3225 · 원본 st.dn.stage 1/2 저장을 직접 읽는 ABI가 없다. native 옛 저장 재개와 별개의 미지원 입력이다.
- P3249 · 휴식 장착은 동작하지만 code 버튼 해독·잘못된 슬롯·다른 소유자·거절 문구를 한 진입점으로 모두 대조하지 못했다.
- P3251 · 탐색 handler의 cont/next/home 무효 전투 상태 및 모든 장비 접두 요청을 합친 전체 대조가 남는다.
- P3287 · 원본 전체 explore의 버튼 순서와 native 지도·기록·보급품 별도 이동이 다르다.
- P3290 · 원본 휴식 안 슬롯별 후보/해제/장착 줄 대신 native는 별도 정비 화면을 쓴다. 후보·소유자·레벨 전체 대조가 남는다.
- P3293 · R.sel 무효 슬롯 정규화·슬롯별 후보 카드 전체가 별도 정비 대상 선택과 다르다.
- P3296 · 파티/귀환 확인은 유지하나 원본 inline gear_card와 native 별도 정비의 정보·선택 순서가 다르다. 성인 카드는 제외다.
- P3305 · run 없음 안내/귀환·inline gear_card·phase별 전체 버튼 구성을 직접 같게 확인하지 못했다.
- P3309 · 원본은 음수·소수 옛 물약 수도 합산한다. native 저장은 이를 원자적으로 거부한다. 이 손상 입력 차이는 남는다.
- P3311 · 원본 canonical G 전체 및 stage 저장을 native로 읽는 범용 이관 ABI가 없다.
- P3331 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3332 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3337 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3338 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3340 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3344 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3540 · 정본 6개 0/1999/2000칸 제한·재개 probe는 수정 후 일치한다. 그러나 원본은 invalid 같은 잘못된 옛 장착 문자열을 유지하고 native는 충돌 보관본으로 옮기므로 전체 관찰 차이가 남는다(known-code-gaps.json). 원문 자체는 보존한다.
- P3639 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3644 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3647 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3659 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P3691 · 제련/가공 본문은 기존 직접 비교 통과. 장소 설명·NPC 역할·완료/귀환 보조 문구와 추가 장착 선택지가 전체 화면에서 다르다.
- P2826 · 그림 없음/잘못된 그림의 NPC 행 생략과 NPC_G 역할 끝 호감 표시를 같은 제품 helper로 연결한 전체 대조가 없다.
- P2828 · Lv.40 대상 제외는 수정했다. 원본의 상품→장비 연속 순서·상품 상세와 native 분리 탭의 정보·순서는 남는다. 성인 사용 장면은 제외다.
- P2841 · 구입/스크롤/장비의 정상·경제 경계는 기존 시험 유지. 전체 접두 버튼의 무효 선택/피드백 dispatcher 직접 대조는 남는다.
- P2904 · 소개 탭의 설명→셀→최근 결과→소개 행동→명단과 진행 막대·부족/대기 보조 안내 전체 순서는 미일치다.
- P2907 · 길드 전체 장소 설명·두 NPC 역할·파티 안내 및 페이지별 헤더/귀환 동선이 다르다.
- P2922 · 길드 전체 접두 해석·ps_* 위임·저장하지 않은 편집 이탈 거절·전체 메시지 합성은 미대조다. AI 전송은 제외다.
- P2954 · 원본 동료 목록→선택과 native 자동 선택/드롭다운, 종족/행동 설명, 부족 자금 비활성 조건이 다르다.
- P2961 · 원본 talk는 즉시 호감 +1, native는 고정 대화 선택을 먼저 연다. 확인 단계·상태 확정 시점의 실제 차이다.
- P0017 · native 초기 생성에는 선생성 의뢰·다른 초기 RNG와 출정 기본 모드가 남아 있다. 빈 원본 G_new 전체 관찰 투영은 같지 않다.
- P0084 · native schema 1/2는 보존하지만 schema 없는 원본 v1 G 전체와 잘못된 타입을 원본처럼 보충해 읽는 경로가 없다.
- P0085 · 원본 v1 load의 초과 경험치 정산·코드 장착 환원·전체 진행을 native restore로 읽는 통합 입력 경로는 없다.
- P0097 · native 파일 왕복은 통과. 원본 v1 코드 장비·상태·진행 전체를 UID로 투영하는 저장/재개 대조는 남는다.
- P0105 · 원본 HUD 장소·금화·최대 3명 즐겨찾기 얼굴·메뉴 버튼 순서와 native 분산된 상/하단 진입은 전체 대조하지 못했다.
- P0131 · 알 수 없는 scene·화면 함수 오류·공개 override의 최상위 native 표시 전체를 원본과 직접 비교하지 못했다. 성인 override는 제외다.
- P0133 · 무효 접두·중복 버튼·저장 실패 뒤 부수효과를 포함한 world_screen 최상위 라우터 전체 대조가 남는다.
- P2425 · 개인/시너지 표시는 보강했다. 종족/계통 미선택 안내와 원본 pg_race 전체 정보·순서의 직접 대조는 남는다.
- P2426 · 차단 이름 덧붙임을 제거하고 원본 bl.s/note/tag로 수정했다. 전체 pg_nation의 설명·순서·선택 유지 합성은 미대조다.
- P2427 · 계열 개인/시너지를 추가했다. 모든 직업의 기본 수치·스킬·출신 주의문을 포함한 전체 순서 직접 대조는 남는다.
- P2428 · 총량 프리셋의 설명·직접 모드 보조 문구 전체는 아직 원본과 다르다.
- P2434 · 원본 능력치 막대·HP/MP·추천/초기화·상한 설명의 전체 화면 정보와 순서를 직접 모두 맞추지 못했다.
- P2442 · 단계 머리/특성/확정/내비게이션 helper는 승격했다. 첫 단계의 원본 언어 선택 버튼·클라우드 설명 및 페이지 전체 합성 순서 차이는 남는다.
- P2462 · 호스트 아바타는 제외. 첫 만남에서 그림 provider 없음·실패 시 초상/이니셜 전체를 CR.face와 별도로 직접 비교하지 못했다.
- P2463 · 원본 각 선택지의 직업/종족/속성·장소/teaser와 목록→미리보기 순서가 native와 다르다.
- P2467 · seed 산식·1회 생성 진입은 수정·대조했다. 첫 만남의 전체 초기 상태·아이템·난수 소비와 생성 의뢰를 합친 관찰은 아직 미일치다. AI 지시는 제외다.
- P2528 · 원본 코드 장착 저장의 전체 UID 이관과 실제 전투 중 패널 진입의 통합 경계가 남는다. 평시 0/1999/2000칸 직접 대조는 기존 통과다.
- P2534 · 30명 한영 상세는 기존 직접 비교 통과. P2528의 원본 옛 장착 저장·전투 연결을 상속하므로 전체 함수 승격은 보류한다.
- P2537 · 도감 전체는 P2528/P2534의 원본 장착 이관·전투 연결 경계가 남는다.
- P2539 · 무효 코드·원본 옛 장착 입력→UID·실제 전투 라우터까지의 handler 전체 관찰은 미대조다.
- P2567 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P2568 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P2593 · 평시 판매/장착/교환/재개는 기존 직접 일치. 전투 중 잔여 버튼 거절과 원본 옛 장착 입력을 합친 전체 경계가 남는다.
- P2606 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- P2617 · 즐겨찾기 최대 3명 얼굴·선택 버튼을 실제 HUD 진입/순서와 연결한 직접 대조가 없다.
- P2629 · 선택지/설명 및 클라우드 대체 기능은 기존 시험 통과. 전체 초기화 뒤 G_new 차이와 계정 화면 복귀/전체 합성은 남는다.
- P2637 · 설정 선택/저장/재개는 기존 통과. 초기화 뒤 원본 G_new의 난수·의뢰·진행 전체 투영 차이가 남는다.

바꾼 기존 파일:

- project/game/dungeon_world_r21.gd
- project/game/expedition_world_r22.gd
- project/game/facilities_world_r22.gd
- project/game/gear_save_r22.gd
- project/game/localization_r22.gd
- project/game/persona_rules.gd
- project/game/persona_world.gd
- project/tests/expedition_r22_test.gd
- project/tests/expe_pass4_r23_test.gd
- project/tests/town_combat_r21_round14_test.gd
- project/tests/town_r21_round10_test.gd
- project/tests/town_r21_round11_test.gd
- project/tests/ui_expedition_r22_test.gd
- project/tests/ui_panels_r22_test.gd
- project/tests/ui_persona_r22_test.gd
- project/tests/ui_phase4_codex_r23_test.gd
- project/tests/ui_phase4_native_r23_test.gd
- project/tests/ui_semantics_native_r23_test.gd
- project/ui/create_screen.gd
- project/ui/journal_screen_r22.gd
- project/ui/panel_screen_r22.gd
- project/ui/town_screen_r21.gd
- project/ui/world_screen.gd

추가 파일:

- project/data/native-locale-r24.json
- project/game/chronicle_display_r24.gd
- project/game/chronicle_display_r24.gd.uid
- project/game/create_display_r24.gd
- project/game/create_display_r24.gd.uid
- project/tests/finish_known_gaps_r24.gd
- project/tests/finish_locale_data_audit.gd
- project/tests/finish_r24_test.gd
- project/tests/finish_r24_test.gd.uid
- project/tests/source_locale_r24.gd
- project/tests/ui_finish_r24_test.gd
- project/tests/ui_finish_r24_test.gd.uid
- project/tests/ui_phase4_visual_r23_test.gd.uid
- tools/finish_r24_focused.py
- tools/finish_r24_oracle.mjs
- tools/finish_r24_report.py
- tools/finish_r24_review.py
- tools/finish_r24_scan.py
- tools/finish_r24_verify.py

재실행: `node tools/finish_r24_oracle.mjs` → `python tools/finish_r24_verify.py` → `python tools/finish_r24_verify.py --cloud` → `python tools/godot_r17.py --headless --script res://tests/finish_locale_data_audit.gd` → `python tools/finish_r24_scan.py --self-test` → `python tools/finish_r24_report.py`. 스캔은 현재 고정 대사 잔여 때문에 종료 1을 반환한다.
