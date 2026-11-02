"""Require fresh merged execution evidence; no Git or remote actions."""
from pathlib import Path
import hashlib,json,re,subprocess,shutil
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round14'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,v):(O/name).write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
base=read(O/'baseline.json')
changed=[p for p,h in base.items() if not (R/p).exists() or sha(R/p)!=h]
new_files=sorted(p.relative_to(R).as_posix() for prefix in ['project','server/abyss-save/src','server/abyss-save/test','tools','docs'] for p in (R/prefix).rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__']) and p.relative_to(R).as_posix() not in base)
allowed={'project/game/localization_r22.gd','project/data/localization-r22.json','project/game/expedition_world_r22.gd','project/game/facilities_world_r22.gd','project/game/persona_world.gd','project/game/dungeon_world_r21.gd','project/game/battle_v3.gd'}
protected={p:h for p,h in base.items() if p.startswith(('project/game/','project/data/','project/assets/')) and p not in allowed}
protected.update({p:h for p,h in base.items() if p=='server/abyss-save/src/index.js' or p.startswith('server/abyss-save/test/')})
broken=[p for p in protected if p in changed]
assets=read(R/'ASSET-HASHES.json');asset_changes=[a['path'] for a in assets if sha(R/a['path'])!=a['sha256']]
markers=[]
for folder in ['project','server/abyss-save/src','tools']:
 for p in (R/folder).rglob('*'):
  if not p.is_file() or '.godot' in p.parts or p.suffix not in ['.gd','.json','.py','.mjs','.js']:continue
  if re.search(r'^(?:<<<<<<< |=======\s*$|>>>>>>> )',p.read_text(encoding='utf-8',errors='replace'),re.M):markers.append(p.relative_to(R).as_posix())
rows={r['name']:r for r in read(O/'regression-initial.json')}
rows.update({r['name']:r for r in read(O/'regression.json')})
for p in sorted((O/'rows').glob('*.json')):
 r=read(p);rows[r['name']]=r
rows=sorted(rows.values(),key=lambda r:r['name'])
extras=['export_licenses','motion_r9_integration','motion_r18_integration','balance_probe','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit']
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in extras}
assert {r['name'] for r in rows}==expected,(expected-{r['name'] for r in rows})
assert all(r['exit_code']==0 and not r['errors'] for r in rows),[r for r in rows if r['exit_code'] or r['errors']]
write('regression.json',rows)
parity=[]
for name,file in [('A6','a6-mixed-audit.json'),('P3','p3-mixed-audit.json'),('A7','a7-gear-audit.json'),('A7 Lv40','a7-gear-balanced-audit.json'),('A8','a8-audit.json'),('A9 Lv10','a9-native-10-audit.json'),('A9 Lv40','a9-native-40-audit.json')]:
 d=read(R/'verification/data-r21'/file)
 assert d['battles']==d['equal_battles'] and d['source_actions']==d['matched_actions']==d['actual_actions']
 parity.append({'name':name,'battles':d['battles'],'records':d['matched_actions']})
p2=read(R/'verification/data-r21/p2-full-battles.json');assert p2['different_actions']==0
parity.insert(0,{'name':'P2','battles':p2['battles'],'records':p2['compared_actions']})
for file in ['p2-full-battles.json','a6-mixed-audit.json','p3-mixed-audit.json','a7-gear-audit.json','a7-gear-balanced-audit.json','a8-audit.json','a9-native-10-audit.json','a9-native-40-audit.json','source-audit.json']:
 shutil.copyfile(R/'verification/data-r21'/file,O/file)
server=[]
for label,file in [('integration','verification/cloud-r22/server-results.json'),('security-r1','verification/cloud-r22/p9b/security-results.json'),('siteverify','verification/cloud-r22/p9b/siteverify-results.json'),('security-r2','verification/cloud-r22/p9c/security-results.json'),('security-r3','verification/cloud-r22/round12/security-results.json'),('deployment','verification/cloud-r22/round12/deployment-results.json'),('combat','verification/town-r21/round14/server-combat-results.json')]:
 d=read(R/file);fail=d.get('failures',sum(not g['passed'] for g in d.get('groups',[])));assert not fail
 server.append({'name':label,'checks':d['checks'],'failures':0})
 if label!='combat':shutil.copyfile(R/file,O/('server-'+label+'-results.json'))
