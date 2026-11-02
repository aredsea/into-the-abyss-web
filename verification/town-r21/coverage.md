# r21-D 시안 → 기능 → 원본 → 착수 시점 구현 대응표

정본: `../../../../outputs/r13-b-all`, `C:/Clauede Code/dungeon-bot`. 각 보드는 좌/중/우 패널 순서. 이 표는 **구현 전 조사**이며 최종 완료 여부는 `UI-R21-D.md`에 기록한다. 생성 이미지의 숫자·장비명은 데이터로 사용하지 않는다.

|시안|필요 기능|원본 규칙 위치|착수 시점|
|---|---|---|---|
|00 홈|출전 파티·금화·날짜·시설 이동·5개 내비|70-town.lua `TW_PLACES`, `tw_T`, `H.tw`|기능 있음, r11 화면·4개 내비|
|01 좌 동료 목록|보유/전체 30명·선택·편성 표시|66-status.lua, 75-sortie.lua `SO.members`, `ordered`|있음, 동일 격자|
|01 중 인물 개요|레벨·HP/MP·능력치·특성|66-status.lua, 24-stats.lua, design/stats.json|있음, 탭 없음|
|01 우 기술|원본 기술 설명·MP·방어 도발·연출 보기|66-status.lua, 10-data.lua, 32-personal-a.lua|있음, 개요와 같은 긴 화면|
|02 좌 편성·장비|전열/후열 편성·장비 관리|75-sortie.lua `SO`, 81-gear.lua `gear_can_equip`|고정 2+2명 구현, 원본 가변 인원·페르소나 없음|
|02 중 장비 보관함|부위·장착/판매·착용 레벨·능력 비교|81-gear.lua `gear_roll`, `gear_equip`, `gear_sell`; design/gear*.json|장착/판매 있음, 비교 없음, 옵션 난수 다름|
|02 우 연출|이전/재생/다음/닫기·방어형 고유기|66-status.lua, 32-personal-a.lua|있음(r18~20 유지 대상)|
|03 좌 원정 준비|목적지·파티·출발 HP/MP|75-sortie.lua, 76-dungeon.lua, design/DUNGEON.md|1곳 검수 원정, 목록 경계 함수 없음|
|03 중 공용 가방|보급품/장비/카드·개수·사용|71-shop.lua `POTION`, 78-battle-item.lua|있음, 부위 탭 분리|
|03 우 아이템 대상|레벨·회복량·HP/MP 대상 미리보기|78-battle-item.lua, 77-explore.lua|사용 있음, 미리보기 없음|
|04 좌 길드 의뢰|4의뢰·수락·포기·갱신·보수|72-guild.lua `gd_new`, `gd_gold`, `gd_refresh_cost`|있음, 생성/정산은 간소화|
|04 중 동료 소개|100+20×영입수·중복 없음|72-guild.lua `gd_recruit_cost`, `gd_candidates`, 74-level.lua `join_level`|있음, 페르소나 대신 파티 최고 레벨|
|04 우 전술 연구|조각 조합·MP·강화|29-persona-skill.lua, design/persona_skill.json|웹판 전술 대체 슬롯 구현|
|05 좌 상회|회복/마나/보호막 소중대·기타·할인|71-shop.lua `shop_price`, `H.sh`, design/shop.json|있음, 할인 내림 및 99개 상한 원본과 다름|
|05 중 직업 장비|일일 진열·착용레벨·품절|71-shop.lua `shop_stock`, `H.sh`|있음, 일일 난수·품절 다름|
|05 우 대장간|강화·보존 실패·가공 등급|81-gear.lua `forge_try`, `process_roll`; 82-smithy.lua|있음, 원본 난수와 다름|
|06 좌 여관|4행동·가격·하루 한도·날짜|73-inn.lua `INN_ACTS`, `H.in`; 74-affection.lua `aff_next`|있음, 100 경계 계산 오류|
|06 중 기록|모험 기록·빈 기록·자동 저장|89-memory.lua, design/SAVE-LOAD.md|40줄 기록 구현|
|06 우 원정 정산|보상·레벨·중복 방지|70-town.lua `tw_settle`, 74-level.lua `award_exp`|간소화 검수 원정 정산 있음|
|07 좌 탐색 지도|선택 경로·현재 위치·인벤토리|77-explore.lua, design/EXPEDITION.md|8노드 고정 경로 구현|
|07 중 봉인 보관함|키 카드 사용·지나치기|77-explore.lua|간소화 있음|
|07 우 휴식|HP30% MP60%·한 번·이동|77-explore.lua|간소화 있음|
|08 좌 탐색 카드|소모 카드·사용 가능 조건|77-explore.lua, design/EXPEDITION.md|2종 검수 카드 있음|
|08 중 귀환 확인|결정 전 요약·확인/취소|77-explore.lua, 70-town.lua|있음|
|08 우 빈 상태|카드/장비/동료 없음·복귀|66-status.lua, 75-sortie.lua|텍스트 빈 상태 있음|
|11 좌 고유 기술|방어·도발 컷인|32-personal-a.lua|r18~20 구현, 전투 파일 수정 금지|
|11 중 승리|획득 보상·경험치·귀환|70-town.lua, 74-level.lua|전투 및 정산 구현, 시안과 다름|
|11 우 패배|손실·철수·귀환|70-town.lua `tw_settle`|패배 정산 다름(미정산 보상만 포기)|

## 제외 목록

79-sex.lua 전체, 장미 골목/창관, 여관·던전의 성적 제안과 친밀도 장면, 매혹의 비약과 피에트로의 해당 덤. 74-affection.lua의 **일반 여관 행동 숫자 계산**은 성적 장면 없이 사용한다. 원본의 AI 대화 송신/생성도 이 독립 게임에서는 연결하지 않는다.
