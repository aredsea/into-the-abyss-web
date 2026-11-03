"""Append functional-equivalence evidence; preserve every previously completed row."""
from pathlib import Path
from collections import Counter
import json,hashlib,subprocess,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23';P=O/'ui-phase3'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def loc(file,needle):
    for i,line in enumerate((R/file).read_text(encoding='utf-8').splitlines(),1):
        if needle in line:return f'{file}:{i}'
    raise ValueError((file,needle))
base=read(P/'ui-before.json');oracle=read(P/'ui-oracle.json');rules=read(P/'ui-semantics-results.json');native=read(P/'ui-native-results.json');cloud=read(P/'ui-cloud-results.json')
assert not rules['failures'] and not native['failures'] and not cloud['failures']
same_ids=set('P0104 P2480 P2492 P2494 P2497 P2498 P2499 P2511 P2512 P2513 P2514 P2515 P2518 P2520 P2531 P2532 P2533 P2576 P3816 P3817'.split())
anchors={'P0104':'button','P2480':'kind','P2492':'experience','P2494':'bar','P2497':'element','P2498':'button','P2499':'stats','P2511':'fxline','P2512':'gear_groups','P2513':'icon','P2514':'tile','P2515':'gear_card','P2518':'tabs','P2520':'tabs','P2531':'passive_block','P2532':'passive_block','P2533':'passive_groups','P2576':'chip','P3816':'table','P3817':'read_table'}
replacements={
 'P2701':'원본 서명 SHA 내부 ror → 엔진 SHA256/HMAC 및 Worker의 계정 인증. ui_rules_r23_test의 SHA/HMAC 블록·전 바이트 벡터와 서버 인증 검사가 대응한다. 단독 ror API를 이식했다고 주장하지 않는다.',
 'P2711':'원본 JSON 직렬화 copy → snapshot.duplicate(true)와 저장/복원용 임시 모델. cloud_journey의 입력 불변·쓰기 실패 보존 검사와 실제 두 클라이언트 저장/재개가 대응한다.',
 'P2712':'원본 v1·bag 문자열 payload → schema 3 전체 snapshot·UID 장비. 실제 upload/download에서 재화·동료·장비·진행 왕복, 손상/옛 저장 거부·이관을 검사한다. wire 필드와 이름 제외 정책은 동일하다고 주장하지 않는다.',
 'P2713':'원본 /s#payload.signature 링크 → 별도 Worker 계정 코드 공유·코드만으로 읽기. offline signed_link 조립도 ui_rules의 원본 벡터와 일치하지만, 실제 사용자 공유 경로는 /v1 계정이다.',
 'P2716':'원본 cloud_apply 정리/가방 합치기 → settings_world.restore를 임시 모델에 적용한 뒤 로컬 백업/쓰기 성공 후 교체. 손상/지원 안 되는 저장·쓰기 실패는 현재 모험과 CAS 커서를 보존한다.',
 'P2717':'원본 cloud_apply 내부 gear_ok → native restore의 알려진 장비·UID·장착 검증. gear/state 회귀와 실제 클라우드 snapshot 왕복으로 대응한다. 원본의 잘못된 장비만 버리는 wire 정리 정책과 동일하다고 주장하지 않는다.',
 'P2718':'원본 getChatVar에 저장한 ui.msg → Cloud.notice 및 changed 신호. 실제 잘못된 코드/PIN·offline·충돌 안내 화면과 원본 실패분기를 대응 검사한다.',
 'P2724':'원본 cloud_button 입력/받기 → cloud 화면의 계정 연결·서버 최신 받기·확인/취소. source 26분기와 native 40검사, 실제 서버 잘못된 PIN·읽기 전용·받기·충돌 검사. AI 대화 전송은 호스트 제외.',
 'P2725':'원본 async task → Cloud.connect_account/download의 HTTPRequest await. 원본 취소/무효 입력/HTTP 오류/손상/성공 분기와 native의 상태 보존·재개를 대응한다.',
 'P2728':'원본 PIN 연결 전 rev 요청 callback → /v1/account/connect 검증 및 rev 취득. 6자리 PIN은 지시된 10자리 PIN으로 대체; 검증 전 로컬 모험을 올리지 않는 보호도 실제 서버로 시험한다.',
 'P2730':'원본 /l/<code> 받기 callback → 코드만으로 GET /v1/save/<code>와 PIN을 통한 /v1/save/read. 읽기 전용과 404/429/서버 오류/손상 저장 보존·성공 재개 시험으로 대응한다.',
 'P2731':'원본 async pcall 오류 wrapper → HTTPRequest 결과 검사·notice·busy 해제. 실제 offline과 실패 뒤 재시도, 입력/손상 오류 대응을 시험한다. RisuAI async 수명은 호스트 제외.',
 'P2735':'원본 dk_rank JSON cache → 계정별 native preferences의 rank_cache_r23. 재시작 유지·다른 계정 차단·손상 캐시 폐기·실패 시 과거 pct 제거를 cloud_compat에서 검사한다.',
 'P2736':'원본 rank cache getChatVar callback → native preferences 읽기와 table-only JSON 파싱. P3816/17의 손상/스칼라/배열/읽기 불가 대조와 cloud_compat 계정별 cache 재개가 대응한다.',
 'P2737':'원본 rank_head 최고층·pct·새로고침 → rank_page 최고층/같은 best의 pct/새로고침. 다른 best의 pct를 숨기는 원본 fixture, 실제 native 순위 화면·서버 결과로 대응한다.',
 'P2739':'원본 rank_refresh의 별도 비동기 진입 → rank_refresh 버튼이 Cloud.fetch_rank에 직접 연결된다. 실제 native 화면 검사와 실제 Worker /v1/rank를 사용한다.',
 'P2740':'원본 B.H.rk의 /r/best·300초 → /v1/rank 등록/조회·300초. 원본 now/at 경계 벡터, 실패 요청도 allowance 소비·재시작 throttle 및 실제 서버 순위 시험.',
 'P2742':'원본 순위 request callback → HTTPRequest POST/GET 순위. 실제 성공/무기록과 offline·이전 pct 제거, server percentile/동률 검사가 대응한다.',
 'P2743':'원본 응답 JSON decode callback → native HTTP 응답 dictionary 검사·rank cache validation. 잘못된 pct/필수 메타데이터 폐기·실패시 과거 백분위 미표시와 서버 순위 시험.',
 'P2622':'원본 cloud_card의 올리기 링크/받기/PIN 등록 → native cloud의 계정 만들기/지금 저장/최신 받기/코드·PIN 연결. 실제 서버 왕복·읽기 전용·충돌과 native 연결/자격증명/충돌/확인 화면 시험으로 대응한다.',
 'P2628':'원본 save 패널 → native cloud 화면. 계정 코드 공유, 올리기, 받기, PIN, 상태/오류/충돌을 실제 서버 및 native UI로 검사한다. 원본 HTML 정적 링크 반환은 대체 경로의 동일성 기준이 아니다.'}
