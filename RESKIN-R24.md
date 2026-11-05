# RESKIN R24 · 2차 수정

미실행: 실물 폰 터치·Web export·배포. 이 작업은 네이티브 Godot 화면에서 확인했으며 git 명령은 사용하지 않았다. 승인 PNG와 실제 데이터·대사 길이의 차이는 아래에 적었다. 품질 최종 승인은 사장님 확인이 필요하다.

## A~M 수정과 직접 확인

아래 전후 사진 13장과 묶음 사진 39장을 직접 열어 확인했다. 수정 전 390px 캡처를 보존했고, 마지막 소스 수정 뒤 세 해상도를 다시 촬영했다.

| 항목 | 바꾼 것 | 전후 비교 |
|---|---|---|
| A | 새 공용 초상·전투 상세·로그 연결 | [사진](verification/reskin-r24/round2/fix-A.jpg) |
| B | NPC 누끼와 일반 알파 합성 | [사진](verification/reskin-r24/round2/fix-B.jpg) |
| C | 시설의 왼쪽 제목·오른쪽 인물·검은 이름표 | [사진](verification/reskin-r24/round2/fix-C.jpg) |
| D | 원정 그림 띠·가로 진행·보상·준비·결과 | [사진](verification/reskin-r24/round2/fix-D.jpg) |
| E | 적 이름표를 각 적 머리 위로 | [사진](verification/reskin-r24/round2/fix-E.jpg) |
| F | 동료 상세의 능력치 격자와 실제 기술 아이콘 | [사진](verification/reskin-r24/round2/fix-F.jpg) |
| G | 초상과 소제목으로 나눈 인물 소개 | [사진](verification/reskin-r24/round2/fix-G.jpg) |
| H | 어깨 뒤에 작고 옅은 먹 번짐 | [사진](verification/reskin-r24/round2/fix-H.jpg) |
| I | 3px·먹 25% 스크롤바와 마을 숨김 | [사진](verification/reskin-r24/round2/fix-I.jpg) |
| J | 붉은 행의 세로 가운데 정렬 | [사진](verification/reskin-r24/round2/fix-J.jpg) |
| K | 본문 14px·보조 12px 기준의 가독성 | [사진](verification/reskin-r24/round2/fix-K.jpg) |
| L | 마을 종이 가장자리와 파티 한 줄 표기 | [사진](verification/reskin-r24/round2/fix-L.jpg) |
| M | 빈 상태의 문구와 다음 행동 | [사진](verification/reskin-r24/round2/fix-M.jpg) |

## 검증 수치

- 프로젝트 검사 169/169 + 전투 대조 실행 8/8: 총 177/177 통과, 최종 실패 0.
- 전투 6,320/6,320판, 219,785행동 일치. 이번 작업에서 여덟 대조를 모두 새로 실행했다.
- 146개 화면·상태 × 3해상도 = 438장. 390×844·360×780·1280×800. 화면 검사 1,728개, 실패 0.
- 글꼴 누락 0, 측정 넘침·실제 줄 잘림 0, 스크롤바 겹침 0, 12px 미만 보조 글자 0.
- 원본 그림 96/96 해시 불변. 게임·대사·데이터 221/221 해시 불변. resource_gauge_r24.gd의 붓 게이지는 수정하지 않고 바깥 숫자 조판만 공용 래퍼에서 키웠다.
- NPC 5/5: isnet-anime, 빨강·검정·종이 대조. 작은 조각 0, 흰 외곽선 0, 경계 5px 안쪽을 제외한 인물 내부 RGB 변경 0. 원본은 덮어쓰지 않았다.
- 이번에 만든 격리 실행 슬롯 4개와 부속 임시 폴더를 정리했다. 기본 runtime은 보존했다. [정리 기록](verification/reskin-r24/round2/runtime-cleanup.json).
- 새 sheet-1.jpg … sheet-39. 폭 1200px, 최대 678,943바이트. A~M 전후 사진도 폭 1200px 이하.

[전체 검사](verification/reskin-r24/round2/all-tests.json) · [화면 스캔](verification/reskin-r24/round2/visual-scan.json) · [전투 대조](verification/reskin-r24/round2/battle-parity.json) · [NPC 검사](verification/reskin-r24/round2/npc/validation.json) · [직접 검토](verification/reskin-r24/round2/visual-review.json) · [변경 목록](verification/reskin-r24/round2/source-handoff.json)

## 기능과 검사 조건

화면 표시만 바꿨다. 버튼 id·콜백·활성 조건·정본 숫자·전투 규칙·대사 데이터·저장 형식은 보존했다. 원정의 입구·1~5·휴식·보스는 가로 경로로 표시하고, 기존 source entry 메타데이터와 행동 순서를 유지했다. 기존 보상 반영과 결과 확인 경로를 그대로 사용하므로 결과를 보는 것만으로 보상이 지급되지 않는다.

초기 검사 실패는 지우지 않고 tests/results.json에 남겼다. 합본에 없던 finish-r24 Lua 대조 파일은 기존 oracle 도구로 정본 봇을 실행해 다시 만들었다. 파일을 읽다가 멈춘 두 격리 검사 프로세스는 종료하고 같은 기대값으로 재실행했다. 클라우드 검사는 실제 로컬 Worker/D1을 시작해 11묶음을 재실행했다. 이름표 줄 잘림, 적 클릭 영역·표지 간격, 공용 초상 명부, 영문 제목은 코드에서 고쳤고 focused-results.json에 재검사 결과를 남겼다. 기존 검사의 기대값은 바꾸지 않았다. 신규 인물 소개 검사는 기존 {{user}} 치환을 거친 원문과 화면 글자를 비교한다.

