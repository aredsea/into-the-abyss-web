# LOOK-R24 · 전 화면 외형 감사 및 수정

## 3차 · 하단 행과 로딩 그림 경계 수정

**관련 검사 6그룹 통과, 14,365건·실패 0. 셸 30상태/크기·실패 0.** 이번에는 지시대로 관련 그룹과 셸만 재검사했다. 아래 2차의 전체 검사 수치는 이전 실행 기록이다. [3차 결과](verification/look-r24/round3/results.json), [스크롤 끝 검사](verification/look-r24/round3/bottom-results.json), [시안 00·2차·3차 비교](verification/look-r24/round3/review/approved-comparison.jpg).

- **능력치:** 같은 단계의 선택·점수 증감 후 스크롤 위치와 누른 행을 유지한다. 스크롤 끝과 하단 먹 선 사이 간격을 4→16px로 늘렸다. [390×664](verification/look-r24/after/create-points-action-390x664.png) · [390×844](verification/look-r24/after/create-points-390x844.png) · [모든 크기](verification/look-r24/round3/review/create-points-action.jpg)를 직접 열어 속도·직업 추천대로·점수 비우기와 마지막 체력/마력 줄이 온전히 보임을 확인했다. 새 모험가 5단계·직접 배분·첫 만남·클라우드 연결/자격 표시/충돌/계정 전환/확인·순위도 끝까지 내려 마지막 행의 접근과 전체 경계를 검사했다. 긴 본문은 스크롤하며, 위쪽 경계에서 지나간 글자가 가려지는 동작은 유지한다.
- **로딩:** 기존 `gesture-base`의 검정 붓 벡터를 마스크와 먹 가장자리로 재사용했다. 그림의 네모난 아래 변을 붓의 찢어진 경계로 바꾸고, 진행 띠를 포스터 아래 **8px**에 붙였다. [390×844](verification/look-r24/after/loading-loading-390x844.png) · [1280×800](verification/look-r24/after/loading-loading-1280x800.png) · [전체 크기](verification/look-r24/round3/review/loading-loading.jpg)를 직접 열었다. 시안 00의 제목·대표 초상·성곽 배치는 유지하며, 아래쪽은 로딩 정보에 이어지는 먹 붓 경계로 처리한 차이가 있다. 초상 원본·크롭 좌표·진행/팁/오류 문구는 그대로다.
- **확인 범위:** 360×780·390×664·390×844·430×932·1280×800 및 360×780 감소 모션. look-r24 캡처 **192회 / 고유 파일 186장**을 다시 저장했고, [3차 연락 시트 9개](verification/look-r24/round3/review/)와 주요 원본을 직접 열어 검토했다. 원본 이미지 **96개 해시 불변**, 금지 경로 변경 **0개**, 게임 규칙·데이터·저장 형식 변경 **0개**. `docs/`·Web export·커밋 **0개**. 새 WASM 통합 검사는 Claude의 export 뒤 남는다. 검증 환경은 Windows Godot 네이티브 UI와 Chromium 원본 셸이며 실제 휴대폰 검사는 하지 않았다.

수정 파일: `project/ui/create_screen.gd`, `project/web_shell.html`, `tools/look_r24_shell_assets.py`, `tools/look_r24_shell.py`, 신규 `project/tests/ui_look_r24_bottom_test.gd` 및 검증 산출물. 기존 검사 3,516건에 마지막 행/전체 행동의 스크롤 접근 검사 4,116건을 추가했다. 생성 UI 2,033건·생성 규칙 4,005건·클라우드 UI 695건과 import도 통과했다. 추가 검사 초안의 오류 2건은 긴 선택 목록 전체를 한 행으로 판정한 시험 오류였으며, 실제 마지막 선택지를 검사하도록 고친 최종 결과는 0건이다. 기존 게임 기대값은 바꾸지 않았다.

Impeccable 경고/권고 7개는 이전과 같은 r11 DESIGN.md와 현행 r21 서체·색·크기 차이다. 승인 시안과 마을 정본을 유지했고, DESIGN.md/sidecar 동기화는 범위 밖으로 남겼다(`document`로 갱신 가능). 시작 시 지시서 읽기와 함께 `git status --short`를 1회 시도했으나 ownership 오류로 실패했으며, 이후 git 명령은 사용하지 않았다.

## 2차 · 지적된 시각 결함 수정과 직접 비교