excluded={
 'P0123':'pend_hard 내부 callback은 getChatLength/getChatRole/addChat으로 RisuAI 대화에 user 메시지를 넣는다. 채팅/AI 호스트 전용이므로 공통 규칙에 따라 제외.',
 'P0128':'pimg_kick callback은 RisuAI async·getPersonaImage 요청을 시작한다. 호스트 전용 이미지 수집이므로 제외; native 초상 fallback은 별도 P2496/P3721에 남긴다.',
 'P0129':'pimg_kick 중첩 callback의 reloadDisplay/nudge는 RisuAI Lua 수명/채팅 재그리기 전용이므로 제외.',
 'P0130':'pimg는 dk_pimg·inlayed 토큰·source::user라는 RisuAI 페르소나 아바타를 읽는다. 호스트 전용으로 제외; native 동료 초상 표시와 합쳐서 제외하지 않는다.'}
remaining={
 'P0017':'원본 G_new의 관찰 투영(빈 생성·아이템·진행·난수 초기화)을 native 전체 초기 상태와 연결하는 시험이 더 필요하다. 기본 생성과 기본 재화 회귀는 통과. 초기화 연결은 수정 금지 persona_world.gd/town_world_r21.gd에 있다.',
 'P0084':'원본 G_migrate는 누락 필드를 채우지만 native는 schema 없는 원본 G와 잘못된 타입을 전체 거절한다. 기존 native schema 1/2 보존 시험만으로 원본 v1 이관까지 같음으로 올리지 않는다. 연결은 수정 금지 persona_world/상위 world 경로.',
 'P0085':'원본 load의 초과 경험치 정산·잘못된 장착 환원과 native restore의 전체 관찰 투영 대조가 남았다. 기존 저장 보존은 통과하나 수정 금지 persona_world/원정·장비 연결을 변경하지 않았다.',
 'P0089':'파싱/타입/캐시 분기는 원본과 일치. 제품의 public 부분 사전은 원본 전체 pack과 같은 집합이 아니다. 이번 57개 공개 키를 보완했으나 제외된 호스트/성인 키를 빼고 모든 공개 키를 대조한 증거는 아직 없다.',
 'P0090':'치환 알고리즘 경계는 일치하지만 모든 공개 문자열의 사전 범위를 아직 전부 비교하지 않았다. 원본 B.U와 B.T가 다른 키 공간을 쓰므로 render fallback으로 두 함수를 통째로 같음 처리하지 않는다.',
 'P0091':'중첩/반복/미지정/조사 callback 대조는 통과. 상위 B.U의 전체 공개 키 범위와 실제 화면 번역 연결은 P0090과 함께 잔여.',
 'P0092':'JSON 오류/스칼라/배열/캐시 분기는 일치. 원본 en_dict 전체 공개 사전 반환 집합과 native words 집합을 전수 비교하지 않아 잔여.',
 'P0095':'비문자 타입 보존과 공개 실행 키는 일치. UI의 render가 B.U 키를 먼저 읽는 경로와 원본 B.T 경로가 모든 문구에서 같은지 전수 확인하지 않았다.',
 'P0097':'로컬 atomic write/백업/재개와 연대기 flush는 기존 회귀 통과. 원본 v1에서 저장 뒤 관찰할 전체 값(코드 장비·상태·진행)을 native UID에 투영하는 대조가 남았다. 저장 매체 차이만을 사유로 남기지 않는다.',
 'P0101':'원본은 time/clock/random을 결합하나 native는 생성 확정 뒤 randi_range로 seed를 고른다. 같은 시간/난수 입력에서 같은 seed/소비 횟수가 되지 않는다. 수정 금지 persona_world.gd의 create_action 연결이 필요.',
 'P0105':'원본 HUD의 장소·금화·즐겨찾기 얼굴·상태/도감/저장/설정 순서와 현재 native 상단/하단에 분산된 동작을 전수 대조하지 않았다. 일부 HUD 연결은 수정 금지 town_screen_r21.gd.',
 'P0131':'생성/첫 만남/패널 조립은 회귀 통과. 알 수 없는 scene과 화면 함수 오류의 사용자 표시 및 override 분기의 native 대응을 아직 원본과 직접 비교하지 않았다. 호스트 잠금/성인 override 자체는 제외 범위.',
 'P0133':'원본 route의 무효 접두/중복 버튼/저장 실패 뒤 부수효과 경계와 native world_screen 전체 경로의 직접 대조가 남았다. 상태 탭 등 개별 handler 같음은 유지.',
 'P2370':'C1_en은 언어와 무관하게 en_dict를 읽으며 false/nil도 빈 문자열로 처리한다. native create 화면의 render는 선택 언어를 따르므로 이 helper의 독립 계약과 같은 대응을 아직 확인하지 않았다.',
 'P2416':'생성 특성 행은 원본 영어 te_raw→번역→ptx 순서를 쓰나 native create_screen.traits는 사전 보간된 te와 별도 syn_text를 섞는다. 설명/라벨/2·3인 수치의 전수 직접 대조가 필요. persona_rules는 이번 수정 금지.',
 'P2417':'원본 opt는 선택/차단 선택지에도 원래 name/sub를 표시한다. native 국가 옵션은 차단 시 선택 불가 문구를 추가하고 일부 tag를 생략한다. 생성 화면의 선택지 문구/순서 대조가 미완료.',
 'P2418':'원본 단계 머리의 n / 5·단계 이름·설명 세 항목 중 native는 별도 머리/질문으로 나누며 n / 5가 없다. 단순 HTML 차이가 아니라 표시 항목 차이.',
 'P2419':'원본 단계 버튼에는 번호와 단계명이 함께 있다. native는 이름만 그리며 비활성 조건은 기존 규칙 시험 통과. 번호/순서를 포함한 화면 직접 대조가 남았다.',
 'P2421':'원본 뒤로/다음 레이블의 삼각형과 native 레이블이 다르고, 마지막 확정 버튼의 모든 불완전 입력 조합을 현재 포인터 시험과 연결하지 않았다.',
 'P2425':'원본 종족 미선택 안내·수인 계통 tag/선택별 개인 효과와 native traits 중복/표시 항목 차이를 아직 전부 메우지 못했다. 규칙 경계 수정은 금지 persona_rules 경로.',
 'P2426':'국가 선택의 전체 tag·차단 사유 표시/선택 유지와 native의 선택 불가 덧붙임/tooltip을 직접 대조해야 한다. 원본과 다른 문구가 남아 있어 잔여.',
 'P2427':'원본 직업의 수치/스킬/출신 주의 문구와 native 요약이 모든 직업에서 동일한 순서·내용인지 직접 대조하지 못했다. 규칙 파일은 이번 수정 금지.',
 'P2428':'원본 총량 프리셋 설명·직접 모드 ±1/±5 및 native 표시의 일부 문구/설명이 다르다. 총량 수치/경계 기존 시험 통과와 화면 전체 같음은 구별했다.',
 'P2434':'원본 능력치 단계의 추천·초기화·증감/상한/HP·MP 설명 전체와 native 화면의 문구/순서를 직접 대조하지 못했다. 규칙 경계는 수정 금지 persona_rules.',
 'P2439':'원본 확정 화면의 종족/국가 개인 특성과 시너지 요약에 비해 native는 이름/능력치 중심 요약이다. 실제로 빠진 항목이 있어 잔여.',
 'P2441':'원본 SUB[5] callback은 pg_confirm을 호출한다. 별도 호스트 전용 함수가 아니며 위 P2439 확정 표시 차이가 그대로 남는다.',
 'P2442':'원본 create 합성의 단계 머리/특성/확정 설명 누락은 P2418/P2425/P2439와 연결된다. 원본 전체 HTML 문자열 차이를 잔여 이유로 사용하지 않는다.',
 'P2462':'원본 CR.face는 페르소나 호스트 아바타와 동료 초상/이니셜을 고른다. 호스트 부분은 제외하지만 첫 만남의 없는 초상 fallback은 아직 직접 대조하지 않았다.',
 'P2463':'원본 첫 만남 선택지의 장소/상황 설명과 native 선택 버튼은 companion 이름 위주로 다르다. 선택한 동료의 미리보기 외 모든 선택지 정보/순서를 비교해야 한다.',
 'P2467':'원본 첫 만남 시작은 seed 설정·동료/호감/아이템·서술 지시를 함께 바꾼다. AI 지시는 제외하지만 native seed 소비 및 출발 상태 관찰 대조가 남으며 persona_world/persona_rules 수정 금지.',
 'P2496':'동료 기본 초상 경로 선택은 기존 oracle와 일치. 이름 인수가 있는 미등록 인물/없는 에셋에서 원본 이니셜과 native 빈 fallback을 아직 전체 대조하지 않았다. RisuAI 아바타 수집 자체는 제외.',
 'P2500':'일반/빈 알림 표시 8개는 직접 대조 통과. 원본 ui.msg의 markup/entity와 native plain-text 알림 규약을 모든 거래/사용자 이름에 대해 연결하지 않아 함수 전체 승격은 보류.',
 'P2501':'원본은 유효 장비 코드→이름, 구 아이템 id→이름, 알 수 없는 id→그대로를 지원한다. native 도감 장비는 UID 중심이고 옛 item fallback의 실제 화면 연결을 전수 대조하지 않았다.',
 'P2521':'도감 tile의 속성 누락은 보완했으나 원본의 호감 막대·즐겨찾기 표시와 native 숫자/텍스트 표시는 전체 일치하지 않는다. 미영입 잠금/실제 선택은 기존 UI 검사 통과.',
 'P2523':'필터·페이지·미영입 선택 제한은 회귀 통과. 원본의 persona 버튼→tabs 순서와 native tabs→persona 순서 및 tile 호감 표시 차이가 있어 잔여.',
 'P2528':'슬롯별 후보 최대 4개·더 보기 안내·Lv·아이콘과 전투 중 후보 조회/장착 handler 거절 안내를 보완했다. 12번째 장비도 실제 가방 경유 장착·저장 재개 통과. 전투 화면에서 패널 진입, 옛 item fallback·가득 찬 가방·무효 코드↔UID 상태 왕복까지 직접 연결한 증거가 없어 잔여. 장비 규칙 파일 수정 금지.',
 'P2534':'이름/능력치/패시브/장비 아이콘·후보 4개 제한은 보완. 전체 상세의 개인 특성 아이콘·정보 순서와 장착/해제 경계 P2528의 직접 대조가 남아 합성 함수는 잔여.',
 'P2537':'persona/영입 상세/미영입 목록 분기는 native에 있다. 선택별 전체 관찰 결과가 P2523/P2534 차이를 상속하므로 합성 함수는 잔여.',
 'P2539':'필터/선택/즐겨찾기/가방 이동은 기존 312입력 대조 통과. 원본 코드형 eq_/un_와 UID형 실제 장착/해제의 가득 찬 가방·옛 item·재개 관찰을 전부 연결하지 않았다. 장비 규칙 변경 금지.',
 'P2563':'원본 즐겨찾기 카드의 속성 태그·호감 문구·HP/MP/도감 보기 순서와 native status 카드의 값/순서 전체를 직접 대조하지 않았다. 현재 status 카드에는 속성 태그가 빠져 있다.',
 'P2565':'원본 st_me의 persona/패시브/즐겨찾기/빈 안내와 native status 합성의 버튼/문구/순서 대조가 남았다. 성인 NPC 카드 자체는 제외이며 그 사유만으로 전체 함수를 남기지 않는다.',
 'P2567':'전투 상태창 단위의 아군 MP/적 심연/상태칩/사망 표시와 native 전투 inspector를 원본 st_unit 출력에 직접 대조하지 않았다. 전투 파일은 이번 수정 금지.',
 'P2568':'전투 승리/패배 표지·아군→적 순서·redo 초기화와 native 상태 패널의 직접 대조가 남았다. 전투 파일 수정 금지로 다음 차수에 남긴다.',
 'P2578':'가방 필터 chip·tile 아이콘/Lv 문구는 새 대조에 맞췄다. 원본 20개 페이지 및 일반 일괄판매 버튼 전체의 정보/순서·빈 필터·페이지 경계 직접 연결 대조가 아직 남는다.',
 'P2586':'실제 선택/장착/이름·수치 재개와 카드 아이콘은 보완/검사했다. 원본 비교의 빈 효과를 -로 표시하는 규약과 native +0%, 모든 유니크/확인 버튼 문구 차이가 있어 잔여.',
 'P2592':'목록/상세/가방 상태 정규화는 native에 있다. 선택 코드가 없어진 경우의 원본 fallback·목록 페이지 관찰과 native 전체 합성을 아직 직접 대조하지 않았다.',
 'P2593':'70개 거래 알림/거부는 기존 source fixture 일치. 2,000칸 경계·이미 팔린 선택·중복 장비 코드와 UID 장착의 재개 전체 관찰 연결이 남았다. 장비 규칙 파일 수정 금지.',
 'P2606':'상태창의 me/battle/bag 탭 및 전투 중 bag 숨김/거부에 대한 값 시험은 있으나 전체 표시 정보·버튼 순서는 P2565/P2568/P2578의 잔여 차이를 상속한다.',
 'P2617':'원본 HUD 즐겨찾기 최대 3명 얼굴·선택 버튼과 native HUD의 실제 진입/배치 대응을 직접 대조하지 않았다. 연결 대상 town_screen_r21.gd는 수정 금지.',
 'P2629':'호스트 전용 art/chap/diet/redraw·성인 설정은 제외. 공개 언어/난이도/연대기/저장/초기화의 설명·버튼 순서·reset 확인 후 재개 전체를 원본 화면에 직접 대조하지 않아 잔여.',
 'P2630':'원본 opt는 form 모드 radio 또는 버튼 모드를 선택하며 native는 버튼만 쓴다(form 호스트 부분 제외). public 언어/난이도/연대기의 모든 selected 조건과 레이블을 직접 대조한 증거가 더 필요.',
 'P2631':'호스트 요약/다이어트 토글은 제외. public chron의 on/off 선택/저장은 회귀 통과하지만 원본 사건 기록 설명 문구와 실제 native 설명 표시를 직접 대조하지 않았다.',
 'P2637':'public lang/diff/chron/reset은 native에서 작동하고 저장 보존 회귀 통과. 원본 reset의 tab guard·전체 초기 관찰 상태는 native archive/reset과 직접 연결 대조하지 않았다. 호스트/성인 설정 분기는 제외.',
 'P3721':'이름표 선택 320개는 기존 원본 대조 통과. 실제 선택 에셋별 리소스와 없는 variant→default→이니셜 관찰 전체를 이번에 전수 대조하지 않았다. 단지 asset 토큰/TextureRect 차이라서 남기는 것은 아니다.'}

