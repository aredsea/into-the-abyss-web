"""Assemble the visual inventory with measured final results; no source edits."""
from pathlib import Path
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/look-r24'
def read(p,default=None):return json.loads(p.read_text(encoding='utf-8')) if p.exists() else default
reg=read(O/'regression/regression.json',[]);cloud=read(O/'cloud/results.json',[])
results={r['test']:r for r in [*reg,*cloud]}
names={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration','balance_probe']}
passed=[n for n in names if results.get(n,{}).get('passed')];failed=[n for n in names if n in results and not results[n]['passed']];missing=sorted(names-results.keys())
summary={'project_groups':len(names),'passed':len(passed),'failed':failed,'pending':missing,'results':[results[n] for n in sorted(names&results.keys())]}
(O/'all-tests.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
before=sorted((O/'before').glob('*.png'));after=sorted((O/'after').glob('*.png'))
native=read(O/'after-results.json',{});extras=read(O/'after-extras-results.json',{});shell=read(O/'after-shell-results.json',[]);bounds=read(O/'boundaries.json',{})
data={
'bag':('가방 · 보급품','08','예','기존 아이템 그림·행·탭 사용. 보호 화면 감사만.'),
'battle':('전투','09·10','예','기존 r17~r20 전투 유지.'),
'battle-defeat':('전투 패배 결과','11','예','먹 제목·종이 결과 칸 유지.'),
'battle-victory':('전투 승리 결과','11','예','먹 제목·주홍 행동 유지.'),
'cards':('탐색 카드 · 빈 상태','08','예','기존 인물·빈 상태·하단 탭 유지.'),
'cloud':('기존 모험 불러오기 · 클라우드 연결','없음','부분','작은 제목·일반 상자. 큰 제목·먹 성곽·굵은 행과 입력선으로 수정.'),
'cloud-confirm':('클라우드 확인','없음','부분','일반 검정 버튼. 공통 주홍 붓 행동·구분선 적용.'),
'cloud-conflict':('클라우드 충돌','없음','부분','일반 상자형 행동. 공통 문법 적용, 선택 동작 유지.'),
'cloud-credentials':('클라우드 첫 계정·PIN 표시','없음','부분','일반 굵은 글꼴. 공통 제목·행 문법 적용.'),
'codex':('캐릭터 도감','01','부분','종이·굵은 제목은 일치. 도감의 2열 탐색 양식은 시안 직접 대응 없음.'),
'create-blocked':('새 모험가 · 출신 선택 불가','없음','부분','선택 불가 문구·활성 조건 유지, 상자 대신 구분선.'),
'create-class':('새 모험가 · 3 직업','없음','부분','일반 회색 상자. 굵은 행·붓 선택으로 수정.'),
'create-confirm':('새 모험가 · 5 확인','없음','부분','본문 서체·빈약한 하단 경계. 제목 서체·먹 경계 적용.'),
'create-lineage':('새 모험가 · 계통·특성','없음','부분','일반 상자. 공통 주홍 선택·먹 행 적용.'),
'create-nation':('새 모험가 · 2 출신','없음','부분','일반 상자. 동일 문구의 먹 구분선 행으로 수정.'),
'create-points':('새 모험가 · 4 능력치','없음','부분','작은 상자형 증감 버튼. 공통 행·선택·제목 적용.'),
'create-race':('새 모험가 · 1 종족','없음','부분','제목은 기존 먹 벡터, 선택지는 일반 상자. 선택지·제목·하단 경계 수정.'),
'depart':('원정 준비','03','예','종이·먹 건축·주홍 출발·하단 탭. persona_* 보호 대상으로 감사만.'),
'dialogue':('여관 대화','06','부분','종이·인물·굵은 제목은 일치, 일반 선택 상자·하단 탭 생략. 시설 보호 화면 감사만.'),
'equipment':('동료 장비 보관함','02','예','기존 인물·먹 배경·하단 탭 유지. 보호 화면 감사만.'),
'expedition-log':('원정 탐색 기록','07','부분','종이·굵은 제목·주홍 행동은 일치, 지도/먹 표현 적음. 원정 보호 화면 감사만.'),
'explore':('탐색 지도','07','예','기존 지도·먹 구성·하단 탭 유지. 원정 보호 화면 감사만.'),
'explore-rest':('탐색 휴게실','07','예','기존 배경·굵은 제목·주홍 행동 유지. 원정 보호 화면 감사만.'),
'facility-scroll':('상회 스크롤 대상','05','부분','종이·행·기존 시설 구성. 시설 보호 화면 감사만.'),
'formation':('편성·원정 준비','02·03','예','기존 원정 편성 화면. persona_* 보호 대상으로 감사만.'),
'guild':('길드 의뢰','04','예','기존 접수원·먹 제목·의뢰 행 유지. 보호 화면 감사만.'),
'inn':('여관','06','예','기존 주인·동료·행동 칸 유지. 보호 화면 감사만.'),
'inventory':('장비 가방','02','부분','종이·굵은 제목·주홍 탭 사용. 장비 비교는 긴 스크롤 양식.'),
'journal':('모험 기록·연대기','없음','부분','종이·굵은 제목·주홍 탭 사용. 기록을 읽는 목록 양식 유지.'),
'loading-challenge':('로딩 셸 · 계정 인증','없음','아니오','옛 파랑·둥근 모달. 종이·먹·주홍 모달로 수정.'),
'loading-error':('로딩 실패·재시도','00 문법','아니오','파스텔 배경·세리프·둥근 칸. 종이·먹 성곽·주홍 재시도로 수정.'),
'loading-indeterminate':('로딩 · 총량 미정','00 문법','아니오','옛 파스텔 셸. 새 문법 적용, 총량 미정 동작 유지.'),
'loading-loading':('로딩 · 다운로드 진행률','00 문법','아니오','파스텔 마을·옛 글꼴. 기존 title-home/성곽/붓 벡터와 기존 서체 적용.'),
'loading-starting':('로딩 · 시작 준비','00 문법','아니오','옛 파스텔 셸. 새 문법 적용, 완료 후 시작 준비 동작 유지.'),
'meeting':('첫 만남 · 인물·장면','없음','부분','기존 인물 원본 유지. 굵은 제목·먹 행·주홍 선택으로 수정.'),
'meeting-empty':('첫 만남 · 미선택','없음','부분','일반 선택 상자. 먹 행·비활성 상태 유지.'),
'meeting-end':('첫 만남 · 긴 장면 아래','없음','부분','같은 텍스트·순서·스크롤을 유지하고 선택지 문법 수정.'),
'member':('동료 개요','01','예','기존 인물·큰 이름·탭 유지. 보호 화면 감사만.'),
'member-details':('동료 긴 특성·기술 상세','01','아니오','옛 얇은 둘레 패널·작은 헤더. 큰 제목·먹 성곽·굵은 구분선·주홍 활성 탭으로 수정.'),
'party':('동료 목록','01','예','기존 인물·먹 구성 유지. 승인 시안의 4명과 시험의 1명은 데이터 차이.'),
'people':('토르바 인물 목록','없음','부분','종이·굵은 제목·주홍 탭. 인물 목록 양식 유지.'),
'person-isolde':('토르바 인물 상세','없음','부분','종이 위 긴 원본 설명. 새로운 그림이나 요약 추가 없음.'),
'place-archive':('마을 장소 · 기록관','없음','부분','종이·굵은 제목·이동/인물 목록. 시안 직접 대응 없음.'),
'places':('마을 장소 · 시내','00·06 문법','부분','기존 먹 마을 그림·종이·탭 사용. 장소 전용 승인 시안 없음.'),
'rank':('대던전 순위 · 미등록','없음','부분','작은 제목·일반 버튼. 공통 큰 제목·먹 행·붓 행동 적용.'),
'rank-record':('대던전 순위 · 기록','없음','부분','공통 제목과 행동 문법 적용. 백분위와 날짜 문구 유지.'),
'recruit':('길드 동료 소개','04','예','기존 접수원·큰 제목·주홍 행동 유지. 보호 화면 감사만.'),
'research':('전술 연구','04','예','기존 인물·먹 제목·조합 행 유지. 보호 화면 감사만.'),
'research-editor':('전술 연구 편집','04','예','기존 인물·조각 편집·주홍 저장 유지. 보호 화면 감사만.'),
'settings':('설정','없음','부분','종이·굵은 제목·주홍 선택·각진 칸. 시안 직접 대응 없음.'),
'settings-reset':('설정 · 처음부터 확인','없음','부분','종이·큰 제목·기존 확인 문구. 실제 초기화는 수행하지 않음.'),
'shop':('상회 보급품','05','예','기존 상인·먹 제목·가격 행 유지. 보호 화면 감사만.'),
'shop-gear':('상회 직업 장비','05','예','기존 상인·장비 목록·주홍 행동 유지. 보호 화면 감사만.'),
'skills':('동료 기술','01','예','기존 인물·기술 칸·붓 행동 유지. 보호 화면 감사만.'),
'smithy':('대장간','05','예','기존 대장장이·먹 제목·장비 탭 유지. 보호 화면 감사만.'),
'status':('페르소나 상태','없음','부분','종이·굵은 제목·주홍 탭. 새 상태 패널 전용 시안 없음.'),
'summary':('원정 정산','06','예','먹 성곽·주홍 층/결과·본문·귀환 행동 유지. 원정 보호 화면 감사만.'),
'town':('마을 첫 화면','00','예','현행 승인 문법 정본. 보호 화면 감사만.'),
}
tags=sorted({p.stem.rsplit('-',1)[0] for p in before});assert set(tags)==set(data),(set(tags)-data.keys(),data.keys()-set(tags))
lines=['# LOOK-R24 · 전 화면 외형 감사 및 수정','',f'실행 검사 **{len(passed)}/{len(names)} 통과**, 실패 **{len(failed)}**, 미완료 **{len(missing)}**. 사용자 시각 승인 판정은 별도다.','',
f'수정 전 **{len(tags)}개 화면·상태 / {len(before)}장**(390×844·1280×800), 수정 후 **{len(after)}장**(360×780·390×664·390×844·430×932·1280×800·360×780 감소 모션).',
f'신규 생성/저장·글자/버튼 경계 검사 **{native.get("checks",0)}건**, 상세/클라우드 추가 검사 **{extras.get("checks",0)}건**, 셸 **{len(shell)}개 상태/크기**. 원본 이미지 **{bounds.get("original_assets",0)}개 해시 불변**, 금지 파일 변경 **{len(bounds.get("forbidden_changed",[]))}개**.','',
'## 바꾼 화면과 파일','',
'- `project/web_shell.html`: 큰 INTO THE ABYSS 먹 제목·종이·온전한 기존 마을 배경·힐데가르트 원본 초상·성곽/붓 벡터·마을 서체로 교체. 진행률·총량 미정·시작 준비·실패·재시도·팁·계정 인증 취소 동작/문구 유지. 셸용 이미지 사본 2개는 원본과 바이트 동일.',
'- `project/ui/create_screen.gd`: 종족·계통·출신·직업·첫 만남 선택에 왼쪽 굵은 이름·기존 설명·오른쪽 화살표·주홍 붓 선택·3px 먹 구분선 적용. 단계 제목 아래 짧은 주홍 선, 데스크톱 선택은 두 열. 부유하던 성곽 조각 제거. 인물·버튼 ID·콜백·진행 조건 유지.',
'- `project/ui/cloud_screen_r22.gd`: 연결·자격 표시·충돌·확인·순위를 마을 서체·굵은 행/입력 경계·왼쪽 정렬 행동으로 정리. 부유하던 성곽 조각 제거. 인증·업로드·다운로드·충돌 논리 유지.',
'- `project/ui/world_screen.gd`: 기존 동료 긴 상세와 확인용 폴백의 헤더·패널·버튼·내비게이션 외형만 정리. 원래 라우팅·행동·모델 호출 유지.',
'- `project/ui/town_theme_r21.gd`: 기존 PAPER/INK/RED/BOLD/DISPLAY·button-ink와 이미 쓰이던 읽기용 주홍색을 재사용하는 선택적 `dress_button`, `brush_style`, `heading_rule`, `rule`. 성곽 조각용 `city` 헬퍼는 제거했다. 기존 `make_theme()`와 승인 마을·전투 호출부는 변경하지 않음.',
'- 재현/검사: `project/tests/ui_look_r24_test.gd`, `capture_look_r24_extras.gd`, `tools/look_r24_*.py`, `tools/look_r24_cloud_launcher.mjs`.','',
'## 전체 감사표','',
'아래 준수 판정은 **수정 전**이다. 예=현행 승인 문법, 부분=종이·서체·선택색은 있으나 전용 시안/먹 구성 일부 없음, 아니오=옛 셸/패널. 시안 번호는 대응 보드이며 시안의 가상 수치·옛 인물을 데이터 정본으로 쓰지 않았다. 전용 시안이 없으면 없음으로 표시했다. 긴 문서는 본문 스크롤을 유지하며 화면 경계에서의 스크롤 가림은 글자 자체의 잘림과 구분했다.','',
'| 화면·상태 / 증거(각 링크의 1280×800 짝도 존재) | 대응 시안 | 문법 준수 | 다른 점·처리 |','|---|---|---|---|']
for tag in tags:
 title,ref,grade,note=data[tag];lines.append(f'| [{title}](verification/look-r24/before/{tag}-390x844.png) | {ref} | {grade} | {note} |')
lines+=['','## 검증과 직접 이미지 검토','',
'- 원본 파일의 SHA-256과 수정 경계: [boundaries.json](verification/look-r24/boundaries.json). 게임 규칙·데이터·저장 형식, 기존 자산, 서버, 보호 대상 화면 3개, `docs/` 변경 0. 기존 이미지의 셸용 사본 2개만 추가했고 원본과 해시가 같다. 새 그림 생성 0.',
'- 색 대비(종이 바탕): 본문 15.82:1, 보조 글자 5.12:1, 읽기용 주홍 4.87:1. 새 색 계열을 만들지 않고 기존 생성/패널 화면의 주홍을 공용 상수로 추출.',
'- 네이티브 마우스 이벤트로 종족→계통→출신 차단→직업→점수→확인→첫 만남→마을을 통과. 저장 재개 뒤 종족·계통·출신·직업·배분 점수 비교. 모든 테스트는 worktree 안의 격리된 저장 경로 사용.',
'- [수정 후 검사](verification/look-r24/after-results.json), [추가 검사](verification/look-r24/after-extras-results.json), [셀 브라우저 검사](verification/look-r24/after-shell-results.json). 변경 화면의 글자·버튼 측정 실패 0; 브라우저 오류·가로 넘침 0. 실제 캡처를 [review/](verification/look-r24/review/)의 연락 시트와 주요 화면 원본으로 열어 확인. 작은 높이에서는 본문을 스크롤하고 하단 행동을 고정해 겹치지 않게 유지.',
'- 새 Web export는 지시대로 수행하지 않았다. 기존 WASM을 새 코드 증거로 쓰지 않고, `web_smoke_r19.py --town-r21`의 포인터·화면 크기·텍스트 경계 검사에 해당하는 네이티브 UI 검사 전부와 **셸 원본을 실행한 Chromium** 검사를 수행했다. 새 WASM 통합 웹 검사는 Claude의 export 뒤 남는 단계다.',
'- 셸의 Engine만 시험용 다운로드 콜백으로 대체했고, 실제 DOM/CSS·진행률/오류/인증 취소 스크립트는 실행했다. 셸은 PCK 이전에 필요하므로 기존 서체의 WOFF2·기존 벡터·그대로 복사한 기존 이미지 2개를 안에 넣었다. 별도 docs 복사 단계 없이 동작한다. `python tools/look_r24_shell_assets.py --check`로 공용 자산 일치 검증.',
'- 전체 프로젝트 결과: [all-tests.json](verification/look-r24/all-tests.json). 클라우드 결과: [cloud/results.json](verification/look-r24/cloud/results.json). `serve.mjs`의 실제 Worker·D1을 독립 loopback 포트와 개발 레지스트리 공유 해제로 실행. 정상 종료 130은 기존 SIGINT 폐기 경로다. 고정 8787의 초기 환경 오류와 독립 서버 재실행 결과를 로그로 보존했다.',
'- Godot의 Windows 인증서 저장소 진단은 baseline과 동일한 환경 진단으로 분리. 실제 시험 실패 판정은 exit·SCRIPT ERROR·기타 ERROR를 사용.',
'- 기존 before 저장 점수 비교에서 JSON 수치형(int/float) 때문에 2건의 시험 단정 오류가 있었고, 점수별 정수 비교로 고친 after 시험으로 재검증했다. 게임 기대값·규칙·수치는 바꾸지 않았다.',
'- 2차 Impeccable detector 경고·권고 7개(폰트 1, 색 3, 크기 2, 크림 바탕 1). 과거 r11 DESIGN.md와 현행 r21 정본의 차이여서 승인 시안·마을 상수를 유지했다. [round2-detector.json](verification/look-r24/round2-detector.json). 1차 taste inspector의 CDP 시간 초과 기록은 보존했다. 이번 셸은 Chromium 캡처·DOM 경계 검사, 네이티브 캔버스는 Godot 글리프·포인터·버튼 경계 검사로 검증했다.','',
'## 남은 화면·후속 작업','',
'- 마을/시설/원정 화면과 persona_* 외형은 지시된 보호 범위라 감사만 했다. 원정 기록의 약한 먹 구성, 시설 스크롤 대상의 일반 행 구성은 위 표에 남겼다.',
'- 도감·상태·장비 가방·설정·연대기·장소/인물은 이미 종이·큰 제목·주홍 선택을 사용한다. 전용 승인 시안이 없는 정보/탐색 양식은 부분으로 기록하고 이번 차수에 전면 재설계하지 않았다.',
'- 금지된 성적/친밀도 장면은 이식·실행하지 않음. 원본 게임 문구·인물 데이터의 변경 없음.',
'- 사용자 기기의 기존 저장은 건드리지 않았다. `docs/`·Web export·commit 없음. 2차 작업에서 git 명령은 사용하지 않았다.',
'- Impeccable 컨텍스트의 r11 DESIGN.md/sidecar가 현행 r21과 어긋난 상태는 이번 범위 밖이라 갱신하지 않았다. 필요할 때 `document`로 정리할 수 있다.','',
'## 재현','',
'```powershell',
'python tools/look_r24_regression.py import',
'python tools/look_r24_suite.py --fresh',
'python tools/look_r24_cloud.py',
'python tools/godot_r17.py --position -10000,-10000 --script res://tests/capture_look_r24_extras.gd -- after',
'python tools/look_r24_shell.py after',
'python tools/look_r24_shell_assets.py --check',
'python tools/look_r24_boundaries.py',
'python tools/look_r24_report.py',
'```','']
if failed or missing:lines+=['현재 미완료/재실행 필요: '+', '.join(failed+missing),'']
intro=O/'round2-review.md'
if intro.exists():lines[2:2]=intro.read_text(encoding='utf-8').splitlines()+['']
(R/'LOOK-R24.md').write_text('\n'.join(lines),encoding='utf-8');print(json.dumps({k:v for k,v in summary.items() if k!='results'},ensure_ascii=True))