1차의 **검사 106/106 통과는 시각 승인 근거가 아니었다.** 거절된 그림은 [round1-after/](verification/look-r24/round1-after/)에 보존했다. [시안 00 · 거절된 1차 · 최종 2차 나란히 비교](verification/look-r24/review/round2-approved-comparison.png)를 직접 열었다. 아래는 승인 시안 00과 01~03, 최종 after 원본 및 전체 132장을 담은 연락 시트 11개를 직접 열어 비교한 결과다. 사용자 시각 승인은 별도다.

| 화면 | 시안과 같아진 점 | 시안과 다른 점·판정 |
|---|---|---|
| [로딩 390×844](verification/look-r24/after/loading-loading-390x844.png) · [1280×800](verification/look-r24/after/loading-loading-1280x800.png) | 00처럼 큰 INTO THE ABYSS, 힐데가르트 원본 초상, 배경 성곽·호수, 주홍 먹을 한 장면에 겹쳤다. 제목의 파인 곳은 머리로 덮여 ARVSS처럼 보이던 빈 반원이 사라졌다. 성곽·호수는 온전한 `bg-town.webp`로 이어진다. | 초상은 마을의 `hildegard-town-main.tres`와 같은 master·source region `(25,0,525,659)`·위 중앙 cover 규칙이다. 제목 구멍을 확실히 덮도록 배치 높이는 마을보다 20px 올렸다. 00의 자원/시설/파티 대신 진행률·팁·재시도를 아래 종이 띠에 둔다. 데스크톱은 마을처럼 중앙 포스터다. 지적된 제목·성곽 결함 수정 확인. |
| [새 모험가 · 종족](verification/look-r24/after/create-race-390x844.png), [계통](verification/look-r24/after/create-lineage-430x932.png), [출신](verification/look-r24/after/create-nation-1280x800.png), [직업](verification/look-r24/after/create-class-390x844.png) | 떠 있던 회색 성곽 조각을 제거했다. 00의 시설 행과 01~03의 제목/선택 문법처럼 왼쪽 굵은 이름·작은 설명·오른쪽 화살표·3px 먹 구분선, 단계 제목 아래 짧은 주홍 선, 선택 행의 주홍 붓을 사용한다. | 생성 화면 전용 시안은 없다. 설명은 기존 `tag`, 직업의 `line / row`, 계통의 `tag` 그대로다. 모바일은 한 열, 1280×800은 폭 900의 두 열로 같은 선택 순서를 유지한다. 원본의 선택 불가 안내·클릭 후 거절도 그대로다. 중앙 정렬 얇은 선택 행 결함 수정 확인. |
| [능력치](verification/look-r24/after/create-points-390x844.png) · [최종 확인](verification/look-r24/after/create-confirm-390x844.png) | 회색 조각 제거, 굵은 제목과 짧은 주홍 밑줄·먹 경계·기존 주홍 선택을 적용했다. | 수치 증감·총량/추천/비우기·확인 버튼은 양식의 역할 때문에 중앙 정렬을 유지한다. 이름/설명이 있는 선택 행과 구분한다. 게임 계산·문구 변화 없음. |
| [첫 만남](verification/look-r24/after/meeting-390x844.png) · [데스크톱](verification/look-r24/after/meeting-1280x800.png) · [선택 행](verification/look-r24/after/meeting-end-390x664.png) | 회색 조각 제거. 인물 선택도 굵은 이름·원래 장면 제목·화살표·먹 선·주홍 선택 행으로 통일했다. 데스크톱에서 초상을 가로로 늘려 얼굴이 잘리던 현상은 340×280 한도로 고쳤다. | 00의 대표 초상 포스터와 달리 선택한 인물의 기존 상세 초상·장면 전문을 읽는 화면이다. 긴 문장·선택지는 본문 스크롤이고 하단 행동은 고정이다. 제목 자체의 잘림·부유하는 붓 조각 없음. |
| [클라우드](verification/look-r24/after/cloud-390x844.png) · [충돌](verification/look-r24/after/cloud-conflict-390x844.png) · [순위](verification/look-r24/after/rank-record-390x844.png) | 헤더 뒤에 떠 있던 회색 조각 제거. 큰 먹 제목·굵은 구분선·왼쪽 정렬 행동·주홍 주 행동을 유지한다. 연결/충돌/계정/PIN/확인/순위 모든 상태에 적용. | 전용 승인 시안 없음. 긴 계정/보안 안내와 입력 칸을 유지하므로 00의 포스터/시설 구성을 그대로 넣지 않았다. 새 동작·설명 추가 없음. |
| [동료 긴 상세](verification/look-r24/after/member-details-390x844.png) | 헤더의 회색 조각 제거. 01과 같은 기존 인물·굵은 이름·주홍 제목·먹 선, 왼쪽 정렬 상세 행동을 사용한다. | 01의 이미 승인된 개요·기술 화면은 보호 대상이라 그대로 두었다. 이 화면은 그곳에서 연 긴 특성/기술 전문 양식이며 01의 큰 초상 포스터를 복제하지 않는다. |

