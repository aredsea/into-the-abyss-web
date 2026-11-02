"""Prepend the completed tenth-round report without replacing older evidence."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21/round10'
def read(p):return json.loads(p.read_text(encoding='utf-8'))
s=read(O/'summary.json');a=s['audit'];rows=read(O/'regression.json');web=read(R/'verification/town-r21/web/results.json')
assert s['groups']==49 and not s['failed_groups'] and len(web)==7
review={'mode':'Operate / existing Godot paper-brush UI preserved','native_contact_sheets_opened':[f'contact-{dim}.jpg' for dim in ['360x780','390x844','390x664','430x932','1280x800']],
 'web_360_opened':['town-360x780-en.png','participate-360x780-en.png','create-360x780-en.png'],
 'settings_360_opened':['settings-en-360x780.png','reset-en-360x780.png'],
 'resolved':['Settings and Codex word clipping: widen controls before fitting type.','Town floor/zone height and smithy heading width corrected.','Bare-variable auto-template falsely split unknown Korean labels; fallback regression added.','P1 selected brush keeps P8 readable red by tinting existing texture.'],
 'remaining':['Partial English only: unsupported native copy, baked Korean artwork and public dialogue remain Korean.','Some narrow P7 controls wrap long English words; full typography redesign is outside this merge.','No physical mobile device or screen-reader QA; Chromium and Godot native viewport tests only.'],
 'scope':'No full-game English, platform-accessibility, or pixel-identical mockup acceptance claimed.'}
(O/'visual-review.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
table='\n'.join(f'|{r["name"]}|{r["exit_code"]}|{len(r["errors"])}|' for r in sorted(rows,key=lambda x:x['name']))
changes='\n'.join('- `'+p+'`' for p in a['changed_project_files'])
section=f'''## 10차 — P8 충돌 해결 · 설정 의미 통합 · 정본 영어 적용

8·9차의 준비 화면·초상 편성·원정 경로와 P7/P10 복귀 흐름을 유지하면서 P8 설정·사전·조사를 결합했다. **완전한 영어판은 아니다.** 정본 영어가 없는 native 문구와 그림 안의 한국어는 유지하며, 관측 목록을 갱신했다. 전투 파일의 번역·수정은 하지 않았다.

|항목|최종 결과|
|---|---:|
|충돌 표시|0|
|전체 실행 그룹 / 실패 그룹|{s['groups']} / 0|
|새 통합 검사 / 실패|{s['integration_checks']:,} / 0|
|초기화 통합 보관·수동 복원 표본|{s['legacy_archives']}|
|새 영어 native 검사 / 실패|{s['ui_checks']:,} / 0|
|native 상태·크기·캡처|30 / 5 / {s['native_captures']}|
|P8 규칙 검사 / 실패|205,194 / 0|
|P8 설정 등 UI 검사 / 실패·캡처|3,630 / 0 · 95|
|정본 Lua oracle 표본|22,460|
|Web 구성 / 언어 / 오류|{s['web_configurations']} / ko·en / 0|
|Web 실제 전투 승리|{s['web_battles']}|
|영어 360폭 native 글자 경계 실패 / Web 관측 넘침|0 / 0|
|보호 파일 / 변경|{a['protected_count']:,} / 0|
|원본 자산 / 변경|96 / 0|
|원본 읽기 파일 / 변경|{a['source_count']} / 0|
|배송 UI·문구 사전 키|{s['dictionary_ui']} / {s['dictionary_words']:,}|
|부분 한국어 관측 문자열 합집합|{s['fallback_observed']}|
|전투 정적 문구 후보 / 별도 구 이름 로그|{s['battle_literal_candidates']} / 1|

### 충돌과 흐름

`create_screen.gd`는 8차의 풍경·한국어 SVG 제목·붓 버튼을 유지한다. 영어 제목에는 정본 `New adventurer` / `First meeting`을 사용하며 우측 설정 버튼과 겹치지 않는다. 선택 붓 버튼은 기존 그림을 P8의 `#c62b15`로 틴트해 작은 흰 글자의 대비 보완도 유지했다. 만들기 단계와 첫 만남 선택은 설정을 다녀와도 그대로다.

`panel_screen_r22.gd` / `journal_screen_r22.gd`는 번역·제목 맞춤을 적용하되 `panels_return` / `journal_return`과 `remember_entry=false`를 유지한다. 마을·동료·가방에서 들어간 경로, 패널 간 이동, 연대기에서 복귀하는 경로가 9차와 같다. `persona_sortie_screen.gd`는 Create 폼으로 되돌리지 않고 Town 상속의 내부 준비 화면으로 남겼다. 전·후열, 초상 한 번씩 표시, 대기 필터, 자기 참전/지휘, 출발 제한, 수락 의뢰와 저장 재시도 위치를 유지한다.

### 설정·이름·저장

P8 난이도는 원본 0.8 / 1 / 1.25와 전투별 고정 배율을 그대로 사용한다. 같은 전투에서 누적 배율이 생기지 않고, 설정 변경은 다음 전투부터 적용되며 snapshot 재로드와 소환/단계 변경 경계까지 기존 P8 규칙 검사를 통과했다. 전투 엔진·적 어댑터를 수정하지 않았다. 공용 `josa_r22`와 `L.u`의 조사·영어 빈 조사도 원본 Lua 전체 음절 대조를 다시 실행했다.

현재 model·P7 cast·대사 이름표는 **힐데가 / 베렌가 / 바르굿**, 영어는 **Hildegard / Berenga / Bargut**이다. P8의 `world.json` 이름 변경은 이미 병합 입력에 있었고 이번에는 그 데이터 파일을 고치지 않았다. 과거 native 이름이 들어 있는 라벨과 연대기 이름 변환에는 표시 단계의 정규화를 추가했다. 저장 원문이나 대사 JSON을 다시 쓰지 않는다.

초기화 보관 구현은 수정할 필요가 없었다. 실제 옛 저장 11개에 8차 성장 충돌 이관과 9차 `favs/panels_r22/chronicle_r22`, 설정을 함께 넣어 복원·v3 저장·두 번째 저장·초기화를 실행했다. 보관 JSON 전체가 연대기 queue를 flush한 당시 메모리와 같고, `persona_migration_r21` 원문·선택 성장값·패널 상태·즐겨찾기·연대기가 모두 있으며, `.disk`와 `.disk.bak`는 초기화 직전 두 세대 바이트와 같다. 보관 JSON을 수동으로 restore해 전체 동등성도 확인했다. 원래 메모리 모델은 변하지 않았다. P8 검사에는 보관 실패 시 초기화 차단도 포함한다. 실제 사용자 프로필은 열지 않았다.

### 영어 적용과 한계

원본 `design/i18n`과 현재 `05-gen.lua`의 `B.en_dict()` / `B.ui_pack("en")`을 Lua 하네스로 읽었다. oracle 도구의 도달 가능 native 대상에 마을을 추가하고 줄바꿈·가운뎃점 조합 필드를 추출한다. 이전 P8 대비 UI 30키·문구 5키가 더해졌으며, 정본 문구를 새로 쓰거나 저장 키를 영어로 바꾸지 않았다. 마을 공용 label/action, 동료 이름·직업·시설·상거래, 준비 화면 층 선택과 탐색·휴식·정산에 도달하는 사전 호출을 연결했다.

검수 중 `{{action}}{{cost}}`처럼 변수만 있는 원본 틀이 미등록 한국어를 임의로 분해하는 문제를 발견했다. 직접 `L.u` 호출 계약은 유지하면서 자동 문자열 인식에서는 이런 틀을 제외했다. `개요/원정/기술/마을/추가` 미등록 라벨 보존을 새 회귀 검사로 고정했다. 정본에 없는 단어를 그럴듯한 영어로 만드는 방식은 쓰지 않았다.

관측 목록은 [untranslated.json](verification/settings-r22/untranslated.json) / [untranslated.md](verification/settings-r22/untranslated.md)이다. 195종은 신규 30상태와 P8 19상태에서 한국어를 포함한 문자열의 합집합이다. 기존 72종보다 검토 범위가 넓어졌으므로 번역률의 분모로 쓰지 않는다. 합성 필드 일부만 영어인 문구도 포함한다. `뒤로`, `원정 준비`, `마을 장소`, native 저장 안내, 생성 질문과 기존 2차 대사 등 정본 대응 없는 부분, SVG 안의 한국어는 그대로다. `{{{{user}}}} → 당신`도 호스트 이름이 없는 기존 대체다.

전투 정적 후보 97행은 목록만 만들었다. 읽기 전용 `project/game/battle_state.gd:261`의 **“첫 번째 펭귄 · 힐데가르트가 대신 받음”**도 별도 후속 항목이다. 따라서 모든 과거 전투 고정 로그의 이름까지 정리됐다고 주장하지 않는다. 일반 전투 이름표는 P8의 정본 model 이름을 사용한다. 성적 장면·클라우드 서버·A 데이터/규칙·대사 데이터·적·초상은 수정하지 않았다.

### 직접 검수와 Web

영어 native 30상태 × 5크기는 360×780 / 390×844 / 390×664 / 430×932 / 1280×800이다. 마을·동료·기술·장비·시설·P7/P10·만들기·첫 만남 외에 빈/보유 카드, 장비 상점, 탐색, 휴식, 퇴각 확인, 귀환 정산을 포함한다. 기존 metrics의 큰 가용 폭 값에 의존하지 않고 실제 Label/Button의 글꼴 치수·내용 여백·줄바꿈·높이를 별도로 검사했다. 설정·도감 단어가 잘리던 버튼, 마을 층/구역 높이, 대장간 제목 폭을 보완했다. 게임 수치와 기존 검사 기대값은 바꾸지 않았다.

최종 [5크기 연락판](verification/town-r21/round10/contact-360x780.jpg)을 모두 직접 열었고, 실제 WASM의 영어 360폭 마을·준비·만들기, native 설정·초기화 화면을 원본 크기로 열었다. 준비 화면의 시안 구조와 그림은 유지되며 페르소나 초상 없음, 부분 한국어, 좁은 P7 영어 단어 줄바꿈은 남는다. 물리 휴대폰·스크린리더 검증이나 전 화면 번역 완료를 주장하지 않는다. 검수 기록은 `round10/visual-review.json`이다.

지정 Web export와 `tools/update_version.py` 완료. **ui_build={a['ui_build']}**, PCK **{a['pck_bytes']:,} bytes**, SHA-256 `{a['pck_sha256']}`. 한국어 6구성(5크기와 360 reduced-motion) + 영어 360×780 1구성을 실제 포인터로 실행했다. 만들기 → 첫 만남 → 대화 확정/재로드 → 영입 → 연구/장비 → P7/P10 왕복 → 출전 → 전투 승리 → 레벨업 → 퇴각 정산/재로드를 검증했다. 영어 구성의 마을 13캡처 지점에서 추가 metrics 검사를 통과했다. 모든 구성의 PCK 해시가 최종 export와 일치한다.

별도 IndexedDB fixture에서도 v1·백업 바이트 보존, 불러오기만 할 때 v3 쓰기 없음, 실제 행동 뒤 v3 우선 재로드, Lv17/XP2 선택·Lv25 원문 보관, 9차 확장 보존과 옛 저장 지휘 모드를 확인했다. 원격 배포는 하지 않았다.

### 검사와 파일

전체 실행은 import + 실제 검사/통합/라이선스 47종 + 읽기 전용 balance probe 1종, 합계 49그룹이다. `enemy_action_fixture_r21.gd`는 검사에 사용되는 상속 fixture이며 단독 MainLoop가 아니다. `build_ink_r20b.gd`는 전투 자산을 다시 만드는 생성기라 읽기 전용 전투 범위에 따라 실행하지 않았다. Windows root certificate store 환경 진단은 별도이며 SCRIPT ERROR·검사 실패는 0이다. 테스트 수치·원본 규칙 기대값 변경은 0이다.

|실행|exit|검사 오류|
|---|---:|---:|
{table}

변경한 기존 프로젝트 파일:

{changes}

추가 검사: `project/tests/{{town_r21_round10_test,ui_town_r21_round10_test}}.gd`와 UID. 도구 변경: `tools/{{settings_r22_oracle.mjs,town_r21_round9_web.py,update_version.py}}`. 새 도구: `tools/town_r21_round10_{{verify,finish,report}}.py`. 부속 결과는 `verification/town-r21/round10/**`, 새 Web 결과는 `verification/town-r21/web/**`, 갱신된 P8 oracle·규칙/UI 로그·미대응 목록은 `verification/settings-r22/**`, export는 `docs/**`다.

재현: `node tools/settings_r22_oracle.mjs`, `python tools/town_r21_round10_verify.py`, 지정 export → `python tools/update_version.py` → `python tools/web_smoke_r19.py --town-r21`, `python tools/town_r21_round10_finish.py`, `python tools/town_r21_round10_report.py`. 보고서의 이전 차수 절은 보존했다. git 명령·다른 worktree 쓰기·클라우드 쓰기는 0이다.

'''
p=R/'UI-R21-D.md';old=p.read_text(encoding='utf-8');tail=old[old.index('## 9차'):];p.write_text('# UI-R21-D\n\n'+section+tail,encoding='utf-8')
print('Report:',p,'; 10차 added; previous rounds retained')