## 승인 시안과 다른 점·한계

[마을 대조](verification/reskin-r24/compare-town.png) · [동료 대조](verification/reskin-r24/compare-companion.png). 실제 저장은 1일째이며 시안의 2일째·가상 HP를 넣지 않았다. 동료 대사는 현재 상황의 원문 전체라 시안보다 길고 대사판 높이도 다르다. 시설 설명은 12px 이상으로 두 줄까지 읽히도록 표지가 조금 높다. 기존 개요·기술·편성·출정 설명은 아래 스크롤에서 접근한다. 시설 의뢰는 정본 난수에 따라 전후 캡처의 이름·보상이 달라질 수 있다. 숫자 변경으로 통과시킨 것은 아니며 기능 대조와 보호 해시로 구분했다.

그림이 없는 인물 소개에는 다른 사람의 초상을 대신 넣지 않았다. 페르소나는 기존 사람 선 아이콘을 사용한다. 실제 폰 브라우저 확인과 배포는 이번 범위에서 실행하지 않았다. Impeccable 정적 탐지는 []였으며 Godot 렌더 확인을 대체하지 않는다. 기존 .impeccable/design.json은 DESIGN.md보다 낡은 캐시라 갱신하지 않았다. 필요하면 별도 document 작업으로 갱신할 수 있다.

## 화면·상태 목록