최종 확인 크기: **360×780, 390×664, 390×844, 430×932, 1280×800, 360×780 감소 모션**. 원본 이미지를 새로 그리거나 변환하지 않았다. 셸용 사본 **2개**는 원본과 SHA-256이 같다. 최종 그림에서 제목·화살표·고정 행동의 잘림, 겹침, 가로 넘침을 확인하지 못했다. 스크롤 아래의 본문/행이 뷰포트에서 가려지는 것은 정상 스크롤로 남긴다. 그 경계의 회색 세로선은 스크롤 막대이며, 제거한 성곽 조각과 다르다.

확인은 Godot 네이티브 UI와 원본 셸 Chromium에서 수행했다. `docs/`와 Web export는 지시대로 건드리지 않았으므로 **새 WASM 통합 검사는 Claude의 export 뒤 남는다.** 수치 통과와 시각 비교 결과를 구분해 기록한다.

실행 검사 **106/106 통과**, 실패 **0**, 미완료 **0**. 사용자 시각 승인 판정은 별도다.

수정 전 **58개 화면·상태 / 116장**(390×844·1280×800), 수정 후 **132장**(360×780·390×664·390×844·430×932·1280×800·360×780 감소 모션).
신규 생성/저장·글자/버튼 경계 검사 **3516건**, 상세/클라우드 추가 검사 **144건**, 셸 **30개 상태/크기**. 원본 이미지 **96개 해시 불변**, 금지 파일 변경 **0개**.

## 바꾼 화면과 파일

- `project/web_shell.html`: 큰 INTO THE ABYSS 먹 제목·종이·온전한 기존 마을 배경·힐데가르트 원본 초상·성곽/붓 벡터·마을 서체로 교체. 진행률·총량 미정·시작 준비·실패·재시도·팁·계정 인증 취소 동작/문구 유지. 셸용 이미지 사본 2개는 원본과 바이트 동일.
- `project/ui/create_screen.gd`: 종족·계통·출신·직업·첫 만남 선택에 왼쪽 굵은 이름·기존 설명·오른쪽 화살표·주홍 붓 선택·3px 먹 구분선 적용. 단계 제목 아래 짧은 주홍 선, 데스크톱 선택은 두 열. 부유하던 성곽 조각 제거. 인물·버튼 ID·콜백·진행 조건 유지.
- `project/ui/cloud_screen_r22.gd`: 연결·자격 표시·충돌·확인·순위를 마을 서체·굵은 행/입력 경계·왼쪽 정렬 행동으로 정리. 부유하던 성곽 조각 제거. 인증·업로드·다운로드·충돌 논리 유지.
- `project/ui/world_screen.gd`: 기존 동료 긴 상세와 확인용 폴백의 헤더·패널·버튼·내비게이션 외형만 정리. 원래 라우팅·행동·모델 호출 유지.
- `project/ui/town_theme_r21.gd`: 기존 PAPER/INK/RED/BOLD/DISPLAY·button-ink와 이미 쓰이던 읽기용 주홍색을 재사용하는 선택적 `dress_button`, `brush_style`, `heading_rule`, `rule`. 성곽 조각용 `city` 헬퍼는 제거했다. 기존 `make_theme()`와 승인 마을·전투 호출부는 변경하지 않음.
- 재현/검사: `project/tests/ui_look_r24_test.gd`, `capture_look_r24_extras.gd`, `tools/look_r24_*.py`, `tools/look_r24_cloud_launcher.mjs`.

## 전체 감사표

