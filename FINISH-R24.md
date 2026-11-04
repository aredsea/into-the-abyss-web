# FINISH-R24 · 4차

**전체 완료 아님. 이어받은 잔여 74행에서 같음 11행 승격, 14행 수정(승격 포함), 63행이 남았다.** 3차 시작 80행 기준 누적 승격은 17행이다. 전 화면·전 데이터 언어 검사는 보호된 대사 미번역 14,216필드 때문에 완료 기준을 충족하지 못한다. 금지된 데이터/영어 대사 표시 함수를 수정하지 않았다.

프로젝트 **175/175그룹 최종 통과·실패 0**, 실제 `serve.mjs` Worker/D1 클라우드 **11그룹** 포함. `npm test` 종료 0, 정상 표본 **393/393**, 두 필드 서버 **64사례·449검사**. 전투 **6,320/6,320판·219,785기록 일치**.

일반 화면 언어 **0건**, 자리표시자 **0건**: 222개 화면·언어 상태, 20,650개 표시 문자열, 데이터 63파일·75,763문자열. 별도 보호 대사 **14,216필드 미번역**, `all_language_complete=false`, 전체 스캐너 종료 1. 전체 언어 0건으로 보고하지 않는다.

| 대조표 | 시작 잔여 | 같음 승격 | 수정 | 남음 |
|---|---:|---:|---:|---:|
| expe | 23 | 3 | 6 | 20 |
| gear | 9 | 3 | 3 | 6 |
| ui | 26 | 5 | 5 | 21 |
| battle | 16 | 0 | 0 | 16 |

수정 수는 이번 제품 동작을 바꾼 행이며 승격과 중복된다. P3540은 이어받은 기존 수정의 재검사로 승격했으므로 이번 수정 수에는 넣지 않았다. 전체 화면/handler의 일부만 확인한 행은 승격하지 않았다. 원본 HTML·저장 매체 자체나 과거 갈래 금지는 잔여 이유로 쓰지 않는다.

주요 변경과 직접 대조:

- 생성: 원본 순서의 종족/출신/직업/능력치 설명·주의·선택·활성·추천/초기화를 실제 화면에 연결했다. 1,008페이지+28총량 입력, 2,636검사. 기본/보너스 막대 비율 564조합을 포함한다. 원본 C printf와 Godot 소수 셋째 자리 tie 16건을 고쳤으며 기존 0~2자리 전투 표시 회귀도 통과했다.
- 휴식 장비: 같은 화면에 원본 슬롯별 후보·해제/장착을 표시하고 선택을 기존 ui.sel에 저장한다. 72표시+252행동, 1,872검사. 잘못된 코드·소유자·직업/레벨·가득 찬 가방과 JSON 재개를 비교했다.
- 정산: 금화·경험치·레벨·호감·장비 획득/버림 메시지를 복원했다. 48입력·560검사, 2,001개 기존 가방도 보존한다. 이 비교의 보스 드롭은 no-drop으로 격리했다. 다층/첫 보스/복합 드롭의 전체 계약은 P3202에 남는다.
- 여관/상회: 실제 UI에서 최상위 원본 버튼 dispatcher를 사용한다. 여관 264입력·266검사, 상회 336입력·384검사. back/list/pick/분류/슬롯/대상/구입·거절 문구와 상태를 직접 비교했다. 기존 여관 경제 320입력·1,281검사도 통과한다. 호스트 채팅 전송 문구만 제외했다. NPC 접근자는 79-sex.lua의 sx_npcst/npc_like만 추출했으며 성인 장면은 실행/이식하지 않았다.
- 실제 D1: 장비 선택/장착, 상회 분류/슬롯/스크롤 선택을 업로드→다른 기기→후속 행동→역방향 저장/파일 재개까지 25검사했다. 외부 소유 장비 거절을 포함하고 서버 키를 추가하지 않았다.
- 언어: 실제 영어 정산 화면의 한국어 제목 1건을 locale 사전에 추가했다. 예전 연대기/스크롤 사용자 이름 결함의 1차 수정은 유지하며 두 크기의 화면을 다시 열었다.