| 화면·상태 | 390×844 | 360×780 | 1280×800 |
|---|---|---|---|
| bag | [캡처](verification/reskin-r24/render/bag-390x844.png) | [캡처](verification/reskin-r24/render/bag-360x780.png) | [캡처](verification/reskin-r24/render/bag-1280x800.png) |
| battle | [캡처](verification/reskin-r24/render/battle-390x844.png) | [캡처](verification/reskin-r24/render/battle-360x780.png) | [캡처](verification/reskin-r24/render/battle-1280x800.png) |
| battle-ko | [캡처](verification/reskin-r24/render/battle-ko-390x844.png) | [캡처](verification/reskin-r24/render/battle-ko-360x780.png) | [캡처](verification/reskin-r24/render/battle-ko-1280x800.png) |
| battle-log | [캡처](verification/reskin-r24/render/battle-log-390x844.png) | [캡처](verification/reskin-r24/render/battle-log-360x780.png) | [캡처](verification/reskin-r24/render/battle-log-1280x800.png) |
| battle-skills | [캡처](verification/reskin-r24/render/battle-skills-390x844.png) | [캡처](verification/reskin-r24/render/battle-skills-360x780.png) | [캡처](verification/reskin-r24/render/battle-skills-1280x800.png) |
| battle-status | [캡처](verification/reskin-r24/render/battle-status-390x844.png) | [캡처](verification/reskin-r24/render/battle-status-360x780.png) | [캡처](verification/reskin-r24/render/battle-status-1280x800.png) |
| battle-supplies | [캡처](verification/reskin-r24/render/battle-supplies-390x844.png) | [캡처](verification/reskin-r24/render/battle-supplies-360x780.png) | [캡처](verification/reskin-r24/render/battle-supplies-1280x800.png) |
| battle-target | [캡처](verification/reskin-r24/render/battle-target-390x844.png) | [캡처](verification/reskin-r24/render/battle-target-360x780.png) | [캡처](verification/reskin-r24/render/battle-target-1280x800.png) |
| cards | [캡처](verification/reskin-r24/render/cards-390x844.png) | [캡처](verification/reskin-r24/render/cards-360x780.png) | [캡처](verification/reskin-r24/render/cards-1280x800.png) |
| cards-empty | [캡처](verification/reskin-r24/render/cards-empty-390x844.png) | [캡처](verification/reskin-r24/render/cards-empty-360x780.png) | [캡처](verification/reskin-r24/render/cards-empty-1280x800.png) |
| cards-filled | [캡처](verification/reskin-r24/render/cards-filled-390x844.png) | [캡처](verification/reskin-r24/render/cards-filled-360x780.png) | [캡처](verification/reskin-r24/render/cards-filled-1280x800.png) |
| cloud | [캡처](verification/reskin-r24/render/cloud-390x844.png) | [캡처](verification/reskin-r24/render/cloud-360x780.png) | [캡처](verification/reskin-r24/render/cloud-1280x800.png) |
| cloud-archived | [캡처](verification/reskin-r24/render/cloud-archived-390x844.png) | [캡처](verification/reskin-r24/render/cloud-archived-360x780.png) | [캡처](verification/reskin-r24/render/cloud-archived-1280x800.png) |
| cloud-busy | [캡처](verification/reskin-r24/render/cloud-busy-390x844.png) | [캡처](verification/reskin-r24/render/cloud-busy-360x780.png) | [캡처](verification/reskin-r24/render/cloud-busy-1280x800.png) |
| cloud-confirm | [캡처](verification/reskin-r24/render/cloud-confirm-390x844.png) | [캡처](verification/reskin-r24/render/cloud-confirm-360x780.png) | [캡처](verification/reskin-r24/render/cloud-confirm-1280x800.png) |
| cloud-conflict | [캡처](verification/reskin-r24/render/cloud-conflict-390x844.png) | [캡처](verification/reskin-r24/render/cloud-conflict-360x780.png) | [캡처](verification/reskin-r24/render/cloud-conflict-1280x800.png) |
| cloud-credentials | [캡처](verification/reskin-r24/render/cloud-credentials-390x844.png) | [캡처](verification/reskin-r24/render/cloud-credentials-360x780.png) | [캡처](verification/reskin-r24/render/cloud-credentials-1280x800.png) |
| cloud-offline | [캡처](verification/reskin-r24/render/cloud-offline-390x844.png) | [캡처](verification/reskin-r24/render/cloud-offline-360x780.png) | [캡처](verification/reskin-r24/render/cloud-offline-1280x800.png) |
| cloud-readonly | [캡처](verification/reskin-r24/render/cloud-readonly-390x844.png) | [캡처](verification/reskin-r24/render/cloud-readonly-360x780.png) | [캡처](verification/reskin-r24/render/cloud-readonly-1280x800.png) |
| cloud-switch-account | [캡처](verification/reskin-r24/render/cloud-switch-account-390x844.png) | [캡처](verification/reskin-r24/render/cloud-switch-account-360x780.png) | [캡처](verification/reskin-r24/render/cloud-switch-account-1280x800.png) |
| codex | [캡처](verification/reskin-r24/render/codex-390x844.png) | [캡처](verification/reskin-r24/render/codex-360x780.png) | [캡처](verification/reskin-r24/render/codex-1280x800.png) |
| codex-bargut | [캡처](verification/reskin-r24/render/codex-bargut-390x844.png) | [캡처](verification/reskin-r24/render/codex-bargut-360x780.png) | [캡처](verification/reskin-r24/render/codex-bargut-1280x800.png) |
| codex-bargut-end | [캡처](verification/reskin-r24/render/codex-bargut-end-390x844.png) | [캡처](verification/reskin-r24/render/codex-bargut-end-360x780.png) | [캡처](verification/reskin-r24/render/codex-bargut-end-1280x800.png) |
| codex-berenga | [캡처](verification/reskin-r24/render/codex-berenga-390x844.png) | [캡처](verification/reskin-r24/render/codex-berenga-360x780.png) | [캡처](verification/reskin-r24/render/codex-berenga-1280x800.png) |
| codex-berenga-end | [캡처](verification/reskin-r24/render/codex-berenga-end-390x844.png) | [캡처](verification/reskin-r24/render/codex-berenga-end-360x780.png) | [캡처](verification/reskin-r24/render/codex-berenga-end-1280x800.png) |
| codex-end | [캡처](verification/reskin-r24/render/codex-end-390x844.png) | [캡처](verification/reskin-r24/render/codex-end-360x780.png) | [캡처](verification/reskin-r24/render/codex-end-1280x800.png) |
| codex-hildegard | [캡처](verification/reskin-r24/render/codex-hildegard-390x844.png) | [캡처](verification/reskin-r24/render/codex-hildegard-360x780.png) | [캡처](verification/reskin-r24/render/codex-hildegard-1280x800.png) |
| codex-hildegard-end | [캡처](verification/reskin-r24/render/codex-hildegard-end-390x844.png) | [캡처](verification/reskin-r24/render/codex-hildegard-end-360x780.png) | [캡처](verification/reskin-r24/render/codex-hildegard-end-1280x800.png) |
| codex-persona | [캡처](verification/reskin-r24/render/codex-persona-390x844.png) | [캡처](verification/reskin-r24/render/codex-persona-360x780.png) | [캡처](verification/reskin-r24/render/codex-persona-1280x800.png) |
| codex-teiris | [캡처](verification/reskin-r24/render/codex-teiris-390x844.png) | [캡처](verification/reskin-r24/render/codex-teiris-360x780.png) | [캡처](verification/reskin-r24/render/codex-teiris-1280x800.png) |
| codex-teiris-end | [캡처](verification/reskin-r24/render/codex-teiris-end-390x844.png) | [캡처](verification/reskin-r24/render/codex-teiris-end-360x780.png) | [캡처](verification/reskin-r24/render/codex-teiris-end-1280x800.png) |
| create-blocked | [캡처](verification/reskin-r24/render/create-blocked-390x844.png) | [캡처](verification/reskin-r24/render/create-blocked-360x780.png) | [캡처](verification/reskin-r24/render/create-blocked-1280x800.png) |
| create-class | [캡처](verification/reskin-r24/render/create-class-390x844.png) | [캡처](verification/reskin-r24/render/create-class-360x780.png) | [캡처](verification/reskin-r24/render/create-class-1280x800.png) |
| create-confirm | [캡처](verification/reskin-r24/render/create-confirm-390x844.png) | [캡처](verification/reskin-r24/render/create-confirm-360x780.png) | [캡처](verification/reskin-r24/render/create-confirm-1280x800.png) |
| create-lineage | [캡처](verification/reskin-r24/render/create-lineage-390x844.png) | [캡처](verification/reskin-r24/render/create-lineage-360x780.png) | [캡처](verification/reskin-r24/render/create-lineage-1280x800.png) |
| create-nation | [캡처](verification/reskin-r24/render/create-nation-390x844.png) | [캡처](verification/reskin-r24/render/create-nation-360x780.png) | [캡처](verification/reskin-r24/render/create-nation-1280x800.png) |
| create-points | [캡처](verification/reskin-r24/render/create-points-390x844.png) | [캡처](verification/reskin-r24/render/create-points-360x780.png) | [캡처](verification/reskin-r24/render/create-points-1280x800.png) |
| create-race | [캡처](verification/reskin-r24/render/create-race-390x844.png) | [캡처](verification/reskin-r24/render/create-race-360x780.png) | [캡처](verification/reskin-r24/render/create-race-1280x800.png) |
| depart | [캡처](verification/reskin-r24/render/depart-390x844.png) | [캡처](verification/reskin-r24/render/depart-360x780.png) | [캡처](verification/reskin-r24/render/depart-1280x800.png) |
| dialogue-choice | [캡처](verification/reskin-r24/render/dialogue-choice-390x844.png) | [캡처](verification/reskin-r24/render/dialogue-choice-360x780.png) | [캡처](verification/reskin-r24/render/dialogue-choice-1280x800.png) |
| dialogue-response | [캡처](verification/reskin-r24/render/dialogue-response-390x844.png) | [캡처](verification/reskin-r24/render/dialogue-response-360x780.png) | [캡처](verification/reskin-r24/render/dialogue-response-1280x800.png) |
| equipment | [캡처](verification/reskin-r24/render/equipment-390x844.png) | [캡처](verification/reskin-r24/render/equipment-360x780.png) | [캡처](verification/reskin-r24/render/equipment-1280x800.png) |
| expedition-log | [캡처](verification/reskin-r24/render/expedition-log-390x844.png) | [캡처](verification/reskin-r24/render/expedition-log-360x780.png) | [캡처](verification/reskin-r24/render/expedition-log-1280x800.png) |
| explore | [캡처](verification/reskin-r24/render/explore-390x844.png) | [캡처](verification/reskin-r24/render/explore-360x780.png) | [캡처](verification/reskin-r24/render/explore-1280x800.png) |
| explore-rest | [캡처](verification/reskin-r24/render/explore-rest-390x844.png) | [캡처](verification/reskin-r24/render/explore-rest-360x780.png) | [캡처](verification/reskin-r24/render/explore-rest-1280x800.png) |
| formation | [캡처](verification/reskin-r24/render/formation-390x844.png) | [캡처](verification/reskin-r24/render/formation-360x780.png) | [캡처](verification/reskin-r24/render/formation-1280x800.png) |
| guild | [캡처](verification/reskin-r24/render/guild-390x844.png) | [캡처](verification/reskin-r24/render/guild-360x780.png) | [캡처](verification/reskin-r24/render/guild-1280x800.png) |
| inn | [캡처](verification/reskin-r24/render/inn-390x844.png) | [캡처](verification/reskin-r24/render/inn-360x780.png) | [캡처](verification/reskin-r24/render/inn-1280x800.png) |
| inn-empty | [캡처](verification/reskin-r24/render/inn-empty-390x844.png) | [캡처](verification/reskin-r24/render/inn-empty-360x780.png) | [캡처](verification/reskin-r24/render/inn-empty-1280x800.png) |
| inventory | [캡처](verification/reskin-r24/render/inventory-390x844.png) | [캡처](verification/reskin-r24/render/inventory-360x780.png) | [캡처](verification/reskin-r24/render/inventory-1280x800.png) |
| inventory-detail | [캡처](verification/reskin-r24/render/inventory-detail-390x844.png) | [캡처](verification/reskin-r24/render/inventory-detail-360x780.png) | [캡처](verification/reskin-r24/render/inventory-detail-1280x800.png) |
| inventory-end | [캡처](verification/reskin-r24/render/inventory-end-390x844.png) | [캡처](verification/reskin-r24/render/inventory-end-360x780.png) | [캡처](verification/reskin-r24/render/inventory-end-1280x800.png) |
| inventory-filter-empty | [캡처](verification/reskin-r24/render/inventory-filter-empty-390x844.png) | [캡처](verification/reskin-r24/render/inventory-filter-empty-360x780.png) | [캡처](verification/reskin-r24/render/inventory-filter-empty-1280x800.png) |
| inventory-sell-confirm | [캡처](verification/reskin-r24/render/inventory-sell-confirm-390x844.png) | [캡처](verification/reskin-r24/render/inventory-sell-confirm-360x780.png) | [캡처](verification/reskin-r24/render/inventory-sell-confirm-1280x800.png) |
| inventory-stock | [캡처](verification/reskin-r24/render/inventory-stock-390x844.png) | [캡처](verification/reskin-r24/render/inventory-stock-360x780.png) | [캡처](verification/reskin-r24/render/inventory-stock-1280x800.png) |
| item-target | [캡처](verification/reskin-r24/render/item-target-390x844.png) | [캡처](verification/reskin-r24/render/item-target-360x780.png) | [캡처](verification/reskin-r24/render/item-target-1280x800.png) |
| journal | [캡처](verification/reskin-r24/render/journal-390x844.png) | [캡처](verification/reskin-r24/render/journal-360x780.png) | [캡처](verification/reskin-r24/render/journal-1280x800.png) |
| journal-disabled | [캡처](verification/reskin-r24/render/journal-disabled-390x844.png) | [캡처](verification/reskin-r24/render/journal-disabled-360x780.png) | [캡처](verification/reskin-r24/render/journal-disabled-1280x800.png) |
| journal-end | [캡처](verification/reskin-r24/render/journal-end-390x844.png) | [캡처](verification/reskin-r24/render/journal-end-360x780.png) | [캡처](verification/reskin-r24/render/journal-end-1280x800.png) |
| journal-legacy | [캡처](verification/reskin-r24/render/journal-legacy-390x844.png) | [캡처](verification/reskin-r24/render/journal-legacy-360x780.png) | [캡처](verification/reskin-r24/render/journal-legacy-1280x800.png) |
| meeting | [캡처](verification/reskin-r24/render/meeting-390x844.png) | [캡처](verification/reskin-r24/render/meeting-360x780.png) | [캡처](verification/reskin-r24/render/meeting-1280x800.png) |
| meeting-empty | [캡처](verification/reskin-r24/render/meeting-empty-390x844.png) | [캡처](verification/reskin-r24/render/meeting-empty-360x780.png) | [캡처](verification/reskin-r24/render/meeting-empty-1280x800.png) |
| member | [캡처](verification/reskin-r24/render/member-390x844.png) | [캡처](verification/reskin-r24/render/member-360x780.png) | [캡처](verification/reskin-r24/render/member-1280x800.png) |
| member_details | [캡처](verification/reskin-r24/render/member_details-390x844.png) | [캡처](verification/reskin-r24/render/member_details-360x780.png) | [캡처](verification/reskin-r24/render/member_details-1280x800.png) |
| party | [캡처](verification/reskin-r24/render/party-390x844.png) | [캡처](verification/reskin-r24/render/party-360x780.png) | [캡처](verification/reskin-r24/render/party-1280x800.png) |
| party-empty | [캡처](verification/reskin-r24/render/party-empty-390x844.png) | [캡처](verification/reskin-r24/render/party-empty-360x780.png) | [캡처](verification/reskin-r24/render/party-empty-1280x800.png) |
| people | [캡처](verification/reskin-r24/render/people-390x844.png) | [캡처](verification/reskin-r24/render/people-360x780.png) | [캡처](verification/reskin-r24/render/people-1280x800.png) |
| people-end | [캡처](verification/reskin-r24/render/people-end-390x844.png) | [캡처](verification/reskin-r24/render/people-end-360x780.png) | [캡처](verification/reskin-r24/render/people-end-1280x800.png) |
| person-agnes | [캡처](verification/reskin-r24/render/person-agnes-390x844.png) | [캡처](verification/reskin-r24/render/person-agnes-360x780.png) | [캡처](verification/reskin-r24/render/person-agnes-1280x800.png) |
| person-anselme | [캡처](verification/reskin-r24/render/person-anselme-390x844.png) | [캡처](verification/reskin-r24/render/person-anselme-360x780.png) | [캡처](verification/reskin-r24/render/person-anselme-1280x800.png) |
| person-cesare | [캡처](verification/reskin-r24/render/person-cesare-390x844.png) | [캡처](verification/reskin-r24/render/person-cesare-360x780.png) | [캡처](verification/reskin-r24/render/person-cesare-1280x800.png) |
| person-dorothea | [캡처](verification/reskin-r24/render/person-dorothea-390x844.png) | [캡처](verification/reskin-r24/render/person-dorothea-360x780.png) | [캡처](verification/reskin-r24/render/person-dorothea-1280x800.png) |
| person-dorothea-end | [캡처](verification/reskin-r24/render/person-dorothea-end-390x844.png) | [캡처](verification/reskin-r24/render/person-dorothea-end-360x780.png) | [캡처](verification/reskin-r24/render/person-dorothea-end-1280x800.png) |
| person-eckhart | [캡처](verification/reskin-r24/render/person-eckhart-390x844.png) | [캡처](verification/reskin-r24/render/person-eckhart-360x780.png) | [캡처](verification/reskin-r24/render/person-eckhart-1280x800.png) |
| person-elowen | [캡처](verification/reskin-r24/render/person-elowen-390x844.png) | [캡처](verification/reskin-r24/render/person-elowen-360x780.png) | [캡처](verification/reskin-r24/render/person-elowen-1280x800.png) |
| person-fenella | [캡처](verification/reskin-r24/render/person-fenella-390x844.png) | [캡처](verification/reskin-r24/render/person-fenella-360x780.png) | [캡처](verification/reskin-r24/render/person-fenella-1280x800.png) |
| person-fenella-end | [캡처](verification/reskin-r24/render/person-fenella-end-390x844.png) | [캡처](verification/reskin-r24/render/person-fenella-end-360x780.png) | [캡처](verification/reskin-r24/render/person-fenella-end-1280x800.png) |
| person-godfroi | [캡처](verification/reskin-r24/render/person-godfroi-390x844.png) | [캡처](verification/reskin-r24/render/person-godfroi-360x780.png) | [캡처](verification/reskin-r24/render/person-godfroi-1280x800.png) |
| person-hanna | [캡처](verification/reskin-r24/render/person-hanna-390x844.png) | [캡처](verification/reskin-r24/render/person-hanna-360x780.png) | [캡처](verification/reskin-r24/render/person-hanna-1280x800.png) |
| person-hanna-end | [캡처](verification/reskin-r24/render/person-hanna-end-390x844.png) | [캡처](verification/reskin-r24/render/person-hanna-end-360x780.png) | [캡처](verification/reskin-r24/render/person-hanna-end-1280x800.png) |
| person-isolde | [캡처](verification/reskin-r24/render/person-isolde-390x844.png) | [캡처](verification/reskin-r24/render/person-isolde-360x780.png) | [캡처](verification/reskin-r24/render/person-isolde-1280x800.png) |
| person-knut | [캡처](verification/reskin-r24/render/person-knut-390x844.png) | [캡처](verification/reskin-r24/render/person-knut-360x780.png) | [캡처](verification/reskin-r24/render/person-knut-1280x800.png) |
| person-loredana | [캡처](verification/reskin-r24/render/person-loredana-390x844.png) | [캡처](verification/reskin-r24/render/person-loredana-360x780.png) | [캡처](verification/reskin-r24/render/person-loredana-1280x800.png) |
| person-loredana-end | [캡처](verification/reskin-r24/render/person-loredana-end-390x844.png) | [캡처](verification/reskin-r24/render/person-loredana-end-360x780.png) | [캡처](verification/reskin-r24/render/person-loredana-end-1280x800.png) |
| person-maximilian | [캡처](verification/reskin-r24/render/person-maximilian-390x844.png) | [캡처](verification/reskin-r24/render/person-maximilian-360x780.png) | [캡처](verification/reskin-r24/render/person-maximilian-1280x800.png) |
| person-muriel | [캡처](verification/reskin-r24/render/person-muriel-390x844.png) | [캡처](verification/reskin-r24/render/person-muriel-360x780.png) | [캡처](verification/reskin-r24/render/person-muriel-1280x800.png) |
| person-noel | [캡처](verification/reskin-r24/render/person-noel-390x844.png) | [캡처](verification/reskin-r24/render/person-noel-360x780.png) | [캡처](verification/reskin-r24/render/person-noel-1280x800.png) |
| person-oswald | [캡처](verification/reskin-r24/render/person-oswald-390x844.png) | [캡처](verification/reskin-r24/render/person-oswald-360x780.png) | [캡처](verification/reskin-r24/render/person-oswald-1280x800.png) |
| person-pietro | [캡처](verification/reskin-r24/render/person-pietro-390x844.png) | [캡처](verification/reskin-r24/render/person-pietro-360x780.png) | [캡처](verification/reskin-r24/render/person-pietro-1280x800.png) |
| person-pietro-end | [캡처](verification/reskin-r24/render/person-pietro-end-390x844.png) | [캡처](verification/reskin-r24/render/person-pietro-end-360x780.png) | [캡처](verification/reskin-r24/render/person-pietro-end-1280x800.png) |
| person-sarkon | [캡처](verification/reskin-r24/render/person-sarkon-390x844.png) | [캡처](verification/reskin-r24/render/person-sarkon-360x780.png) | [캡처](verification/reskin-r24/render/person-sarkon-1280x800.png) |
| person-shorgai | [캡처](verification/reskin-r24/render/person-shorgai-390x844.png) | [캡처](verification/reskin-r24/render/person-shorgai-360x780.png) | [캡처](verification/reskin-r24/render/person-shorgai-1280x800.png) |
| person-sven | [캡처](verification/reskin-r24/render/person-sven-390x844.png) | [캡처](verification/reskin-r24/render/person-sven-360x780.png) | [캡처](verification/reskin-r24/render/person-sven-1280x800.png) |
| person-vittoria | [캡처](verification/reskin-r24/render/person-vittoria-390x844.png) | [캡처](verification/reskin-r24/render/person-vittoria-360x780.png) | [캡처](verification/reskin-r24/render/person-vittoria-1280x800.png) |
| person-wolfram | [캡처](verification/reskin-r24/render/person-wolfram-390x844.png) | [캡처](verification/reskin-r24/render/person-wolfram-360x780.png) | [캡처](verification/reskin-r24/render/person-wolfram-1280x800.png) |
| persona-status | [캡처](verification/reskin-r24/render/persona-status-390x844.png) | [캡처](verification/reskin-r24/render/persona-status-360x780.png) | [캡처](verification/reskin-r24/render/persona-status-1280x800.png) |
| place-alley | [캡처](verification/reskin-r24/render/place-alley-390x844.png) | [캡처](verification/reskin-r24/render/place-alley-360x780.png) | [캡처](verification/reskin-r24/render/place-alley-1280x800.png) |
| place-archive | [캡처](verification/reskin-r24/render/place-archive-390x844.png) | [캡처](verification/reskin-r24/render/place-archive-360x780.png) | [캡처](verification/reskin-r24/render/place-archive-1280x800.png) |
| place-gate | [캡처](verification/reskin-r24/render/place-gate-390x844.png) | [캡처](verification/reskin-r24/render/place-gate-360x780.png) | [캡처](verification/reskin-r24/render/place-gate-1280x800.png) |
| place-guild | [캡처](verification/reskin-r24/render/place-guild-390x844.png) | [캡처](verification/reskin-r24/render/place-guild-360x780.png) | [캡처](verification/reskin-r24/render/place-guild-1280x800.png) |
| place-inn | [캡처](verification/reskin-r24/render/place-inn-390x844.png) | [캡처](verification/reskin-r24/render/place-inn-360x780.png) | [캡처](verification/reskin-r24/render/place-inn-1280x800.png) |
| place-lamp | [캡처](verification/reskin-r24/render/place-lamp-390x844.png) | [캡처](verification/reskin-r24/render/place-lamp-360x780.png) | [캡처](verification/reskin-r24/render/place-lamp-1280x800.png) |
| place-rose | [캡처](verification/reskin-r24/render/place-rose-390x844.png) | [캡처](verification/reskin-r24/render/place-rose-360x780.png) | [캡처](verification/reskin-r24/render/place-rose-1280x800.png) |
| place-shop | [캡처](verification/reskin-r24/render/place-shop-390x844.png) | [캡처](verification/reskin-r24/render/place-shop-360x780.png) | [캡처](verification/reskin-r24/render/place-shop-1280x800.png) |
| place-smithy | [캡처](verification/reskin-r24/render/place-smithy-390x844.png) | [캡처](verification/reskin-r24/render/place-smithy-360x780.png) | [캡처](verification/reskin-r24/render/place-smithy-1280x800.png) |
| place-town | [캡처](verification/reskin-r24/render/place-town-390x844.png) | [캡처](verification/reskin-r24/render/place-town-360x780.png) | [캡처](verification/reskin-r24/render/place-town-1280x800.png) |
| places | [캡처](verification/reskin-r24/render/places-390x844.png) | [캡처](verification/reskin-r24/render/places-360x780.png) | [캡처](verification/reskin-r24/render/places-1280x800.png) |
| places-end | [캡처](verification/reskin-r24/render/places-end-390x844.png) | [캡처](verification/reskin-r24/render/places-end-360x780.png) | [캡처](verification/reskin-r24/render/places-end-1280x800.png) |
| rank | [캡처](verification/reskin-r24/render/rank-390x844.png) | [캡처](verification/reskin-r24/render/rank-360x780.png) | [캡처](verification/reskin-r24/render/rank-1280x800.png) |
| rank-record | [캡처](verification/reskin-r24/render/rank-record-390x844.png) | [캡처](verification/reskin-r24/render/rank-record-360x780.png) | [캡처](verification/reskin-r24/render/rank-record-1280x800.png) |
| recruit | [캡처](verification/reskin-r24/render/recruit-390x844.png) | [캡처](verification/reskin-r24/render/recruit-360x780.png) | [캡처](verification/reskin-r24/render/recruit-1280x800.png) |
| recruit-complete | [캡처](verification/reskin-r24/render/recruit-complete-390x844.png) | [캡처](verification/reskin-r24/render/recruit-complete-360x780.png) | [캡처](verification/reskin-r24/render/recruit-complete-1280x800.png) |
| recruit-poor | [캡처](verification/reskin-r24/render/recruit-poor-390x844.png) | [캡처](verification/reskin-r24/render/recruit-poor-360x780.png) | [캡처](verification/reskin-r24/render/recruit-poor-1280x800.png) |
| research | [캡처](verification/reskin-r24/render/research-390x844.png) | [캡처](verification/reskin-r24/render/research-360x780.png) | [캡처](verification/reskin-r24/render/research-1280x800.png) |
| research-editor | [캡처](verification/reskin-r24/render/research-editor-390x844.png) | [캡처](verification/reskin-r24/render/research-editor-360x780.png) | [캡처](verification/reskin-r24/render/research-editor-1280x800.png) |
| result-defeat | [캡처](verification/reskin-r24/render/result-defeat-390x844.png) | [캡처](verification/reskin-r24/render/result-defeat-360x780.png) | [캡처](verification/reskin-r24/render/result-defeat-1280x800.png) |
| result-victory | [캡처](verification/reskin-r24/render/result-victory-390x844.png) | [캡처](verification/reskin-r24/render/result-victory-360x780.png) | [캡처](verification/reskin-r24/render/result-victory-1280x800.png) |
| retreat-confirm | [캡처](verification/reskin-r24/render/retreat-confirm-390x844.png) | [캡처](verification/reskin-r24/render/retreat-confirm-360x780.png) | [캡처](verification/reskin-r24/render/retreat-confirm-1280x800.png) |
| save-error | [캡처](verification/reskin-r24/render/save-error-390x844.png) | [캡처](verification/reskin-r24/render/save-error-360x780.png) | [캡처](verification/reskin-r24/render/save-error-1280x800.png) |
| save-error-inn | [캡처](verification/reskin-r24/render/save-error-inn-390x844.png) | [캡처](verification/reskin-r24/render/save-error-inn-360x780.png) | [캡처](verification/reskin-r24/render/save-error-inn-1280x800.png) |
| save-error-member | [캡처](verification/reskin-r24/render/save-error-member-390x844.png) | [캡처](verification/reskin-r24/render/save-error-member-360x780.png) | [캡처](verification/reskin-r24/render/save-error-member-1280x800.png) |
| save-error-message | [캡처](verification/reskin-r24/render/save-error-message-390x844.png) | [캡처](verification/reskin-r24/render/save-error-message-360x780.png) | [캡처](verification/reskin-r24/render/save-error-message-1280x800.png) |
| save-error-party | [캡처](verification/reskin-r24/render/save-error-party-390x844.png) | [캡처](verification/reskin-r24/render/save-error-party-360x780.png) | [캡처](verification/reskin-r24/render/save-error-party-1280x800.png) |
| save-error-shop | [캡처](verification/reskin-r24/render/save-error-shop-390x844.png) | [캡처](verification/reskin-r24/render/save-error-shop-360x780.png) | [캡처](verification/reskin-r24/render/save-error-shop-1280x800.png) |
| scroll-target | [캡처](verification/reskin-r24/render/scroll-target-390x844.png) | [캡처](verification/reskin-r24/render/scroll-target-360x780.png) | [캡처](verification/reskin-r24/render/scroll-target-1280x800.png) |
| settings | [캡처](verification/reskin-r24/render/settings-390x844.png) | [캡처](verification/reskin-r24/render/settings-360x780.png) | [캡처](verification/reskin-r24/render/settings-1280x800.png) |
| settings-end | [캡처](verification/reskin-r24/render/settings-end-390x844.png) | [캡처](verification/reskin-r24/render/settings-end-360x780.png) | [캡처](verification/reskin-r24/render/settings-end-1280x800.png) |
| settings-reset | [캡처](verification/reskin-r24/render/settings-reset-390x844.png) | [캡처](verification/reskin-r24/render/settings-reset-360x780.png) | [캡처](verification/reskin-r24/render/settings-reset-1280x800.png) |
| shop | [캡처](verification/reskin-r24/render/shop-390x844.png) | [캡처](verification/reskin-r24/render/shop-360x780.png) | [캡처](verification/reskin-r24/render/shop-1280x800.png) |
| shop-gear | [캡처](verification/reskin-r24/render/shop-gear-390x844.png) | [캡처](verification/reskin-r24/render/shop-gear-360x780.png) | [캡처](verification/reskin-r24/render/shop-gear-1280x800.png) |
| shop-poor | [캡처](verification/reskin-r24/render/shop-poor-390x844.png) | [캡처](verification/reskin-r24/render/shop-poor-360x780.png) | [캡처](verification/reskin-r24/render/shop-poor-1280x800.png) |
| shop-receipt | [캡처](verification/reskin-r24/render/shop-receipt-390x844.png) | [캡처](verification/reskin-r24/render/shop-receipt-360x780.png) | [캡처](verification/reskin-r24/render/shop-receipt-1280x800.png) |
| skills | [캡처](verification/reskin-r24/render/skills-390x844.png) | [캡처](verification/reskin-r24/render/skills-360x780.png) | [캡처](verification/reskin-r24/render/skills-1280x800.png) |
| smithy | [캡처](verification/reskin-r24/render/smithy-390x844.png) | [캡처](verification/reskin-r24/render/smithy-360x780.png) | [캡처](verification/reskin-r24/render/smithy-1280x800.png) |
| smithy-process | [캡처](verification/reskin-r24/render/smithy-process-390x844.png) | [캡처](verification/reskin-r24/render/smithy-process-360x780.png) | [캡처](verification/reskin-r24/render/smithy-process-1280x800.png) |
| status | [캡처](verification/reskin-r24/render/status-390x844.png) | [캡처](verification/reskin-r24/render/status-360x780.png) | [캡처](verification/reskin-r24/render/status-1280x800.png) |
| status-end | [캡처](verification/reskin-r24/render/status-end-390x844.png) | [캡처](verification/reskin-r24/render/status-end-360x780.png) | [캡처](verification/reskin-r24/render/status-end-1280x800.png) |
| summary-empty | [캡처](verification/reskin-r24/render/summary-empty-390x844.png) | [캡처](verification/reskin-r24/render/summary-empty-360x780.png) | [캡처](verification/reskin-r24/render/summary-empty-1280x800.png) |
| summary-retreat | [캡처](verification/reskin-r24/render/summary-retreat-390x844.png) | [캡처](verification/reskin-r24/render/summary-retreat-360x780.png) | [캡처](verification/reskin-r24/render/summary-retreat-1280x800.png) |
| town | [캡처](verification/reskin-r24/render/town-390x844.png) | [캡처](verification/reskin-r24/render/town-360x780.png) | [캡처](verification/reskin-r24/render/town-1280x800.png) |
| town-empty-party | [캡처](verification/reskin-r24/render/town-empty-party-390x844.png) | [캡처](verification/reskin-r24/render/town-empty-party-360x780.png) | [캡처](verification/reskin-r24/render/town-empty-party-1280x800.png) |
| town-news | [캡처](verification/reskin-r24/render/town-news-390x844.png) | [캡처](verification/reskin-r24/render/town-news-360x780.png) | [캡처](verification/reskin-r24/render/town-news-1280x800.png) |
| town-no-news | [캡처](verification/reskin-r24/render/town-no-news-390x844.png) | [캡처](verification/reskin-r24/render/town-no-news-360x780.png) | [캡처](verification/reskin-r24/render/town-no-news-1280x800.png) |
| town-persona | [캡처](verification/reskin-r24/render/town-persona-390x844.png) | [캡처](verification/reskin-r24/render/town-persona-360x780.png) | [캡처](verification/reskin-r24/render/town-persona-1280x800.png) |

