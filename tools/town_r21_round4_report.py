"""Persist the human 28-panel review and a measured, explicitly partial handoff."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';V=O/'round4';C=O/'compare-round4'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
# Directly reviewed review-1..7.jpg after final lossy imports and result poses.
# Same means the named item's principal appearance, not pixel identity or approval.
judgements=[
 ('town','다름','다름','다름','다름','로고를 크게 복원했으나 가려진 E의 벡터 보완·헤드 위치·명패/도시 비율이 다름.'),
 ('party','같음','다름','다름','다름','동료 헤더 유지. 도시가 다른 위치에 넓게 보이며 사선·몸통 확대·명패 각도 미달.'),
 ('member','다름','다름','다름','다름','동적 이름은 크게 표시하나 폭과 잉크 마모가 다름. 우측 성채 대신 호숫가 도시가 보임.'),
 ('skills','다름','다름','다름','다름','초상 과도한 확대를 줄였음. 시안의 성채/붓 띠 위치·기술 제목과 본문 비율은 다름.'),
 ('formation','같음','다름','다름','다름','큰 제목 SVG. 원본 4인 도트를 사용하나 투시 격자·선택 프레임·하단 상세 영역 크기 다름.'),
 ('equipment','같음','다름','다름','다름','큰 제목 SVG·장비점 창/선반 복원. 실제 보유 장비가 없고 아이템 그림·초상 크롭·분할 비율 다름.'),
 ('art','같음','다름','다름','다름','큰 제목 SVG. 외곽 얼굴 띠와 내부 기존 컷인을 재사용해 시안의 사선 얼굴/전신 구도와 다름.'),
 ('depart','다름','다름','다름','다름','실제 이름 학술원 폐허 상층·1층, 출전 Lv1을 사용. 계단/아치 복원, 원정 경로 축소 그림·초상 비율 미달.'),
 ('bag','같음','같음','다름','같음','제목/종이 배경 유지, 인물 없음. 원본 보급품 전체 목록·원본 아이콘을 사용해 시안의 네 품목/필터와 다름.'),
 ('target-selected','같음','같음','다름','다름','제목/종이 배경 유지. 실제 회복값·재고·Lv1이며 라디오·회복 예고 상자·얼굴 크롭 차이.'),
 ('guild','같음','다름','다름','다름','의뢰 큰 제목 SVG, 길드 홀 복원. 손을 내미는 포즈가 원본에 없어 원본 정면 초상. 의뢰판 비율 다름.'),
 ('recruit','같음','다름','다름','다름','동료 소개 큰 제목과 대각 빨강 띠 SVG. 금화/보유 수 영역 위치·초상 포즈·목록 비율 다름.'),
 ('research','같음','다름','다름','다름','기존 화면을 시안형으로 교체. 큰 제목·서재 복원, 기존 전술 드롭다운 유지로 카드 합성 삽화/결과 구도 미달.'),
 ('shop','같음','다름','다름','다름','마렌토 상회 검정/빨강 제목 SVG·병 선반 복원. 원본 상인 포즈와 세부 행/금화/상품 그림 차이.'),
 ('shopgear','같음','다름','다름','다름','시안의 힐데가르트 대신 실제 상인 피에트로. 작업대 무기 삽화·캐릭터 선택/진열 구도 미달.'),
 ('smithy','다름','다름','다름','다름','검정/빨강 제목을 추적했으나 우측 가림 조각이 남음. 원본 한나 포즈·망치·장비 그림·빈 상태 차이.'),
 ('inn','같음','다름','다름','다름','큰 여관 제목과 실내 복원. 원본 정면 초상·동료 영역·아이콘/띠·행동 패널 비율 차이.'),
 ('journal','같음','다름','다름','같음','큰 기록 제목·호수 도시 복원, 인물 없음. 실제 로그 1줄을 표시해 시안 4사건/삽화 타임라인과 다름.'),
 ('summary','같음','다름','다름','다름','큰 귀환 제목 SVG·도시 복원. 배경의 4인 뒷모습 없음, 실제 보상 0·성장값과 원본 초상 칸 사용.'),
 ('explore','같음','다름','다름','다름','큰 탐색 지도 제목·등각 유적 복원. 원본 단일 5탐색에 8표지(입구/5회/휴식/보스)를 연결, 갈림길 없음.'),
 ('cache','다름','다름','다름','다름','큰 제목 위치가 약 6px 다름. 상자/서재 복원, 옛 저장 카드 사용/지나가기 동작 보존. A 새 원정은 자동 적립.'),
 ('rest','같음','다름','다름','다름','큰 휴게실 제목·담쟁이/탁자/소파 복원. 원본 초상이 서 있는 구도이며 시안의 앉은 자세를 새로 그리지 않음.'),
 ('cards','다름','다름','다름','다름','키/야영 그림을 SVG로 추적. 제목 크기·얼굴 크롭·붓 띠·카드 하단 비율과 사용 가능 상태 차이.'),
 ('retreat','같음','다름','다름','같음','귀환 질문 제목 SVG·협곡/교량/폭포 복원. 시안의 4인 실루엣·미니맵·금화/책 삽화 없음. 초상 패널 없음.'),
 ('cards-empty','다름','다름','다름','다름','창·상자·장비 배경 복원. 시안은 장비 빈 상태 문구이나 실제 카드를 표시. 원본 정면 초상, 하단 정물 삽화 미달.'),
 ('cutin','다름','다름','다름','다름','금지된 전투 파일은 그대로. r18~20 기존 컷인과 시안은 제목·그림·레이어·초상 모두 다름.'),
 ('victory','같음','다름','다름','다름','크고 기울어진 검정/빨강 VICTORY SVG. 폐허 복원·원본 준비 도트 4명, 뒷모습/포즈·HP/MP 칸 구도 차이.'),
 ('defeat','같음','다름','다름','다름','큰 검정 DEFEAT SVG. 폐허·도트 회색화, 시안의 앉거나 고개 숙인 자세는 원본에 없어 미재현.'),
]
comparison=read(C/'comparison.json');assert len(comparison['screens'])==len(judgements)==28
lines=['# 4차 · 28패널 직접 비교','',
'최종 `review-1..7.jpg`를 직접 열어 28쌍을 확인했다. 아래는 기계 색 마스크가 아닌 육안 판정이다. 같음은 해당 요소의 주된 모양/문법이 같다는 뜻이며 픽셀 동일·2px 합격·사장님 승인이 아니다. 인물 자체가 없는 패널의 초상 같음은 양쪽 모두 없음을 뜻한다. 나머지 차이는 각 행에 적었다.','',
'|패널 / 게임|제목|배경|구성|초상|직접 본 차이|','|---|---|---|---|---|---|']
for screen,j in zip(comparison['screens'],judgements):
 assert screen['name']==j[0],(screen,j)
 screen['human_review']={'title':j[1],'background':j[2],'composition':j[3],'portrait':j[4],'notes':j[5]}
 lines.append('|'+screen['panel']+' / '+j[0]+'|'+'|'.join(j[1:])+'|')
comparison['judgement']='Direct human review, final review-1..7.jpg; not pixel identity or owner approval'
(C/'comparison.json').write_text(json.dumps(comparison,ensure_ascii=False,indent=2),encoding='utf-8');(C/'comparison.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
common=read(O/'common-results.json');audit=read(V/'audit.json');sizes=read(V/'export-sizes.json');web=read(O/'web/results.json');version=read(R/'docs/version.json')
assert len(common)==27 and all(x['exit_code']==0 and not x['errors'] for x in common)
assert len(web)==6 and len({(x['width'],x['height']) for x in web})==5
assert all(not x['errors'] and not x['text_errors'] and x['viewport_restored_after_victory'] for x in web)
assert version['ui_build']=='r21-d-town-20261101b'
assert sizes['sha256']==hashlib.sha256((R/'docs/index.pck').read_bytes()).hexdigest()==version['pck_sha256']
ui=sum(read(p)['checks'] for p in [O/'ui-results.json',O/'ui-round2-results.json',O/'round3/ui-results.json',O/'round3/result-ui-results.json',V/'ui-results.json'])
summary={'styled_panels':27,'preserved_battle_panels':1,'comparison_pairs_directly_opened':28,'fixed_title_svgs':18,'backgrounds':19,'background_webp_bytes':audit['background_bytes'],'background_pck_bytes':sizes['background_pck_bytes'],'native_groups':27,'failed_groups':0,'town_ui_checks':ui,'town_rules_checks':17389,'source_lua_matches':11064,'source_lua_samples':11064,'web_configs':6,'web_distinct_sizes':5,'web_errors':0,'original_asset_changes':len(audit['original_asset_changes']),'protected_file_changes':len(audit['protected_changes']),'pck':sizes,'images':comparison['outputs'],'visual_approval':False,'whole_comp_match':False}
(V/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
archive=V/'UI-R21-D-round3.md'
if not archive.exists():archive.write_bytes((R/'UI-R21-D.md').read_bytes())
report=['# UI-R21-D','', '## 4차 — 큰 제목·배경·노드 지도 적용, 시안 전패널 일치 미완료','',
'27개 마을/결과/외곽 패널에 시안형 외형을 연결하고, 금지된 전투 컷인 1패널은 유지했다. 기존 화면이던 연구와 봉인 보관함도 외형을 교체했다. 고정 제목 SVG 18종, image_gen 배경 편집 19종, 실제 원본 진행만 표시하는 노드 지도를 적용했다. **28쌍을 직접 비교했으며, 초상 포즈·크롭·패널 비율·배경 세부 형태가 여전히 다르다. 전패널 동일·시안 느낌 완성으로 보고하지 않는다.** 지시서의 “다 못 끝내면 끝낸 데까지 검사 통과 상태” 조항에 따른 부분 인계다.','',
'### 핵심 수치','', '|항목|4차 최종|','|---|---:|',
f'|외형 적용 / 기존 전투 유지|27 / 1 패널|',f'|직접 연 시안-게임 비교|28쌍|',f'|고정 제목 SVG / 배경 WebP|18 / 19|',f'|배경 파일 합계 / 실제 PCK 기여|{audit["background_bytes"]:,} / {sizes["background_pck_bytes"]:,} bytes|',f'|배경 제한|10,000,000 bytes 이하|',f'|공통·추가 검사 그룹 / 실패|27 / 0|',f'|마을 UI 검사 / 실패|{ui:,} / 0|','|마을 규칙 / Lua 대조|17,389 / 11,064 일치|','|Web 구성 / 다른 크기 / 오류|6 / 5 / 0|','|원본 SHA / 변경|96 / 0|','|금지된 전투·A·B·C 파일 변경|0|',f'|최종 PCK|{sizes["after_pck_bytes"]:,} bytes|',f'|owner-sheet|900×3531 / {comparison["outputs"]["owner_sheet"]["bytes"]:,} bytes|','',
'### 적용과 보존 경계','',
'고정 제목은 승인 패널의 검정/빨강 획을 OpenCV 윤곽으로 추적한 순수 SVG 경로다. 로고 THE의 E는 시안 인물에 가려져 있어 기하 벡터로 보완했으며 원본 보이는 픽셀과 동일하다고 세지 않았다. 가변 동료·던전·층 제목은 전투의 기존 AbyssDisplayR19를 크게 사용하고 폭을 맞췄다. 큰 검정 가변 활자 위에는 시안에서 추적한 작은 종이색 마모 SVG를 얹었다. 장식 붓 띠 7종·카드 그림·버튼도 SVG다. 생산용 래스터 제목/독립 잉크 파일은 추가하지 않았다.','',
'풍경은 해당 시안의 영역을 image_gen 내장 편집 도구에 넣고 인물·문자·UI를 지운 뒤 같은 건축을 메우도록 요청했다. 초기 편집본의 붉은 그래픽 띠/군중은 추가 편집으로 제거하고 그래픽 띠는 별도 SVG로 배치했다. 원본 인물·적 도트는 생성 도구에 다시 그리도록 요청하지 않았다. 배경의 원본 가려진 부분을 메우면서 비가림 부분의 세부 구조·종이 마모도 재해석된 곳이 있다. 따라서 “그 부분만 변경·풍경 픽셀 그대로”는 미달이다. 홈/동료 상세에는 공용 도시 배경을 사용해 시안의 성채 위치와 다르다. 원본 배경·편집본·프롬프트·SHA·크롭은 `round4/asset-provenance.json`, `imagegen-files.json`, `background-pack.json`, `accent-provenance.json`에 기록했다. 최종 배경은 `project/assets/ui-r21/bg-*.webp` 19장이다.','',
'연구는 기존 전술 선택/장착/해제/강화 핸들러와 저장 형식을 그대로 사용한다. 원본 페르소나 연구 전체 규칙으로 확장하지 않았다. 봉인 보관함은 옛 지도 저장의 봉인 해제/지나가기/이동을 새 외형에 연결했다. 새 A 원정에서 보관함 사건이나 카드 지급을 추가하지 않았다. 원본 초상 및 C 마스터/300칸, B 적 100종과 전투·A 데이터 파일은 바이트 변경 0이다. 결과의 4인·편성은 기존 CharacterSprite의 준비 도트를 재사용하고 패배 결과만 표시 셰이더로 회색화했다. 사용자 저장 경로·schema·진행 규칙을 바꾸지 않았다. UI 시험은 전용 fixture 경로만 사용한다. 성적 장면/79-sex.lua는 실행·이식하지 않았다.','',
'### 탐색 지도가 시안과 달라야 하는 이유','',
'읽기 전용으로 원본 `C:/Clauede Code/dungeon-bot/bot/src/77-explore.lua`, A의 `dungeon_world_r21.gd`·`dungeon_view_r21.gd`를 대조했다. 원본은 층마다 5회 순차 탐색→자동 휴식→층 보스이며, 시안의 서가/순찰로/보관함/회랑/야영지 갈림길을 선택하는 규칙은 없다. 새 `town_map_r21.gd`는 입구+실제 5탐색+휴식+보스의 8표지만 단일 선으로 연결한다. 완료 길과 현재 위치를 강조하고 미래 탐색은 일반 나침반으로 표시한다. 미래 전투/발견을 미리 결정하거나 새 선택 버튼을 만들지 않았다. 지도 구성은 상태·RNG를 바꾸지 않는지 0~5단계 모두 검사했다.','',
'### PCK 전후와 웹','',
f'작업 시작 docs PCK 실측은 {sizes["before_pck_bytes"]:,} bytes다. 3차 보고서의 61,934,348 bytes와 일치하지 않는 오래된 export였으므로 둘을 섞지 않았다. 최종 {sizes["after_pck_bytes"]:,} bytes, 시작 실물 대비 +{sizes["increase_bytes"]:,}, 3차 보고 수치 대비 +{sizes["increase_from_round3_report_bytes"]:,} bytes다. 초기 무손실 가져오기는 71,517,648 bytes였고, 새 배경 19장만 Godot Lossy/0.85로 가져와 용량을 줄였다.',
f'동일 최종 코드에서 배경 19장만 제외한 측정용 PCK는 {sizes["same_code_without_background_pck_bytes"]:,} bytes다. 최종과의 차이 {sizes["background_pck_bytes"]:,} bytes가 실제 배경 패킹 증가분이며 10MB 이하다. `budget-no-background`는 실행용이 아닌 용량 측정용 불완전 export다. 최종 실행본은 docs이다. 필터는 측정 후 원래 바이트로 복원했다. `round4/export-sizes.json`과 export 로그에 근거를 보존했다.',
f'최종 `ui_build={version["ui_build"]}`, PCK SHA-256 `{version["pck_sha256"]}`. `python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 후 `python tools/update_version.py`로 갱신했다. 원격 배포는 하지 않았다.',
'`tools/web_smoke_r19.py --town-r21`을 390×844, 360×780, 390×664, 1280×800, 430×932 및 360×780 reduced-motion에서 실행했다. 실제 포인터로 기본 마을·시설·연구·영입 경로·원본 장비 구매/품절/장착·연출·실제 전투·결과 확인·viewport 복귀를 검사했다. 6/6 통과, 콘솔/페이지/텍스트 오류 0. 결과는 `verification/town-r21/web/results.json`이다.','',
'### 직접 실행한 검사','', '|검사|최종 결과|','|---|---|']
for x in common:report.append('|'+x['name']+'|'+'; '.join(x['summary'][-2:]).replace('|','/')+f' · exit {x["exit_code"]} / errors {len(x["errors"])}|')
report+=['',
'r18 UI는 첫 실행에서 검사 4,592개 실패 0이었지만 종료 리소스 오류 1개/객체 경고 2개가 발생했다. 같은 검사 단독 재실행은 4,592개 실패 0·종료 오류 0으로 재현되지 않았다. 이를 숨기거나 오류 필터를 완화하지 않았고 `round4/r18-initial-exit-note.json`에 적었다. root certificate store 경고만 기존 격리 환경 경고로 계속 분리한다. 기존 검사 기대값은 변경하지 않았다. 공개 build 식별자 검사만 새 b 문자열로 갱신했다. Label을 SVG로 옮겨 기존 UI의 글자 검사 수가 줄었으며 시각 합격으로 해석하지 않는다.','',
'### 직접 연 비교와 남은 작업','',
'[28패널 제목·배경·구성·초상 같음/다름 표](verification/town-r21/compare-round4/comparison.md). `review-1..7.jpg`를 최종 가져오기 후 모두 직접 열었다. [전체 시트](verification/town-r21/owner-sheet.jpg)와 확대 비교 [1](verification/town-r21/owner-zoom-1.jpg) · [2](verification/town-r21/owner-zoom-2.jpg) · [3](verification/town-r21/owner-zoom-3.jpg)도 확인했다. 기계 수치로 같음을 대신하지 않았다.','',
'남은 외형은 동료 콜라주의 큰 얼굴/사선/명패, 상세·기술의 성채 배경, 편성의 투시 프레임과 하단 상세, 장비/대장간의 전용 장비 그림, 연구의 합성 카드 그림과 결과 띠, 기록의 사건별 삽화 타임라인, 정산/귀환의 4인 뒷모습, 휴게실의 앉은 포즈, 빈 상태의 하단 정물, 컷인과 결과의 정확한 인물 구도다. 배경 재해석과 제목 가림 흔적·소수 픽셀 잔흔, 버튼 질감 차이도 남는다. 원본에 없는 자세를 새로 그리거나 전투 파일을 수정해 해결하지 않았다. 정본 규칙에 따른 지도 단일 진행과 실제 이름/레벨/재고/보상 차이는 유지해야 한다. 3차의 원본 페르소나 연구/영입 RNG/카드 사건 전체/연대기 미이식도 그대로 남는다.','',
'디자인 검수는 design-taste-frontend의 직접 비교/수정 절차를 적용했으며 사용자가 정한 B 시안이 방향이므로 새 방향 추첨은 하지 않았다. Godot canvas 대상이라 DOM/CSS 검사기 대신 native 5크기와 실제 WASM 포인터 검사를 사용했다. 시각 자평은 10점 중 제목 7·배경 6·구성 5·초상 구도 4다. 이 점수는 사장님 승인이 아니다.','',
'### 변경 파일','']
report+=['- '+p for p in audit['changed'] if not p.endswith('.uid')]
report+=['- '+p for p in audit['added'] if not p.endswith('.uid') and not p.startswith('project/assets/ui-r21/')]
report+=['- project/assets/ui-r21/title-*.svg (18종), accent-*.svg (7종), card-*.svg, button-ink.svg, type-drybrush.svg','- project/assets/ui-r21/bg-*.webp 및 .import (19종, 새 배경만 Lossy/0.85)','- verification/town-r21/round4/**, compare-round4/**, owner-sheet.jpg, owner-zoom-1..3.jpg','- docs/** (최종 local Web export)','',
'모든 프로젝트 쓰기는 현재 worktree 안에서 했고 git 명령·다른 갈래 쓰기·원격 배포·타인에게 메시지 송신은 하지 않았다. 내장 image_gen의 기본 저장 위치 결과는 원래 위치에 남기고 최종 프로젝트 자산은 이 worktree에 저장했다.','', '## 이전 차수 기록','',archive.read_text(encoding='utf-8')]
(R/'UI-R21-D.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False,indent=2))