시각 확인: 최신 한영 생성·휴식·정산·여관 48장과 기존 연대기/스크롤 결함 4장, **총 52장**을 `390×844`·`1280×800`에서 직접 열었다. 관련 실제 UI **3,092검사**, 소스 표시 조각/컨트롤/미터와 콜백을 확인했다. 긴 설명은 기존 스크롤 영역을 사용한다. 원본 그림·팔레트·서체·공용 게이지는 유지했다. 전체 화면 순서의 남은 차이는 행별 기록을 따른다.

검증 근거:

- [최종 전체 검사](verification/finish-r24/round4/all-tests.json), [최초 실패와 재검사](verification/finish-r24/round4/recheck-history.json), [npm test](verification/finish-r24/round4/npm-test.log), [실제 클라우드](verification/finish-r24/round4/cloud/results.json)
- [생성](verification/finish-r24/round4/create-results.json), [휴식 장비](verification/finish-r24/round4/rest-gear-results.json), [정산](verification/finish-r24/round4/settle-results.json), [여관](verification/finish-r24/round4/inn-routes-results.json), [상회](verification/finish-r24/round4/shop-routes-results.json), [새 D1 재개](verification/finish-r24/round4/cloud-rest.json)
- [행별 원본 hash·판정·남은 이유](verification/finish-r24/round4/row-audit.json), [전투](verification/finish-r24/round4/battle-regression.json), [시각 검토와 PNG hash](verification/finish-r24/round4/visual-review.json), [변경 파일/보호 경계](verification/finish-r24/round4/boundaries.json)
- [전체 언어 스캔](verification/finish-r24/locale-scan.json), [보호 대사 검출](verification/finish-r24/authored-language-audit.json), [이전 보고](verification/finish-r24/round4/round3-report.md)

재검사 해석: 최초 전체 실행의 chronicle fixture는 초기 의뢰가 없다는 원본 G_new 복원 뒤 비어 있는 배열을 참조했다. 완료된 게임용 fixture에 의뢰판 생성을 명시했다. pass5 화면 fixture는 새 gear_card 포함 및 원본이 가정한 dungeon 모드를 명시했다. 둘 다 관련 재검사 통과, 원본 수치 기대값은 바꾸지 않았다. 전체 대사 UI 검사도 1,489,324검사·실패/overflow 0을 유지했다. npm의 시간 경계 실패와 사라진 외부 의존성 경로는 재실행으로 확인했으며 최종 실행은 성공했다.

경계: 원본 이미지 **96/96 불변**. 대사 데이터·영어 표시 함수·공용 게이지·docs 불변, 새 그림/Web export 없음. 기존 미커밋 3차 변경을 보존했다. 이번 서버 파일 변경은 0건이며 기존 depletions/last_kill strict allowlist만 유지·재검사했다. 보안/속도 제한은 바꾸지 않았다. 다른 갈래 node_modules는 읽기만 했고 launcher는 개발 registry 공유만 끈 실제 Worker/D1을 사용한다. 만든 runtime 슬롯은 모두 정리했고 기본 runtime은 보존했다.

남은 이유: 보호 대사 외에도 원본 G/VER2 전체·옛 stage 입력 이관, 전체 화면 정보/선택 순서, 전투 복합 훅의 반환·로그·시간 이력 및 일부 최상위 dispatcher 합성의 직접 대조가 미완료다. id 전용 last_kill은 원본 이름+기술 문구를 완전히 보존할 수 없다. 세부 63행은 다음과 같다.

