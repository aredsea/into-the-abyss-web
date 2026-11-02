"""Summarize executed round-nine evidence and preservation, without git."""
from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round9'
def read(p):return json.loads((R/p).read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
rows=read('verification/town-r21/common-results.json')
logic=read('verification/town-r21/round9/integration-results.json')
ui=read('verification/town-r21/round9/ui-results.json')
web=read('verification/town-r21/web/results.json')
idb=read('verification/town-r21/round9/indexeddb-results.json')
version=read('docs/version.json');comparison=read('verification/town-r21/round9/comparison.json')
assert len(rows)==44 and all(not r['errors'] and not r['exit_code'] for r in rows)
assert not logic['failures'] and not ui['failures'] and len(ui['captures'])==55
assert len(web)==6 and len({(r['width'],r['height']) for r in web})==5
assert all(not r['errors'] and not r['text_errors'] and r['pck_sha256']==version['pck_sha256'] for r in web)
assert idb and all(r['v1_and_backup_unchanged'] and r['v3_priority_on_reload'] for r in idb)
assert comparison['direct_review']=='opened' and comparison['bytes']<=300000
assert read('verification/town-r21/round9/impeccable-detect.json')==[]
base=read('verification/town-r21/round9/baseline.json')
current={p.relative_to(R).as_posix():sha(p) for f in ['project','tools'] for p in (R/f).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.pyc','.import']}
changed=[p for p,h in base.items() if current.get(p)!=h]
new=[p for p in current if p not in base]
protected=[p for p in base if ((p.startswith(('project/assets/','project/data/','project/game/')) and p!='project/game/chronicle_world_r22.gd') or Path(p).name.startswith(('battle_','combat_')))]
assets=read('ASSET-HASHES.json')
sources={}
for row in read('verification/town-r21/round7/card-audit.json')['manifest']:sources[str(Path(row['file']))]=row['sha256']
for row in read('verification/chronicle-r22/provenance.json')['files']:sources[str(Path(row['path']))]=row['sha256']
audit={'changed':changed,'new':new,'protected_count':len(protected),'protected_changed':[p for p in protected if current.get(p)!=base[p]],
 'original_assets':len(assets),'original_assets_changed':[x['path'] for x in assets if sha(R/x['path'])!=x['sha256']],
 'source_count':len(sources),'source_changed':[p for p,h in sources.items() if sha(Path(p))!=h],
 'ui_build':version['ui_build'],'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':sha(R/'docs/index.pck'),
 'owner_zoom_bytes':comparison['bytes']}
assert not audit['protected_changed'] and not audit['original_assets_changed'] and not audit['source_changed']
assert version['ui_build']=='r21-d-town-20261102e'
(V/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
summary={'groups':len(rows),'failed_groups':0,'integration_checks':logic['checks'],'dialogue_cases':logic['dialogue_cases'],'legacy_specimens':logic['legacy_specimens'],
 'ui_checks':ui['checks'],'captures':len(ui['captures']),'web_configurations':len(web),'web_sizes':5,'web_battles':sum(r['battles'] for r in web),'protected_count':len(protected),'zoom_bytes':comparison['bytes']}
(V/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
def result(row):
    s='; '.join(row['summary'])
    if '{' in s:
        try:return str(json.loads(s[s.index('{'):])['checks'])+' checks / 0 failures'
        except (ValueError,KeyError):pass
    return s or 'exit 0'
table='\n'.join('|'+r['name']+'|'+result(r)+'|' for r in rows)
files='\n'.join('- `'+p+'`' for p in changed+new)
section=f'''## 9차 — P7·P10 의미 통합 · 전후열 편성·그림 경로

P7 도감·상태·장비 가방과 P10 장소·인물·연대기를 8차 페르소나 흐름에 연결했다. 선택지 대화의 실제 호감 확정 직후 공용 `Chronicle.affection_changed()`를 호출한다. 준비 화면은 **전열/후열을 분리하고 선택한 동료 초상을 한 번씩만** 보여 준다. 원정 진행은 원본의 **탐색 5회 → 휴식 → 층 보스**를 유지하고 기존 그림 3칸으로 표시한다.

|항목|결과|
|---|---:|
|import·공통·기존 r21·P1·round8·P7·P10·새 검사 그룹 / 실패|{len(rows)} / 0|
|새 의미 통합 검사 / 실패|{logic['checks']:,} / 0|
|실제 선택지 호감 경계 조합|{logic['dialogue_cases']}|
|실제 옛 저장 통합 이관·왕복 표본|{logic['legacy_specimens']}|
|새 native UI 검사 / 실패|{ui['checks']:,} / 0|
|새 native 화면 / 크기|{len(ui['captures'])} / 5|
|Web 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|Web 실제 전투 승리 합계|{summary['web_battles']}|
|IndexedDB 옛 저장·백업 바이트 보존 / v3 우선 재로드|통과 / 통과|
|보호 파일 / 변경|{len(protected):,} / 0|
|원본 자산 / 변경|96 / 0|
|원본 Lua·설계·공개 인물 파일 / 변경|{len(sources)} / 0|
|owner-zoom-9 비교판|1200×677 / {comparison['bytes']:,} bytes|
|Web PCK|{audit['pck_bytes']:,} bytes|

### 의미 통합과 저장

`chronicle_world_r22.gd`의 선택지 진입점이 부모의 선택 확정을 성공한 뒤에만 호감 전후 값을 공용 연대기로 전달한다. 잘못된 선택·하루 제한·반응 재확인·같은 단계 변화에는 기록을 추가하지 않는다. 세 동료 × 17개 경계 값 × 선택지 3개, 합계 153건을 실제 선택지 경로로 실행하고 선택 전/후 JSON 복원, 입력 불변, 상승·하락·무변화와 재실행을 검사했다. 대화 JSON과 2차 대사는 수정하거나 병합하지 않았다.

첫 만남·영입·P1 전투 직후의 레벨업·귀환 정산이 P10 facade를 통과하도록 실행했다. 원본 레벨 경계 직전의 native fixture에서 통제된 실제 전투 승리를 만들고 중첩 경험치 호출에도 레벨업 기록 1개, 퇴각 기록 1개, 반복 정산 추가 기록 0개를 확인했다. 영입 레벨은 성장한 `s.persona`와 같다. 이 native fixture의 공격 능력치 조정은 테스트 입력이며 게임 데이터 변경이 아니다. Web에서는 적·능력치·보상을 바꾸지 않고 실제 전투로 레벨업했다. 기존 P10 검사도 돌파·구역 보스·의뢰·전설 장비·귀환·직접 다음 층과 중복 방지를 다시 확인했다.

실제 옛 저장 11표본 각각을 원문 그대로 복원하고 기존 활동 로그와 소급 기록 없음, 입력 바이트 보존을 확인했다. 같은 표본에 D 충돌 성장 값과 P7 `favs/panels_r22`, P10 `chronicle_r22`를 함께 담아 Lv17/XP2 선택, 원문 Lv25 보관, 반복 이관 불변, 패널 page/bg 복원, 큐 flush와 디스크 왕복까지 확인했다. schema3·`world_v3.json`·백업·옛 `world_v1.json` fallback 정책은 유지한다. 임시 native fixture와 새 Chromium 문맥만 사용했다.

### 진입·뒤로 가기·화면

도감·상태·장비 가방은 들어온 화면으로 돌아간다. 마을 도감 → 상태 → 뒤로는 마을, 동료 도감 상세 → 뒤로는 동료, 가방 장비 → 상태 → 기록 → 뒤로 → 뒤로는 상태 → 가방이다. 뒤로 가기는 새 진입으로 기록하지 않아 순환을 막는다. 장소·인물·연대기 탭도 최초 진입 화면을 유지한다. 하단 탭 이름을 마을·동료·원정·가방·기록으로 통일하고 도감/상태는 동료, 장비 가방은 가방, 장소/인물/연대기는 기록을 활성 표시한다. 새 진입 버튼과 기존 버튼의 겹침을 5크기에서 검사했다. 첫 동료 테이리스의 긴 직업명이 마을에서 잘리던 문제도 이름 아래 별도 줄로 수정했다.

편성 초상은 전열/후열 두 영역으로 나뉘고 선택 해제는 해당 초상을 누른다. 아래 목록에는 대기 동료만 보여 준다. 한 열에 3~4명이 몰리면 그 열만 가로 스크롤하며, 네 번째 초상을 실제 입력으로 해제하는 검사도 포함했다. 필터는 대기 동료만 바꾸므로 선택된 후열도 화면과 해제 입력을 유지한다. 기존 8차 UI 검사 **한 항목**을 이 새 행동에 맞춰 변경했다. 원본 규칙·수치 기대값은 바꾸지 않았다.

경로 그림은 `bg-explore.webp`, `bg-rest.webp`, `bg-departure.webp`의 기존 자산만 사용한다. 시안의 갈림길/집필실/귀환 문구는 게임 규칙으로 가져오지 않았다. 수락 의뢰가 있으면 기존처럼 별도 의뢰 출발 행동을 보여 준다. 하단 원정 활성선은 글자 아래로 내리고 아이콘·라벨도 고정 영역 안에 맞췄다. 저장 실패 재시도와 의뢰 출발은 같은 자리를 동시에 차지하지 않는다.

비교판 [owner-zoom-9.jpg](verification/town-r21/owner-zoom-9.jpg), 5크기 native 연락판 및 주요 원본 크기 화면, 실제 Web 준비 화면을 직접 열었다. 최종 검토는 `round9/visual-review.json`에 기록했다. 남는 차이는 페르소나에 승인 초상이 없어 문자 칸인 점, 새 모드/필터 때문에 시안과 세로 비율이 다른 점, 3칸 그림이 시안 삽화와 다르고 실제 규칙 이름을 쓰는 점이다. 새 그림은 만들지 않았다. P7/P10 읽기 화면의 폼/스크롤 문법과 영어 연대기 본문은 기존 구현/원본 계약을 유지하며 전체 봇 동등성을 뜻하지 않는다.

### 검사·export 근거

|검사|실행 결과|
|---|---|
{table}

대화 JSON 검사 오류 0, selftest 58개 실패 0, Impeccable detector `[]`. native·Web 크기는 360×780 / 390×844 / 430×932 / 390×664 / 1280×800이며 Web에는 360폭 reduced-motion을 더했다. 원본 P7·P10 oracle fixture를 현재 병합 코드에서 다시 실행했으며 원본 Lua fixture를 새로 추출한 것은 아니다. Windows root certificate store 진단은 기존 환경 경고로 별도 분류했다. SCRIPT ERROR·기능 검사 실패는 0이다.

지정 명령 `python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 및 `python tools/update_version.py` 완료. **ui_build={version['ui_build']}**, PCK SHA-256 `{audit['pck_sha256']}`. Web 6구성 모두 이 PCK 해시와 일치한다. 원격 배포는 하지 않았다.

근거: `verification/town-r21/common-results.json`, `round9/{{integration-results,ui-results,indexeddb-results,audit,summary,comparison,visual-review}}.json`, `web/results.json` 및 검사 원문 로그. 비교 도구는 `tools/town_r21_round9_compare.py`, Web 흐름은 `tools/town_r21_round9_web.py`다.

전투 파일·A 데이터/규칙·대화 JSON·적/초상·원본 파일 변경 0, 다른 worktree/클라우드 쓰기 0이다. 지시서 내용이 도착하기 전 읽기 전용 `git status`를 한 번 시도했으나 소유권 오류로 실패했다. 금지 규칙을 읽은 뒤 git 명령은 실행하지 않았으며 git 변경 명령은 0이다. 기존 DESIGN.md/sidecar 드리프트는 수정 범위 밖으로 유지했다.

### 변경 파일

{files}

추가 산출물: `verification/town-r21/round9/**`, 검사·캡처·Web 결과, `owner-zoom-9.jpg`, `docs/**`, 이 보고서.

'''
p=R/'UI-R21-D.md';previous=p.read_text(encoding='utf-8')
if '## 9차' in previous:previous=previous[:previous.index('## 9차')]+previous[previous.index('## 8차'):]
previous=previous.split('\n',1)[1].lstrip() if previous.startswith('# UI-R21-D') else previous
p.write_text('# UI-R21-D\n\n'+section+previous,encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True))