아래 준수 판정은 **수정 전**이다. 예=현행 승인 문법, 부분=종이·서체·선택색은 있으나 전용 시안/먹 구성 일부 없음, 아니오=옛 셸/패널. 시안 번호는 대응 보드이며 시안의 가상 수치·옛 인물을 데이터 정본으로 쓰지 않았다. 전용 시안이 없으면 없음으로 표시했다. 긴 문서는 본문 스크롤을 유지하며 화면 경계에서의 스크롤 가림은 글자 자체의 잘림과 구분했다.

| 화면·상태 / 증거(각 링크의 1280×800 짝도 존재) | 대응 시안 | 문법 준수 | 다른 점·처리 |
|---|---|---|---|
| [가방 · 보급품](verification/look-r24/before/bag-390x844.png) | 08 | 예 | 기존 아이템 그림·행·탭 사용. 보호 화면 감사만. |
| [전투](verification/look-r24/before/battle-390x844.png) | 09·10 | 예 | 기존 r17~r20 전투 유지. |
| [전투 패배 결과](verification/look-r24/before/battle-defeat-390x844.png) | 11 | 예 | 먹 제목·종이 결과 칸 유지. |
| [전투 승리 결과](verification/look-r24/before/battle-victory-390x844.png) | 11 | 예 | 먹 제목·주홍 행동 유지. |
| [탐색 카드 · 빈 상태](verification/look-r24/before/cards-390x844.png) | 08 | 예 | 기존 인물·빈 상태·하단 탭 유지. |
| [기존 모험 불러오기 · 클라우드 연결](verification/look-r24/before/cloud-390x844.png) | 없음 | 부분 | 작은 제목·일반 상자. 큰 제목·먹 성곽·굵은 행과 입력선으로 수정. |
| [클라우드 확인](verification/look-r24/before/cloud-confirm-390x844.png) | 없음 | 부분 | 일반 검정 버튼. 공통 주홍 붓 행동·구분선 적용. |
| [클라우드 충돌](verification/look-r24/before/cloud-conflict-390x844.png) | 없음 | 부분 | 일반 상자형 행동. 공통 문법 적용, 선택 동작 유지. |
| [클라우드 첫 계정·PIN 표시](verification/look-r24/before/cloud-credentials-390x844.png) | 없음 | 부분 | 일반 굵은 글꼴. 공통 제목·행 문법 적용. |
| [캐릭터 도감](verification/look-r24/before/codex-390x844.png) | 01 | 부분 | 종이·굵은 제목은 일치. 도감의 2열 탐색 양식은 시안 직접 대응 없음. |
| [새 모험가 · 출신 선택 불가](verification/look-r24/before/create-blocked-390x844.png) | 없음 | 부분 | 선택 불가 문구·활성 조건 유지, 상자 대신 구분선. |
| [새 모험가 · 3 직업](verification/look-r24/before/create-class-390x844.png) | 없음 | 부분 | 일반 회색 상자. 굵은 행·붓 선택으로 수정. |
| [새 모험가 · 5 확인](verification/look-r24/before/create-confirm-390x844.png) | 없음 | 부분 | 본문 서체·빈약한 하단 경계. 제목 서체·먹 경계 적용. |
| [새 모험가 · 계통·특성](verification/look-r24/before/create-lineage-390x844.png) | 없음 | 부분 | 일반 상자. 공통 주홍 선택·먹 행 적용. |
| [새 모험가 · 2 출신](verification/look-r24/before/create-nation-390x844.png) | 없음 | 부분 | 일반 상자. 동일 문구의 먹 구분선 행으로 수정. |
| [새 모험가 · 4 능력치](verification/look-r24/before/create-points-390x844.png) | 없음 | 부분 | 작은 상자형 증감 버튼. 공통 행·선택·제목 적용. |
| [새 모험가 · 1 종족](verification/look-r24/before/create-race-390x844.png) | 없음 | 부분 | 제목은 기존 먹 벡터, 선택지는 일반 상자. 선택지·제목·하단 경계 수정. |
| [원정 준비](verification/look-r24/before/depart-390x844.png) | 03 | 예 | 종이·먹 건축·주홍 출발·하단 탭. persona_* 보호 대상으로 감사만. |
| [여관 대화](verification/look-r24/before/dialogue-390x844.png) | 06 | 부분 | 종이·인물·굵은 제목은 일치, 일반 선택 상자·하단 탭 생략. 시설 보호 화면 감사만. |
| [동료 장비 보관함](verification/look-r24/before/equipment-390x844.png) | 02 | 예 | 기존 인물·먹 배경·하단 탭 유지. 보호 화면 감사만. |
| [원정 탐색 기록](verification/look-r24/before/expedition-log-390x844.png) | 07 | 부분 | 종이·굵은 제목·주홍 행동은 일치, 지도/먹 표현 적음. 원정 보호 화면 감사만. |
| [탐색 지도](verification/look-r24/before/explore-390x844.png) | 07 | 예 | 기존 지도·먹 구성·하단 탭 유지. 원정 보호 화면 감사만. |
| [탐색 휴게실](verification/look-r24/before/explore-rest-390x844.png) | 07 | 예 | 기존 배경·굵은 제목·주홍 행동 유지. 원정 보호 화면 감사만. |
| [상회 스크롤 대상](verification/look-r24/before/facility-scroll-390x844.png) | 05 | 부분 | 종이·행·기존 시설 구성. 시설 보호 화면 감사만. |
| [편성·원정 준비](verification/look-r24/before/formation-390x844.png) | 02·03 | 예 | 기존 원정 편성 화면. persona_* 보호 대상으로 감사만. |
| [길드 의뢰](verification/look-r24/before/guild-390x844.png) | 04 | 예 | 기존 접수원·먹 제목·의뢰 행 유지. 보호 화면 감사만. |
| [여관](verification/look-r24/before/inn-390x844.png) | 06 | 예 | 기존 주인·동료·행동 칸 유지. 보호 화면 감사만. |
| [장비 가방](verification/look-r24/before/inventory-390x844.png) | 02 | 부분 | 종이·굵은 제목·주홍 탭 사용. 장비 비교는 긴 스크롤 양식. |
| [모험 기록·연대기](verification/look-r24/before/journal-390x844.png) | 없음 | 부분 | 종이·굵은 제목·주홍 탭 사용. 기록을 읽는 목록 양식 유지. |
| [로딩 셸 · 계정 인증](verification/look-r24/before/loading-challenge-390x844.png) | 없음 | 아니오 | 옛 파랑·둥근 모달. 종이·먹·주홍 모달로 수정. |
| [로딩 실패·재시도](verification/look-r24/before/loading-error-390x844.png) | 00 문법 | 아니오 | 파스텔 배경·세리프·둥근 칸. 종이·먹 성곽·주홍 재시도로 수정. |
| [로딩 · 총량 미정](verification/look-r24/before/loading-indeterminate-390x844.png) | 00 문법 | 아니오 | 옛 파스텔 셸. 새 문법 적용, 총량 미정 동작 유지. |
| [로딩 · 다운로드 진행률](verification/look-r24/before/loading-loading-390x844.png) | 00 문법 | 아니오 | 파스텔 마을·옛 글꼴. 기존 title-home/성곽/붓 벡터와 기존 서체 적용. |
| [로딩 · 시작 준비](verification/look-r24/before/loading-starting-390x844.png) | 00 문법 | 아니오 | 옛 파스텔 셸. 새 문법 적용, 완료 후 시작 준비 동작 유지. |
| [첫 만남 · 인물·장면](verification/look-r24/before/meeting-390x844.png) | 없음 | 부분 | 기존 인물 원본 유지. 굵은 제목·먹 행·주홍 선택으로 수정. |
| [첫 만남 · 미선택](verification/look-r24/before/meeting-empty-390x844.png) | 없음 | 부분 | 일반 선택 상자. 먹 행·비활성 상태 유지. |
| [첫 만남 · 긴 장면 아래](verification/look-r24/before/meeting-end-390x844.png) | 없음 | 부분 | 같은 텍스트·순서·스크롤을 유지하고 선택지 문법 수정. |
| [동료 개요](verification/look-r24/before/member-390x844.png) | 01 | 예 | 기존 인물·큰 이름·탭 유지. 보호 화면 감사만. |
| [동료 긴 특성·기술 상세](verification/look-r24/before/member-details-390x844.png) | 01 | 아니오 | 옛 얇은 둘레 패널·작은 헤더. 큰 제목·먹 성곽·굵은 구분선·주홍 활성 탭으로 수정. |
| [동료 목록](verification/look-r24/before/party-390x844.png) | 01 | 예 | 기존 인물·먹 구성 유지. 승인 시안의 4명과 시험의 1명은 데이터 차이. |
| [토르바 인물 목록](verification/look-r24/before/people-390x844.png) | 없음 | 부분 | 종이·굵은 제목·주홍 탭. 인물 목록 양식 유지. |
| [토르바 인물 상세](verification/look-r24/before/person-isolde-390x844.png) | 없음 | 부분 | 종이 위 긴 원본 설명. 새로운 그림이나 요약 추가 없음. |
| [마을 장소 · 기록관](verification/look-r24/before/place-archive-390x844.png) | 없음 | 부분 | 종이·굵은 제목·이동/인물 목록. 시안 직접 대응 없음. |
| [마을 장소 · 시내](verification/look-r24/before/places-390x844.png) | 00·06 문법 | 부분 | 기존 먹 마을 그림·종이·탭 사용. 장소 전용 승인 시안 없음. |
| [대던전 순위 · 미등록](verification/look-r24/before/rank-390x844.png) | 없음 | 부분 | 작은 제목·일반 버튼. 공통 큰 제목·먹 행·붓 행동 적용. |
| [대던전 순위 · 기록](verification/look-r24/before/rank-record-390x844.png) | 없음 | 부분 | 공통 제목과 행동 문법 적용. 백분위와 날짜 문구 유지. |
| [길드 동료 소개](verification/look-r24/before/recruit-390x844.png) | 04 | 예 | 기존 접수원·큰 제목·주홍 행동 유지. 보호 화면 감사만. |
| [전술 연구](verification/look-r24/before/research-390x844.png) | 04 | 예 | 기존 인물·먹 제목·조합 행 유지. 보호 화면 감사만. |
| [전술 연구 편집](verification/look-r24/before/research-editor-390x844.png) | 04 | 예 | 기존 인물·조각 편집·주홍 저장 유지. 보호 화면 감사만. |
| [설정](verification/look-r24/before/settings-390x844.png) | 없음 | 부분 | 종이·굵은 제목·주홍 선택·각진 칸. 시안 직접 대응 없음. |
| [설정 · 처음부터 확인](verification/look-r24/before/settings-reset-390x844.png) | 없음 | 부분 | 종이·큰 제목·기존 확인 문구. 실제 초기화는 수행하지 않음. |
| [상회 보급품](verification/look-r24/before/shop-390x844.png) | 05 | 예 | 기존 상인·먹 제목·가격 행 유지. 보호 화면 감사만. |
| [상회 직업 장비](verification/look-r24/before/shop-gear-390x844.png) | 05 | 예 | 기존 상인·장비 목록·주홍 행동 유지. 보호 화면 감사만. |
| [동료 기술](verification/look-r24/before/skills-390x844.png) | 01 | 예 | 기존 인물·기술 칸·붓 행동 유지. 보호 화면 감사만. |
| [대장간](verification/look-r24/before/smithy-390x844.png) | 05 | 예 | 기존 대장장이·먹 제목·장비 탭 유지. 보호 화면 감사만. |
| [페르소나 상태](verification/look-r24/before/status-390x844.png) | 없음 | 부분 | 종이·굵은 제목·주홍 탭. 새 상태 패널 전용 시안 없음. |
| [원정 정산](verification/look-r24/before/summary-390x844.png) | 06 | 예 | 먹 성곽·주홍 층/결과·본문·귀환 행동 유지. 원정 보호 화면 감사만. |
| [마을 첫 화면](verification/look-r24/before/town-390x844.png) | 00 | 예 | 현행 승인 문법 정본. 보호 화면 감사만. |

