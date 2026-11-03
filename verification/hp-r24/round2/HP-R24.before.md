# HP-R24 · A 먹 붓 게이지

승인된 A를 공용 `resource_gauge_r24.gd`로 적용했다. 전체 **158/158그룹 통과, 실패 0**, 전투 **6,320/6,320판·219,785행동 일치**, 원본 이미지 **96/96개 불변**이다. Web export는 이번 지시의 금지 범위이므로 새 브라우저 빌드의 통합 실행은 하지 않았다. 시각 비교에서 남긴 차이는 아래에 명시했다.

## 구현

- 모든 HP 막대의 공용 그리기: 9px 높이, 위·아래 불규칙한 붓 윤곽, 종이색 바탕, `#c9321d` 채움, 25·50·75% 눈금. 코드로 만든 결정적 윤곽이며 AI 이미지 생성·원본 이미지 변경 없음.
- 현재 HP는 즉시 갱신한다. 피해 구간은 `#f0b9a8`로 0.4초 유지 후 0.25초 cubic ease-out으로 사라진다. 반복 피해는 현재 잔상 위치에서 다시 시작한다. 회복·전투 불능·감소 모션에서는 잔상을 즉시 정리한다. 화면 재구성 뒤에도 unit ID별 표시 기록이 이어지며 저장에는 넣지 않는다.
- 보호막은 실제 HP 오른쪽에 흰색·회색 빗금으로 붙이고 최대치를 넘는 부분을 자른다. 숫자는 실제 보호막 전체를 `+20`처럼 표시한다. 적의 `effects.shield.amount`도 읽는다.
- 25% 이하 살아 있는 인물의 채움은 `#8e1f12`, 현재 숫자는 주홍. 0 HP는 빈 바, 흑백·옅은 초상과 -8° 전투 불능 도장. 아군 상세 초상에도 적용한다. 차례의 주홍 초상 테두리와 이름 옆 차례 표시를 유지한다.
- 숫자는 기존 AbyssNotoBlackCondensed/기존 본문 굵은 서체만 사용한다. 작은 HP/MP, 큰 현재, 작은 회색 /최대·보호막을 구분한다. MP는 남색 3px와 옅은 남색 바탕이며 전투 카드에서 HP와 3px 간격이다.
- 단계 문턱은 실제 적 정의가 phase2를 가질 때만 `dungeon_enemy_r21.rules.catalog.tune.boss.phase_hp`를 읽어 3px 먹선으로 표시한다. 이름표의 n단계도 실제 phase 값이다.

## A 시안과 직접 비교

[승인 A와 실제 전투 나란히](verification/hp-r24/compare-approved-A.png)를 열어 확인했다. 아래 표는 공용 함수를 썼다는 주장만으로 판정하지 않고 실제 PNG를 본 결과다.

| 화면 | A와 같은 점 | 차이·유지한 배치 |
|---|---|---|
| 전투 아군 카드 | 붓 윤곽·눈금·주홍·잔상·빗금·위험 숫자·KO·차례 | 기존 51px 초상/카드 위치를 유지한다. A보다 현재 숫자가 크고, 기존 MP 수치도 바 아래에 남긴다. 이름은 기존 게임의 짧은 이름 정본이다. |
| 적 이름표·적 대상 선택 | 같은 붓 바, 오른쪽 정렬 숫자, 실제 단계·굵은 문턱 | 기존 33px HUD를 유지해 숫자를 바 위에 둔다(A는 아래). 좁은 적 이름은 기존 말줄임·전체 이름 tooltip 규칙을 유지한다. 증거는 실제 단계가 있는 폭주한 강의 인형으로 찍었다. |
| 선택 적 상세 | 같은 붓 바와 현재/최대 | 기존 우측 수치 영역을 사용하며 약점·심연·행동 문구를 보존한다. |
| 아군 상태 패널 | 동일한 붓/빗금/현재·최대/남색 MP, KO 초상·도장 | 기존 큰 초상과 우측 수치 자리 유지, 현재 숫자는 28px다. |
| 전투 보급품 대상 | 실제 선택 아군의 HP·MP·보호막을 동일 컴포넌트로 표시 | 기존 하단 확인 행 안에서 HP/MP를 두 열로 놓는다. 사용·취소 버튼 위치는 유지한다. |
| 마을 동료 개요·장비·아이템 대상 | 동일한 붓 HP·3px MP와 숫자 계층 | 개요의 HP/MP 두 열, 장비의 세로 수치, 대상의 회복 후 숫자·버튼 자리를 유지한다. 레벨 등 비자원 미리보기는 기존 표시를 유지한다. |
| 원정 탐색·기존 준비/결과 공용 막대 | HP 9px·MP 3px 공용 그리기 | 탐색은 정본 presenter가 반환한 ratio와 숫자 문구를 그대로 사용한다. 현재 원정 준비 화면은 자원 막대 없이 편성·레벨을 표시하므로 HP를 새로 지어 넣지 않았다. 기존 small_party 및 전투 결과의 HP 막대 경로도 공용화했다. |
| 상태창·도감 | 기존 HP/MP 능력치 수치 보존 | 현재 두 패널에는 HP/MP 비율 막대가 없다. HP/MP는 최대 능력치 텍스트이며 보이는 막대는 경험치·호감도다. 이를 HP로 바꾸거나 임의의 현재 HP를 만들지 않았다. |

A PNG의 93/93 +20 예시는 빗금 자리를 예약해 두었지만, 지시문의 **최대치에서 자른다**를 적용했다. 65/93 +20에서는 빗금이 보이고, 93/93 +20에서는 바가 가득 차며 +20만 남는다. 두 상태를 따로 캡처했다. 원래 전투 배경·컷인·먹 효과·버튼·전투 수치·난수·저장 형식은 변경하지 않았다.