## 수정 파일

- `project/ui/battle_screen.gd`
- `project/ui/create_screen.gd`
- `project/ui/expedition_screen_r22.gd`
- `project/ui/facilities_screen_r22.gd`
- `project/ui/journal_screen_r22.gd`
- `project/ui/persona_sortie_screen.gd`
- `project/ui/portrait_layout_r24.gd`
- `project/ui/portrait_slot_r24.gd`
- `project/ui/portrait_slot_r24.gdshader`
- `project/ui/reskin_components_r24.gd`
- `project/ui/town_result_r21.gd`
- `project/ui/town_screen_r21.gd`
- `project/ui/world_screen.gd`
- `project/assets/portraits-r24/npc/dorothea.png`
- `project/assets/portraits-r24/npc/dorothea.png.import`
- `project/assets/portraits-r24/npc/fenella.png`
- `project/assets/portraits-r24/npc/fenella.png.import`
- `project/assets/portraits-r24/npc/hanna.png`
- `project/assets/portraits-r24/npc/hanna.png.import`
- `project/assets/portraits-r24/npc/landmarks.json`
- `project/assets/portraits-r24/npc/loredana.png`
- `project/assets/portraits-r24/npc/loredana.png.import`
- `project/assets/portraits-r24/npc/pietro.png`
- `project/assets/portraits-r24/npc/pietro.png.import`
- `project/tests/ui_reskin_r24_test.gd`
- `project/tests/ui_reskin_r24_round2_test.gd`
- `DESIGN.md`

검증 도구: `tools/portrait_r24_npc.py`, `tools/reskin_r24_round2_verify.py`, `tools/reskin_r24_round2_recheck.py`, `tools/reskin_r24_test_prerequisites.py`, `tools/reskin_r24_round2_report.py`, `tools/reskin_r24_round2_finalize.py`. 공용 cloud 도구에는 결과 폴더·격리 슬롯 선택만 추가했다.
