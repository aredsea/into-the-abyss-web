"""Produce the row ledger and delivery report from actual saved test results.

Function-entry coverage never upgrades a row on its own. Conservative decisions
below name an observable contract; incomplete event/log/save contracts stay open.
"""
from pathlib import Path
from collections import Counter
import json,hashlib,re,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
if (O/'batch-latest.json').exists():
 import runpy
 runpy.run_path(str(R/'tools/report_battle_r23_batch.py'),run_name='__main__')
 sys.exit(0)
read=lambda n:json.loads((O/n).read_text(encoding='utf-8'))
baseline=read('battle-baseline.json');coverage=read('coverage.json');cov={r['id']:r for r in coverage['rows']}
equal={
 'P1640':('battle_r23_compose_test','compose/pools first and cached','pools의 최초/캐시 반환 전체와 정본 100종 분류 목록'),
 'P1641':('battle_r23_compose_test','compose/flags','100종 및 1단계/2단계 행동·진입 소환/없음 6경계의 Boolean'),
 'P1642':('battle_r23_compose_test','compose/flags','100종 및 빈 행동/충전 행동의 Boolean'),
 'P1646':('battle_r23_compose_test','compose/fits','100종 × 7슬롯 제한 × 6기존 편성 = 4200 Boolean'),
 'P1660':('battle_r23_test','r23/persona_meta','실제 접두·접미 전체, 없는 id와 문자열 아닌 id의 조회 반환'),
 'P1717':('battle_r23_test','r23/debuff','공격/방어 약화·여우불 8조합 × 지속 피해 4종류의 Boolean'),
 'P1723':('battle_r23_test','r23/speed, r23/enemy_speed, r23/pack_speed','속도 반환: 종족 단계·사망·연금술사·검투사·카라쉰 처치·버프·적 HP 문턱·30% 하한'),
 'P1725':('battle_r23_test','r23/target','살아 있는 인원 0~4·자기 대상·최저 HP·무작위·동률·native aimed 별칭·RNG=1 경계의 표적과 RNG'),
 'P1733':('battle_r23_clock_test','clock/preview','현재/죽은/없는 행동자, 전원 이탈, 0/1/8/60/61/100개 요청과 원본 상태 불변'),
}
fixed={
 'P1725':'명시적 low가 aimed 별칭보다 우선. 별칭의 기본 low=true 유지. 난수 상한의 마지막 칸 클램프.',
 'P1875':'숨었다는 상태만으로 원거리 감경을 만들지 않고 ranged_dr 규칙이 있을 때만 적용.',
 'P1877':'되치기 경로의 재진입을 전투 단위로 막고 실제 타격 속성으로 weak_hit_delay를 판정.',
 'P1880':'되치기는 회피·총대 메기·일반 공격용 강화/분노/장기전 배율을 거치지 않고 원본 e_counter 식으로 strike.',
 'P1912':'빈 칸을 먼저 선택하고 같은 사건에서 바뀐 사망 칸 재사용을 막음. 옛 mob 등급 소환 칸 호환 유지.',
 'P1919':'소환 수 0/1/2/3/9, 한도·빈 칸 우선·직전 사망의 배치/RNG 순서를 수정.',
 'P1674':'미완성 조합은 무동작. 단일 지원의 쓰러진 대상에는 보호막·재생·강화를 남기지 않음.',
 'P1550':'전투 사이 HP=0 carry의 대기값 10^9 유지. JSON 저장 재개와 옛 유한 대기값 보존.',
 'P1553':'새 전투 초기화가 carry 사망자의 대기값을 10000으로 다시 덮지 않음.',
 'P2033':'carry 사망자를 통상 대기시간 뒤 조기 소생시키던 입력을 원본과 일치시킴.',
 'P2321':'마지막 일격의 0.15초 히트스탑은 원본이 전달하는 아군 공격 4종에만 적용.',
 'P2324':'eatk/eall/adot에 last 필드가 있어도 원본의 숫자/치명/보호막 callback 시각 유지.',
}
# These are specific missing contracts, not assertions that their native feature
# is absent. Original audit reasons and original missing-branch keys are retained.
reasons={
'P1473':'지능 인원에 따른 MP 회복은 회귀에 있으나 B.syn의 표시 배열 전체를 새 fixture로 직접 비교하지 않음.',
'P1474':'원본의 6개 로그·HTML·기록 시각과 native journal의 저장/표시 계약을 직접 정규화 대조해야 함.',
'P1477':'T와 칸 변경 추적을 검증했으나 ev.pre/h/q0 전체 및 과거 로그 t=-1은 native 사건 모델에 그대로 있지 않음.',
'P1482':'장비 setf 연결에 칸 변경 추적을 추가했으나 hp/mp/sh/ay 필드별 시간 이력 전체가 아직 없음.',
'P1485':'native 사건은 k/a/t/ht/targets를 보존하지만 원본 사건 payload 전체와 반환 참조 계약은 비교하지 않음.',
'P1488':'1~4인 정의의 직업·열·속성은 비교. 표시명/아트/특성 설명 및 미지 캐릭터·직업 fallback 전체는 남음.',
'P1489':'기술 실행/메타데이터 회귀는 통과. 모든 직업 목록의 순서·아이콘·설명·row 전체와 빈 슬롯은 직접 비교하지 않음.',
'P1490':'원본 번호 기반 SK 목록과 native 문자열 행동 id의 조회/찾지 못함 반환을 직접 비교하지 않음.',
'P1491':'1~4인 초기화는 비교. 저장된 pend/pid의 유지·재탐색·취소와 옛 id 없는 입력은 남음.',
'P1498':'단계 전환 상태는 비교. chiefb/eliteb의 깊은 이름·등급/표시 레벨·모든 정의 필드의 직접 비교가 남음.',
'P1499':'조합 편성 초기화는 실행. fl 없는 옛 EDEF 4칸과 DEF 16칸의 잔존 정의 제거는 새 fixture로 비교하지 않음.',
'P1500':'초기 HP/MP/주 능력·방어·속도 등은 비교. unit0의 모든 보조 플래그/필드와 native 대응의 전 필드 비교는 남음.',
'P1539':'carry·1~4인·Lv1/10/40은 비교. 옛 고정 적, 개인 초기 능력 비율, dm HP 하한 및 장비를 함께 묶은 전체 반환은 남음.',
'P1542':'페르소나 생성 stats 비율 보정의 누락/0 분모/숫자 문자열을 독립적으로 새 대조하지 않음.',
'P1550':'HP=0 대기값과 저장은 수정·검증. 없는 값/문자열/상한 초과 HP·MP/빈 4슬롯의 모든 carry 반환은 남음.',
'P1553':'초기화 48편성과 carry 소생 조건은 비교. 기본/옛 편성·dm·로그·q·first를 포함한 fresh 전체 반환은 남음.',
'P1587':'동일 편성 재시도의 bn 증가와 rg/qid/place/sid 이전 계약을 새 원본 fixture로 비교하지 않음.',
'P1589':'같은 bn으로 재시작하며 난이도·편성·출처를 유지하는 전체 반환을 새 대조하지 않음.',
'P1590':'native schema-3 이전 저장 유지 시험은 통과. 원본 VER2 8유닛의 rc/ln/na/bx/x 이관과 동일 계약은 아님.',
'P1594':'carry sentinel 및 옛 native 저장 재개는 통과. 원본 채팅 변수 JSON·VER2 이관·invalid→fresh의 계약은 별도 대조 필요.',
'P1595':'native JSON 왕복은 검증. 원본 채팅 변수에 쓰는 상태 전체와 native snapshot 간 완전한 필드 이관은 남음.',
'P1596':'채팅 길이/role을 검색하는 RisuAI 호스트 함수이며 native에서 같은 호스트 계약을 직접 재현하지 않음.',
'P1599':'실제 파티의 직업 능력치는 비교. id/한글 명칭/잘못된 명칭→nil 조회 전체를 직접 비교하지 않음.',
'P1600':'48편성의 실제 전투 수치는 비교. 반환 12필드 전체, 레벨 문자열/미지 직업/모든 동료 mod 경계가 남음.',
'P1601':'성장 보조식은 초기화 결과에 포함. 각 key/curve/grow/mod의 독립 입력과 전체 실수 반환 대조는 남음.',
'P1602':'기존 전투 피해와 새 상태 fixture에서 K를 사용. 모든 L/누락 L의 K 반환을 직접 비교하지 않음.',
'P1604':'조합 적 수치 회귀는 통과. 옛 mob/elite/boss와 잘못된 kind/star fallback의 enemy_stats 전체 반환은 남음.',
'P1613':'곡선 캐시를 비운 뒤 설정 변경이 다시 계산되는 계약을 새 fixture로 검증하지 않음.',
'P1616':'1~4인 전투 초기화는 검증. 편성 정리·페르소나 fight·빈 슬롯/장비/개인 stats의 battle_pm 반환 전체는 남음.',
'P1617':'옛 별 수별 고정 적 선택의 전체 반환을 새 원본 fixture로 비교하지 않음.',
'P1618':'균열 id/한글 의뢰명/알 수 없는 입력의 조회 반환을 새 비교하지 않음.',
'P1619':'층 편성 480개는 비교. 의뢰 종류/난이도/균열·씨앗의 quest_compose 전체 반환은 별도 필요.',
'P1620':'편성→전투 시작→scene/보상/식별자 저장까지의 G 변경 전체를 새 대조하지 않음.',
'P1630':'정수 씨앗 9개와 53비트 상한의 정확한 PM 상태는 비교. nil·소수·비숫자 seed 변환 전체는 남음.',
'P1631':'연속 8개 PM 상태는 정확 비교. mkrng의 전체 입력 형식/반환 closure 계약까지 승격하지 않음.',
'P1645':'정상 3원소에서 72회 선택은 비교. 빈 목록→nil과 비정상 RNG 경계의 반환은 새 비교하지 않음.',
'P1647':'1~4인·층 순서가 편성 480개에 포함. tcount 직접 덮어쓰기 및 독립 RNG 소비 계약은 남음.',
'P1650':'층 편성의 전체 출력 480개는 비교. rift/nonraid_union 등 모든 context와 소환 예약 칸의 독립 반환은 남음.',
'P1651':'편성 480개가 슬롯 확장/축소를 실행. 각 템플릿·tc·elite의 슬롯 배열 전체를 따로 비교하지 않음.',
'P1652':'편성에서 shuffle은 실행. 임의 배열/빈 배열/최종 RNG 상태의 직접 대조는 남음.',
'P1653':'DFS를 거친 편성 결과는 비교. 예산 소진·백트래킹 때의 작업 배열/예산/RNG 변경 전체는 남음.',
'P1654':'최종 전열 우선 안정 순서 480개는 비교. comparator의 동일 인덱스 등 직접 반환 fixture는 없음.',
'P1655':'native floor_enc는 dn.kind, 원본 floor_plan은 dn.stage를 사용. 상태 메타데이터까지 포함한 대응/이관이 남음.',
'P1699':'피해 수치는 비교하나 nm의 언어별 표시 문자열 반환을 독립적으로 새 대조하지 않음.',
'P1702':'피해에 약점이 쓰이는 회귀는 통과. nil el/wk·전 속성의 isweak Boolean을 새 독립 대조하지 않음.',
'P1705':'슬롯 정의의 cid/없는 정의 fallback을 native id와 직접 비교하지 않음.',
'P1706':'native는 존재하는 파티만 배열로 가짐. 원본 4칸의 빈 cid/찾지 못함을 포함한 slot 번호 반환 대조가 남음.',
'P1713':'보스별 기술 수치는 비교. 생존 보스 유무에 따른 보조 설명 문자열을 독립 비교하지 않음.',
'P1715':'기존 자기 차례 buff fresh/만료 회귀는 통과. bf 없음과 모든 보조 메타데이터의 직접 새 fixture는 없음.',
'P1720':'새 피해·개인 기술에서 hook dispatch가 실행됨. 소유자 순서·죽은 소유자·전역 훅의 payload/반환 전체는 남음.',
'P1721':'회귀가 훅 결과를 검사하나 nil 합성/다중 소유자 반환과 인자 전파를 독립 대조하지 않음.',
'P1722':'strike의 take 결과는 비교. 임의 훅 합성과 at 위치를 포함한 전체 chain_at 반환은 남음.',
'P1724':'trait 사건 시각의 회귀는 통과. nm/ab payload·명시적 at·언어별 문자열 전체는 남음.',
'P1726':'레비아 동작 회귀는 통과. foe 없음/빈 foe/초기 적 수의 enemy0 반환을 직접 새 비교하지 않음.',
'P1737':'기존 end_turn·저장 재개 회귀는 통과. 차례 끝 모든 플래그·buff·후크·고유 기술 상태를 새 fixture에서 전 필드 비교하지 않음.',
'P1746':'72가지 직접 strike와 기존 장비/사제/생존 회귀는 통과. 반환 ls/tags, 모든 구원 소유자 순서 및 필드 시간 이력은 남음.',
'P1760':'기술의 심연 수치는 비교. 반환 ab/list·레비아 전염·고갈 사건 시각·장비 훅 전체는 남음.',
'P1761':'주어별 한국어 조사/접속 문자열을 native 기록과 독립적으로 새 대조하지 않음.',
'P1762':'피해와 보호막 값은 비교. 약점·처치·보호막 등 모든 로그 문구/조사 조합은 남음.',
'P1772':'개인 기술/컷인 회귀는 통과. 해금 조건·소유자·문구 및 전 사건 payload 직접 새 대조는 남음.',
'P1789':'직업/페르소나 DOT 회귀는 통과. 오래된 집계형 저장·cap·소유자·장비별 초기 수명 전 필드의 새 대조는 남음.',
'P1806':'6인 기술 조건 72개는 비교. 모든 직업/장비 MP 할인·nil sk·등록 없는 개인 기술의 계약까지는 아님.',
'P1811':'전체 전투 대조는 유지. 단일 적 공격의 모든 evade/cover/after-hit/로그 반환을 새 독립 fixture로 비교하지 않음.',
'P1812':'전체 공격과 반격 순서 회귀는 통과. 각 회피/사망·tags·타격 시각을 새 직접 대조하지 않음.',
'P1813':'100종 행동 회귀는 통과. 적 차례 전체 상태·사건·로그 계약의 미도달 분기는 별도 필요.',
'P1824':'전투/시설 경험치 회귀는 통과. fl 없는 옛 적·qmult·출전자 보너스의 reward 반환을 새 직접 비교하지 않음.',
'P1825':'승패/400행동 회귀는 통과. 정산문·부상자·EXP·출처·로그·cur/q 초기화 전체의 대조는 남음.',
'P1830':'승패와 행동 상한 회귀는 유지. 끝난 상태 재호출의 반환·finish 부수 효과까지 새 비교하지 않음.',
'P1831':'6320판 진행 결과는 비교. guard 80·모든 시작/라운드/사망·자동 방출의 전체 상태 경계는 남음.',
'P1842':'레비아 공격 회귀는 통과. amt 반올림 0/1·다른 적의 사망/고갈·list와 사건 시각의 새 직접 대조는 남음.',
'P1847':'구원 우선순위 회귀는 통과. 자기/타인·횟수 소진·소형 mhp와 HP=1→회복의 시간 이력 전체는 남음.',
'P3492':'native act·잘못된 버튼 회귀는 통과. 원본 pend/pid·취소·2단계 대상 선택·반환 상태 전체는 남음.',
'P3502':'호스트 재렌더/메시지 갱신 callback은 native 저장/렌더 흐름과 직접 대조하지 않음.',
'P3505':'native 입력 회귀는 통과. 원본 채팅 변수 load/bind/act/save/redraw를 한 버튼으로 묶은 전체 계약은 남음.',
'P1864':'적 표시명 번역 반환은 독립적으로 새 비교하지 않음.',
'P1870':'감경/분노 배율은 비교하나 모든 비율의 반올림 표시 숫자 반환을 직접 새 비교하지 않음.',
'P1871':'적 공격 수치는 회귀에 있음. 피해·보호막·tags·부상·조사의 전체 문구는 새 비교하지 않음.',
'P1872':'적 100종 행동은 회귀 통과. fl 없음·빈/죽은/생존 선제 행동 적의 초기 g 변경을 새 독립 대조하지 않음.',
'P1875':'배율 40조건을 비교·수정. dr_while_ally/melee/ranged의 tags 문자열 배열은 native에서 직접 정규화 대조하지 않음.',
'P1877':'실제 속성 덮어쓰기·보스/처치 경계 36개와 되치기 진입을 수정·비교. hitT/로그·다중 재진입의 전체 사건 대조는 남음.',
'P1880':'되치기 17경계의 피해/보호막·수혜자·강화/분노 무시·회피 없음·RNG를 비교·수정. 반환 res/tags와 eatk/로그 시각 전체는 남음.',
'P1881':'분노/HP 경계·20/21/30/40라운드 배율 160개는 비교. 반환하는 tags 문자열 전체는 남음.',
'P1882':'적 DOT 4개 FIFO 회귀는 통과. per<=0·n 경계와 by 저장 전 필드를 새 대조하지 않음.',
'P1885':'DOT 사망·구원/장비 회귀는 통과. 빈/무효 DOT 목록과 반환 kill/사건·필드 이력 전체의 새 대조는 남음.',
'P1892':'2단계/약점 순환 회귀는 유지. turn_start의 protect/hide 해제·tn·cycle 상태 전 필드 새 대조는 남음.',
'P1897':'충전·은신 주기 회귀는 통과. act.big/turns·로그와 전체 종료 상태의 직접 새 대조는 남음.',
'P1901':'적 buff 회귀는 통과. self/ally/allies·aura·shield/pull과 반환 사건/기록의 모든 조합 새 대조는 남음.',
'P1908':'적 debuff 회귀는 통과. 모든 능력·대상·누락 amount/turns의 전 반환/기록 새 대조는 남음.',
'P1910':'적 DOT 회피 회귀는 통과. 두 반환 경로의 tg/시간·DOT 전체 저장 상태 새 대조는 남음.',
'P1911':'회복 없음/최저 HP 선택 회귀는 통과. self/일반 대상·동률·상한과 사건/문구의 새 직접 대조는 남음.',
'P1912':'빈 칸/재사용/동일 사건·옛 저장의 배치와 RNG를 검증. 반환 칸/nil 및 전체 ev.h 필드 이력을 native와 직접 비교하는 작업은 남음.',
'P1919':'소환 25경계의 상태/RNG를 비교·수정. made/tgs·빈 소환 문구·전체 기록장 반환은 남음.',
'P1920':'기존 보호 우선순위 회귀는 통과. 동료 없음/후열 우선·guard의 모든 사건과 로그 새 대조는 남음.',
'P1926':'침묵 200개 회귀는 통과. 후보 없음·다른 fx·선택한 기술의 문자열/로그 전체 새 대조는 남음.',
'P1930':'기존 100종 dispatch는 검증. 알려지지 않은 kind→무동작과 payload 전파를 새 독립 대조하지 않음.',
'P1931':'실제 break_self 적의 HP 경계별 취소 상태를 비교. ia/cq·로그·필드 시간 이력의 전체 반환은 남음.',
'P1934':'모든 실제 2단계 적의 문턱·치명 피해·진입/약점/RNG를 비교. 사건/로그·정의 전체 반환은 남음.',
'P1942':'실제 2단계 적의 HP 경계를 비교. ev 없음·반환 전환 수·한번에 복수 보스의 전체 상태는 남음.',
'P1944':'원본 정산용 장소·적·층/균열 문구를 native 정산 메타데이터와 직접 새 비교하지 않음.',
'P1945':'보상 회귀는 통과. 소환 제외/원래 등급·구역/심층/의뢰 배수와 모든 파티 보너스의 새 반환 대조는 남음.',
'P2363':'레이드 HTML 숫자 포맷의 독립 새 반환 대조는 없음.',
'P2365':'레이드 pips의 켜짐/꺼짐·HTML/의미상 개수 대조는 새 fixture에 없음.',
'P2366':'레이드 화면 회귀는 통과. 보스별 모든 상태/배지/예고/필드 시간의 의미상 출력 대조는 남음.',
'P2368':'기존 레이드 배치는 유지. 원본 raid_field와 native의 빈 칸·호위·보스별 표시 전체는 새 대조하지 않음.',
}
reasons.update({
'P1664':'통상 수준·문자열·범위 초과·Boolean·NaN은 비교. 지수 문자열과 비유한값까지 포함한 tonumber/클램프 전체 계약은 검증하지 않아 승격하지 않음.',
'P1666':'p/s 정의와 clean 반환의 시험 입력은 일치. 의존하는 lvl의 모든 입력 형식 계약을 아직 확정하지 않아 함수 전체는 일부 유지.',
'P1948':'개인 기술에서 x를 사용했으나 잘못된 x의 표 초기화/반환 참조를 직접 비교하지 않음.',
'P1950':'개인 기술이 생존 적을 순회. 빈/예약/죽은 칸을 포함한 foes 배열 반환을 독립 대조하지 않음.',
'P1951':'거다 기술은 12경계를 실행. 전열/후열/대체 적/없음의 behind 반환 칸을 독립 새 대조하지 않음.',
'P1954':'개인 기술의 비율 표시 숫자를 독립 새 비교하지 않음.',
'P1955':'개인 기술의 스킬 이름 표시/조사 문자열을 독립 새 비교하지 않음.',
'P1957':'같은 열/다른 열·사망·버프의 수치는 비교. caster source 메타데이터·첫 동료 사건/문구 전체는 남음.',
'P1994':'부식 DOT의 수치/소유자는 비교. 잘못된 x·부식 만료 뒤 cor=0 초기화의 직접 새 대조는 남음.',
'P1996':'부식 수치/수명/소유자는 비교. 반환 n/per·빈 x·오래된 중첩·교체 순서 전체의 새 대조는 남음.',
'P2004':'주디스 12입력의 버프/속도/부식은 비교. 재시전 slow 만료 시점·로그/시간 이력 전체는 남음.',
'P2017':'우르다 12입력의 없거나 있는 버프·70% cap/doubled는 비교. 동률/기존 doubled/잔여 턴·문구 전체는 남음.',
'P2020':'기존 라운드 회복 회귀는 통과. 회복 없음·정화 우선순위·이벤트 시간의 새 전체 직접 대조는 남음.',
'P2033':'carry 대기값/조기 소생을 수정. 다수 사망자의 earliest/tie·1회 소진·각종 효과 유지의 새 직접 대조는 남음.',
'P2040':'기존 구원/사망 회귀는 통과. 자기/타인·invalid x의 death_tick 기록 반환을 새 독립 대조하지 않음.',
'P2079':'기존 어그로 회귀는 유지. hgk/hg·이미 자기 대상·도발·확률 실패/성공의 모든 새 상태 대조는 남음.',
'P2091':'표시명 번역 반환을 새 직접 비교하지 않음.',
'P2092':'한국어 조사로 주어를 만드는 sub 반환을 새 직접 비교하지 않음.',
'P2093':'개인 기술 설명 bp 포맷 반환을 새 직접 비교하지 않음.',
'P2094':'짧은 기술 이름 short의 다국어/구두점 반환을 새 직접 비교하지 않음.',
'P2095':'개인 기술 비율의 반올림 표시 반환을 새 직접 비교하지 않음.',
'P2096':'공격에 K를 사용. st.K 누락/다른 el의 helper Kc 반환을 새 독립 대조하지 않음.',
'P2107':'군힐드 피해는 비교. 같은 행동/다음 행동·같은/다른 표적에서 gn/gs/gt와 tags 반환의 직접 새 대조는 남음.',
'P2115':'빠른/느린/동률·죽은 적·보스 개인 기술 수치는 비교. amb opt와 실패 로그 전체는 남음.',
'P2120':'전체 전투의 바르구트 당김 회귀는 통과. i~=o·pull<=0·signed g와 pull 초기화의 새 독립 대조는 남음.',
'P2132':'콜레트 기술 사용 조건은 비교. definition.magic/각 행동 magic/ic 및 빈 목록의 Boolean 직접 대조는 남음.',
'P2171':'요르드 직접 피해/출혈 회귀는 통과. 3중첩 폭발·사망/보스·지연 합성·기존 출혈 만료 상태의 새 전체 대조는 남음.',
'P2181':'라비니아 공격 수치 회귀는 통과. 행동 아이콘별 casting 반환을 새 직접 비교하지 않음.',
'P2201':'미코 12입력의 회복/0 이하 당김은 비교. 현재 variant 외 측정용 variant1과 buff·사건/문구는 남음.',
'P2205':'정본 현재 variant2를 유지. 측정용 variant1의 mk/mkv 소비·opt 재사용과 tags 반환은 새 대조하지 않음.',
'P2207':'기존 라운드 당김 회귀는 통과. 동료 없음·음수 wait·동률·variant1 무동작을 새 독립 대조하지 않음.',
'P2218':'시전자 사망 정리 회귀는 통과. 오직 red20/red만 제거하는 helper의 임의 source/누락 bf 직접 새 대조는 남음.',
'P2220':'기존 사망/재생 회귀는 통과. old damaged callback·죽은 시전자·adeline x.areg 전 칸 제거를 새 전 필드 비교하지 않음.',
'P2235':'특성 문구 placeholder 해석/백분율/알 수 없는 경로의 새 직접 대조가 없음.',
'P2236':'placeholder callback의 수치/변수 fallback 및 문자열 반환을 직접 새 비교하지 않음.',
'P2239':'특성 문구 노드의 표시 데이터 반환을 직접 새 비교하지 않음.',
'P2242':'시너지에서 x를 사용. 잘못된 x/반환 참조 계약을 직접 새 비교하지 않음.',
'P2245':'0~4인 시너지 경계 수치는 비교. lv 보조 함수 자체를 독립 대조하지 않음.',
'P2249':'활성 시너지 수치는 비교. L의 표식 누락/비정상 값 직접 반환 대조는 남음.',
'P2267':'특성 사건은 회귀에 있으나 txt/at 전달과 native 로그 전체를 독립 새 비교하지 않음.',
'P2268':'능력치/활성 시너지는 동적 계산으로 비교. 원본 st.sy와 모든 유닛 bx 저장 메타데이터는 직접 대응하지 않음.',
'P2280':'암살자 회귀는 통과. extra/사망·이미 처치·장비 확률·일반 공격 opt와 RNG 전 필드 직접 새 대조는 남음.',
'P2287':'보상 회귀는 통과. 실제 pm(사망 포함)의 경계도시·세레디아 exp 반환을 새 독립 대조하지 않음.',
'P2292':'120조건의 연속 행동 g/double/RNG는 비교. st.sy/bx·특성/로그·비아군 원시 호출의 전체 계약은 남음.',
'P2300':'40조건의 처치 회복/MP/죽은 소유자는 비교. nil/0/>4 actor·장비 처치 훅·SKON 복원의 전 부수 효과는 남음.',
'P2301':'기존 cap 축소/부식 유지 회귀는 통과. 모든 줄 종류·죽은 적·오래된 class DOT의 독립 새 전 필드 대조는 남음.',
'P1671':'32조합·수준/무효 입력의 이름/force_en 반환은 비교. B.LANG=en의 자동 언어 경로는 새 대조하지 않음.',
'P1672':'32조합의 한국어/force_en 설명 전체를 비교. 자동 언어 설정과 새 수치 포맷 극단값 전체는 남음.',
'P1673':'기술 정의의 전 필드를 한국어에서 비교. B.LANG 전환에 따른 name/d의 전체 자동 로케일 계약은 남음.',
'P1674':'32조합·수준·죽은 지원 대상·보호/과잉 피해·무효 입력의 수치/RNG는 비교·수정. 컷인/공격·지원 사건 payload와 로그 전체는 남음.',
'P1678':'길드 편집기의 자동 언어 label 반환을 새 대조하지 않음.',
'P1679':'기존 편집기 회귀는 통과. 원본 ui.psd 우선순위·없는 UI/저장값 반환 전체를 새 직접 대조하지 않음.',
'P1680':'기존 draft 회귀는 통과. 사용하지 않는 조각 수준 차이까지 포함한 same 반환을 새 직접 대조하지 않음.',
'P1681':'기존 dirty/저장 회귀는 통과. 원본 type(ui)/type(psd)별 dirty의 전체 직접 새 대조는 남음.',
'P1682':'기존 길드 UI는 유지. 모든 prefix/suffix·dirty/ready·강화 상한/부족 금화 표시의 의미상 출력 전체는 새 대조하지 않음.',
'P1687':'변경 조합/강화의 영어 서술 배열을 native 대화 지시와 새 직접 비교하지 않음.',
'P1688':'기존 저장/대화 회귀는 통과. pending/busy·변경 없음·ready 없음·장면 지시의 G 변경 전체는 새 대조하지 않음.',
'P1692':'기존 길드 행동 회귀는 통과. 모든 무효 문자열·누락 선택·강화/환급·dirty 제거의 전체 G 전이를 새 직접 대조하지 않음.',
})
fx={
'P2307':'숫자 callback 시각은 비교. %.2f 스타일 문자열 자체의 입력 경계는 새 직접 대조하지 않음.',
'P2308':'callback 시각은 비교. 선택 CSS 변수 x 유무와 --t 문자열 전체는 새 직접 대조하지 않음.',
'P2309':'native는 HTML 조각 결합을 사용하지 않음. 칸별 시각 사건을 의미상 대응하는 직접 대조가 남음.',
'P2310':'280개 사건의 숫자 callback은 비교. text/class/left/top과 실제 표시 내용을 함께 대조하지 않음.',
'P2311':'치명 callback 시각은 비교. 치명 표시 문자열/배치 전체는 새 직접 대조하지 않음.',
'P2312':'plaque callback 시각은 비교. 표시명/언어/class/배치 전체는 새 직접 대조하지 않음.',
'P2316':'클라이맥스 강도 분기를 실행. --k 생략/출력의 의미상 renderer 대조는 남음.',
'P2317':'카메라 후보 생성은 실행. cls/t/k/rank와 최강 둘 선택까지 native 시각 결과의 직접 대조는 남음.',
'P2318':'피격 callback은 비교. arc/crit/백광/abfx·icwf/hit/hk/카메라 후보의 전체 시각 계약은 남음.',
'P2319':'약점 tag는 실행. 고갈/여우불/일반 tag 스타일의 새 의미상 출력 대조는 남음.',
'P2320':'심연 수치는 회귀에 있음. 본체/전염 표적별 숫자와 0.35+n*0.08 시각의 직접 대조는 남음.',
'P2321':'피해·치명·부분/전량 보호막/last callback의 280사건 시각을 수정·비교. text/style/tags/abyss 표시 전체는 남음.',
'P2322':'컷인 callback 시각은 비교. 아트/대사·표시명·마커/카메라 정보 전체는 남음.',
'P2323':'프로필 컷인 callback을 실행. 인레이/data/http 이미지·fallback과 escape/마커 전체는 새 비교하지 않음.',
'P2324':'28종 × 10경계의 hit/number/critical/plaque/cut callback은 비교. 나머지 필드·오라·카메라·태그 시각 전체는 남음.',
'P2326':'개인 이름의 언어/길이·한글 보존 반환을 새 직접 대조하지 않음.',
'P2327':'HUD 비율 표시의 분모 0/음수/최대치를 독립 새 대조하지 않음.',
'P2328':'HUD 소수점 시간 문자열을 새 직접 대조하지 않음.',
'P2329':'pre→각 시각 필드 변경 이력과 현재 수치의 dyn 출력 전체를 새 직접 대조하지 않음.',
'P2331':'dyn 내부 callback의 필드별 구간/최종값 처리를 새 직접 대조하지 않음.',
'P2332':'수치 span의 표시값/class/갱신 시각 전체를 새 직접 대조하지 않음.',
'P2333':'상태 chip의 문자열/아이콘 의미상 출력 전체를 새 직접 대조하지 않음.',
'P2334':'기존 상태 chip 회귀는 유지. 남은 턴 단위/언어 전환의 새 직접 대조는 없음.',
'P2335':'기존 DOT chip 회귀는 유지. 여러 DOT의 최대 수명/표시 전체의 새 직접 대조는 없음.',
'P2336':'기존 상태 목록 회귀는 유지. 동시 중첩/순서·지원 대상 이름·모든 chip 전체의 새 직접 대조는 없음.',
'P2337':'HP/MP/심연 수치는 비교. 사전값·동적 값·빈/사망 슬롯의 HUD 표현 계약 전체는 남음.',
'P2339':'원본 아이콘 id와 native 자산의 의미상 전수 매핑 대조는 새 fixture에 없음.',
'P2340':'기존 적 intent 회귀는 통과. 모든 target/self/침묵/충전·고갈/누락 행동 문구 전체의 새 대조는 남음.',
'P2341':'적 상태 수치는 비교. 적 타일의 weak/badges/intent/동적 HP·심연 및 빈 칸 전체는 새 의미상 대조하지 않음.',
'P2343':'개별 특성 배지의 모든 조건/표시와 사망 상태를 새 직접 대조하지 않음.',
'P2344':'아군 수치는 비교. 아군 타일의 buff/선택/충전·부상/장비 배지 전체는 새 의미상 대조하지 않음.',
'P2347':'행동 순서 타일의 현재/예정/사망·빈 칸 표현 전체를 새 직접 대조하지 않음.',
'P2348':'CTB preview 반환은 새 검증. rail의 표시 순서/현재·예정 표식/클래스 전체는 새 의미상 대조하지 않음.',
'P2349':'전투 제목·장소·행동/라운드·단계 표기 전체를 새 직접 대조하지 않음.',
'P2350':'키/활성 상태 chip의 전수 대응을 새 직접 대조하지 않음.',
'P2351':'버튼 MP/설명·disabled·선택 상태의 의미상 출력 전체를 새 직접 대조하지 않음.',
'P2353':'기술 조건 회귀는 통과. 행동/아이템/대상 선택·취소·버튼 배열의 전체 새 대조는 남음.',
'P2358':'원본 최대 6개 로그와 각 t/현재 사건 표시, native journal 표현의 새 직접 대조는 남음.',
'P2359':'기존 native 화면/오버플로 회귀는 유지. 모든 원본 상태에서 HUD·대상·로그·카메라의 의미상 전체 출력 대조는 남음.',
'P2361':'render의 배지/효과 선택 callback은 독립 새 대조하지 않음.',
'P2362':'카메라 후보 강도·동률/우선순위와 최종 선택 둘의 의미상 결과를 새 직접 대조하지 않음.',
}
reasons.update(fx)
def line(file,needle):
 text=(R/file).read_text(encoding='utf-8').splitlines()
 return next((i+1 for i,s in enumerate(text) if needle in s),1)
