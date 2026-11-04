# RESKIN R24

미완료·병합 전 사항: 초상 레인 결과는 아직 합치지 않았으며 기존 상반신을 얇은 어댑터로 표시한다. 공통 규칙의 git 명령 금지를 지켜 단계 커밋은 하지 않았다. 새 Web export·docs 배포와 실물 폰 검증은 하지 않았다. DESIGN.md는 교체했으나 수정 허용 범위 밖인 기존 .impeccable/design.json 캐시는 갱신하지 않았다. 필요하면 impeccable document로 별도 갱신할 수 있다.

회귀 검사 통과 160/160, 실패 0, 미실행 0. 실패·미실행이 있으면 아래 목록에 그대로 남긴다.

실제 게임 UI 코드에 종이·먹·버밀리언 체계를 적용했다. 게임 규칙·대사·저장 형식은 바꾸지 않았다. 코드에서 먼저 추출한 화면/함수/분기 목록은 [source-inventory.json](verification/reskin-r24/source-inventory.json), 실제 상태별 목록은 아래 표다.

- 캡처 423장, 세 해상도. 입력·캡처 검사 1446개, 실패 0.
- 실제 렌더 글꼴 누락 0, 측정 텍스트 넘침 0, 스크롤바 겹침 0건.
- 원본 이미지 96/96 해시 불변. 보호 파일 226/226 불변.
- 기존 전투 대조 출력 집계 6,320/6,320판, 219,785행동 일치. 신규 실행 여부는 all-tests.json의 audit 그룹과 함께 확인한다.
- 폰 검토용 sheet-1.jpg … sheet-36. 각 장 폭 1200, 최대 695,347바이트.

## 바뀐 것

1. 공용 부품: reskin_components_r24.gd에 종이·제목·선·행·주 행동·선택·선 아이콘·내비·찢긴 가장자리·스크롤을 통합. UI-r24의 wash는 승인 CSS SVG를 Chromium으로 구운 것이다. 그림 생성 없음.
2. 마을 B: 시설 네 곳을 지도 표지로, 파티 네 자리를 상자 없는 상반신과 자원으로, 다음 원정을 큰 행동으로 교체. 원본의 설명과 추가 출정 선택은 아래 스크롤에 보존. 동료 C: 오른쪽 상반신·세로 선택·실제 단계 대사·시설 행. 생성 5단계: 본문과 선택 분리·화살표 선 아이콘·스크롤 복원. 목록·상세·시설·가방·장비·원정·기록·도감·설정·클라우드는 같은 공용 문법을 사용. 여관 행동은 네모 타일에서 행으로 변경.
3. 전투: 하단 파티·상태·기록의 인물만 초상 어댑터로 연결. 전장 배치·규칙·효과·컷인은 유지. 원본 자원 게이지 보존. DESIGN.md를 새 체계로 재작성.

## 기준 PNG와의 차이

[마을 대조](verification/reskin-r24/compare-town.png), [동료 대조](verification/reskin-r24/compare-companion.png). 시안의 2일째·가상 HP와 실제 저장의 날짜·금화·HP는 다르며 게임 데이터가 우선이다. 동료의 대사는 현재 단계 원문 전체를 사용하므로 시안의 한 줄보다 길다. 기존 상반신의 구도·먹 번짐 가장자리는 별도 초상 레인 결과를 기다린다. 원본의 개요·기술·편성·출정 설명은 첫 화면 아래에 남아 있어 시안보다 스크롤이 길다. 여관의 붉은 새 소식 표지는 실제 현재 단계의 미열람 대화가 있고 오늘 대화가 가능한 경우에만 표시한다. 읽기만으로 저장·난수를 바꾸지 않는 검사도 포함한다.

## 화면·상태 목록

아래 각 행은 390×844·360×780·1280×800에서 캡처했다. 첫 화면과 끝 상태, 빈 상태·오류·확인·입력 상태를 별도로 표기한다. 데이터에 따른 수치 조합은 기존 기능 검사와 원본 대조 검사가 맡는다.