suite=read(O/'regression.json');expected=subprocess.check_output([sys.executable,'tools/ui_r23_verify.py','list'],cwd=R,text=True,encoding='utf-8').splitlines()
assert len(suite)==len(expected) and {x['test'] for x in suite}==set(expected) and all(x['passed'] for x in suite)
servers=read(O/'server/results.json');assert all(x['exit']==0 for x in servers)
life=read(O/'server-lifecycle.json');assert life['ready'] and life['clean_shutdown'] and not life['forced_shutdown']
review=[]
for row in base['rows']:
    if row['status']=='같음':continue
    id=row['id'];old=row['status'];row['phase3_previous_status']=old
    row['source_calls_phase3']=oracle['calls'].get(Path(row['source']['file']).name+':'+str(row['source']['start']),0)
    evidence=[]
    if id in rules['groups']:
        g=rules['groups'][id];assert g['failures']==0
        evidence.append({'test':'project/tests/ui_semantics_r23_test.gd','result':'verification/parity-r23/ui-phase3/ui-semantics-results.json','group':id,'checks':g['checks'],'source_cases':'verification/parity-r23/ui-phase3/ui-oracle.json','comparison':'태그/스타일을 제외한 visible text/action/order/selected/disabled/bar ratio','comparison_passed':id in same_ids})
        if id=='P2512':evidence.append({'test':'project/tests/ui_semantics_r23_test.gd','result':'verification/parity-r23/ui-phase3/ui-semantics-results.json','group':'P2512.native-adapter','checks':rules['groups']['P2512.native-adapter']['checks'],'scope':'1,030종 × 한영, 실제 panel_gear.describe의 결과를 원본 gear_roll→gear_fx의 보이는 효과와 비교','comparison_passed':True})
    if id=='P2528':evidence.append({'tests':['project/tests/ui_semantics_r23_test.gd','project/tests/ui_semantics_native_r23_test.gd','project/tests/ui_parity_r23_test.gd'],'source':'verification/parity-r23/ui-phase3/ui-oracle.json#battle_preview','group':'P2528.battle-preview','scope':'거점/전투의 원본 12개 후보 목록 대조·전투 중 장착 handler의 상태 보존/거절 안내·4개 미리보기와 12번째 가방 포인터 장착/재개','comparison_passed':False,'note':'해당 분기는 통과; 실제 전투 화면에서 패널 진입은 미검증이며 전체 함수의 다른 경계도 잔여'})
    if id in same_ids:
        assert id in rules['groups'] and row['source_calls_phase3']>0,(id,'source function not executed')
        row['status']='같음';row['remaining_reason']=''
        file='project/game/ui_json_r23.gd' if id in {'P3816','P3817'} else 'project/game/ui_semantics_r23.gd'
        if id=='P2515':file='project/ui/panel_screen_r22.gd'
        row['phase3_modified']={'file':loc(file,'func '+anchors[id]+'('),'change':'공개 표시/저장 getter의 기능 등가를 원본 실행 fixture로 고정하고 실제 native 화면/저장 경로에 연결'}
        if row.get('modified') and not row.get('phase2_modified'):row['earlier_modified']=row['modified']
        row['modified']=row['phase3_modified']
        if id not in {'P3816','P3817'}:evidence.append({'test':'project/tests/ui_semantics_native_r23_test.gd','result':'verification/parity-r23/ui-phase3/ui-native-results.json','checks':native['checks'],'scope':'3개 휴대폰 크기 × 한영; 실제 필터 클릭·선택 표시·저장/재개·수치·장비 화면'})
    elif id in replacements:
        row['status']='대체';row['remaining_reason']='';row['replacement_mapping']=replacements[id]
        evidence.append({'tests':['project/tests/ui_cloud_replacement_r23_test.gd','project/tests/cloud_r22_test.gd','project/tests/cloud_compat_r23_test.gd','project/tests/cloud_journey_r23_test.gd','project/tests/ui_cloud_r22_test.gd'],'source_cases':'verification/parity-r23/ui-phase3/ui-oracle.json#cloud','source_branches':len(oracle['cloud']),'new_native_checks':cloud['checks'],'results':['verification/parity-r23/ui-phase3/ui-cloud-results.json','verification/cloud-r22/native-service-results.json','verification/parity-r23/cloud-compat-results.json','verification/cloud-r22/native-ui-results.json','verification/parity-r23/server/results.json'],'scope':replacements[id],'comparison_passed':True,'contract':'의도적 대체의 사용자 기능 대응; 원본 wire/UI 문구/수치 전체 동일성을 뜻하지 않음'})
    elif id in excluded:
        row['status']='제외';row['remaining_reason']='';row['exclusion_reason']=excluded[id]
        evidence.append({'source':row['source'],'rule':'r21-common.md: RisuAI 채팅/AI/호스트 전용 제외','scope':excluded[id]})
    else:
        assert id in remaining,id
        row['remaining_reason']=remaining[id]
        evidence.append({'review':'verification/parity-r23/ui-phase3/ui-row-review.json','scope':remaining[id],'comparison_passed':False})
        if id in {'P2521','P2528','P2534','P2578','P2586'}:
            file='project/ui/codex_screen_r22.gd' if id in {'P2521','P2528','P2534'} else 'project/ui/inventory_screen_r22.gd'
            needle='func build(' if id in {'P2521','P2578'} else 'for slot in R.DATA.slots:' if id=='P2528' else 'func detail('
            row['phase3_modified']={'file':loc(file,needle),'change':'누락 속성·장비 후보 최대 4개/더 보기·아이콘/Lv·상세 부가 정보 위치를 보완; 전체 함수 판정은 일부 유지'}
            if row.get('modified'):row['earlier_modified']=row['modified']
            row['modified']=row['phase3_modified']
    row['new_evidence']+=evidence
    review.append({'id':id,'source':row['source'],'previous_status':old,'status':row['status'],'new_evidence':evidence,'remaining_reason':row['remaining_reason']})
