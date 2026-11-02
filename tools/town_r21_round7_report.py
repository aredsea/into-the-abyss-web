"""Assemble the handoff from actual local evidence, without git or source writes."""
from pathlib import Path
import hashlib,json

R=Path(__file__).resolve().parents[1]
O=R/'verification/town-r21/round7'
def read(p):return json.loads((R/p).read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
rows=read('verification/town-r21/common-results.json')
web=read('verification/town-r21/web/results.json')
d=read('verification/town-r21/round7/dialogue-results.json')
u=read('verification/town-r21/round7/ui-dialogue-results.json')
rec=read('verification/town-r21/round7/recruit-results.json')
assert len(rows)==34 and all(not r['exit_code'] and not r['errors'] for r in rows)
assert len(web)==6 and all(not r['errors'] and not r['text_errors'] for r in web)
assert not d['failures'] and not u['failures'] and not rec['failures']
b=read('verification/town-r21/round7/baseline.json')
changed=[p for p,h in b.items() if (R/p).exists() and sha(R/p)!=h]
protected=[p for p in b if (p.startswith('project/assets/') and not p.endswith('.import')) or p.startswith('project/data/') or Path(p).name.startswith(('battle_','combat_','signature_')) or p.startswith(('project/game/dungeon_','project/ui/battle_'))]
new=[str(p.relative_to(R)).replace('\\','/') for folder in ['project','tools'] for p in (R/folder).rglob('*') if p.is_file() and '.godot' not in p.parts and '__pycache__' not in p.parts and str(p.relative_to(R)).replace('\\','/') not in b]
assets=read('ASSET-HASHES.json')
source=read('verification/town-r21/round7/card-audit.json')['manifest']
audit={'changed':changed,'new':new,'protected_count':len(protected),'protected_changed':[p for p in changed if p in protected],
       'source_files':len(source),'source_changed':[x['file'] for x in source if sha(Path(x['file']))!=x['sha256']],
       'original_assets':len(assets),'original_assets_changed':[x['path'] for x in assets if sha(R/x['path'])!=x['sha256']],
       'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':sha(R/'docs/index.pck'),
       'owner_zoom_bytes':(R/'verification/town-r21/owner-zoom-6.jpg').stat().st_size}
assert not audit['protected_changed'] and not audit['source_changed'] and not audit['original_assets_changed']
assert audit['owner_zoom_bytes']<=300000
(O/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')

def summary(r):
    if not r['summary']:return 'exit 0'
    s=r['summary'][-1]
    if '{' in s:
        try:return str(json.loads(s[s.index('{'):])['checks'])+' checks / 0 failures'
        except (ValueError,KeyError):pass
    return s
table='\n'.join('|'+r['name']+'|'+summary(r)+'|' for r in rows)
files='\n'.join('- `'+p+'`' for p in changed+new)
report=f'''## 6차 — 선택지 대화·호감 훅·원본 영입 (7차 지시)

**선택지 재생기·호감 훅·영입 주선은 연결하고 검사했다. 카드 사건은 현재 정본에 규칙이 없어 이식 완료로 세지 않는다.** 원본의 HTML 정보 패널을 뜻하는 `*_card`와 기존 웹 시제품의 소모성 카드를 구분했다. 카드 정본 감사까지 마친 뒤 영입으로 진행했다.

|항목|이번 결과|
|---|---:|
|공통·기존·신규 Godot 검사 그룹 / 실패|34 / 0|
|대화·호감 실행 검사 / 실패|{d['checks']:,} / 0|
|새 UI 검사 / 실패·넘침|{u['checks']:,} / 0·0|
|영입 검사 / 실패|{rec['checks']:,} / 0|
|원본 Lua 여관·파티·NPC 표본|768 + 70 + 5|
|원본 Lua 영입 결과 대조|2,496 / 2,496|
|원본 카드 감사 / 탐색 실행|96파일 / 8,000회|
|Web 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|보호 파일 / 변경|{audit['protected_count']:,} / 0|
|원본 자산 / 변경|96 / 0|
|직접 연 대화 4장 합본|1440×810 / {audit['owner_zoom_bytes']:,} bytes|
|최종 PCK|{audit['pck_bytes']:,} bytes|

### 선택지 대화와 호감

`dialogue_player_r21.gd`가 읽기 전용 JSON을 ID별로 불러온다. 현재 8단계의 장면 중 본 횟수가 가장 적은 것을 먼저 고르며, 전부 본 뒤에는 `seen` 도입과 기존 선택지를 쓴다. 여관의 실제 대화 버튼 → 3개 선택지 → 반응 → 실제 호감 변화 → 단계 변화 장면 → 여관 복귀를 연결했다. 선택지의 aff는 기존 talk +1을 **대체**한다. 원본 `inn()` API는 콘텐츠 없는 동료의 기존 +1 경로로 유지하며, UI는 `begin_dialogue()`를 사용한다.

선택을 마칠 때만 하루 제한과 본 장면 횟수를 확정한다. 고르기 전 취소는 비용·호감·하루 제한을 소모하지 않는다. 재시작하면 선택 전 장면 또는 결제 완료 반응을 복원하며 같은 선택을 두 번 지급하지 않는다. 장면 선택·짧은 말 변형은 게임 RNG를 소비하지 않는다. -100~200, 100 초과 양수 몫 ×0.4, 원본 반올림·8단계·여러 경계를 건널 때 최종 도착 경계 한 장면을 적용했다. 없는 동료 파일은 기존 동작으로 돌아간다.

여관 식사·숙박은 도로테아 +1, 대화·선물은 도로테아 변화 없음이다. 상점 구매는 피에트로, 의뢰 수락·영입은 페넬라, 가공·강화는 한나의 성공한 행동에 +1을 준다. NPC 행동 호감은 100에서 멈추고 이미 100을 넘는 값은 줄이지 않는다. 동료 여관 행동은 하루 제한·비용·숙박 날짜를 원본대로 유지한다. 원정에서는 정산 한 번에 승리×1 + 보스3, 의뢰2를 반영하고 솔렌 성왕국 3명 편성의 ×1.2도 원본 `aff_party/tx_aff`와 대조했다. 패배는 동료 호감을 주지 않는다.

출발·층 진입·발견·전투 시작·승리·보스 전/후·아군 위기·자신의 부상·쓰러짐·휴식·보관함·귀환·패배의 14상황을 연결했다. 전투 저장 스냅샷은 읽어서 위기/쓰러짐을 한 전투·동료마다 한 번만 기록한다. 전투 시작 전과 결과 확인 후의 별도 대사 화면에서 읽으며 전투 화면 파일은 바꾸지 않았다. 진행 중 전투를 재로드하면 전투부터 복원하고, 대기 대사는 전투 밖에서 이어 본다. 보관함은 기존 옛 지도 경로에만 존재하며 새 원정 사건으로 만들지 않았다.

### 카드 정본 감사 — 규칙 없음

`bot/src`와 `design`의 현재 96개 Lua/JSON/Markdown 파일을 UTF-8로 검색하고 SHA를 기록했다. `77-explore.lua`의 원본 `ex_roll`을 Wasmoon으로 8,000회 실행한 결과는 battle 4,952 / elite 619 / coin 1,209 / item 854 / equip 366이다. `head_card`, `last_card`, `party_card`, `gear_card`는 HTML 정보 패널 함수다. 검색된 “봉인 해제”는 적의 기술이며 소모성 카드가 아니다. `76-dungeon.lua`, `77-explore.lua`, `78-battle-item.lua`와 원본 마을 하네스에 웹판 `key/camp` 카드 지급·보관함 해제 규칙은 없다.

따라서 카드 지급 확률·사용 효과·보유 상한·정산 규칙을 새로 정하지 않았다. 기존 웹 시제품의 `key/camp`와 사용자 저장의 손패는 보존했다. 원본 Git 이력이나 별도 옛 버전은 조사하지 않았으므로 “과거에도 없었다”는 뜻은 아니다. 근거는 `round7/card-audit.json`, 재현 도구는 `tools/town_r21_card_audit.mjs`다. 이 항목은 **정본 규칙 없음 / 추가 이식 없음**으로 인계한다.

### 영입 주선과 저장 이관

`72-guild.lua`의 `CAST_ORDER` 후보 순서, 미영입자 필터, 비용 100+20×횟수, `floor(G_rnd×후보수)` 한 번을 그대로 사용한다. 게시판과 같은 `town_r21.counter`를 공유하므로 의뢰 갱신 사이에 영입해도 다음 난수 번호가 이어진다. 전원 보유·돈 부족·원정 중에는 돈·명단·카운터가 바뀌지 않는다. 새 동료는 즉시 소유 목록에 추가하고 aff/XP를 0으로, 합류 레벨은 페르소나 기준으로 정한다. 8개 seed × 4개 시작 RNG 번호 × 3개 레벨 × 26명 = 2,496결과를 원본 meet 핸들러와 대조했다.

이 게임에는 독립 페르소나 전투 주체가 아직 없으므로 `persona_progress_r21`에 **비출전 성장 기록만** 추가했다. 원본 `persona.lv/exp`가 저장에 있으면 이관하고, 없으면 원본 기본값 Lv.1/XP0이다. 파티 최고 레벨을 대신 쓰지 않는다. 이후 원정 정산 시 원본의 비출전 XP `floor(total/2)`와 레벨 비용을 적용한다. 독립 페르소나 전투·행동·클래스 구현 완료로 세지 않는다. 이미 진행한 과거 원정의 누락 경험치를 추정하여 소급하지 않는다.

schema2·사용자 저장 경로는 유지한다. `dialogue_r21`, `npc_aff_r21`, `persona_progress_r21`만 추가하고, 없는 옛 저장은 기본 상태로 이관한다. schema1의 날짜·손패·행동 기록과 schema2의 진행 중 전투·연구 draft를 보존하는 검사, 선택 전/후 JSON roundtrip, 입력 저장 불변, 불량 상태의 원자적 거절을 포함한다. 테스트는 전용 fixture 경로와 임시 브라우저 문맥만 사용했다. 사용자 저장을 삭제·덮어쓰지 않았다. 이미 웹 RNG로 결정된 옛 영입을 다시 뽑거나 과거 RNG 사용 이력을 추정하지 않는다. 저장된 마을 카운터 다음부터 원본 순서를 적용한다.

### 실제 렌더와 Web

360×780·390×844·430×932·390×664·1280×800에서 새 흐름을 검사했다. 세 동료의 84장면 전체와 선택지 252개는 360·430 양끝 폭에서 모두 실제 렌더 치수를 검사했고, 단계·반응·포인터·전투 전 대사 확인도 검사했다. 새 선택지는 기준 높이 58이며 검사 크기에서 실제 클릭 높이 44px 이상이다.

힐데가·마르셀린·테이리스 선택지 및 힐데가 19→21 단계 변화 4장 합본 [owner-zoom-6.jpg](verification/town-r21/owner-zoom-6.jpg)를 직접 열었다. 배경에 묻히던 이름/호감 표시는 종이색 면으로 보완한 뒤 다시 열었다. 실제 WASM 360폭 선택지 화면도 직접 열었다. 원본 대사 이름 힐데가와 기존 게임 표시명 힐데가르트 차이는 데이터 읽기 전용 조건대로 유지했다. 이 검수는 기존 마을 전체 시안의 미완성 부분까지 해결했다는 뜻은 아니다.

요청 명령으로 로컬 Web export 후 `update_version.py`를 실행했다. `ui_build=r21-d-town-20261102c`, PCK SHA-256 `{audit['pck_sha256']}`. 원격 배포는 하지 않았다. `web_smoke_r19.py --town-r21` 6구성이 실제 포인터로 대화 선택·반응 저장·재로드·하루 제한, 기존 상점/연구, 자연 전투 승리·결과 확인·뷰포트 복원을 통과했다. 결과는 `verification/town-r21/web/results.json`, export 로그는 `round7/export.log`다.

### 검사와 보호 경계

|검사|최종 결과|
|---|---|
{table}

`dialogue_r21_check.py` 오류 0, `dialogue_r21_selftest.py` 58검사 실패 0, impeccable detector `[]`도 확인했다. Godot의 기존 Windows root certificate store 오류는 각 원문 로그와 common-results의 환경 경고 필드에 따로 남겼다. 이를 기능 검사 실패에 섞거나 숨기지 않았다.

기존 round2/3/4 UI 검사는 새 대사의 “계속”을 실제로 누른 뒤 종전 화면을 검사하도록 보완했다. 게임 수치 기대값은 바꾸지 않았고, 웹 빌드 식별자 기대값만 c로 갱신했다. 구형 DungeonWorld를 주입한 화면에도 대화 상태가 없으면 기존 동작을 유지하도록 고쳤다. 원본 Lua 수식/결과 기대값은 변경하지 않았다. 보호 파일 SHA·변경 목록은 `round7/audit.json`이다.

성적 장면·79-sex 행동·AI 생성은 이식하지 않았다. 79 파일에서는 비성적 NPC 호감 함수만 원본 대조용으로 읽었다. 전투/A 데이터/초상/적/대화 JSON 쓰기, 다른 worktree 쓰기, git 명령, 외부 메시지 송신을 하지 않았다. 독립 페르소나 전투 전체, 정본이 확인되지 않은 카드 사건, 나머지 동료의 미작성 콘텐츠, 이전 보고서의 전체 시안 차이는 남는다. 기존 DESIGN.md와 .impeccable/design.json의 메타데이터 드리프트도 유지되며 별도 `document` 작업으로 정리할 수 있다.

### 변경 파일

{files}

추가 산출물: `verification/town-r21/round7/**`, 공통/기존 검사 재생성 결과, `owner-zoom-6.jpg`, `docs/**`, 본 보고서.

'''
p=R/'UI-R21-D.md';old=p.read_text(encoding='utf-8')
start='## 6차 — 선택지 대화·호감 훅·원본 영입 (7차 지시)'
if start in old:
    old=old[old.index('## 이전 6차'):]
else:
    old=old.replace('# UI-R21-D\n','',1).lstrip().replace('## 6차 — 호감 단계 판정 부분 인계','## 이전 6차 — 호감 단계 판정 부분 인계',1)
p.write_text('# UI-R21-D\n\n'+report+old,encoding='utf-8')
(O/'summary.json').write_text(json.dumps({'groups':len(rows),'failures':0,'dialogue_checks':d['checks'],'ui_checks':u['checks'],'recruit_checks':rec['checks'],'web_configurations':len(web),'audit':audit},ensure_ascii=False,indent=2),encoding='utf-8')
print('UI-R21-D.md / 34 groups, 0 failures / Web 6 of 6 /',d['checks'],u['checks'],rec['checks'])
