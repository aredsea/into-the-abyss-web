"""Final pass-five audit and report from actual test/export evidence, no Git."""
from pathlib import Path
import hashlib,json,shutil
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';V=O/'round5'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
base=read(V/'baseline.json');changed=[p for p,h in base['files'].items() if not (R/p).exists() or sha(R/p)!=h]
added=[p.relative_to(R).as_posix() for folder in ['project','tools'] for p in (R/folder).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.pyc','.import'] and p.relative_to(R).as_posix() not in base['files']]
protected=[]
for p in changed:
    name=Path(p).name
    if name.startswith(('battle_','combat_','signature_')) or name in ['dungeon_rules_r21.gd','dungeon_enemy_r21.gd','dungeon_world_r21.gd','dungeon_view_r21.gd'] or name.endswith('-r21.json') or p.startswith(('project/assets/enemies-r21/','project/assets/portraits-r21/','project/assets/portraits-r21-web/','project/assets/portraits-r10/','project/assets/src/')):protected.append(p)
original=read(R/'ASSET-HASHES.json');asset_changes=[v['path'] for v in original if sha(R/v['path'])!=v['sha256']]
provenance=read(V/'persona-provenance.json');source_changes=[v['path'] for v in provenance['files'] if sha(Path(v['path']))!=v['sha256']]
shutil.copyfile(O/'common-results.json',V/'common-results.json')
shutil.copyfile(O/'web/results.json',V/'web-results.json')
results=read(O/'common-results.json');failed=[v['name'] for v in results if v['exit_code'] or v['errors']]
web=read(O/'web/results.json');persona=read(V/'persona-results.json');ui=read(V/'ui-results.json');compare=read(O/'compare-round5/comparison.json');version=read(R/'docs/version.json')
assert len(results)==30 and not failed,failed
assert not protected and not asset_changes and not source_changes,(protected,asset_changes,source_changes)
assert provenance['data_matches_project_semantic']
assert len(web)==6 and len({(v['width'],v['height']) for v in web})==5
assert all(not v['errors'] and not v['text_errors'] and 'source:research-confirmed' in v['town_screens'] for v in web)
assert persona['lua_matches']==persona['lua_samples'] and not persona['failures'] and not ui['failures']
assert version['ui_build']=='r21-d-town-20261102' and version['pck_sha256']==sha(R/'docs/index.pck')
assert (O/'owner-zoom-5.jpg').stat().st_size<=300000
assert compare['status']=='directly reviewed', 'Open final comparison images and record judgement first'
pck=(R/'docs/index.pck').stat().st_size
report={'groups':len(results),'failed_groups':failed,'lua_samples':persona['lua_samples'],'lua_matches':persona['lua_matches'],'new_rule_checks':persona['checks'],'new_ui_checks':ui['checks'],'original_assets':len(original),'original_asset_changes':asset_changes,'protected_changes':protected,'source_changes':source_changes,'changed':changed,'added':added,'web_configurations':len(web),'web_sizes':5,'pck_bytes':pck,'pck_delta':pck-base['pck_bytes'],'version':version,'owner_zoom_bytes':(O/'owner-zoom-5.jpg').stat().st_size}
(V/'audit.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
table='\n'.join('|'+x['name']+'|'+('<br>'.join(x['summary']) or 'exit 0')+'|0|' for x in results)
filelist='\n'.join('- `'+p+'`' for p in changed+added+['tools/town_r21_round5_baseline.py (착수 SHA 캡처 전에 생성)'])
text=f'''## 5차 — 결과 문구 복구·원본 연구 편집 규칙 부분 이식

**부분 인계다.** 패배 문구 잘림과 승리 부제 중복/가림을 고쳤고, 원본 연구의 마을 편집·강화·저장 규칙을 기존 동료별 전술 슬롯에 연결했다. 원본의 독립 페르소나 전투 주체와 전투 실행 전체를 이식한 것은 아니다. 카드 사건 전체, 영입 원본 난수 순서, NPC 호감 훅은 이번 차수에서 구현하지 않았다. 지시서의 “범위가 너무 크면 위 순서대로 하고, 끝낸 데까지 검사 통과 상태로 멈추고 남은 것을 적어라”에 따라 이 범위에서 검사 실패 0인 상태로 인계한다.

### 핵심 수치

|항목|5차 최종|
|---|---:|
|공통·추가 검사 그룹 / 실패|{len(results)} / 0|
|새 연구 규칙 검사 / 실패|{persona['checks']:,} / 0|
|새 원본 Lua 대조 / 일치|{persona['lua_samples']:,} / {persona['lua_matches']:,}|
|표본 구성|정제 7 + 비용 12 + 조합/단계 7,744 + 행동 전이 6,080|
|새 연구 UI 검사 / 실패|{ui['checks']:,} / 0|
|결과 UI 검사 / 실패|235 / 0|
|Web 구성 / 서로 다른 크기 / 오류|6 / 5 / 0|
|원본 자산 SHA / 변경|{len(original)} / 0|
|전투·A 데이터·적·C 산출물 변경|0|
|owner-zoom-5.jpg|1200×1342 / {report['owner_zoom_bytes']:,} bytes|
|최종 PCK / 착수 실물 대비|{pck:,} / {pck-base['pck_bytes']:+,} bytes|

### 결과 화면

`town_result_r21.gd`에서 결과 문구를 불투명 종이 영역 위의 실제 Label로 분리했다. 패배 “부상으로 전투에서 이탈했습니다.” 전체가 보이며, 승리 “적을 모두 쓰러뜨렸습니다.”와 “전투 승리 · …”는 서로 다른 줄에 있다. 승리 제목 SVG에 섞였던 기울어진 한글 부제 조각은 원본 시안에서 그 영역만 제외해 벡터로 다시 추적했다. 원본 시안·배경 그림은 수정하지 않았다. 제외 다각형·SHA·추적 허용치는 `round5/title-provenance.json`에 있다.

360×780·390×844의 승리/패배 4쌍을 [owner-zoom-5.jpg](verification/town-r21/owner-zoom-5.jpg)로 직접 열었고, 나머지 3크기는 native 실제 결과 시험으로 검사했다. 전체 시안 일치는 아니다. 파티 포즈·폐허 구조·HP/MP 칸·제목의 기울기/마모 차이는 그대로 남는다. 종이 문구 영역은 시안보다 각이 지며 승리 상세 한 줄 때문에 더 높다. 전투 파일은 읽기만 했고 기존 결과 확인/중복 보상 방지 핸들러를 유지했다.

### 연구: 실제 구현 범위와 원본 대비 차이

정본은 읽기 전용 `C:/Clauede Code/dungeon-bot/bot/src/29-persona-skill.lua`, 난수/공용 보조를 포함한 `01-game.lua`, `design/persona_skill.json`이다. 기존 프로젝트 `persona_skill.json`과 원본은 공백/줄바꿈 바이트가 다르지만 JSON 의미는 같다. 이 데이터 파일은 변경하지 않았다.

새 `persona_research_r21.gd`는 접두 8종·접미 8종의 호환, 비정상 입력 정제, 0~10단계, 단계별 이름·한/영 설명·스킬 메타데이터, 임시 조합, 변경 감지, 강화 즉시 지출, 저장 전 기존 장착 유지, 준비 완료 시 저장 확정을 구현한다. 접두를 바꿔 호환이 깨지면 접미가 비워지며 다른 조각의 강화 단계는 남는다. 비용은 **다음 단계 n에 대해 40+20×n²**이므로 첫 강화는 60금화다. 옛 동료 전술 관리의 강화 단축 경로도 이 비용을 사용하도록 고쳤다. 기존 expansion_world의 예전 규칙/검사 기대값은 손대지 않았다.

마을의 전술 연구 → “조각 조합 · 편집 후 저장”으로 열며, 기존 동료 전술 관리도 유지했다. 새 편집기는 동료별로 draft·지출액을 저장하고 저장 버튼을 눌러야 기존 전술 슬롯에 반영한다. 저장된 슬롯은 기존 battle_data/tactic 경로로 전달되는 것을 검사했다. native에서 5크기로 실제 강화/저장 포인터·조합 선택 이벤트·재로드를 검사했고, Web에서도 키보드로 실제 드롭다운을 선택하고 실제 포인터로 강화·확정했다. [시안과 편집/저장 상태 비교](verification/town-r21/compare-round5/research-review.jpg)를 직접 열었다. 합성 카드 삽화와 원본 손을 든 자세는 재현하지 않았다.

**원본과 다른 연결 경계:** 원본은 `G.persona.skill` 한 개이고 이 게임은 기존 `s.research[동료]` 30슬롯이다. 이 구조를 독립 사용자 페르소나로 바꾸지는 않았다. 원본 `B.PRUN.persona`·라운드 훅·클래스 속성 실행은 이번 새 시험의 검증 범위가 아니다. 기존 battle_v3의 전술 실행을 그대로 쓴다. 기존 전술의 즉시 장착/해제 단축 경로도 호환용으로 남으므로 원본의 전체 UI 흐름과 동일하다고 세지 않는다. 원본 길드 나가기의 미저장 변경 차단도 적용하지 않았고, 임시 작업은 화면을 나가도 저장에 남는다. AI 장면, pending 대화 생성/송신과 성적 장면은 제외했다. 정본의 busy 저장 거절은 순수 규칙에서 표본 대조했지만 게임은 AI 대화 대기 상태를 만들지 않는다.

### 원본 하네스와 저장 호환

`tools/town_r21_persona_oracle.mjs`가 기존 Wasmoon `lua_sim.mjs` 위에서 원본 Lua 함수를 수정 없이 실행한다. AI/외부 송신을 막기 위해 `pend_busy`만 fixture 값으로, `pend_hard`만 로컬 no-op으로 대체했다. 저장 메시지까지 원본과 대조하지만 게임에는 “보내기” 대화 버튼을 추가하지 않았다. Lua 빈 테이블이 JSON에서 빈 배열로 나오는 차이만 시험에서 빈 사전으로 정규화하고, 숫자 정수/실수의 저장 표현은 값으로 비교한다. 원본 계산 기대값은 변경하지 않았다. 표본·SHA·대체 경계는 `round5/persona-oracle.json`·`persona-provenance.json`·`persona-results.json`에 있다.

schema2·사용자 저장 경로를 유지하고 `research_editor_r21`만 추가했다. 없으면 빈 사전으로 이관한다. 입력 저장 불변, 기존 모든 필드 보존, 결제한 임시 단계의 JSON roundtrip, 진행 중 원정과 draft 동시 복원, 불량 지출/단계/소유자 원자적 거절, 돈 부족/원정 중 행동 거절을 검사했다. 테스트는 격리 엔진의 fixture 파일과 임시 Web 브라우저 문맥만 썼고, 사용자 저장을 삭제·덮어쓰거나 초기화하지 않았다.

### 남은 작업 — 이식 완료로 세지 않음

1. 페르소나 전술 **전체**: 독립 사용자 페르소나 주체와 원본 전투 실행/라운드 훅을 연결해야 한다. 금지된 전투 파일을 이번 작업에서 고치지 않았다.
2. 카드 사건 전체: 원본 `76-dungeon.lua`·`77-explore.lua`·`78-battle-item.lua`의 사건/획득/사용/RNG를 A 원정에 연결하는 작업과 Lua 대조 시험이 남았다. 기존 key/camp·옛 봉인 보관함만 유지한다.
3. 영입 원본 RNG: `72-guild.lua`의 `gd_candidates`/`gd_rnd`/주선 순서와 `74-level.lua`의 페르소나 기준 합류 레벨은 미이식. 기존 웹 RNG/파티 최고 레벨을 유지한다. 비용/미영입 중 1명/중복 없음만 종전 수준이다.
4. NPC 호감: `73-inn.lua`·`74-affection.lua`·시설별 `npc_like` 훅을 새로 이식하거나 표본 시험하지 않았다. 기존 동료 여관 호감 규칙만 유지한다. 79-sex.lua·성적 친밀도 장면·AI 대사는 제외다.

### 직접 실행한 검사

|검사|결과 원문|실패|
|---|---|---:|
{table}

각 실행 종료 코드 0·스크립트 오류 0. 격리 Windows의 기존 root certificate store 경고만 분리했고 원문 로그를 보존했다. 이번 차수는 기존 공통 검사 기대값을 바꾸지 않았다. 결과 UI 검사는 완전 문구, 종이 영역 포함 관계, 그리기 순서, 승리 두 줄 비중첩을 추가했다. Web build 식별자 기대값만 요청된 날짜로 바꿨다.

### Web와 산출물

`python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 후 `python tools/update_version.py` 실행. `ui_build={version['ui_build']}`, PCK SHA-256 `{version['pck_sha256']}`. 시작 PCK {base['pck_bytes']:,} bytes → 최종 {pck:,} bytes. `round5/export.log`에 내보내기 원문이 있다. 로컬 export이며 원격 배포는 하지 않았다.

`tools/web_smoke_r19.py --town-r21`은 390×844·360×780·390×664·1280×800·430×932와 360×780 reduced-motion에서 실행했다. 전부 새 연구 확정, 기존 상점/장비/시설/고유기, 자연 승리 결과와 viewport 복귀를 통과했다. `web/results.json` 및 `round5/web-results.json`에 6구성·오류 0이 기록됐다. 변경 화면은 canvas이므로 DOM/CSS inspector로 내부 레이아웃을 측정할 수 없다. native Label/Control 실제 치수 검사와 WASM 포인터 검사로 대체했고, impeccable 기계 검출 결과는 `[]`였다. 시각 합격을 자동 검사 수치로 대신하지 않았다.

### 변경 파일

{filelist}

추가 산출물: `verification/town-r21/round5/**`, `compare-round5/**`, `owner-zoom-5.jpg`, `docs/**`, 본 보고서. `round5/audit.json`은 착수 직전 SHA와 최종 파일을 Git 없이 비교한다. 원본 자산 96개와 전투/A/B/C 보호 파일 변경은 0이다. 모든 쓰기는 본 worktree 안에서 수행했고 git 명령·다른 worktree 쓰기·외부 메시지 송신은 하지 않았다.

기존 DESIGN.md와 .impeccable/design.json의 드리프트는 여전히 남는다. 요청 범위 밖 문서를 고치지 않았으며 필요하면 별도 document 작업으로 갱신할 수 있다.

'''
path=R/'UI-R21-D.md';old=path.read_text(encoding='utf-8')
if '\n## 5차 —' in old:
    start=old.index('\n## 5차 —');end=old.index('\n## 4차 —',start);old=old[:start]+old[end:]
old=old.replace('# UI-R21-D\n','# UI-R21-D\n\n'+text,1)
path.write_text(old,encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ['changed','added','version']},ensure_ascii=True))