assert len(review)==99
before=read(P/'ui-before.json');before_same={x['id']:x for x in before['rows'] if x['status']=='같음'}
assert all(x==before_same[x['id']] for x in base['rows'] if x['id'] in before_same)
assets=read(R/'ASSET-HASHES.json');changed_assets=[a['path'] for a in assets if hashlib.sha256((R/a['path']).read_bytes()).hexdigest()!=a['sha256']];assert not changed_assets
battles=[]
for name in ['p2-full-battles.json','a6-mixed-audit.json','p3-mixed-audit.json','a7-gear-audit.json','a7-gear-balanced-audit.json','a8-audit.json','a9-native-10-audit.json','a9-native-40-audit.json']:
    v=read(R/'verification/data-r21'/name);n=v['battles'];equal=v.get('equal_battles',n if not v.get('field_differences') else 0);battles.append({'file':name,'battles':n,'matched':equal})
assert sum(x['battles'] for x in battles)==sum(x['matched'] for x in battles)==6320
counts=Counter(x['status'] for x in base['rows']);left=[x for x in base['rows'] if x['status'] not in {'같음','대체','제외'}]
changes=[];hashes=read(P/'ui-hashes-before.json')
for folder in ['project','tools','server']:
    for p in (R/folder).rglob('*'):
        if not p.is_file() or any(k in p.parts for k in ['node_modules','.godot','__pycache__']):continue
        key=p.relative_to(R).as_posix();sha=hashlib.sha256(p.read_bytes()).hexdigest()
        if hashes.get(key)!=sha:changes.append(key)
