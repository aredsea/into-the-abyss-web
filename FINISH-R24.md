# FINISH-R24 · 2차

**서버 허용 목록 변경이 필요한 결함을 재현하여 지시서대로 중단했다. 전체 기능 등가 완료가 아니다.** 전투 저장 재개에서 `depletions=3 → 0`, `last_kill=테이리스 → 빈 문자열`로 바뀐다. 기존 저장은 서버 검증을 통과하지만 두 필드를 추가한 저장은 각각 거절된다. 서버나 허용 목록은 수정하지 않았다. [재현 결과](verification/finish-r24/round2/server-boundary.json).

전체 프로젝트 **162/162그룹 통과·실패 0**, 로컬 D1 클라우드 9그룹 포함. 원본 전투 **6,320/6,320판·219,785기록 일치**. 신규 직접 대조 **216개**, 신규 화면 검사 **228개** 통과. 일반 화면 언어·자리표시자 결함 **0건**. 보호 대상 고정 대사 영어 미지원 **14,216개**는 별도 집계하며 전체 언어 0건으로 보고하지 않는다.

이번 지시의 시작 잔여는 expe 31 + gear 14 + ui 27 = 72행, battle 16행으로 총 88행이다. **같음 승격 8행(규칙 수정 2행 포함), 남음 80행**이다. 기존 1차 8행 승격과 중복 집계하지 않았다.

| 대조표 | 시작 잔여 | 같음 승격 | 규칙 수정 | 남음 |
|---|---:|---:|---:|---:|
| expe | 31 | 8 | 2 | 23 |
| gear | 14 | 0 | 0 | 14 |
| ui | 27 | 0 | 0 | 27 |
| battle | 16 | 0 | 0 | 16 |

수정과 승격:

- P3195: 미등록 코드도 구문이 유효하면 원본처럼 입고 성공으로 응답한다. 다음 가방 읽기에서 원본처럼 제외하며 사용 가능한 새 장비를 만들지 않는다. 중간 facade가 이 규칙을 다시 거절하던 경로도 연결했다. 만석 신규 버림, 옛 초과 장비 보존, 제련 상태 복원은 유지한다.
- P3020: 직업이 빈 옛 저장에서도 참전 선택 버튼을 활성화하고 참전 상태를 바꾼다. 이 저장에서 참전 선택 뒤 실제 출발은 기존 직업 유효성 검사에 막힌다(지휘로 되돌리면 출발 가능). 원본의 기본 전사 전투 입력까지 잇는 출발 handler는 P3041/P1620의 미완료 범위로 남기며, 버튼 행의 판정을 전파하지 않는다.
- P3331/P3332/P3337/P3338/P3340/P3344: 통합 전투 표에 이미 있는 동일 함수의 직접 비교 결과를 재실행하고 expe의 중복 이관 상태를 해소했다.

기존 신고 두 화면은 다시 촬영·확인했다. 연대기의 옛 영어 기록은 삭제하지 않고 설정 언어에 맞춰 표시한다. 레벨업 스크롤의 페르소나 자리표시자도 표시 때 치환한다. `390×844`, `1280×800`에서 한영·옛 저장 참전 화면을 포함한 after 12장을 직접 열어 보았다. [시각 검토](verification/finish-r24/round2/visual-review.json).

언어 스캔은 메뉴/패널 206상태·19,290문자열과 데이터 63파일·75,762문자열을 검사했다. 스캔 종료값은 보호된 영어 대사 미지원 때문에 1이며 숨기지 않았다. `project/data/dialogue-r21/*.json`, 영어 대사 표시 함수, `resource_gauge_r24.gd`, 승인 외형·원본 이미지 **96/96**, `server/`, `docs/`를 보존했다. git 명령·Web export·새 그림 없음.

클라우드 실행기는 그룹별로 별도 실제 로컬 서버/D1을 시작한다. 하나의 서버를 공유하며 계정 생성에 실패했던 2그룹은 새 서버에서 원래 검사 그대로 통과했고 전체 9그룹도 격리 실행으로 재확인했다. 제품의 제한이나 검증 조건을 낮추지 않았다. Windows root certificate store 메시지는 기존 환경 진단으로 분리하고 나머지 ERROR/Script error는 실패로 센다. 기존 ui_persona_town_round8_test의 참전 버튼 비활성과 persona_town_r21_round8_test의 참전 거절 기대는 원본 fight_row/H.so의 허용 기대에 맞췄다. 선택 뒤에는 별도 원래 저장을 다시 읽어 지휘 출발·경험치·중복 정산 검사를 모두 유지했다. 새 36개 원본 대조 및 실제 포인터 클릭 시험도 추가했다. 초기 실패와 재검사는 recheck-history.json에 남긴다. 전투 수치 기대값은 바꾸지 않았다.