## 검증과 직접 이미지 검토

- 원본 파일의 SHA-256과 수정 경계: [boundaries.json](verification/look-r24/boundaries.json). 게임 규칙·데이터·저장 형식, 기존 자산, 서버, 보호 대상 화면 3개, `docs/` 변경 0. 기존 이미지의 셸용 사본 2개만 추가했고 원본과 해시가 같다. 새 그림 생성 0.
- 색 대비(종이 바탕): 본문 15.82:1, 보조 글자 5.12:1, 읽기용 주홍 4.87:1. 새 색 계열을 만들지 않고 기존 생성/패널 화면의 주홍을 공용 상수로 추출.
- 네이티브 마우스 이벤트로 종족→계통→출신 차단→직업→점수→확인→첫 만남→마을을 통과. 저장 재개 뒤 종족·계통·출신·직업·배분 점수 비교. 모든 테스트는 worktree 안의 격리된 저장 경로 사용.
- [수정 후 검사](verification/look-r24/after-results.json), [추가 검사](verification/look-r24/after-extras-results.json), [셀 브라우저 검사](verification/look-r24/after-shell-results.json). 변경 화면의 글자·버튼 측정 실패 0; 브라우저 오류·가로 넘침 0. 실제 캡처를 [review/](verification/look-r24/review/)의 연락 시트와 주요 화면 원본으로 열어 확인. 작은 높이에서는 본문을 스크롤하고 하단 행동을 고정해 겹치지 않게 유지.
- 새 Web export는 지시대로 수행하지 않았다. 기존 WASM을 새 코드 증거로 쓰지 않고, `web_smoke_r19.py --town-r21`의 포인터·화면 크기·텍스트 경계 검사에 해당하는 네이티브 UI 검사 전부와 **셸 원본을 실행한 Chromium** 검사를 수행했다. 새 WASM 통합 웹 검사는 Claude의 export 뒤 남는 단계다.
- 셸의 Engine만 시험용 다운로드 콜백으로 대체했고, 실제 DOM/CSS·진행률/오류/인증 취소 스크립트는 실행했다. 셸은 PCK 이전에 필요하므로 기존 서체의 WOFF2·기존 벡터·그대로 복사한 기존 이미지 2개를 안에 넣었다. 별도 docs 복사 단계 없이 동작한다. `python tools/look_r24_shell_assets.py --check`로 공용 자산 일치 검증.
- 전체 프로젝트 결과: [all-tests.json](verification/look-r24/all-tests.json). 클라우드 결과: [cloud/results.json](verification/look-r24/cloud/results.json). `serve.mjs`의 실제 Worker·D1을 독립 loopback 포트와 개발 레지스트리 공유 해제로 실행. 정상 종료 130은 기존 SIGINT 폐기 경로다. 고정 8787의 초기 환경 오류와 독립 서버 재실행 결과를 로그로 보존했다.
- Godot의 Windows 인증서 저장소 진단은 baseline과 동일한 환경 진단으로 분리. 실제 시험 실패 판정은 exit·SCRIPT ERROR·기타 ERROR를 사용.
- 기존 before 저장 점수 비교에서 JSON 수치형(int/float) 때문에 2건의 시험 단정 오류가 있었고, 점수별 정수 비교로 고친 after 시험으로 재검증했다. 게임 기대값·규칙·수치는 바꾸지 않았다.
- 2차 Impeccable detector 경고·권고 7개(폰트 1, 색 3, 크기 2, 크림 바탕 1). 과거 r11 DESIGN.md와 현행 r21 정본의 차이여서 승인 시안·마을 상수를 유지했다. [round2-detector.json](verification/look-r24/round2-detector.json). 1차 taste inspector의 CDP 시간 초과 기록은 보존했다. 이번 셸은 Chromium 캡처·DOM 경계 검사, 네이티브 캔버스는 Godot 글리프·포인터·버튼 경계 검사로 검증했다.