assert 'web smoke exit 0' in (O/'web-execution.txt').read_text(encoding='utf-8')
assert 'npm test exit 0' in (O/'npm-execution.txt').read_text(encoding='utf-8')
native=read(O/'integration-results.json');assert not native['failures']
web=read(R/'verification/town-r21/web/results.json');version=read(R/'docs/version.json')
assert len(web)==8 and all(w['ui_build']=='r21-d-town-20261103c' and w['pck_sha256']==version['pck_sha256'] and not w['errors'] and not w['text_errors'] for w in web)
assert any(w.get('persona_attacks',0)>0 and w.get('midfight_reload') and w.get('midfight_nonterminal') for w in web)
write('web-results.json',web)
bundle=subprocess.run(['node','--input-type=module','-e',"import fs from 'node:fs';import {bundle} from './server/abyss-save/build.mjs';console.log(fs.readFileSync('server/abyss-save/dist/worker.mjs','utf8')===bundle());"],cwd=R,stdout=subprocess.PIPE,check=True).stdout.strip()==b'true'
assert not (broken or asset_changes or markers) and bundle and version['pck_sha256']==sha(R/'docs/index.pck')
assert read(R/'verification/data-r21/source-audit.json')['failures']==0
assert 'cloud_archive_r22_test PASS' in (O/'archive-command.log').read_text(encoding='utf-8')
review=read(O/'visual-review.json');assert all(sha(R/v['path'])==v['sha256'] and v['viewed'] for v in review)
summary={'regression_groups':len(rows),'failed_groups':0,'parity':parity,'battles':sum(r['battles'] for r in parity),'records':sum(r['records'] for r in parity),'native_checks':native['checks'],'native_samples':native['samples'],'server':server,'server_checks':sum(r['checks'] for r in server),'server_failures':0,'web_configurations':len(web),'web_battles':sum(w['battles'] for w in web),'web_errors':0,'ui_build':version['ui_build'],'pck_bytes':(R/'docs/index.pck').stat().st_size,'pck_sha256':version['pck_sha256'],'protected_files':len(protected),'protected_changed':broken,'assets':len(assets),'assets_changed':asset_changes,'conflict_markers':markers,'worker_matches_source':bundle,'changed_files':changed,'new_files':new_files,'visual_review':review}
write('summary.json',summary)
text=f'''## 14차 — 전투 갈래 병합 · CTB 저장·서버 검증 · Web c

두 충돌 파일을 내용으로 합쳤다. 마을의 `장비 가공`과 A8 전투 영어를 모두 보존했고 같은 키의 서로 다른 영문 값은 0개였다. 합친 배송 사전은 UI 181키·문구 2,789키다. 파일의 충돌 표시는 **0**이다. git 명령은 실행하지 않았으며 병합 인덱스와 커밋은 Claude가 처리한다. 결과는 `verification/town-r21/round14/summary.json`이다.

|항목|결과|
|---|---:|
|import·전체 Native·로컬 서버·전투 audit 그룹 / 실패|{len(rows)} / 0|
|P2·A6·P3·A7·A8·A9 씨앗 전투|{summary['battles']:,} / 모두 일치|
|원본 대조 기록 / 불일치|{summary['records']:,} / 0|
|새 마을→실제 CTB→정산·저장 검사 / 실패|{native['checks']:,} / 0|
|새 Native 통합 저장 / 실제 D1 왕복|{native['samples']} / {native['samples']}|
|서버 npm test 합계 / 실패|{summary['server_checks']:,} / 0|
|Web ko/en 구성 / 실제 승리 / 오류|8 / {summary['web_battles']} / 0|
|보호 파일 / 원본 에셋 / 변경|{len(protected):,} / 96 / 0|

### 의미 통합과 변경

`persona_world`가 이미 적용하는 장비 능력치를 `expedition_world_r22.stats`에서 다시 곱하던 중복을 제거했다. 전투 입력은 기존 P4의 pre-equipment 능력치와 `native_eq` 경로를 유지한다. 페르소나 1회 편성, native 장비 1회 전달, 실제 전투 능력치와 정본 장비 계산, P8 적 HP의 1.25배 1회 적용과 진행 중 난이도 고정을 검사했다. 30명 각각 실제 통합 모델에서 정본 전설 장신구를 장착해 전투 행동과 Native 저장을 검사했다. 전체 전투 대조의 수치·허용 오차·기대값은 바꾸지 않았다.

출발·전투 입력에서 P4 계산기가 P6의 대장간 규칙 객체를 영구 교체하던 문제도 고쳤다. 해당 계산 동안만 P4 계산기를 사용하고 호출자의 객체를 복원한다. 전투→귀환→가공·제련·영수증·클라우드 통합 148항목과 객체 보존 검사를 통과했다.

P5와 P6의 장비 정산은 원본 code·seed·source_r21·UID를 함께 보존한다. 가방 2,000칸 초과 보상은 기존 P4 overflow에 보관하며 P6의 코드별 제련값도 유지한다. 초과분을 원본처럼 버리는 대신 보존하는 차이는 사용자 저장 삭제 금지 지시에 따른 것이다. 정산 영수증의 `gear_lost` 개수는 즉시 가방에 넣지 못한 수량이며 overflow에는 남는다.

실제 CTB 행동→승리→P5 보류 XP→퇴각 정산→P1 XP·호감 지급·P10 사실 기록을 검사했다. 같은 finish/settle을 다시 호출하면 전체 상태와 대사 큐가 불변이다. 기존 보스 돌파·다음 층·시설·가방·연대기·호감·30명 대사 검사는 전체 회귀에서 다시 통과했다. Native 클라우드는 실제 저장기로 연대기 큐를 flush한 뒤 계정 생성→업로드→다운로드→다음 행동의 전투 snapshot 동일성을 검사했다. schema 3과 옛 저장 11종 이관을 유지했다.

이전 공개판 P5의 장비 중복 보너스로 높아진 페르소나 HP/MP는 숫자 전용 `equipment_vitals_before_r14`에 원래 값을 보관한 뒤 올바른 상한으로 이관한다. 원문 입력 보존·전투 HP·원정 maxima·반복 불러오기·임의 객체 거부를 검사했다. P6에서 허용하는 소모품 10,001개도 P5 전투 저장을 통과하도록 옛 Native 10,000개 제한을 JSON 안전 정수 범위로 맞췄다. 음수·소수·범위 초과는 거절한다. 이는 새 재화 상한이 아니라 P6-R22.md의 기존 저장 계약을 연결한 것이다.

서버에는 CTB tick/round, 부호 있는 CTB remaining, P3 효과 메타데이터·DOT 줄/수명/소유자/순서·재생, 장비 임시 상태와 네 전역 상태, 페르소나 연구 초안, 장비 code를 **명시적 허용 목록과 타입·범위·참조 검증**으로 추가했다. 장비 전역 소유자는 JSON 키 순서 대신 실제 출전 순서를 따른다. 코드의 id/seed/source 표시는 서로 일치해야 한다. 페르소나의 엘프 MP와 이전 인간 편성 HP 보존 상한도 반영했다. 임의 객체용 칸을 추가하지 않았다. 기존 인증·PIN·CAS·속도 제한·Turnstile·보관·migration·운영 설정은 변경하지 않았다.

새 서버 시험은 {native['samples']}종의 Native 저장을 실제 Worker/D1으로 생성→읽기→PUT→오래된 rev 409→최신 읽기까지 왕복한다. 새 중첩 필드의 정상 대조군과 잘못된 타입·참조·범위·임의 객체도 검사한다. `npm test`에 이 검사를 포함했고 기존 보안 검사 전체를 유지했다. 지정한 `node server/abyss-save/test/godot-r13.mjs cloud_archive_r22_test`도 별도로 실행해 5항목 실패 0을 확인했다.

### Web와 직접 확인

지정 Godot Web export와 `update_version.py` 완료. **ui_build={version['ui_build']}**, PCK **{summary['pck_bytes']:,} bytes**, SHA-256 `{summary['pck_sha256']}`. 최종 패키지로 `python tools/web_smoke_r19.py --town-r21`의 8구성을 완주했다. 기존 7구성에 **430×932 영어 페르소나 기본 공격·전투 IndexedDB 재로드** 1구성을 추가했다. 이어 같은 PCK로 추가 구성만 `--persona-only` 재실행해 **적이 살아 있는 persona 차례의 비종결 전투**에서 저장→재로드→실제 공격→승리·정산을 확인했다. IndexedDB 원시 snapshot은 정확 비교하고 JS 표시 직렬화의 실수만 기존 1e-7 오차를 허용한다. 고유 기술의 포인터 입력은 Native A8 UI에서 검증했다. 원격 배포는 하지 않았다.

직접 연 이미지와 해시는 `visual-review.json`에 기록했다. 모든 자동 캡처를 개별 육안 검수한 것은 아니다. 영문 정본이 없는 전투·정산 문구는 한국어 fallback을 유지한다. 사용자 페르소나의 정본 초상·스프라이트 정의는 없어 기존 자리표시자를 유지했다. 물리 휴대폰·스크린리더·운영 HTTPS/Turnstile·실제 두 기기 검증은 수행하지 않았다. 성적·친밀 장면은 추가하지 않았다.

### 재현·파일

제품 변경은 `project/data/localization-r22.json`, `project/game/{{localization_r22,expedition_world_r22,facilities_world_r22,persona_world,dungeon_world_r21,battle_v3}}.gd`, 빌드 식별자의 `project/ui/world_screen.gd`, 서버 `src/validate.js`, `gen_known.mjs`, `src/known.json`, `dist/worker.mjs`, `package.json`이다. 검사·도구는 `project/tests/{{town_combat_r21_round14_test,expedition_r22_test,ui_expedition_r22_test}}.gd`, `server/abyss-save/test/{{godot-r14,combat-r14}}.mjs`, `tools/town_r21_round14_{{prepare,report}}.py`, `tools/{{town_r21_round9_web,update_version}}.py`다. 기존 파일 변경·새 코드 목록은 summary.json에 있다. 최종 docs와 검사 산출물을 재생성했다.

수정 전 통합 시험은 장비 중복·코드 누락·overflow 누락 **3실패**였으며 `integration-before.json/log`에 보존했다. 첫 로스터 fixture의 첫 만남 선택 범위 오류, Native HTTP 시험의 긴 동기 작업 직후 첫 프레임 timeout, 연대기 flush 전후 비교도 시험 쪽에서 바로잡았다. 보급품 시험은 실제 CTB 아군 차례를 기다리도록 고쳤으며 소비 기대 수치는 그대로다. UI 저장은 프로세스별로 격리해 이전 실행의 활성 전투 자동 복원과 fixture 교체가 겹치지 않게 했다. 초기 Web 고유 기술 탐색의 중단 내역은 `web-attempts.json`에 남겼고 최종 추가 구성은 요청된 자기 참전·기본 공격·비종결 전투 재로드로 검증했다. 초기 회귀 서버의 옛 허용 목록을 사용한 클라우드 그룹은 최종 서버로 재실행했다. 보고서 집계의 Native/서버 파일명 충돌을 분리하고 Native 결과를 다시 생성했다. Windows root certificate store 진단은 기능 실패와 구분해 원시 로그에 남겼다.

```powershell
node server/abyss-save/test/godot-r14.mjs
node server/abyss-save/test/godot-r13.mjs cloud_archive_r22_test
cd server/abyss-save
npm run generate
npm run build
npm test
cd ../..
python tools/godot_r17.py --headless --export-release Web ../docs/index.html
python tools/update_version.py
python tools/web_smoke_r19.py --town-r21
python tools/audit_data_r21.py
python -X utf8 tools/town_r21_round14_report.py
```

'''
p=R/'UI-R21-D.md';old=p.read_text(encoding='utf-8')
if '## 14차 —' in old:old='# UI-R21-D\n\n'+old[old.index('## 13차 —'):]
p.write_text(old.replace('# UI-R21-D\n\n','# UI-R21-D\n\n'+text,1),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['changed_files','new_files','visual_review']},ensure_ascii=True,indent=2))
