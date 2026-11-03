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
