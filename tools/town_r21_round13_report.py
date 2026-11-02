"""Require fresh passing evidence before inserting the round-13 handoff."""
from pathlib import Path
import json,shutil,subprocess
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round13'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
subprocess.run(['python','-X','utf8','tools/town_r21_round13_audit.py'],cwd=R,check=True,stdout=subprocess.PIPE)
audit=read(O/'audit.json');rows=read(O/'regression.json')
for name in ['dialogue_roster_r21_test','ui_dialogue_roster_r21_test','ui_dialogue_journey_roster_r21_test']:
    execution=read(O/(name+'-execution.json'))
    rows=[r for r in rows if r['name']!=name]+[execution]
rows.sort(key=lambda r:r['name']);write(O/'regression.json',rows)
assert len(rows)==61 and all(r['exit_code']==0 and not r['errors'] for r in rows)
dialog=read(O/'dialogue-results.json');ui=read(O/'ui-dialogue-results.json');journey=read(O/'ui-journey-results.json')
assert not (dialog['failures'] or ui['failures'] or journey['failures'] or ui['overflow'] or journey['overflow'])
web=read(R/'verification/town-r21/web/results.json')
assert len(web)==7 and all(w['ui_build']==audit['ui_build'] and w['pck_sha256']==audit['pck_sha256'] and not w['errors'] and not w['text_errors'] for w in web)
write(O/'web-results.json',web)
server=[]
for name,path in [('integration','verification/cloud-r22/server-results.json'),('security-r1','verification/cloud-r22/p9b/security-results.json'),('siteverify','verification/cloud-r22/p9b/siteverify-results.json'),('security-r2','verification/cloud-r22/p9c/security-results.json'),('security-r3','verification/cloud-r22/round12/security-results.json'),('deployment','verification/cloud-r22/round12/deployment-results.json')]:
    d=read(R/path);shutil.copyfile(R/path,O/(name+'-results.json'))
    failures=d.get('failures',sum(not g['passed'] for g in d.get('groups',[])))
    assert not failures
    server.append({'name':name,'checks':d['checks'],'failures':0})