| 화면 / 상태 | 390×844 | 360×780 | 1280×800 |
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
| person-eckhart | [캡처](verification/reskin-r24/render/person-eckhart-390x844.png) | [캡처](verification/reskin-r24/render/person-eckhart-360x780.png) | [캡처](verification/reskin-r24/render/person-eckhart-1280x800.png) |
| person-elowen | [캡처](verification/reskin-r24/render/person-elowen-390x844.png) | [캡처](verification/reskin-r24/render/person-elowen-360x780.png) | [캡처](verification/reskin-r24/render/person-elowen-1280x800.png) |
| person-fenella | [캡처](verification/reskin-r24/render/person-fenella-390x844.png) | [캡처](verification/reskin-r24/render/person-fenella-360x780.png) | [캡처](verification/reskin-r24/render/person-fenella-1280x800.png) |
| person-godfroi | [캡처](verification/reskin-r24/render/person-godfroi-390x844.png) | [캡처](verification/reskin-r24/render/person-godfroi-360x780.png) | [캡처](verification/reskin-r24/render/person-godfroi-1280x800.png) |
| person-hanna | [캡처](verification/reskin-r24/render/person-hanna-390x844.png) | [캡처](verification/reskin-r24/render/person-hanna-360x780.png) | [캡처](verification/reskin-r24/render/person-hanna-1280x800.png) |
| person-isolde | [캡처](verification/reskin-r24/render/person-isolde-390x844.png) | [캡처](verification/reskin-r24/render/person-isolde-360x780.png) | [캡처](verification/reskin-r24/render/person-isolde-1280x800.png) |
| person-knut | [캡처](verification/reskin-r24/render/person-knut-390x844.png) | [캡처](verification/reskin-r24/render/person-knut-360x780.png) | [캡처](verification/reskin-r24/render/person-knut-1280x800.png) |
| person-loredana | [캡처](verification/reskin-r24/render/person-loredana-390x844.png) | [캡처](verification/reskin-r24/render/person-loredana-360x780.png) | [캡처](verification/reskin-r24/render/person-loredana-1280x800.png) |
| person-maximilian | [캡처](verification/reskin-r24/render/person-maximilian-390x844.png) | [캡처](verification/reskin-r24/render/person-maximilian-360x780.png) | [캡처](verification/reskin-r24/render/person-maximilian-1280x800.png) |
| person-muriel | [캡처](verification/reskin-r24/render/person-muriel-390x844.png) | [캡처](verification/reskin-r24/render/person-muriel-360x780.png) | [캡처](verification/reskin-r24/render/person-muriel-1280x800.png) |
| person-noel | [캡처](verification/reskin-r24/render/person-noel-390x844.png) | [캡처](verification/reskin-r24/render/person-noel-360x780.png) | [캡처](verification/reskin-r24/render/person-noel-1280x800.png) |
| person-oswald | [캡처](verification/reskin-r24/render/person-oswald-390x844.png) | [캡처](verification/reskin-r24/render/person-oswald-360x780.png) | [캡처](verification/reskin-r24/render/person-oswald-1280x800.png) |
| person-pietro | [캡처](verification/reskin-r24/render/person-pietro-390x844.png) | [캡처](verification/reskin-r24/render/person-pietro-360x780.png) | [캡처](verification/reskin-r24/render/person-pietro-1280x800.png) |
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

## 검사 결과와 변경한 시험

[전체 로그/결과](verification/reskin-r24/all-tests.json). Windows root certificate store 메시지는 환경 진단으로 별도 취급하며, 다른 ERROR·SCRIPT ERROR는 실패다. 초기 클라우드의 서버 부재 실패는 격리된 실제 Worker/D1로 재검사했다. 대사 전수 UI 검사는 최초 래퍼의 360초 제한과 네이티브의 1200초 감시 제한 때문에, 오류 없이 완료한 인물·언어·크기 블록을 보존하고 나머지를 같은 기대값으로 이어 검사했다. [연속 검사 근거](verification/reskin-r24/dialogue-continuation.json)는 120/120블록과 실제 재개 프로세스 종료 0을 기록한다. 반복 재구성 시 동일 셰이더를 공유해 다시 만드는 비용도 줄였다.

실패: 없음

미실행: 없음

위치 보정: [목록](verification/reskin-r24/test-position-updates.json)의 11개 포인터 도우미는 기존 버튼을 스크롤 안으로 가져온 뒤 같은 마우스 입력을 보낸다. ui_town_r21_test는 스크롤 안 컨트롤도 실제로 끝까지 도달할 수 있는지 검사한다. 기능 기대값·활성 조건·순서·상태 변화는 바꾸지 않았다. 외형 보정: ui_town_r21_round9_test는 같은 인물 수를 새 어댑터에서 세고 승인 계약대로 활성 막대가 글자 위에 있는지 검사한다. ui_town_r21_round11_test는 SVG 파일명 대신 동일한 번역 제목과 실제 Label을 검사한다. ui_semantics_native_r23_test는 흰 글자 대신 선택 상태와 실제 밑줄 그림을 검사한다. ui_expe_pass5_r23_test는 원본 문구와 별표 개수를 그대로 비교하고 각 별이 실제 승인 SVG로 그려지는지도 확인한다. 대사 검사 감시 시간은 3600초로 늘리고 완료 블록의 재개 근거를 남긴다.

[컨트롤 id 대조](verification/reskin-r24/control-id-audit.json): 변경한 주요 5개 화면의 기존 리터럴 컨트롤 id 누락 0. 승인 C 구성에 필요한 동료 칩·시설 행만 추가했다. [디자인 탐지](verification/reskin-r24/design-detector.json)는 지적 0이며 직접 렌더 검토를 대체하지 않는다.

## 최종 검토와 인계

네이티브 캡처 423장으로 구성한 시트 36장을 직접 검토했다. 최종 수정 후 시트 2·14·26·31~36을 다시 확인했다. [검토 기록](verification/reskin-r24/visual-review.json), [소스 인계 목록](verification/reskin-r24/source-handoff.json), [런타임 정리](verification/reskin-r24/cleanup.json)를 함께 남긴다. 임시 런타임 슬롯은 0개이며 공용 기본 런타임은 보존했다.

저장 실패의 복구 안내는 본문 위에 별도 공간을 예약하고 원래 행동은 스크롤로 접근할 수 있게 했다. 페르소나 파티 자리는 동료 전용 대사·특성 데이터가 없으므로 기존 상태창을 연다. 실제 클릭으로 원본 능력치·스킬을 확인했다. 구형 상세창의 내비게이션도 연속된 검은 띠로 통일했다. 셰이더는 공유하여 화면 반복 구성 비용을 줄였다.

소스 인계 목록은 읽기 전용 r21-portrait 사본과 다른 허용 UI·시험 파일, 이 작업의 UI 자산·도구·문서에 대한 경로와 SHA-256이다. 전체 작업공간의 git diff를 대신하는 목록은 아니며, 보호 파일 검사는 별도 protected-check.json을 기준으로 한다.