def ref(file,needle):return {'file':file,'line':line(file,needle),'symbol':needle}
refs={
'P1725':ref('project/game/dungeon_enemy_r21.gd','func pick_target'),
'P1875':ref('project/game/dungeon_enemy_r21.gd','func defense'),
'P1877':ref('project/game/dungeon_enemy_r21.gd','func after_hit'),
'P1880':ref('project/game/battle_v3.gd','func _enemy_hit'),
'P1912':ref('project/game/dungeon_enemy_r21.gd','func summon'),
'P1919':ref('project/game/dungeon_enemy_r21.gd','func summon'),
'P1674':ref('project/game/persona_combat_r22.gd','static func run'),
'P1550':ref('project/game/battle_v3.gd','func _start_ctb'),
'P1553':ref('project/game/battle_v3.gd','func _start_ctb'),
'P2033':ref('project/game/battle_v3.gd','func _felice_scan'),
'P2321':ref('project/game/combat_display_r22.gd','static func schedule'),
'P2324':ref('project/game/combat_display_r22.gd','static func schedule'),
}
for id,symbol in [('P1640','func _init'),('P1641','func has_summon'),('P1642','func has_charge'),('P1646','func fits')]:refs[id]=ref('project/game/dungeon_rules_r21.gd',symbol)
for id,symbol in [('P1660','static func part'),('P1664','static func level'),('P1666','static func clean')]:refs[id]=ref('project/game/persona_research_r21.gd',symbol)
refs['P1717']=ref('project/game/persona_combat_r22.gd','static func debuffed')
refs['P1723']=ref('project/game/battle_v3.gd','func speed')
refs['P1733']=ref('project/game/combat_clock_r22.gd','static func preview')
groups_tests={
 0:['battle_r23_state_test','battle_r23_compose_test','combat_p2_r22_test'],
 1:['battle_r23_test','battle_r23_clock_test','combat_p2_r22_test','combat_p3_r22_test'],
 2:['battle_r23_enemy_test','battle_r23_test','enemy_action_r21_test'],
 3:['battle_r23_test','battle_r23_state_test','combat_p3_r22_test'],
 4:['battle_r23_test','combat_p3_r22_test','combat_a9_r22_test'],
 5:['battle_r23_test','persona_combat_a8_test','persona_research_r21_test'],
 6:['battle_r23_display_test','combat_a6_r22_test','ui_battle_r17_test','ui_battle_r18_test','ui_battle_r19_test','ui_battle_r20_test'],
}
audit_rows={r['id']:r for r in baseline['rows']};ledger=[]
partial_direct=set(fixed)|{'P1630','P1631','P1645','P1647','P1650','P1651','P1652','P1653','P1654','P1715','P1720','P1722','P1724','P1746','P1760','P1789','P1806','P1877','P1881','P1931','P1934','P1942','P1957','P1994','P1996','P2004','P2017','P2107','P2115','P2132','P2171','P2181','P2201','P2245','P2249','P2268','P2292','P2300','P2301','P1671','P1672','P1673','P2310','P2311','P2312','P2318','P2320','P2322','P2323'}
partial_direct.update({'P1664','P1666'})
for gi,group in enumerate(baseline['groups']):
 for item in group['items']:
  id=item['id'];base=audit_rows[id];c=cov[id]
  status='같음' if id in equal else ('일부' if id in partial_direct and (c['called'] or id in fixed) else item['status'])
  if id not in equal and id not in reasons:raise AssertionError('Missing row-specific review '+id)
  evidence=[{'test':x,'log':'verification/parity-r23/suite-final/'+x+'.log','scope':'묶음의 수치/상태 회귀. 이 함수 전체나 미도달 분기의 같음 근거로 전파하지 않음.'} for x in groups_tests[gi]]
  if id in equal:
   t,label,contract=equal[id];evidence=[{'test':t,'labels':label,'contract':contract,'log':'verification/parity-r23/suite-final/'+t+'.log'}]
  ledger.append({**item,'feature_group':group['feature_group'],'prior_status':item['status'],'status':status,'fixed':id in fixed,'fix':fixed.get(id),'native_evidence':refs.get(id),'new_evidence':evidence,'remaining_reason':None if status=='같음' else reasons[id],'branch_coverage':c,'baseline_review':base.get('review'),'baseline_reason':base.get('evidence',{}).get('reason'),'baseline_implementation':base.get('implementation')})