for key in changes:
    assert Path(key).name not in ['town_world_r21.gd','town_rules_r21.gd','facilities_world_r22.gd','town_screen_r21.gd','facilities_screen_r22.gd','dungeon_world_r21.gd'],key
    if key.startswith('project/game/'):
        name=Path(key).name
        assert name not in ['town_world_r21.gd','town_rules_r21.gd','facilities_world_r22.gd','town_screen_r21.gd','facilities_screen_r22.gd','dungeon_world_r21.gd']
        assert not name.startswith(('persona_rules','persona_world','expedition_','battle','combat','gear_rules'))
    assert not key.startswith('server/'),key
original_changed=[]
for source in oracle['sources']:
    p=Path('C:/Clauede Code/dungeon-bot/bot/src')/source['file']
    if hashlib.sha256(p.read_bytes()).hexdigest()!=source['sha256']:original_changed.append(str(p))
assert not original_changed
prior_provenance=read(O/'ui-provenance.json')
assert all(hashlib.sha256((Path('C:/Clauede Code/dungeon-bot')/source['file']).read_bytes()).hexdigest()==source['sha256'] for source in prior_provenance['source_files'])
icon_assets=read(P/'ui-gear-assets.json')
for a in icon_assets:
    assert hashlib.sha256((R/a['path']).read_bytes()).hexdigest()==a['sha256']==hashlib.sha256(Path(a['source']).read_bytes()).hexdigest()