- expe P2757 `B.SCREENS.town`: 마을 본문·전체 시설 설명·수락 의뢰/최고층 안내를 기존 하단 영역의 스크롤에 추가했다. 출전자 없음 안내, place_id에 따른 장소별 hero 제목/본문, 원본 전체 버튼 순서는 아직 직접 일치하지 않는다. 고정 시안의 기존 바로가기도 유지했으므로 전체 화면은 승격하지 않는다.
- expe P2758 `B.H.tw`: 마을의 새 의뢰/대던전 버튼은 실제 모드 선택으로 연결했다. 전체 이동의 ui.tab 초기화·잘못된 scene·의뢰 없음 메시지 및 거래 영수증 경계는 facilities_world_r22.facility_route와 world_screen.go에 걸친다. 전체 handler 직접 대조는 남는다.
- expe P2784 `B.tw_settle`: 실제품 의뢰 정산은 facilities_world_r22.settle이 override한다. st.rg 우선/의뢰 fallback, 미종료 전투, 엘리트 입고, 재정산, 원문 메시지의 단일 진입점 직접 대조가 남는다.
- expe P2792 `B.HUD_EXTRA[#B.HUD_EXTRA + 1]`: 원본 battle HUD의 id/load/bn 실패·탐색 승리 제외와 귀환/층 정산 label/subtitle은 현재 battle 화면 파일에 있다. 이번에 고친 패배 후 마을 경로만으로 전체 HUD의 같음을 주장하지 않는다.
- expe P3016 `face`: 동료의 원본 초상과 새 번역 첫 글자 fallback은 유지·보강했다. SO.face의 persona pimg(호스트 사용자 아바타/실루엣)와 PX.face의 nonempty plain-string provider 반환 경계는 town tw_face와 다른 계약이다. native persona 표시는 이 전체 분기와 아직 같지 않다. 호스트 아바타 부분은 호스트 전용 범위로 별도 기록한다.
- expe P3032 `B.SCREENS.sortie`: 미지정 출정 기본 모드를 원본 의뢰 모드로 복원했다. picker/고정 슬롯/별도 스크롤·보조 출발 버튼의 전체 정보·버튼 순서 차이는 남는다.
- expe P3037 `legacy_start`: 현재 전투 엔진이 없는 원본 환경의 fresh(T.bn) 옛 전투 생성 fallback은 native의 옛 저장 재개와 별개의 기능이다. canonical legacy 출정 상태 생성/이관 ABI가 아직 없으며 이번 화면 fixture로 대체하지 않았다.
- expe P3041 `B.H.so`: 실제 슬롯 제거·persona 지휘 전환·mode/filter/floor/page를 연결했고 중복 rm이 재등록하지 않도록 했다. 참전 전환의 마지막 동료 대기/만석 메시지를 보강했다. source go/back의 모든 scene·무효 입력과 legacy engine-absent 분기를 하나의 handler로 직접 대조하는 것은 남는다.
- expe P3079 `B.dn_card`: 0/2/8/27/54/419 최고층과 1/2/99쪽의 목록·잠김·돌파/추천·보스/일반 금화·적 레벨·4인 안내 36건의 직접 대조를 추가했다. rank_head의 cached percentile은 원본처럼 카드 안에 표시하지 않고 별도 native 순위 화면으로 연결한다. 명시적 클라우드 대체의 순위 기능은 기존 시험으로 유지하지만 전체 카드의 cached 상태 표시까지 같음으로 올리지는 않는다.
- expe P3145 `B.ex_battle`: 전투 진입 자원·탐색 투영은 기존 대조를 유지한다. 원본 sid/bn/dn/carry 전부와 native battle snapshot의 전체 경계 동등성은 아직 직접 확정하지 못했다.
- expe P3182 `do_cont`: 수치 투영·스냅샷 회귀는 유지했다. native continuation의 적 이름 중복 제거 last/log·정예 장비 log와 source sid/bn/over/dn 불일치 분기 전체는 아직 직접 비교/수정하지 않았다.
- expe P3202 `finish_run`: 정산 금화·경험치·레벨·동료 호감·장비/손실/원문 메시지를 48개 원본 입력으로 비교했다(한영×성공/퇴각/패배×케른×가방 0/1999/2000/2001). 기존 넘친 장비는 보존한다. 이 fixture는 1층, 보스 장비 드롭은 no-drop으로 격리하므로 다층/첫 보스/보스 드롭과 탐색 보상의 합성 전체는 아직 직접 대조하지 않았다.
- expe P3223 `B.dn_settle`: 원본 sid/bn 불일치 시 거점 복귀와 legacy stage 분기, native snapshot 검증을 통합한 정산 경계의 직접 대조가 미완료다. 패배의 정상 경로 수정만으로 무효 입력까지 승격하지 않는다.
- expe P3225 `B.dn_settle_legacy`: 옛 native 저장 재개 회귀는 유지했다. canonical 원본 st.dn.stage 1/2 저장을 읽어 정산하는 입력 ABI가 아직 없다. 매체 차이가 아니라 미지원 구체 입력 경로로 남긴다.
- expe P3251 `B.H.ex`: 탐색·물약·퇴각 요청/취소/확정의 기존 대조와 새 확인 화면 정보를 유지했다. cont/next/home의 무효 전투 상태 및 모든 장비 버튼을 합친 전체 handler 직접 대조는 남는다.
- expe P3287 `explore_screen`: ask에도 head/last/party/물약 정보를 함께 남기도록 수정하고 실제 UI에서 확인했다. 원본 전체 explore 화면의 버튼 종류/순서와 시안의 지도·기록·카드·보급품 이동 차이는 남아 전체 승격하지 않는다.
- expe P3296 `rest_screen`: 원본 gear_card를 실제 휴식 화면 안에 추가하고 선택·장착·해제를 연결했다. 파티/물약/장비 조각은 통과하지만 휴식 화면 전체의 정보·버튼 순서와 별도 보급품/정비 이동 구성이 아직 다르다. 성적 휴식 카드는 제외한다.
- expe P3305 `B.SCREENS.dungeon`: 실제 휴식의 inline gear_card·선택/장착과 정산 보상 문구를 보완했다. run 없음 안내/귀환 및 전체 phase별 정보·버튼 구성의 원본 직접 대조는 미완료다.
- expe P3309 `move_old`: potion/mana의 유효 옛 저장 합산은 유지했다. 원본 음수/소수 합산과 native 원자적 거부는 실제 허용 입력 차이로 남는다. 저장 검증을 약화하거나 손상 데이터를 조용히 버리지 않았다.
- expe P3311 `B.G_migrate`: 이번 local mode 필드의 손실 없는 이관·왕복 시험은 추가했다. 원본 canonical G 전체/옛 stage 저장을 native로 읽는 범용 이관은 아직 없다. 이 추가 이관을 전체 G_migrate 근거로 쓰지 않는다.
- gear P3691 `B.SCREENS.smithy`: 제련·가공 본문/탭/실행은 직접 일치. 전체 화면에는 원본 장소 설명·NPC 역할·완료/귀환 버튼의 보조 문구가 빠져 있고, native의 장비 장착하기 선택지가 추가된다. AI 장면 자체는 제외하며 이 표시/선택 차이만 남긴다.
- gear P2828 `B.SCREENS.shop`: 원본처럼 Lv40 대상은 스크롤 목록에서 숨긴다. 구입/선택 handler는 직접 대조했으나 전체 화면의 상품 상세 설명·단일 상품→장비 순서와 native 분리 탭의 정보/선택 순서는 아직 다르다. 비매품의 성인 사용 장면은 제외한다.
- gear P2904 `B.gd_recruit_tab`: 소개비 셀·최근 카드·명단·금화/RNG/합류는 직접 일치. 전체 소개 탭의 설명→셀→최근 결과→소개 행동→명단 표시 순서와 진행 막대, 부족/대기 보조 안내의 전체 화면 대조는 남음. AI 보내기 문구는 제외.
- gear P2907 `B.SCREENS.guild`: 의뢰판·영입 하위 helper 및 탭은 직접 일치. 전체 길드의 장소 설명·접수/길드장 두 NPC 역할·파티 선택 안내가 누락되고 native 페이지 간 헤더/귀환 동선이 다르다. HTML 반환 형식은 사유에서 제외.
- gear P2922 `B.H.gd`: 의뢰 수락/거절/포기/갱신·영입 경제는 기존 대조 유지. 전체 버튼 해석 및 ps_* 연구 위임/저장 안 한 편집 이탈 거절의 합성, 거절 시 전체 안내 문구를 새 source/native 일괄 대조하지 못함. AI 호스트 전송은 제외.
- gear P2954 `B.SCREENS.inn`: 행동의 즉시 확정·거절·성공 피드백은 원본 handler와 일치하고 화면에 표시한다. 전체 여관 화면의 동료 목록→선택과 native 자동 선택/드롭다운, 종족/행동 설명 및 정보·선택 순서는 아직 다르다.
- ui P0084 `B.G_migrate`: 원본 G_migrate는 누락 필드를 채우지만 native는 schema 없는 원본 G와 잘못된 타입을 전체 거절한다. 기존 native schema 1/2 보존 시험만으로 원본 v1 전체 이관을 같음으로 판정하지 않는다.
- ui P0085 `B.G_load`: 원본 load의 초과 경험치 정산·잘못된 장착 환원과 native restore의 전체 관찰 투영 대조가 남았다. 기존 native 저장 보존은 통과한다.
- ui P0097 `B.G_save`: 로컬 atomic write/백업/재개와 연대기 flush는 기존 회귀 통과. 원본 v1에서 저장 뒤 관찰할 전체 값(코드 장비·상태·진행)을 native UID에 투영하는 대조가 남았다. 저장 매체 차이만을 사유로 남기지 않는다.
- ui P0105 `B.hud`: 원본 HUD의 장소·금화·즐겨찾기 얼굴·상태/도감/저장/설정 순서와 native 상단/하단에 분산된 동작의 전수 직접 대조가 남았다.
- ui P0131 `B.view`: 생성/첫 만남/패널 조립은 회귀 통과. 알 수 없는 scene과 화면 함수 오류의 사용자 표시 및 override 분기의 native 대응을 아직 원본과 직접 비교하지 않았다. 호스트 잠금/성인 override 자체는 제외 범위.
- ui P0133 `B.route`: 원본 route의 무효 접두/중복 버튼/저장 실패 뒤 부수효과 경계와 native world_screen 전체 경로의 직접 대조가 남았다. 상태 탭 등 개별 handler 같음은 유지.
- ui P2442 `B.SCREENS.create`: 종족/출신/직업/능력치 단계의 본문·선택·버튼은 직접 대조했다. 전체 생성 합성의 단계 머리·특성/확정·별도 설정/클라우드 진입을 포함한 전체 정보와 동작 순서는 아직 직접 대조하지 않았다.
- ui P2462 `B.CR.face`: 원본 CR.face는 페르소나 호스트 아바타와 동료 초상/이니셜을 고른다. 호스트 부분은 제외하지만 첫 만남의 없는 초상 fallback은 아직 직접 대조하지 않았다.
- ui P2463 `B.SCREENS.scenario`: 원본 첫 만남 선택지의 장소/상황 설명과 native 선택 버튼은 companion 이름 위주로 다르다. 선택한 동료의 미리보기 외 모든 선택지 정보/순서를 비교해야 한다.
- ui P2467 `B.H.sc`: 원본 첫 만남 시작은 seed 설정·동료/호감/아이템·서술 지시를 함께 바꾼다. AI 지시는 제외하지만 native seed 소비 및 출발 상태의 직접 관찰 대조는 미완료다.
- ui P2528 `PX.cx_equip`: 표시 순서·장비 해제의 빈 칸/1999/2000칸·중복 코드 장착·저장 재개는 직접 대조 통과. 실제 전투에서 도감 패널을 여는 전체 경로와 원본의 옛 아이템 문자열 장착 저장을 UID 모델로 옮기는 입력 경로는 아직 지원/대조하지 않았다.
- ui P2534 `PX.cx_detail`: 30명×한영의 전체 공개 상세 정보/문구/순서/막대, 실제 원본 특성 아이콘 4개와 여우/늑대/표범 계통 패시브까지 직접 대조 통과. 장착·해제와 옛 장착 저장 및 실제 전투 진입의 복합 경계 P2528이 남아 전체 승격은 보류.
- ui P2537 `B.PANELS.codex`: 목록·미영입·전체 동료 상세와 페르소나의 불필요한 패시브 표시는 보완했다. 전체 패널은 P2528/P2534의 옛 장착 저장·실제 전투 연결 경계가 미완료다.
- ui P2539 `B.H.cx`: 8개 실제 상태 대조에서 2000칸 교환, 1999/2000칸 해제, 중복 코드·장착 UID·저장 재개·오류 알림은 일치. 원본 버튼 코드→native UID의 잘못된 코드/옛 장착 입력 및 실제 전투 라우터를 합친 관찰은 미완료다.
- ui P2567 `PX.st_unit`: 전투 상태창 단위의 아군 MP/적 심연/상태칩/사망 표시와 native 전투 inspector의 전체 의미상 출력을 직접 대조하지 않았다.
- ui P2568 `PX.st_battle`: 전투 승리/패배 표지·아군→적 순서·redo 초기화와 native 상태 패널의 직접 대조가 남았다.
- ui P2593 `B.H.bg`: 판매된 선택의 판매/장착, 중복 장비, 2000칸 교환과 저장 재개는 실제 native 어댑터와 일치. 전투 중 버튼 요청을 공통 라우터에서 거절하는 전체 경로 및 옛 장착 저장 입력은 미완료다.
- ui P2606 `B.PANELS.status`: 평시 persona/즐겨찾기·가방 표시와 전투 상태가 있는 패널 구성요소의 가방 진입 숨김은 검사했다. 실제 전투 진입은 먼저 전투 화면으로 강제 전환되어 원본 st_unit/st_battle의 동작·탭·복귀를 합친 전체 대응이 미완료다.
- ui P2617 `B.HUD_EXTRA[#B.HUD_EXTRA + 1]`: 원본 HUD 즐겨찾기 최대 3명의 얼굴·선택 버튼과 native HUD의 실제 진입/표시 순서를 직접 대조하지 않았다.
- ui P2629 `B.PANELS.settings`: 공개 설정 32상태의 레이블/선택·설명, 초기화 확인 중 다른 설정 유지 및 클라우드 대체 화면 진입은 검사했다. G_new 초기 상태는 일치하지만 P2637의 reset 알림/복귀/무효 입력과 별도 계정 화면 복귀를 포함한 전체 합성 대조는 남았다.
- ui P2637 `B.H.op`: 초기화 뒤 초기 의뢰·난수·출정 기본값 차이는 G_new 직접 비교와 실제 파일 초기화/보관 사본 검사로 해소했다. 최상위 op handler 전체의 reset 알림·복귀·무효 접두를 원본과 직접 모두 비교한 것은 아니므로 남음.
- battle P1553 `B.fresh`: 초기화 48편성과 carry 소생 조건은 비교. 기본/옛 편성·dm·로그·q·first를 포함한 fresh 전체 반환은 남음.
- battle P1587 `B.again`: 동일 편성 재시도의 bn 증가와 rg/qid/place/sid 이전 계약을 새 원본 fixture로 비교하지 않음.
- battle P1589 `B.redo`: 같은 bn으로 재시작하며 난이도·편성·출처를 유지하는 전체 반환을 새 대조하지 않음.
- battle P1594 `B.load`: 고갈 횟수·마지막 일격 id·옛 필드 없음의 기본값은 재개 및 실제 D1 왕복 통과. 원본 VER2 전체 상태를 native로 읽는 통합 이관은 여전히 없음. 지시된 id 전용 last_kill로 원본 이름+기술 문구를 보존할 수 없어 이 차이도 남는다.
- battle P1595 `B.save`: native 저장에 고갈 횟수와 알려진 마지막 일격 id를 넣고 서버/D1/다른 기기/파일 재개를 검증했다. 원본 VER2 전체 왕복과 기술명 문구의 id 전용 표현 차이는 남는다.
- battle P1620 `B.battle_start`: 편성→전투 시작→scene/보상/식별자 저장까지의 G 변경 전체를 새 대조하지 않음.
- battle P1746 `B.strike`: 72가지 직접 strike와 기존 장비/사제/생존 회귀는 통과. 반환 ls/tags, 모든 구원 소유자 순서 및 필드 시간 이력은 남음.
- battle P1811 `B.e_attack`: 기존256+추가16개 단일/전체 공격 기록에서 치명 taunt 원문/시간을 수정. 여러 개인/장비 반격 훅을 섞은 모든 사건·반환·시간 순서 직접 대조는 남음.
- battle P1812 `B.e_attack_all`: 단일/전체 256입력의 대상별 시각·사망·보호자 상태·tags·피격 후 효과 비교. 다중 반격/장비 훅 혼합의 전체 사건/로그 대조는 남음.
- battle P1813 `B.enemy_turn`: 100종 각 행동·건강/손상652개 조합 편성의 차례 전체 상태·사건·로그·다음 RNG 직접 일치. fl 없는 옛 고정 적 차례 전체와 다중 개인/장비 훅 혼합 직접 대조는 남음.
- battle P1825 `B.finish`: 고갈 횟수는 저장 재개 뒤 유지한다. last_kill을 id만 저장하라는 지시 때문에 원본의 이름+기술 문구는 이름으로 복원되어 일부 정보가 빠진다. 실제 의뢰 출처/rg/qmult의 모든 정산 연결도 전체 직접 대조 미완료.
- battle P1831 `B.run`: 6320판 진행 결과는 비교. guard 80·모든 시작/라운드/사망·자동 방출의 전체 상태 경계는 남음.
- battle P1682 `B.ps_guild_tab`: 기존 길드 UI는 유지. 모든 prefix/suffix·dirty/ready·강화 상한/부족 금화 표시의 의미상 출력 전체는 새 대조하지 않음.
- battle P2351 `sbtn`: 버튼 MP/설명·disabled·선택 상태의 의미상 출력 전체를 새 직접 대조하지 않음.
- battle P2353 `B.r_act`: 기술 조건 회귀는 통과. 행동/아이템/대상 선택·취소·버튼 배열의 전체 새 대조는 남음.
- battle P2359 `B.render`: 기존 native 화면/오버플로 회귀는 유지. 모든 원본 상태에서 HUD·대상·로그·카메라의 의미상 전체 출력 대조는 남음.

재실행: `node tools/finish_r24_round4_oracle.mjs` 및 같은 접두사의 expe/settle/inn/shop oracle, `R24_FINISH_OUTPUT=verification/finish-r24/round4` 환경에서 `python tools/finish_r24_verify.py`와 `--cloud`. `npm test`는 기존 설치 경로를 ABYSS_NODE_MODULES로 지정하고 finish_r24_node_launcher.mjs를 NODE_OPTIONS --import로 사용한다. 전체 스캔은 `python tools/finish_r24_scan.py`이며 보호 대사가 남으면 종료 1이 정상 검출 결과다. 보고/표는 `python tools/finish_r24_round4_report.py`로 재생성한다.