## 남은 화면·후속 작업

- 마을/시설/원정 화면과 persona_* 외형은 지시된 보호 범위라 감사만 했다. 원정 기록의 약한 먹 구성, 시설 스크롤 대상의 일반 행 구성은 위 표에 남겼다.
- 도감·상태·장비 가방·설정·연대기·장소/인물은 이미 종이·큰 제목·주홍 선택을 사용한다. 전용 승인 시안이 없는 정보/탐색 양식은 부분으로 기록하고 이번 차수에 전면 재설계하지 않았다.
- 금지된 성적/친밀도 장면은 이식·실행하지 않음. 원본 게임 문구·인물 데이터의 변경 없음.
- 사용자 기기의 기존 저장은 건드리지 않았다. `docs/`·Web export·commit 없음. 2차 작업에서 git 명령은 사용하지 않았다.
- Impeccable 컨텍스트의 r11 DESIGN.md/sidecar가 현행 r21과 어긋난 상태는 이번 범위 밖이라 갱신하지 않았다. 필요할 때 `document`로 정리할 수 있다.

## 재현

```powershell
python tools/look_r24_regression.py import
python tools/look_r24_suite.py --fresh
python tools/look_r24_cloud.py
python tools/godot_r17.py --position -10000,-10000 --script res://tests/capture_look_r24_extras.gd -- after
python tools/look_r24_shell.py after
python tools/look_r24_shell_assets.py --check
python tools/look_r24_boundaries.py
python tools/look_r24_report.py
```