env_count=sum((O/(r['name']+'.log')).read_text(encoding='utf-8',errors='replace').count('Failed to read the root certificate store') for r in rows)
summary={'regression_groups':len(rows),'regression_failed_groups':0,'dialogue_checks':dialog['checks'],'ui_checks':ui['checks']+journey['checks'],'render_states':sum(ui['states'].values())+sum(journey['states'].values()),'labels_measured':ui['labels_measured']+journey['labels_measured'],'overflow':0,'server_checks':sum(s['checks'] for s in server),'server_failures':0,'server':server,'save_samples':dialog['samples'],'web_configurations':len(web),'web_battles':sum(w['battles'] for w in web),'environment_certificate_warnings':env_count,'audit':audit}
write(O/'summary.json',summary)
text=f'''## 13차 — 동료 30명 대사 전수 연결 검증 · Web b

30명 전원의 기존 동적 재생기를 실제 여관·원정 화면과 통합 저장 모델로 검증했다. 대사 JSON은 읽기만 했으며 전투·A 데이터·적·초상·서버 보안 로직은 바꾸지 않았다. 최종 결과는 `verification/town-r21/round13/summary.json`이다.

|항목|결과|
|---|---:|
|동료 / 여관 / 선택지|30 / 840 / 2,520|
|던전 14상황·3구간·2변형 / 단계 변화|2,520 / 420|
|새 통합 대사 검사 / 실패|{dialog['checks']:,} / 0|
|360·430폭 × ko/en 여관 상태|{sum(ui['states'].values()):,}|
|같은 구성의 던전·단계 변화 상태|{sum(journey['states'].values()):,}|
|Native 전체 상태 / 실제 글자 치수 검사|{summary['render_states']:,} / {summary['labels_measured']:,}|
|Native UI 검사 / 실패 / 넘침|{summary['ui_checks']:,} / 0 / 0|
|서버 D1 integration / 전체 npm test|6,739 / {summary['server_checks']:,} · 실패 0|
|새 실제 native 저장 / D1 왕복|120 / 120|
|import 포함 전체 Godot 그룹 / 실패|{len(rows)} / 0|
|Web ko/en 구성 / 실제 전투 승리 / 오류|7 / {summary['web_battles']} / 0|
|보호 파일 / 원본 에셋 / 변경|{audit['protected_count']:,} / 96 / 0|
|직접 연 4명 360폭 합본|{audit['owner_jpg_bytes']:,} bytes · 300KB 이하|

### 표시와 실행

대사 본문·상황·선택지·반응·단계 변화는 UI 번역기에 넣지 않고 JSON 원문을 그대로 표시한다. 영어 설정에서도 대사는 한국어다. 이름표는 기존 정본 영어 사전을 사용한다. 진행·취소·여관 복귀 버튼은 원본 `05-gen.lua`의 `계속한다 → Continue`, `취소 → Cancel`, `아랫마을 여관 → Lower Town Inn`을 재사용한다. 새 영문 대사를 만들지 않았다.

긴 도입은 본문 높이를 100→132로 늘리고 선택지 시작을 561→573으로 조정했다. 본문 18px·선택지 15px를 유지했다. 취소 버튼 높이는 46→48로 늘려 360폭에서도 실제 높이 44px 이상이다. 응답·선택·취소·복귀 버튼의 뷰포트 이탈·겹침, 글자 폭·높이와 본문 간격을 실제 Native 렌더에서 측정했다. 대사 840개의 최초 도입·seen 도입·모든 선택 반응, 420개 변화 장면을 양쪽 폭·언어에서 전수 검사했다. 별도 원정 화면에서도 2,520개 짧은 말과 420개 변화 장면을 같은 구성으로 모두 그렸다.

30명 각각 실제 여관 버튼→선택→반응→복귀·하루 제한을 합성 포인터로 조작했다. 실행 검사는 840장면의 2,520선택, 14상황의 모든 구간·변형, 인접 7경계 상승·하락 420장면을 포함한다. 호감 수식·게임 RNG·금화·하루 제한·중복 지급 방지와 연대기 사실 한 번 기록을 확인했다. `speech.address_terms`는 표시용 발화로 오인하지 않으며 30명 모두 중첩 형식 그대로 읽힌다.

`stats.json`의 30명 이름을 대사 데이터와 직접 대조해 불일치 0이다. 기존 표시 보정 `힐데가르트→힐데가`, `베렝가→베렌가`, `바르구트→바르굿`을 유지하며 원본 저장·로그 문자열을 다시 쓰지 않는다.

### 저장·서버

각 동료의 선택 전·응답·원정 단계 변화·짧은 말, 합계 120종을 실제 통합 모델에서 생성했다. Native restore·입력 불변·진행 상태 왕복 뒤 실제 Worker/D1의 계정 생성→읽기→PUT→구 rev 409→최신 읽기를 모두 통과했다. 표본에는 동료별 seen 28장면도 들어 있다. 기존 옛 저장 이관·클라우드 HTTP·보관·보안 검사는 전체 회귀에서 함께 돌렸다.

기존 서버 카탈로그가 시범 3명(84장면·42변화)에 머물러 있었으므로 `npm run generate`로 **840장면·420변화**를 반영했다. 원문에서 생성한 소유자·선택 ID·변화 경계를 정확히 대조했고 Worker 번들도 재생성했다. `validate.js`, `index.js`, rate limit·Turnstile·보관·인증·migration은 수정하지 않았다. 서버 허용 규칙을 느슨하게 하지 않았다. 최종 PCK에도 30개 JSON 경로와 각각의 원문 바이트가 모두 있음을 `pack-dialogue-inventory.json`으로 확인했다.

### 직접 확인·빌드·검사 기록

최종 [owner-zoom-13.jpg](verification/town-r21/owner-zoom-13.jpg)를 직접 열어 힐데가·베렌가·바르굿·우르다의 서로 다른 화계와 이름표·선택지·취소 버튼을 확인했다. 베렌가 영어 원정 변화 화면과 최종 Web의 한국어·영어 선택/반응도 직접 열었다. 모든 자동 검사 상태를 사람이 개별 열람했다고 주장하지 않는다. 기존 픽셀 시안 차이·물리 휴대폰·스크린리더는 이번 작업의 새 검증 범위가 아니다.

지정 Godot Web export와 `update_version.py`를 완료했다. **ui_build={audit['ui_build']}**, PCK **{audit['pck_bytes']:,} bytes**, SHA-256 `{audit['pck_sha256']}`. 최종 패키지로 `python tools/web_smoke_r19.py --town-r21`을 실행해 영어 360폭과 한국어 6구성, IndexedDB 이관·재로드·대화·시설·연대기·실제 전투·복귀를 확인했다. 원격 배포는 하지 않았다.

첫 시도와 수정 과정도 보존했다. 전수 검사에서 발견한 마르셀린·테이리스 도입 넘침은 UI 공간을 늘려 해결했다. 초기 경계 fixture의 음수 경계·150 이상 감속값과 JSON 숫자 직렬화 비교 오류, 테스트 전용 저장 디렉터리 누락을 바로잡았다. 첫 로그는 `first-attempt-*`, 8건 넘침의 완주 결과는 `overflow-attempt-*`에 있다. 영어 `Continue`가 로컬 사전에 없는 문제는 정본 영어를 직접 재사용해 고쳤으며 실패 결과는 `english-continue-attempt-*`에 보존했다. 영어 버튼 보완 전·최종 export 전 중단한 Web 실행도 별도 로그로 남겼고 최종 7구성 결과만 합산했다.

기존 대화 시험을 3→30명으로 확대했다. 실제 바르굿 콘텐츠가 생겨 사라진 '파일 없음' 시험은 캐시를 잠시 빈 값으로 주입해 기존 fallback 동작을 계속 검사한다. 게임 수치 기대값은 바꾸지 않았다. 빌드 식별자 기대값은 지시된 b로 갱신했다. 공통 회귀의 인증서 저장소 환경 경고 {env_count}회는 기능 실패와 분리해 원시 로그에 보존했다.

Impeccable detector 결과는 `[]`이다. Godot canvas 본문은 DOM 검사로 측정되지 않으므로 Native 글꼴 치수·렌더·Web 캡처로 검수했다. 기존 DESIGN.md와 sidecar의 drift는 범위를 넓혀 수정하지 않았으며 별도 `document` 작업으로 동기화할 수 있다. 성적·친밀 장면은 추가하지 않았다.

### 변경 파일과 재현

- UI: `project/ui/{{town_screen_r21,world_screen}}.gd`.
- 검사: `project/tests/{{dialogue_player_r21_test,dialogue_roster_r21_test,ui_dialogue_roster_r21_test,ui_dialogue_journey_roster_r21_test}}.gd`.
- 서버: `server/abyss-save/src/known.json`, `dist/worker.mjs`, `test/{{integration,godot-r13}}.mjs`.
- 도구: `tools/{{update_version,town_r21_round9_web,town_r21_round13_run,town_r21_round13_audit,town_r21_round13_report}}.py`.
- 산출: `docs/**`, `verification/town-r21/round13/**`, `owner-zoom-13.jpg`, 기존 검사 재생성 결과와 이 문서.

```powershell
python -X utf8 tools/town_r21_round13_run.py dialogue_roster_r21_test ui_dialogue_roster_r21_test ui_dialogue_journey_roster_r21_test
cd server/abyss-save
npm run generate
npm run build
npm test
cd ../..
node server/abyss-save/test/godot-r13.mjs
python tools/godot_r17.py --headless --export-release Web ../docs/index.html
python tools/update_version.py
python tools/web_smoke_r19.py --town-r21
python -X utf8 tools/town_r21_round13_report.py
```

'''
path=R/'UI-R21-D.md';old=path.read_text(encoding='utf-8')
start=old.find('## 13차')
if start>=0:
    end=old.find('## 12차',start);old=old[:start]+old[end:]
path.write_text(old.replace('# UI-R21-D\n\n','# UI-R21-D\n\n'+text,1),encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k!='audit'},ensure_ascii=False,indent=2))