## 크기·상태 검토

각 크기에서 차례/잔상/보호막/위험/KO/보스 단계를 한 화면에 두고, 적 대상·아군 상세·KO 상세·보급품 대상·보호막 최대 초과도 별도로 촬영했다. 각 크기를 일반/감소 모션으로 모두 검토했다.

| 크기 | 직접 연 결과 |
|---|---|
| 360×780 | 카드 안 현재·최대·+20이 들어간다. HP 9px·MP 3px, 차례·KO 도장 판독. |
| 390×664 | 짧아진 기존 전장은 유지하며 하단 카드·상세·대상 수치가 겹치지 않는다. |
| 390×844 | A와 나란히 비교한 주 화면. 잔상·빗금·위험의 차이를 판독할 수 있다. |
| 430×932 | 기존 늘어난 전장과 같은 카드 폭을 유지한다. 게이지를 세로로 늘리지 않는다. |
| 1280×800 | 기존 중앙 430px 전투 프레임을 유지한다. 좌우 여백은 아래 연락 시트에서 잘라 확대해 보았고 원본 PNG는 전체 크기다. |
| 감소 모션(위 5크기 전부) | 피해 잔상을 즉시 없앤다. 자원·도장·차례·문턱은 동일하다. |

직접 연 연락 시트: [기본](verification/hp-r24/review-states.png), [적 대상](verification/hp-r24/review-target.png), [상태](verification/hp-r24/review-status.png), [KO 상태](verification/hp-r24/review-status-ko.png), [보급품 대상](verification/hp-r24/review-supply-target.png), [보호막 상한](verification/hp-r24/review-shield-cap.png), [마을/패널](verification/hp-r24/review-world.png). 원본 캡처 **73장** 목록은 [hp-results.json](verification/hp-r24/hp-results.json)에 있다.

잔상은 [직후](verification/hp-r24/trail-0.0.png)·[0.4초](verification/hp-r24/trail-0.4.png)·[0.7초](verification/hp-r24/trail-0.7.png)의 정확한 시각 샘플과 [실시간 재생 3프레임](verification/hp-r24/review-live-trail.png)을 둘 다 열어 봤다. 정확한 샘플에서 현재 HP 62, 잔상 90→90→62다. 실시간 프레임의 캡처 시각은 hp-results.json에 기록했다. 캡처 시계와 직전 렌더 프레임은 한 프레임 이내의 차이가 있어 0.4초 사진은 아직 지연 끝자락일 수 있고, 0.7초 사진에서는 잔상이 사라진다.

## 검사·수정 파일

[전체 검사](verification/hp-r24/all-tests.json) **158그룹·실패 0·미실행 0**. import, world/state/route/expansion/motion/motion_asset/art/export_licenses, ui_battle_r17~r20, motion_r9/r18 integration 및 현재 프로젝트의 모든 *_test와 기존 전투 audit를 실행했다. 신규 HP 검사는 **602항목·실패 0**이며, 실제 impact callback의 표시 기록 갱신과 전투 snapshot/난수 불변, 잔상 지연·보간·회복·KO·감소 모션, 표시 폭·단계 정본을 검사한다. 기존 검사 기대값은 변경하지 않았다.

[전투 일치](verification/hp-r24/battle-parity.json): 8개 기존 audit **6,320판·219,785행동 일치**. 대형 trace를 복제하지 않고 기존 출력 경로와 집계만 보관했다. [클라우드](verification/hp-r24/cloud/results.json)는 실제 로컬 serve.mjs/Worker/D1에서 **9그룹 실패 0**. [서버 종료](verification/hp-r24/cloud/lifecycle.json)의 130은 기존 stdin→SIGINT 정상 종료 경로다. Windows root certificate store 진단은 환경 메시지로 분리했으며 다른 ERROR/SCRIPT ERROR는 실패로 판정했다.

제품 수정: `project/ui/resource_gauge_r24.gd`, `resource_ko_r24.gdshader` 신규 및 `battle_screen.gd`, `town_screen_r21.gd`, `expedition_screen_r22.gd`, `town_result_r21.gd`, `world_screen.gd`. 검사/도구: `project/tests/ui_hp_r24_test.gd`, `tools/hp_r24_verify.py`, `hp_r24_review.py`, `hp_r24_report.py`. Godot가 생성한 신규 UID sidecar를 포함한다. [파일 목록/해시](verification/hp-r24/delivery-files.json), [원본 자산 96개](verification/hp-r24/asset-check.json).

임시 runtime-hp-r24-*·runtime-local-hp-r24-*·tmp-hp-r24-*는 검사 종료 후 이 작업에서 만든 경로만 검증하여 지웠다. [정리 결과](verification/hp-r24/cleanup.json): 잔여 임시 슬롯 0, 기본 runtime 보존. git 명령·Web export·docs 쓰기·원본 봇 쓰기·AI 그림 생성 없음.

추가 확인 범위: 지정 크기는 native viewport에 직접 설정했다. 기존 Web의 최소 설계 높이 780에 따른 짧은 화면 축소 로직은 유지했다. 새 Web export를 하지 않았으므로 새 브라우저 실행/터치/OS 설정 연동의 통합 확인은 이번 결과에 포함하지 않는다. 기존 브라우저 빌드의 캡처를 새 코드 검증으로 간주하지 않았다. 최종 시각 수용 여부는 사용자 검토가 남는다.

디자인 도구 참고: impeccable detector의 결과는 빈 목록이며 Godot 렌더링 판정을 대신하지 않는다. 기존 DESIGN.md보다 .impeccable/design.json이 오래되었다는 context 경고가 있었고, 이번 범위에서는 문서를 재생성하지 않았다. 필요하면 impeccable document로 갱신할 수 있다.