passives=read(Path('C:/Clauede Code/dungeon-bot/design/passives.json'))
assert all(oracle['passives'][key]==passives[key] for key in ['classes','races','nations'])
big=[str(p.relative_to(P)) for p in P.rglob('*') if p.is_file() and p.stat().st_size>50_000_000];assert not big
s=base['summary'];phase={'reviewed_rows':99,'promoted_same':len(same_ids),'fixed_rows':len(same_ids)+5,'replacement_rows':len(replacements),'excluded_rows':len(excluded),'remaining_rows':len(left),'new_rule_checks':rules['checks'],'new_native_checks':native['checks'],'new_cloud_checks':cloud['checks'],'source_cloud_cases':len(oracle['cloud']),'captures':len(native['captures']),'copied_original_icons':len(icon_assets)}
s.update({'promoted_same':counts['같음'],'replaced_rows':counts['대체'],'excluded_rows':counts['제외'],'remaining_rows':len(left),'remaining_counts':dict(Counter(x['status'] for x in left)),'fixed_rows':sum(bool(x.get('modified')) for x in base['rows']),'project_groups':len(suite),'project_failed_groups':0,'server_groups':len(servers),'server_failed_groups':0,'combat_battles':6320,'combat_matched':6320,'changed_assets':[],'phase3':phase})
s['rule_checks']=before['summary']['rule_checks']+rules['checks'];s['native_ui_checks']=before['summary']['native_ui_checks']+native['checks'];s['native_ui_captures']=before['summary']['native_ui_captures']+len(native['captures'])
s['fixed_and_promoted']=sum(bool(x.get('modified')) and x['status']=='같음' for x in base['rows']);s['fixed_remaining_partial']=sum(bool(x.get('modified')) and x['status'] not in {'같음','대체','제외'} for x in base['rows'])
base['method']+=' Phase 3 applies r21-common functional equivalence. Same/excluded/replaced are separate; previous 45 same rows are byte-equivalent JSON objects. Partial composite functions are not promoted merely because child functions pass. All 99 remaining rows reviewed; concrete unverified/missing behavior is retained per row.'
write(O/'ui.json',base);write(P/'ui-row-review.json',review);write(P/'ui-summary.json',{**s,'counts':dict(counts),'combat':battles,'changed_files':changes})
write(P/'ui-write-audit.json',{'changed_files':changes,'changed_original_assets':changed_assets,'copied_source_icons':len(icon_assets),'copied_icon_bytes':sum((R/a['path']).stat().st_size for a in icon_assets),'changed_source_files':original_changed,'server_disk_changes':[],'forbidden_rules_changed':[],'git_commands':False,'web_export':False,'docs_writes':False,'files_over_50MB':big,'notes':'Import-created .gd.uid/.webp.import sidecars are listed separately from product implementation. Existing port 8787 was never killed or reused.'})
write(P/'ui-suite-coverage.json',{'expected':expected,'executed':[x['test'] for x in suite],'missing':[],'failures':[]})
report=f'''# R23-ui · 3차 기능 등가 재판정

3차 잔여 99행 검토: **같음 +{len(same_ids)}, 수정·보완 {phase['fixed_rows']}행(같음과 중복), 대체 {len(replacements)}, 호스트 제외 {len(excluded)}, 잔여 {len(left)}행**.
누적 **같음 {counts['같음']}/144 · 대체 {counts['대체']} · 제외 {counts['제외']} · 남음 {len(left)}**. 전체 이식 완료는 아니다. 기존 같음 45행은 판정/근거를 변경하지 않았다.

행별 기존 상태·정본 위치·새 시험·대응 기능·구체적인 잔여 이유는 [ui.json](verification/parity-r23/ui.json), 이번 99행만은 [ui-row-review.json](verification/parity-r23/ui-phase3/ui-row-review.json). 이전 보고서는 ui-phase3/ui-report-before.md에 보존했다.

## 구현과 직접 대조

- 공용 표시 함수를 실제 도감/가방/상태 화면에 연결했다. 단계별 HTML을 비교하는 대신 표시 글·순서·버튼 action/선택/비활성·막대 값을 원본 Lua 실행 결과에서 추출했다.
- 도감 하위 필터 선택 표시와 원본 ‘모두’/가방 ‘전체’ 문구, 누락 속성, 소수 능력치, 최대 레벨/현재 경험치 막대를 보완했다. 장비 기본/무작위/고유 효과의 순서·수치·한영 문구를 1,030종 실제 native 어댑터와 비교했다.
- 정본 장비 아이콘 220개(278,882바이트)를 새 경로에 그대로 복사했다. 1,030종 전체의 아이콘 선택/리소스·등급·이름/Lv/선택지 유무·한영 장착 문구를 비교하고 가방/도감 후보/장비 카드에 연결했다. 후보는 원본처럼 슬롯당 최대 4개와 더 보기 안내로 제한한다. 아이콘을 추가한 뒤 import를 갱신하고 새 검사·실제 화면을 재확인했다.
- 도감 구성요소는 원본처럼 전투 중에도 후보를 조회할 수 있게 하고 장착 handler는 거절 안내를 낸다. 조회만 전투 변경 가드와 분리했으며 실제 장착/해제는 기존 가드로 거절되고 장비가 보존되는지 시험했다. **실제 전투 화면에서 패널에 진입하는 전체 경로는 미검증/잔여**다. 전투 규칙은 변경하지 않았다.
- 패시브는 정본 passives.json과 같은 원문을 사용하고 번역 뒤 변수 치환을 적용한다. 수인 dog/cat/미선택, 빈 node/미선택 직업, 2·3인 단계/준비 중 분기를 검사했다. persona_rules 파일은 읽기만 했다.
- table-only JSON getter는 객체/배열/스칼라/오류/파일 읽기 불가를 실제 파일 저장·재읽기로 비교하고 클라우드 preferences 읽기에 연결했다. 사용자 게임 저장 형식은 바꾸지 않았다.
- 원본 cloud_button의 취소/잘못된 코드·PIN/404/429/500/망가진 응답·저장/지원 버전/성공/통신 오류 26분기를 실행했다. native 입력/실패/복원/재개 40검사와 실제 Worker/D1 왕복·PIN 거부·읽기 전용·충돌·순위·cache 재개 시험을 ‘대체’ 근거로 썼다. 행별 대응은 ui.json의 replacement_mapping이다.

## 직접 실행 결과

|검사|결과|
|---|---:|
|새 원본/native 의미 대조 + 실제 장비 어댑터 + JSON getter|{rules['checks']:,} / 실패 0|
|새 native 화면/포인터/저장 재개|{native['checks']:,} / 실패 0 / {len(native['captures'])}캡처|
|새 클라우드 대응 분기|{cloud['checks']} / 실패 0|
|현재 프로젝트 import·전체 시험·전투 trace|{len(suite)}종 / 실패 0 / 누락 0|
|로컬 Worker/D1 전체 package 시험|{len(servers)}종 / 실패 0|
|전투 대조|6,320 / 6,320판 일치|
|보호 원본 자산|96개 / 변경 0|

초기 새 표시 경계 미구현 4,546실패는 ui-phase3/ui-baseline.json에 보존했다. 원본 빈 Lua table의 JSON 배열 표현은 table 등가로 처리한다. 새 fixture 개발 중 잘못된 settings fixture·동종 비교·누락된 battle 구조·존재하지 않는 host 속성 가정도 수정했고 최종 SCRIPT ERROR 0을 확인했다. 실제 전투 패널 진입은 시험했다고 주장하지 않는다.

기존 ui_parity_r23_test의 ‘도감에 후보 12개 모두 표시’ 기대값은 정본 65-codex.lua의 PX.CX_CAND=4에 맞춰 ‘4개 미리보기 + 나머지는 가방에서 접근’으로 수정했다. 4번째 미리보기와 12번째 장비를 실제 가방 페이지/포인터로 장착하고 저장 재개까지 검사한다. 변경 전 실패 로그는 ui-phase3/ui-candidate-expectation-before.log, 최초 전체 검사 집계는 ui-phase3/ui-regression-full-initial.json에 보존했다. 다른 기존 기대값은 바꾸지 않았다.

전체 검사 전 첫 서버 실행은 기존 8787 리스너에 내부 proxy가 붙어 401로 종료했다. 기존 프로세스는 건드리지 않았다. tools/ui_r23_phase3_server.mjs가 **원본 serve.mjs를 실행하면서 runtime(8787)만 메모리에서 runtime()으로 바꿔** 별도 포트를 배정한다. Worker/서버/시험 원본 디스크 파일은 변경 0. TEMP도 workspace 안에 격리했다. 최종 lifecycle: ready={life['ready']}, clean={life['clean_shutdown']}, forced={life['forced_shutdown']}. Windows root certificate store 진단은 별도 기록하고 SCRIPT ERROR/실패를 숨기지 않았다.

## 남은 범위

남은 {len(left)}행은 원본/현재 표시 항목 차이 또는 아직 직접 대조하지 않은 구체적인 분기를 각 id에 적었다. 예: 생성 단계 번호/특성·확정 설명, 개인 특성 아이콘과 전체 장착 경계, 상세 비교의 ‘-’ 대 ‘+0%’, 즐겨찾기 속성/호감 표시, 전체 공개 번역 키, 전투 상태 패널, 원본 v1 상태의 관찰 투영. HTML/CSS 반환·저장 매체·호스트 차이만으로 남기지 않았다.

수정 금지 persona_rules/persona_world/town/전투/원정 경로가 필요한 행은 해당 파일을 명시했다. **허용 UI 경로에도 미완료 표시 대조가 남아 있으며 이 차수에서 모두 고쳤다고 주장하지 않는다.** 원본 AI/채팅/아바타 수집 4행만 호스트 제외로 옮겼다. 복합 화면의 공개 기능까지 함께 제외하지 않았다. 성적 장면은 구현하지 않았다.

실제 화면은 360×780·390×844·430×932 × 한영. 직접 연 화면과 관찰은 ui-phase3/ui-visual-review.json에 있다. 장비 아이콘이 연결되어도 전체 언어/화면 이식 완성이나 사용자 시각 승인을 뜻하지 않는다. Impeccable 기계 검사는 변경 UI 3개에서 0건. 기존 .impeccable/design.json이 DESIGN.md보다 오래되었다는 진단은 기록만 했으며 `document`로 별도 갱신할 수 있다.

주요 변경: game/ui_semantics_r23.gd·ui_json_r23.gd·cloud_store_r22.gd·panels_state_r22.gd, ui/panel_screen_r22.gd·codex_screen_r22.gd·inventory_screen_r22.gd, data/localization-r22.json·ui-passives-r23.json·ui-gear-icons-r23.json, assets/ui-gear-r23/ 및 새 시험/도구. 전체 경로와 경계 감사는 ui-phase3/ui-write-audit.json. git 명령·Web export·docs 쓰기·서버 디스크 변경·원본 자산 변경 없음.

재현: node tools/ui_r23_phase3_oracle.mjs → python tools/ui_r23_phase3_data.py → python tools/ui_r23_verify.py → python tools/ui_r23_server_tests.py → python tools/ui_r23_phase3_report.py.
'''
(R/'R23-ui.md').write_text(report,encoding='utf-8');print(json.dumps({'counts':dict(counts),'phase3':phase,'project_groups':len(suite),'server_groups':len(servers)},ensure_ascii=True,indent=2))