다음 작업은 `battle_v3.gd` 저장/재개에 마지막 일격과 심연 고갈 횟수의 명시적 필드를 넣고, 서버 battle 검증 허용 목록·범위·옛 저장 기본값을 함께 이관하는 것이다. 이 서버 변경이 현재 금지되어 중단했다. 남은 80행의 이전 차이/미검증 이유는 아래와 각 표의 `finish.round2.previous_remaining_reason`에 보존했다. 다른 남은 행을 이 저장 결함만 고치면 자동 완료된다고 주장하지 않는다.

검증: [전체 검사](verification/finish-r24/round2/all-tests.json) · [직접 대조](verification/finish-r24/round2/unit-results.json) · [원본 실행](verification/finish-r24/round2/oracle.json) · [전투 회귀](verification/finish-r24/round2/battle-regression.json) · [언어 스캔](verification/finish-r24/locale-scan.json) · [보호 경계](verification/finish-r24/round2/boundaries.json) · [행별 기록](verification/finish-r24/round2/row-audit.json) · [1차 보고 보존](verification/finish-r24/round2/first-pass-report.md).

재실행: `node tools/finish_r24_round2_oracle.mjs` 후 PowerShell에서 `$env:R24_FINISH_OUTPUT="verification/finish-r24/round2"; python tools/finish_r24_verify.py` 및 `python tools/finish_r24_verify.py --cloud`. 진단은 `python tools/godot_r17.py --headless --script res://tests/finish_resume_r24_probe.gd` → `node tools/finish_r24_resume_boundary.mjs`. 보호 대사 감사와 스캔은 1차와 같은 도구를 사용하고, 보고서는 `python tools/finish_r24_round2_report.py`로 쓴다.

시각 검토 제한: 영어 출정 상단의 긴 제목과 회복 안내는 기존 그림 영역에 빽빽하게 붙는다. 이번에는 승인 외형을 바꾸지 않았다. 디자인 스킬 context가 DESIGN.md와 .impeccable/design.json의 동기화 필요를 보고했다. 작업 범위 밖의 메타데이터는 수정하지 않았으며 `document`로 갱신할 수 있다.

이번 변경 파일:

- project/game/expedition_world_r22.gd
- project/game/facilities_world_r22.gd
- project/game/persona_world.gd
- project/tests/finish_r24_test.gd
- project/tests/persona_town_r21_round8_test.gd
- project/tests/ui_persona_town_round8_test.gd
- project/ui/expe_sortie_legacy_r23.gd
- project/ui/persona_sortie_screen.gd
- tools/finish_r24_focused.py
- tools/finish_r24_verify.py

추가 시험·도구:

- project/tests/finish_round2_r24_test.gd
- project/tests/ui_finish_round2_r24_test.gd
- project/tests/finish_resume_r24_probe.gd
- tools/finish_r24_round2_oracle.mjs
- tools/finish_r24_resume_boundary.mjs
- tools/finish_r24_round2_report.py

남은 행과 이전 이유:

- expe P2757 · 장소별 제목/본문, 출전자 없음, 원본 전체 시설 버튼 순서와 고정 마을 바로가기의 정보·순서가 아직 다르다.
- expe P2758 · 시설 이동·영수증·없는 의뢰·무효 scene을 함께 처리하는 최상위 handler의 전체 직접 대조가 남는다.
- expe P2784 · 의뢰 정산의 st.rg 우선/의뢰 fallback·미종료 전투·엘리트 입고·재정산을 실제 단일 진입점으로 모두 대조하지 못했다.
- expe P2792 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- expe P3016 · SO.face의 사용자 아바타는 호스트 제외. 일반 문자열 provider의 표시와 native Texture provider의 fallback 전체는 미대조다.
- expe P3032 · 출정 전체의 picker/고정 슬롯/별도 스크롤과 보조 출발 버튼이 원본의 전체 정보·버튼 순서와 다르다.
- expe P3037 · 원본의 새 전투 엔진 부재 fresh(T.bn) fallback 입력을 native에서 만드는 경로가 없다.
- expe P3041 · go/back의 모든 scene·무효 입력·engine 부재를 합친 handler의 전체 관찰 대조가 남는다.
- expe P3079 · 원본 카드 안 cached percentile 표시와 native 별도 순위 화면 진입의 정보 위치·상태가 다르다.
- expe P3145 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- expe P3182 · 연속 전투의 적 이름 중복 제거 last/log·정예 장비 log 및 sid/bn/over/dn 불일치 전체 입력은 미대조다.
- expe P3202 · 만석 신규 장비 버림은 수정·대조했다. 전체 승리/퇴각/패배 보상 조합과 원본 canonical stage 저장 입력까지의 함수 전체 대조는 남는다.
- expe P3223 · sid/bn 불일치·legacy stage·snapshot 검증을 합친 정산 경계 전체는 미대조다.
- expe P3225 · 원본 st.dn.stage 1/2 저장을 직접 읽는 ABI가 없다. native 옛 저장 재개와 별개의 미지원 입력이다.
- expe P3249 · 휴식 장착은 동작하지만 code 버튼 해독·잘못된 슬롯·다른 소유자·거절 문구를 한 진입점으로 모두 대조하지 못했다.
- expe P3251 · 탐색 handler의 cont/next/home 무효 전투 상태 및 모든 장비 접두 요청을 합친 전체 대조가 남는다.
- expe P3287 · 원본 전체 explore의 버튼 순서와 native 지도·기록·보급품 별도 이동이 다르다.
- expe P3290 · 원본 휴식 안 슬롯별 후보/해제/장착 줄 대신 native는 별도 정비 화면을 쓴다. 후보·소유자·레벨 전체 대조가 남는다.
- expe P3293 · R.sel 무효 슬롯 정규화·슬롯별 후보 카드 전체가 별도 정비 대상 선택과 다르다.
- expe P3296 · 파티/귀환 확인은 유지하나 원본 inline gear_card와 native 별도 정비의 정보·선택 순서가 다르다. 성인 카드는 제외다.
- expe P3305 · run 없음 안내/귀환·inline gear_card·phase별 전체 버튼 구성을 직접 같게 확인하지 못했다.
- expe P3309 · 원본은 음수·소수 옛 물약 수도 합산한다. native 저장은 이를 원자적으로 거부한다. 이 손상 입력 차이는 남는다.
- expe P3311 · 원본 canonical G 전체 및 stage 저장을 native로 읽는 범용 이관 ABI가 없다.
- gear P3540 · 정본 6개 0/1999/2000칸 제한·재개 probe는 수정 후 일치한다. 그러나 원본은 invalid 같은 잘못된 옛 장착 문자열을 유지하고 native는 충돌 보관본으로 옮기므로 전체 관찰 차이가 남는다(known-code-gaps.json). 원문 자체는 보존한다.
- gear P3639 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- gear P3644 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- gear P3647 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- gear P3659 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- gear P3691 · 제련/가공 본문은 기존 직접 비교 통과. 장소 설명·NPC 역할·완료/귀환 보조 문구와 추가 장착 선택지가 전체 화면에서 다르다.
- gear P2826 · 그림 없음/잘못된 그림의 NPC 행 생략과 NPC_G 역할 끝 호감 표시를 같은 제품 helper로 연결한 전체 대조가 없다.
- gear P2828 · Lv.40 대상 제외는 수정했다. 원본의 상품→장비 연속 순서·상품 상세와 native 분리 탭의 정보·순서는 남는다. 성인 사용 장면은 제외다.
- gear P2841 · 구입/스크롤/장비의 정상·경제 경계는 기존 시험 유지. 전체 접두 버튼의 무효 선택/피드백 dispatcher 직접 대조는 남는다.
- gear P2904 · 소개 탭의 설명→셀→최근 결과→소개 행동→명단과 진행 막대·부족/대기 보조 안내 전체 순서는 미일치다.
- gear P2907 · 길드 전체 장소 설명·두 NPC 역할·파티 안내 및 페이지별 헤더/귀환 동선이 다르다.
- gear P2922 · 길드 전체 접두 해석·ps_* 위임·저장하지 않은 편집 이탈 거절·전체 메시지 합성은 미대조다. AI 전송은 제외다.
- gear P2954 · 원본 동료 목록→선택과 native 자동 선택/드롭다운, 종족/행동 설명, 부족 자금 비활성 조건이 다르다.
- gear P2961 · 원본 talk는 즉시 호감 +1, native는 고정 대화 선택을 먼저 연다. 확인 단계·상태 확정 시점의 실제 차이다.
- ui P0017 · native 초기 생성에는 선생성 의뢰·다른 초기 RNG와 출정 기본 모드가 남아 있다. 빈 원본 G_new 전체 관찰 투영은 같지 않다.
- ui P0084 · native schema 1/2는 보존하지만 schema 없는 원본 v1 G 전체와 잘못된 타입을 원본처럼 보충해 읽는 경로가 없다.
- ui P0085 · 원본 v1 load의 초과 경험치 정산·코드 장착 환원·전체 진행을 native restore로 읽는 통합 입력 경로는 없다.
- ui P0097 · native 파일 왕복은 통과. 원본 v1 코드 장비·상태·진행 전체를 UID로 투영하는 저장/재개 대조는 남는다.
- ui P0105 · 원본 HUD 장소·금화·최대 3명 즐겨찾기 얼굴·메뉴 버튼 순서와 native 분산된 상/하단 진입은 전체 대조하지 못했다.
- ui P0131 · 알 수 없는 scene·화면 함수 오류·공개 override의 최상위 native 표시 전체를 원본과 직접 비교하지 못했다. 성인 override는 제외다.
- ui P0133 · 무효 접두·중복 버튼·저장 실패 뒤 부수효과를 포함한 world_screen 최상위 라우터 전체 대조가 남는다.
- ui P2425 · 개인/시너지 표시는 보강했다. 종족/계통 미선택 안내와 원본 pg_race 전체 정보·순서의 직접 대조는 남는다.
- ui P2426 · 차단 이름 덧붙임을 제거하고 원본 bl.s/note/tag로 수정했다. 전체 pg_nation의 설명·순서·선택 유지 합성은 미대조다.
- ui P2427 · 계열 개인/시너지를 추가했다. 모든 직업의 기본 수치·스킬·출신 주의문을 포함한 전체 순서 직접 대조는 남는다.
- ui P2428 · 총량 프리셋의 설명·직접 모드 보조 문구 전체는 아직 원본과 다르다.
- ui P2434 · 원본 능력치 막대·HP/MP·추천/초기화·상한 설명의 전체 화면 정보와 순서를 직접 모두 맞추지 못했다.
- ui P2442 · 단계 머리/특성/확정/내비게이션 helper는 승격했다. 첫 단계의 원본 언어 선택 버튼·클라우드 설명 및 페이지 전체 합성 순서 차이는 남는다.
- ui P2462 · 호스트 아바타는 제외. 첫 만남에서 그림 provider 없음·실패 시 초상/이니셜 전체를 CR.face와 별도로 직접 비교하지 못했다.
- ui P2463 · 원본 각 선택지의 직업/종족/속성·장소/teaser와 목록→미리보기 순서가 native와 다르다.
- ui P2467 · seed 산식·1회 생성 진입은 수정·대조했다. 첫 만남의 전체 초기 상태·아이템·난수 소비와 생성 의뢰를 합친 관찰은 아직 미일치다. AI 지시는 제외다.
- ui P2528 · 원본 코드 장착 저장의 전체 UID 이관과 실제 전투 중 패널 진입의 통합 경계가 남는다. 평시 0/1999/2000칸 직접 대조는 기존 통과다.
- ui P2534 · 30명 한영 상세는 기존 직접 비교 통과. P2528의 원본 옛 장착 저장·전투 연결을 상속하므로 전체 함수 승격은 보류한다.
- ui P2537 · 도감 전체는 P2528/P2534의 원본 장착 이관·전투 연결 경계가 남는다.
- ui P2539 · 무효 코드·원본 옛 장착 입력→UID·실제 전투 라우터까지의 handler 전체 관찰은 미대조다.
- ui P2567 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- ui P2568 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- ui P2593 · 평시 판매/장착/교환/재개는 기존 직접 일치. 전투 중 잔여 버튼 거절과 원본 옛 장착 입력을 합친 전체 경계가 남는다.
- ui P2606 · battle 이관: 전투 소유 함수/화면의 전체 관찰 대조가 남는다. 전투 파일을 수정하거나 기능 전체 같음으로 승격하지 않았다.
- ui P2617 · 즐겨찾기 최대 3명 얼굴·선택 버튼을 실제 HUD 진입/순서와 연결한 직접 대조가 없다.
- ui P2629 · 선택지/설명 및 클라우드 대체 기능은 기존 시험 통과. 전체 초기화 뒤 G_new 차이와 계정 화면 복귀/전체 합성은 남는다.
- ui P2637 · 설정 선택/저장/재개는 기존 통과. 초기화 뒤 원본 G_new의 난수·의뢰·진행 전체 투영 차이가 남는다.
- battle P1553 · 초기화 48편성과 carry 소생 조건은 비교. 기본/옛 편성·dm·로그·q·first를 포함한 fresh 전체 반환은 남음.
- battle P1587 · 동일 편성 재시도의 bn 증가와 rg/qid/place/sid 이전 계약을 새 원본 fixture로 비교하지 않음.
- battle P1589 · 같은 bn으로 재시작하며 난이도·편성·출처를 유지하는 전체 반환을 새 대조하지 않음.
- battle P1594 · 저장 매체 차이는 사유에서 제거. 원본 VER2 기록을 native에서 불러와 같은 다음 행동/소지·장착·진행으로 재개하는 직접 왕복 대조와 손상 입력 결과 비교가 아직 없음. 원본 migrate 대조 및 native 자체 restore 통과만으로 전체 load/save 행을 승격하지 않음.
- battle P1595 · 저장 매체 차이는 사유에서 제거. 원본 VER2 기록을 native에서 불러와 같은 다음 행동/소지·장착·진행으로 재개하는 직접 왕복 대조와 손상 입력 결과 비교가 아직 없음. 원본 migrate 대조 및 native 자체 restore 통과만으로 전체 load/save 행을 승격하지 않음.
- battle P1620 · 편성→전투 시작→scene/보상/식별자 저장까지의 G 변경 전체를 새 대조하지 않음.
- battle P1746 · 72가지 직접 strike와 기존 장비/사제/생존 회귀는 통과. 반환 ls/tags, 모든 구원 소유자 순서 및 필드 시간 이력은 남음.
- battle P1811 · 기존256+추가16개 단일/전체 공격 기록에서 치명 taunt 원문/시간을 수정. 여러 개인/장비 반격 훅을 섞은 모든 사건·반환·시간 순서 직접 대조는 남음.
- battle P1812 · 단일/전체 256입력의 대상별 시각·사망·보호자 상태·tags·피격 후 효과 비교. 다중 반격/장비 훅 혼합의 전체 사건/로그 대조는 남음.
- battle P1813 · 100종 각 행동·건강/손상652개 조합 편성의 차례 전체 상태·사건·로그·다음 RNG 직접 일치. fl 없는 옛 고정 적 차례 전체와 다중 개인/장비 훅 혼합 직접 대조는 남음.
- battle P1825 · 256개 직접 원본 모양 정산에서 결과문·부상자·EXP·로그·종료 이벤트·cur/q·재호출 일치. 실제 native world의 모든 의뢰 rg/qmult·출처 연결과 저장 재개 뒤 nd/마지막 일격 기록 복구는 남음.
- battle P1831 · 6320판 진행 결과는 비교. guard 80·모든 시작/라운드/사망·자동 방출의 전체 상태 경계는 남음.
- battle P1682 · 기존 길드 UI는 유지. 모든 prefix/suffix·dirty/ready·강화 상한/부족 금화 표시의 의미상 출력 전체는 새 대조하지 않음.
- battle P2351 · 버튼 MP/설명·disabled·선택 상태의 의미상 출력 전체를 새 직접 대조하지 않음.
- battle P2353 · 기술 조건 회귀는 통과. 행동/아이템/대상 선택·취소·버튼 배열의 전체 새 대조는 남음.
- battle P2359 · 기존 native 화면/오버플로 회귀는 유지. 모든 원본 상태에서 HUD·대상·로그·카메라의 의미상 전체 출력 대조는 남음.
