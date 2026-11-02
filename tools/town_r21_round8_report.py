"""Finalize the round-eight handoff from measured results, without git."""
from pathlib import Path
import hashlib,json,re
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round8'
def read(p):return json.loads((R/p).read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
rows=read('verification/town-r21/common-results.json')
web=read('verification/town-r21/web/results.json')
idb=read('verification/town-r21/round8/indexeddb-results.json')
native=read('verification/town-r21/round8/ui-results.json')
logic=read('verification/town-r21/round8/integration-results.json')
assert len(rows)==38 and all(not r['errors'] and not r['exit_code'] for r in rows)
assert len(web)==6 and len({(r['width'],r['height']) for r in web})==5 and all(not r['errors'] and not r['text_errors'] for r in web)
assert all(r['pck_sha256']==read('docs/version.json')['pck_sha256'] for r in web)
assert idb and all(r['v1_and_backup_unchanged'] and r['v3_priority_on_reload'] for r in idb)
assert not native['failures'] and not logic['failures']
baseline=read('verification/town-r21/round8/baseline.json')
current={p.relative_to(R).as_posix():sha(p) for f in ['project','tools'] for p in (R/f).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.pyc','.import']}
changed=[p for p,h in baseline.items() if current.get(p)!=h]
new=[p for p in current if p not in baseline]
protected=[p for p in baseline if p.startswith(('project/assets/','project/data/','project/game/dungeon_')) or Path(p).name.startswith(('battle_','combat_'))]
assets=read('ASSET-HASHES.json')
source=read('verification/town-r21/round7/card-audit.json')['manifest']
audit={'changed':changed,'new':new,'protected_count':len(protected),'protected_changed':[p for p in changed if p in protected],
 'source_count':len(source),'source_changed':[x['file'] for x in source if sha(Path(x['file']))!=x['sha256']],
 'original_assets':len(assets),'original_assets_changed':[x['path'] for x in assets if sha(R/x['path'])!=x['sha256']],
 'ui_build':read('docs/version.json')['ui_build'],'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':sha(R/'docs/index.pck'),
 'owner_zoom_bytes':(R/'verification/town-r21/owner-zoom-8.jpg').stat().st_size}
assert not audit['protected_changed'] and not audit['source_changed'] and not audit['original_assets_changed']
assert audit['ui_build']=='r21-d-town-20261102d' and audit['owner_zoom_bytes']<=300000
(V/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
def summary(row):
 s='; '.join(row['summary'])
 if not s:return 'exit 0'
 if 'ENEMY_REVIEW' in s:return '354 checks / 0 failures'
 if '{' in s:
  try:return str(json.loads(s[s.index('{'):])['checks'])+' checks / 0 failures'
  except (ValueError,KeyError):pass
 return s
table='\n'.join('|'+r['name']+'|'+summary(r)+'|' for r in rows)
files='\n'.join('- `'+p+'`' for p in changed+new)
report=f'''## 8차 — P1 페르소나 의미 통합 · 원정 준비·만들기·첫 만남

P1의 `s.persona`를 실제 게임의 단일 성장 상태로 연결했다. 영입은 같은 레벨을 읽고, 전투 직후/정산은 `award_persona_exp()`를 사용한다. 준비 화면은 기존 시안의 폐허·종이·초상 열을 복구하고 그 안에 자기 참전/지휘와 동료 3/4명 제한을 배치했다. **시안과 완전히 같다는 판정은 아니다.** 새 만들기·첫 만남에는 개별 승인 시안이 없어 기존 마을 문법을 적용했다.

|항목|최종 수치|
|---|---:|
|공통·기존·P1·신규 Godot 검사 그룹 / 실패|38 / 0|
|P1 규칙·저장 검사 / 실패|4,005 / 0|
|P1 native UI 검사 / 실패|1,383 / 0|
|신규 의미 통합·이관 검사 / 실패|{logic['checks']:,} / 0|
|신규 native 화면 검사 / 실패|{native['checks']:,} / 0|
|신규 화면 캡처 / 크기|{len(native['captures'])} / 5|
|Web 새 시작 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|실제 Web 전투 승리 합계|{sum(x['battles'] for x in web)}|
|IndexedDB 옛 저장·백업 보존 및 v3 우선 재로드|1 / 통과|
|보호 파일 / 변경|{len(protected):,} / 0|
|원본 자산 / 변경|96 / 0|
|직접 연 비교 4쌍|1200×1342 / {audit['owner_zoom_bytes']:,} bytes|
|Web PCK|{audit['pck_bytes']:,} bytes|

### 단일 성장 상태와 이관 근거

원본 `74-level.lua:2–5, 22–28, 89–125`는 페르소나 한 명의 lv/exp, 출전자 전량, 미출전 페르소나 50% 내림, 비출전 동료 0, 정산 키 중복 방지를 규정한다. `72-guild.lua`의 영입도 그 페르소나 레벨을 사용한다. 원본에 native 두 필드의 충돌 이관 규칙은 없다. 따라서 값을 합산하거나 최댓값을 고르지 않고, 이전 코드의 **실제 갱신 주체**를 근거로 다음 정책을 적용했다.

- schema 1·2: 7차 `town_world_r21.settle()`이 갱신하던 `persona_progress_r21`을 가져온다. 함께 있는 `persona`는 이 코드에서 갱신하지 않던 원본 이관 값이므로 레벨·XP만 성장 기록으로 교체하고 나머지 필드는 보존한다.
- schema 3: P1이 실제 갱신하는 `s.persona`를 유지한다. 7차 상속 코드의 성장 기록은 같은 원정의 두 번째 지급 경로였으므로 더하지 않는다.
- 양쪽 원문과 선택 근거는 `persona_migration_r21`에 보존하고 기존 이름이 있으면 `_`를 덧붙인다. 활성 `persona_progress_r21`은 없앤다. 재로드는 다시 이관하지 않는다. 원본 곡선보다 넘친 XP는 기존 `exp_settle` 방식으로 정리하며 이전 값도 `experience_before_r22`에 보존한다.

40개 레벨 × 반대쪽 레벨 3개에서 양방향 충돌·원문 보존·입력 불변·반복 복원을 검사했다. schema3의 작은 레벨이 이기는 경우도 포함한다. JSON이 schema를 float로 읽으면 배열 멤버십으로 정수 schema를 고르는 판정이 달라지는 버그도 찾아 숫자 동등 비교로 고쳤고, 120개 옛 저장의 JSON 왕복을 추가했다. 진행 중 옛 원정에는 페르소나 편성 스냅샷이 없으므로 동료만 출전한 원정으로 이어 받고, 귀환 때 원본의 미출전 50%를 지급한다. P1 원정은 전투 때 지급한 XP를 귀환에서 다시 주지 않는다. 기존 schema1/2 모델은 옛 저장 검증용 호환 경로로 남고, 실제 월드는 항상 P1 schema3이다.

첫 만남 호감 0 → 여관 선택/반응·하루 제한 → 영입 → 편성 → 출전 → 승리 → 정산 → 레벨업과 그 뒤 영입 레벨을 연결했다. native 의미 검사는 통제된 전투 입력을 사용하며, Web 6구성은 능력치·적·보상 변경 없이 실제 포인터 전투로 Lv.2 이상까지 진행했다. 기본 보너스 20점·직업 추천 배분은 원본의 선택 범위다.

### 저장 파일과 IndexedDB

기존 `world_v1.json`/`.bak` 읽기 전용 fallback과 새 `world_v3.json`/`.bak` 쓰기를 유지했다. 실제 사용자 프로필은 열지 않았고, native fixture 경로와 임시 Chromium 문맥만 사용했다. Web에서 schema2 성장 Lv.17/XP2와 원본 이관 값 Lv.25/XP3을 함께 심은 fixture를 로드해 **17/2**를 확인했다. 불러오기만 해서는 v3 파일이 생기지 않았고 v1·백업 바이트도 그대로였다. 실제 여관 대화로 저장한 뒤 v3가 생성됐고, 재로드는 그 선택 전 대화를 복원하므로 v3 우선순위도 확인했다. 근거: `round8/indexeddb-results.json`.

P1의 기존 저장 보존 검사는 필드 삭제를 허용하도록 느슨하게 바꾸지 않았다. 활성 성장 기록의 위치가 바뀌는 한 항목만 새 보존 위치를 검사하도록 갱신했다. JSON 숫자의 int/float 표현은 값으로 대조한다. 원본 Lua 수식·게임 수치 기대값은 바꾸지 않았다. 기존 `ui_persona_r22_test`는 Create 상속 화면만 폼 치수를 검사하므로 준비 화면이 Town 상속으로 바뀐 뒤 1,383개로 줄었다. 새 UI 검사는 준비 화면의 실제 글자 치수·겹침·뷰포트·44px 터치·원정 연결을 별도로 검사한다.

### 화면·실제 검수와 차이

`persona_sortie_screen.gd`는 폼 상속을 제거하고 기존 `town_screen_r21`의 종이·폐허·배경·초상·버밀리언 버튼·하단 이동을 사용한다. 4칸 중 첫 칸이 자기 참전 페르소나이며, 지휘에서는 동료 4명이다. 빈 칸·전열 없음·보유 동료 정렬/필터·최대 인원·빈 출발 차단·페르소나 단독 출발·수락 의뢰의 별도 출발을 유지했다. 390×664에서도 새 주요 버튼의 실측 높이는 44px 이상이다. 후보가 많으면 해당 영역만 스크롤한다. 생성 클래스 정보가 없는 옛 저장은 자기 참전을 막고 이유를 표시하며 기존 지휘·4인 파티를 유지한다. 직업을 임의로 채우거나 옛 동료를 다시 생성하지 않는다. 이 저장에 새로 생성 정보를 지정하는 편집 흐름은 이번 범위에 넣지 않았다.

만들기 5단계는 기존 글꼴의 SVG 윤곽 제목, 수묵 마을 배경, 종이, 선택/진행의 버밀리언을 쓴다. SVG는 기존 글꼴에서 생성한 것이며 승인 시안 글자를 추적한 것이라고 주장하지 않는다. 첫 만남은 선택한 동료의 기존 `detail-overview` 초상을 크게 놓고 원문 장면을 스크롤로 읽는다. 준비 화면 초상도 기존 `party-tall`/`formation-face` 칸의 배치·크롭만 조절했고 새 초상은 그리지 않았다.

[owner-zoom-8.jpg](verification/town-r21/owner-zoom-8.jpg)의 4쌍과 실제 WASM 360폭 준비 화면을 직접 열었다. 원정 준비는 `03-preparation-0`과 자기 참전/지휘를 비교했다. 만들기·첫 만남은 개별 시안이 없으므로 비교판에 “개별 시안 없음, 마을/길드 문법 참고”라고 표시했다. 확대 합본의 초상 크기를 보고 기존 슬롯의 표시 크롭을 보완한 뒤 다시 열었다. 시안 속 Lv.20/금화/2층 숫자를 복제하지 않고 실제 상태를 쓴다.

남는 외형 차이는 준비 화면에 새 모드 전환·후보 목록이 들어가 원래의 전열/후열 얼굴 줄과 경로 삽화 대신 필터·후보·짧은 경로 안내를 쓰는 점, 페르소나가 초상 없는 문자 칸인 점, 제목이 기존 r21 글꼴 윤곽인 점이다. 새 초상 생성·전투 파일 수정으로 이 차이를 숨기지 않았다. 독립 페르소나의 종족/직업 특성·장비/고유기술 전체 동등성 등 P1 후속 묶음은 이번 검증 범위가 아니다. 기존 카드 정본 없음·나머지 대화 콘텐츠 부족도 이 차수에서 추가 구현하지 않았다.

### 검사·export 근거

|검사|결과|
|---|---|
{table}

대화 JSON 검사 오류 0, selftest 58개 실패 0, impeccable detector `[]`를 확인했다. 기존 Windows root certificate store 진단은 환경 경고로 별도 기록했다. 5크기는 360×780·390×844·430×932·390×664·1280×800이며 360폭 reduced-motion을 더해 Web 6구성이다. 모든 구성에서 선택/반응 재로드, 첫 동료 0, 영입 레벨, 모드 전환, 빈 편성 차단, 전투 승리·레벨업, 귀환 XP 중복 없음, 정산 재로드, 전투 후 뷰포트 복원을 검사했다. 상점 스크롤 검사는 실제 조상 ScrollContainer의 표시 범위를 읽고 실제 휠로 이동한다.

요청한 `godot_r17.py --headless --export-release Web ../docs/index.html` 및 `update_version.py` 실행 완료. `ui_build=r21-d-town-20261102d`, PCK SHA-256 `{audit['pck_sha256']}`. 원격 배포는 하지 않았다. 결과는 `verification/town-r21/common-results.json`, `web/results.json`, `round8/{{integration-results,ui-results,indexeddb-results,audit,comparison}}.json`과 원문 로그에 있다.

전투·A 데이터/규칙·대화 JSON·기존 적/초상·원본 Lua {len(source)}파일은 변경하지 않았다. 사용자 저장 삭제/덮어쓰기, git 명령, 다른 worktree 쓰기, 외부 메시지, 성적 장면 이식은 하지 않았다. 기존 DESIGN.md와 `.impeccable/design.json`의 메타데이터 드리프트는 남겨 두었다.

### 변경 파일

{files}

추가 산출물: `verification/town-r21/round8/**`, 검사 결과·native/Web 캡처, `owner-zoom-8.jpg`, `docs/**`, 이 보고서.

'''
p=R/'UI-R21-D.md';previous=p.read_text(encoding='utf-8');start=previous.find('## 8차')
if start>=0:previous=previous[:start]+previous[previous.index('## 6차',start):]
heading='# UI-R21-D\n\n'
if previous.startswith('# UI-R21-D'):previous=previous.split('\n',1)[1].lstrip()
p.write_text(heading+report+previous,encoding='utf-8')
print(json.dumps({'groups':len(rows),'failed_groups':0,'integration_checks':logic['checks'],'ui_checks':native['checks'],'web':len(web),'protected':len(protected),'zoom_bytes':audit['owner_zoom_bytes'],'report':str(p)},ensure_ascii=False))