assert len(ledger)==212 and len({r['id'] for r in ledger})==212
assert all(cov[id]['called'] and not cov[id]['remaining_entries'] for id in equal)
suite_dir=O/'suite-final';suite=[json.loads(p.read_text(encoding='utf-8')) for p in sorted((suite_dir/'rows').glob('*.json'))]
extras=['balance_probe','export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
missing=sorted(expected-{r['test'] for r in suite});failed=[r for r in suite if not r['passed']]
in_progress=[r['test'] for r in suite if (suite_dir/(r['test']+'.log')).stat().st_mtime_ns>(suite_dir/'rows'/(r['test']+'.json')).stat().st_mtime_ns]
target=[]
for name in ['latest','enemy-latest','state-latest','compose-latest','display-latest','clock-latest']:
 j=read(name+'.json');target.append({'name':name,'checks':j['checks'],'failures':len(j['failures'])})
data=R/'verification/data-r21';parity=[]
for name,file in [('A6','a6-mixed-audit.json'),('P3','p3-mixed-audit.json'),('A7','a7-gear-audit.json'),('A7 balanced','a7-gear-balanced-audit.json'),('A8','a8-audit.json'),('A9 native10','a9-native-10-audit.json'),('A9 native40','a9-native-40-audit.json')]:
 j=json.loads((data/file).read_text(encoding='utf-8'));parity.append({'name':name,**{k:j[k] for k in ['battles','equal_battles','source_actions','actual_actions','matched_actions']}})
p2=json.loads((data/'p2-full-battles.json').read_text(encoding='utf-8'))
assert all(r['battles']==r['equal_battles'] and r['source_actions']==r['actual_actions']==r['matched_actions'] for r in parity) and p2['different_actions']==0
start=read('start-manifest.json');changed=[n for n,h in start.items() if not (R/n).exists() or hashlib.sha256((R/n).read_bytes()).hexdigest()!=h]
protected={name:{'files':sum(n.startswith(name+'/') for n in start),'changed':[n for n in changed if n.startswith(name+'/')]} for name in ['docs','project/assets','server']}
assert not any(v['changed'] for v in protected.values())
source_audit=json.loads((data/'source-audit.json').read_text(encoding='utf-8'))
assert source_audit['failures']==0 and source_audit['original_assets']==96 and not source_audit['changed_assets'] and not source_audit['changed_source']
work_files=sorted([str(p.relative_to(R)).replace('\\','/') for folder,pattern in [('tools','*battle_r23*'),('project/tests','battle_r23*')] for p in (R/folder).glob(pattern) if p.is_file()])
summary={'rows_reviewed':len(ledger),'newly_equal_rows':sum(r['status']=='같음' for r in ledger),'fixed_rows':sum(r['fixed'] for r in ledger),'fixed_and_equal_overlap':sum(r['fixed'] and r['status']=='같음' for r in ledger),'remaining_rows':sum(r['status']!='같음' for r in ledger),'statuses':dict(Counter(r['status'] for r in ledger)),'called_functions':coverage['called_functions'],'baseline_missing_entries':coverage['baseline_missing_entries'],'newly_entered_baseline_entries':coverage['newly_entered_baseline_entries'],'new_checks':sum(r['checks'] for r in target),'new_failures':sum(r['failures'] for r in target),'suite_groups':len(suite),'expected_suite_groups':len(expected),'suite_missing':missing,'suite_failed_groups':len(failed),'parity_battles':sum(r['battles'] for r in parity)+p2['battles'],'parity_records':sum(r['source_actions'] for r in parity)+p2['compared_actions'],'product_files_changed':[n for n in changed if n.startswith('project/game/')],'protected':protected}
payload={'task':'r23-battle','scope':'r22b remaining_work 전투 7묶음','summary':summary,'proof_policy':'진입 계측만으로 같음 승격하지 않음. 같음은 해당 행의 정규화된 native 반환 계약과 명시된 유효 입력에 한함. 상위/하위 행으로 판정을 전파하지 않음.','rows':ledger,'target_tests':target,'battle_parity':parity,'p2_parity':p2,'test_tool_files':work_files,'source_asset_audit':source_audit}
summary['fixed_but_not_equal_rows']=sum(r['fixed'] and r['status']!='같음' for r in ledger)
summary['neither_equal_nor_fixed_rows']=sum(not r['fixed'] and r['status']!='같음' for r in ledger)
summary['fresh_oracle_runs']=len(coverage['runs'])
summary['suite_in_progress']=in_progress
(O/'battle.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(O/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(suite_dir/'results.json').write_text(json.dumps(suite,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
if missing or failed or in_progress or summary['new_failures']:
 print('Report is a draft: outstanding test groups remain.');sys.exit(1)
assert summary['parity_battles']==6320 and summary['parity_records']==219785
visual=read('visual-review.json')
assert all(r['viewed'] and hashlib.sha256((R/r['path']).read_bytes()).hexdigest()==r['sha256'] for r in visual['images'])
before=[('기본 경계값','before.json'),('소환/단계','enemy-before.json'),('페르소나','persona-before.json'),('carry','state-before.json'),('표시 시각','display-before.json'),('되치기','counter-before.json'),('실제 타격 속성 지연','element-delay-before-corrected.json')]
before_rows=[]
for label,name in before:
 j=read(name);before_rows.append(f'|{label}|{j["checks"]:,}|{len(j["failures"]):,}|`verification/parity-r23/{name}`|')
lines=['# R23-battle 작업 보고','',f'대상 **212행**을 행별로 검토했다. 새로 **같음 {summary["newly_equal_rows"]}행**, 수정 근거가 있는 행 **{summary["fixed_rows"]}행**, 남은 행 **{summary["remaining_rows"]}행**이다. 같음과 수정은 {summary["fixed_and_equal_overlap"]}행이 겹친다. **원본 전 기능 이식 완료는 아니다.** 남은 함수와 사유를 `verification/parity-r23/battle.json`에 모두 기록했다.','',f'새 대조 **{summary["new_checks"]:,}항목 / 실패 0**, 프로젝트 검사 **{len(suite)}그룹 / 실패 0**. 기존 **6,320전투 · 219,785개 기록 일치 / 차이 0**을 유지했다.','', '## 재현과 수정','', '|시험|수정 전 항목|실패|증거|','|---|---:|---:|---|',*before_rows,'','페르소나 무효 조합 4개는 위 수치 실패와 별도로 script error도 재현했다(`persona-before.log`). 최초 fixture의 빈 Lua 표/Dictionary 표현, 아군 대상 선택, `seal` 필드, CTB round/tick 일관성은 제품 수정 전에 바로잡았다. RNG는 JSON 소수 자릿수 손실을 피하도록 정확한 Park-Miller 정수 상태를 비교했다. 원본 수치를 바꿔 맞춘 기대값 변경은 없다.','', '제품 변경은 다음 6파일이다.','']
for n in summary['product_files_changed']:lines.append('- `'+n+'`')
lines.extend(['','수정한 동작은 8종이다: 규칙 없는 숨은 적의 감경 제거, 명시적 low/aimed 별칭/RNG 상한의 표적 선택, 빈 소환 칸 우선, 같은 사건의 사망 칸 재사용 금지, 미완성 페르소나 기술 무동작, 쓰러진 단일 지원 대상 제외, carry 사망 대기값과 저장 보존, 마지막 일격 히트스탑의 적용 범위 제한. 옛 schema-3 mob 등급 소환 칸은 계속 재사용할 수 있다.','', '## 새 증거 범위','', '|시험|항목|실패|','|---|---:|---:|'])
for r in target:lines.append(f'|{r["name"]}|{r["checks"]:,}|{r["failures"]}|')
lines.extend(['',f'원본 Lua에 Boolean 진입 기록만 추가하여 재실행했다. 계측 전/후 oracle 결과가 모두 같은 것을 확인했다. 대상 함수 **{coverage["called_functions"]}/212개 호출**, 기존 미검증 진입 **{coverage["newly_entered_baseline_entries"]}/{coverage["baseline_missing_entries"]}개 도달**이다. 이 수치는 조건 조합 전수나 함수 완성도가 아니다. 원본 소스 해시, 계측 정보, 행별 미도달 목록은 `coverage.json`과 `coverage/`에 있다.','', '새 입력은 원본 `bot/src/*.lua`를 읽기 전용으로 Wasmoon/lua_sim에서 실행했다. 저장 가능한 입력과 명시된 무효/경계값의 반환·상태·RNG를 비교한다. 숫자 실수의 기존 허용 오차는 1e-7이며, 정수 피해·게이지·RNG 상태는 정확 비교한다. 편성 RNG 상태는 별도로 정수 동등성을 검사한다.','', '## 남은 작업',''])
for group in baseline['groups']:
 rs=[r for r in ledger if r['feature_group']==group['feature_group']];lines.append(f'- {group["feature_group"]}: 같음 {sum(r["status"]=="같음" for r in rs)}, 남음 {sum(r["status"]!="같음" for r in rs)}.')
lines.extend(['','전체 상태/반환/부수 효과를 검증하지 못한 행은 일부 또는 미확인으로 유지했다. 특히 원본 저장 버전·pend/pid 이관, 모든 사건의 필드별 시간 이력과 payload, 훅 합성/측정용 변형, 다국어 설명과 로그, HUD·버튼·대상의 의미상 출력 대조가 남는다. 여러 통합 전투가 통과했다는 이유만으로 이 함수들을 같음으로 세지 않았다. 행별 기존 판정 사유·원본 위치·baseline 미검증 분기와 이번 결과를 함께 보존했다.','', '## 검사와 보존','', '`node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs`로 원래 로컬 Worker/D1 서버를 실행했다. Miniflare 설치본은 기존 다른 worktree의 의존성을 읽기 전용으로 참조했다. 시험 전용 preload가 같은 DB에 보관 계정 fixture와 독립 quota를 준비한다. 서버 제품 파일은 수정하지 않았다.','',f'`docs/` {protected["docs"]["files"]:,}개, `project/assets/` {protected["project/assets"]["files"]:,}개, `server/` {protected["server"]["files"]:,}개에서 manifest 기준 변경 0. Web export·버전 갱신을 하지 않았다. 사용자 저장은 열거나 덮지 않았고 모든 Godot 실행은 격리 wrapper를 사용했다. schema_version은 3 그대로다. 기존 사망자의 유한 대기값은 그대로 불러오며, 새 10^9 sentinel은 HP=0 아군에만 허용한다.','', '공통 문서 로딩과 같은 첫 도구 호출에서 `git status --short`를 한 번 시도했으나 소유권 오류로 실패했다. 이후 git 명령·설정 변경·커밋은 하지 않았다.','', 'Windows root certificate store 진단은 기존 환경 메시지로 분리했다. Script error와 기타 ERROR는 통과로 세지 않는다. 모든 결과 이미지의 육안 전수 검증·모바일 실기기·새 Web/WASM 검증은 하지 않았다. 직접 연 이미지는 `visual-review.json`에 별도로 기록한다.','', '재실행:','', '```powershell','python tools/prepare_battle_r23.py','node tools/oracle_battle_r23.mjs','node tools/oracle_battle_r23_enemy.mjs','node tools/oracle_battle_r23_state.mjs','node tools/oracle_battle_r23_display.mjs','node tools/oracle_battle_r23_compose.mjs','node tools/oracle_battle_r23_clock.mjs','python tools/coverage_battle_r23.py',"$env:R23_SUITE_NAME='suite-final'",'python tools/run_battle_r23.py','python tools/report_battle_r23.py','```',''])
lines=[s.replace('수정한 동작은 8종이다:', '수정한 동작은 10종이다:').replace('마지막 일격 히트스탑의 적용 범위 제한. 옛', '마지막 일격 히트스탑의 적용 범위 제한, 되치기의 고유 피해/대상/회피 경로, 실제 타격 속성에 따른 적 지연. 옛') for s in lines]
lines.insert(3,f'수정했지만 전체 계약이 남은 {summary["fixed_but_not_equal_rows"]}행도 남은 {summary["remaining_rows"]}행에 포함한다. 같음도 수정도 아닌 행은 {summary["neither_equal_nor_fixed_rows"]}행이다.')
i=lines.index('## 남은 작업')
lines[i:i]=['기존 6,320판의 원본 oracle도 새로 실행하여 기존 기준 JSON과 모든 관측값이 같음을 확인했다. 새 6종 oracle와 기존 전체 전투 8종·단위 2종, 총 16개 실행을 계측했다. 기준 파일을 덮지 않고 `coverage/retained-*-oracle.json`에 따로 보존했다.','', '실제 속성 지연 fixture는 양쪽 표적 약점 목록을 빈 목록으로 맞췄다. `element-delay-before-corrected.json`은 저장해 둔 수정 전 Godot 관측값을 보정한 짝 입력의 Lua 결과에 다시 비교한 것으로, 관측값은 바꾸지 않았다. raw before 파일과 두 자료의 해시도 남겼다.','']
i=lines.index('재실행:')
lines[i:i]=['로컬 서버는 별도 터미널에서 다음과 같이 준비한다.','', '```powershell',r"$env:ABYSS_NODE_MODULES=(Resolve-Path '..\r21-d-town\server\abyss-save').Path",r"$env:TEMP=(Join-Path (Get-Location) '.p6tmp')",'$env:TMP=$env:TEMP','$env:TMPDIR=$env:TEMP','node --import ./tools/cloud_battle_r23_preload.mjs server/abyss-save/test/serve.mjs','```','']
lines.extend(['## 시험·도구 파일','',*['- `'+n+'`' for n in work_files],''])
(R/'R23-battle.md').write_text('\n'.join(lines),encoding='utf-8')
