---
name: "Into the Abyss · 밝은 토르바 r11"
description: "휴대폰 세로 Godot 웹 게임을 위한 밝고 정제된 청백자 판타지 UI"
colors:
  ground: "#edf3f8"
  paper: "#fffdf8"
  pale: "#dce8f2"
  ink: "#253c52"
  muted: "#526b7e"
  blue: "#355f80"
  gold: "#8c6833"
  line: "#bbcbd7"
  hp: "#ad5855"
  mp: "#477d9f"
  battle-hp: "#db9b94"
  battle-mp: "#a3c5dc"
  plate: "#fffaf0"
  plate-line: "#cfb98f"
  inset: "#bda778"
  hover-target: "#e9f1f7"
  disabled: "#e3e8eb"
typography:
  headline:
    fontFamily: "Gowun Batang"
    fontSize: "22px"
    fontWeight: 700
  title:
    fontFamily: "Gowun Batang"
    fontSize: "18px"
    fontWeight: 700
  body:
    fontFamily: "Gowun Batang"
    fontSize: "14px"
    fontWeight: 400
  navigation:
    fontFamily: "Gowun Batang"
    fontSize: "12px"
    fontWeight: 700
  supporting:
    fontFamily: "Gowun Batang"
    fontSize: "12px"
    fontWeight: 400
  loading-display:
    fontFamily: "Gowun, serif"
    fontSize: "48px"
    fontWeight: 400
    lineHeight: 1.06
    letterSpacing: "-1px"
rounded:
  panel: "8px"
  button: "7px"
  plate: "5px"
  inset: "4px"
  scrollbar: "3px"
spacing:
  party-gap: "6px"
  compact: "8px"
  content: "12px"
  identity-gap: "14px"
  heading-inset: "16px"
components:
  button-primary:
    backgroundColor: "{colors.blue}"
    textColor: "{colors.paper}"
    rounded: "{rounded.button}"
    padding: "8px 12px"
    height: "54px"
  button-secondary:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.button}"
    padding: "8px 12px"
    height: "54px"
  navigation-active:
    backgroundColor: "{colors.pale}"
    textColor: "{colors.blue}"
    typography: "{typography.navigation}"
    rounded: "{rounded.panel}"
    height: "54px"
  portrait-card:
    backgroundColor: "{colors.pale}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    height: "164px"
  portrait-card-large:
    backgroundColor: "{colors.pale}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    height: "222px"
  facility:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.button}"
    height: "60px"
  container:
    backgroundColor: "{colors.paper}"
    textColor: "{colors.ink}"
    rounded: "{rounded.panel}"
    padding: "12px"
  resource-meter:
    backgroundColor: "{colors.pale}"
    height: "10px"
---

# Design System: Into the Abyss · 밝은 토르바 r11

## Overview

**Creative North Star: "청백자 판타지 · Blue-white porcelain"**

밝고 정제된 판타지 세계를 청백색 바탕, 따뜻한 명패, 푸른 법랑색 행동 버튼으로 표현한다. 고운바탕의 한글 세리프와 원래 인물 그림이 게임의 성격을 이끈다. 색만 교체한 금속 UI가 아니라 인물 카드, 시설 입구, 명령, 내비게이션의 역할이 각각 보이는 구성이다.

기준은 실제 r11 구현이다. FORM 출처는 `seed:5b4c8f653e0e6ee4`이며 기존의 blue-white porcelain 방향을 보존한다. 원본 인물의 얼굴·의상·정체성을 유지하고 이미지와 명패를 하나의 카드로 묶는다. 플랫폼과 자산 보존 조건은 [PRODUCT.md](PRODUCT.md)를 따른다.

**Key Characteristics:**
- 밝은 청백색 바탕과 절제된 황동 테두리.
- 고운바탕 Regular/Bold로 이어지는 한글 판타지 활자.
- 원본 초상과 명패가 결합된 클릭 가능한 인물 카드.
- 휴대폰 세로 화면의 고정 내비게이션과 스크롤 콘텐츠.
- 명확한 선택 표시와 짧은 화면 전환.

이 문서는 코드 추출 결과다. 제한된 범위의 최종 검토가 세 가지 주요 수정 이후 ship 판정을 반환했지만, 이는 사용자 시각 승인이나 전체 게임 검증을 뜻하지 않는다. 최종 시각 수용 여부는 사용자가 결정한다.

## Colors

청백색 중성면에 푸른 법랑과 황동을 배치한다. 정확한 값은 위 frontmatter가 기준이다.

### Primary
- **Blue / 푸른 법랑:** 원정 준비 같은 강조 행동, 활성 내비게이션, 사용자 정의 버튼의 포커스 표시.
- **Gold / 황동:** 강조 버튼 외곽선, 선택된 인물 카드의 테두리, 보조 강조 글자. 강조 버튼 안쪽 선은 더 옅은 Inset이다.

### Secondary
- **HP / 붉은 자원색, MP / 푸른 자원색:** 동료 상세의 자원 막대. 전투 막대는 별도의 옅은 Battle HP/Battle MP를 사용해 숫자가 읽히도록 한다.

### Neutral
- **Ground / 맑은 바탕:** 화면 전체 배경.
- **Paper / 도자기 흰색:** 패널과 기본 버튼.
- **Pale / 옅은 청색:** 초상 배경, 선택면, 자원 막대 바탕.
- **Ink / 짙은 청회색, Muted / 보조 청회색:** 본문과 보조 정보.
- **Line / 청회색 경계:** 기본 테두리. Plate와 Plate Line은 초상 명패의 따뜻한 색이다.
- **Hover Target, Disabled:** 호버 보간의 목표색과 비활성 버튼 배경. Hover Target을 모든 버튼의 최종 호버색으로 대입하지 않는다.

**The Role Contrast Rule.** 강조 행동은 Blue와 Paper, 일반 정보는 Paper와 Ink의 역할 구분을 유지한다.

## Typography

런타임은 `GowunBatang-Regular.ttf`와 `GowunBatang-Bold.ttf`를 직접 불러온다. 웹 로딩 화면은 `GowunBatang-loading.woff2`를 `Gowun`이라는 CSS 이름으로 사용하며 serif 폴백을 둔다. 런타임에서 별도의 CSS 폴백 체계를 사용한다는 뜻은 아니다.

화면 제목은 Headline, 동료 상세 이름과 원정 준비는 Title, 기본 테마 본문은 Body를 따른다. 화면별 본문·설명은 13–16px, 전투의 보조 라벨은 주로 12–14px다. 작은 인물 카드 이름/직업은 12/11px, 큰 카드는 16/12px다. 시설 제목/설명은 14/11px다. Navigation은 고운바탕 Bold다. 전투의 별도 Label 노드는 Regular를 사용하므로 모든 전투 텍스트를 Bold로 기록하지 않는다.

Loading Display는 로딩 화면 전용이며 화면 높이가 700px 이하일 때 38px가 된다. 런타임의 행간과 자간은 개별 노드 및 Godot 글꼴 측정에 맡긴다. 웹의 행간을 게임 전체 규칙으로 옮기지 않는다.

**The Korean Serif Rule.** 새 UI는 고운바탕의 한글 세리프 성격을 이어가며 나눔고딕 중심의 이전 방향으로 돌아가지 않는다.

## Layout

Godot 기준 뷰포트는 360×780이며 `canvas_items`와 `expand`를 사용한다. 주요 휴대폰 검토 크기는 360×780과 390×844다. 월드 화면은 폭 440px 이하로 중앙 정렬하고 전투는 폭 430px·높이 860px 이하의 중앙 프레임을 쓴다. 웹 로딩 화면의 최대 폭은 별도로 460px다.

월드 헤더는 높이 68px, 콘텐츠는 좌우 12px 여백과 상단 76px에서 시작한다. 스크롤 영역 높이는 화면 높이에서 152px를 뺀 값이다. 하단 내비게이션은 화면 아래 66px 위치에서 높이 54px를 차지하며 버튼 최소 높이는 52px다. 월드 콘텐츠 간격은 마을 8px, 그 외 12px다.

마을은 풍경, 출전 파티, 원정 준비, 시설 순서다. 네 인물 카드는 한 줄에 배치한다. 동료 목록은 두 열, 시설도 두 열이며 큰 카드와 시설의 높이는 frontmatter의 변형별 값을 따른다. 전투는 전장, 파티, 상세, 명령 영역을 구분하며 전장 내부의 어두운 배경은 스프라이트 대비를 위해 유지한다.

일반 메뉴 버튼 높이는 54px다. 전투 주 행동은 행동 수가 네 개 이하이면 64px, 더 많으면 52px다. 기록 버튼은 48×44px, 닫기는 44×44px다. 기술 목록은 행 간격 54px에 버튼 높이 50px이므로 메뉴의 54px 높이와 혼동하지 않는다. 보급품 목록 버튼은 54px다.

## Elevation & Depth

재사용 패널에는 그림자가 없다. 청백색 면의 차이, 가는 테두리, 명패의 겹침, 강조 버튼의 안쪽 선으로 깊이를 만든다. 눌림은 사용자 정의 버튼 표면이 아래로 1px 이동하고 배경을 6% 어둡게 하는 반응이다. 이것을 별도의 릴리스 애니메이션으로 기술하지 않는다.

**The Porcelain Surface Rule.** 패널의 깊이는 면과 선으로 표현하고 반복되는 검은 금속 패널로 되돌리지 않는다.

## Shapes

기본 패널과 인물 카드는 Panel 모서리, 버튼은 Button 모서리, 명패는 Plate 모서리, 강조 버튼 내부 선은 Inset 모서리를 사용한다. 테두리는 기본 1px다. 월드 헤더와 전투의 `_panel`은 각진 형태이므로 모든 면을 동일하게 둥글리지 않는다.

내비게이션은 독립적인 금속 버튼 대신 공통 하단 영역의 아이콘과 라벨로 보인다. 활성면에는 옅은 배경과 2px 푸른 밑줄이 생긴다. 원본 SVG 아이콘을 유지하며 문자 기호를 시설 아이콘의 대용으로 삼지 않는다.

## Components

### Buttons
`forged_button.gd`는 기본 도자기 버튼과 푸른 강조 버튼을 그린다. 강조 버튼에는 황동 외곽선과 4px 안쪽으로 들어간 옅은 선이 있다. 활성 일반 버튼은 Pale, 비활성 버튼은 Disabled 배경과 Muted 글자다. 포커스는 안쪽 4px에 Blue 테두리를 그린다.

호버 양은 매 프레임 `move_toward(hover_amount, goal, delta * 8)`로 변한다. 일반 버튼은 Hover Target 쪽으로 호버 양의 65%만큼 보간한다. 고정된 140ms 릴리스나 모든 버튼에 적용되는 CSS easing은 구현되어 있지 않다. 눌림 1px 이동은 표면에만 적용된다.

### Navigation
`navigation_button.gd`는 23×23px SVG 아이콘과 12px Bold 라벨을 그린다. 활성 상태는 공통 버튼의 Pale 면과 Blue 밑줄을 사용한다. 거점/원정, 동료, 가방, 기록의 의미를 아이콘과 글자로 함께 전달한다.

### Portrait cards
`portrait_card.gd`의 그림과 명패는 하나의 버튼이다. 작은 카드 명패 높이는 43px, 큰 것은 48px다. 선택·포커스는 Gold 테두리, 호버·누름은 얇은 흰색 오버레이와 Gold 경계로 표현한다.

메뉴 그림은 `character_portrait.gd`를 사용하며 필터는 `TEXTURE_FILTER_LINEAR`다. 일부 인물은 별도의 얼굴 크롭, 나머지는 원본 텍스처를 샘플링하는 실루엣 메시를 사용한다. 원본 픽셀·파일을 다시 칠하지 않는다. 전투 스프라이트와 메뉴 초상은 별도 자산 경로다. 일반 TextureRect 헬퍼의 밉맵 설정을 메뉴 초상에 잘못 적용해 기록하지 않는다.

**The Integrated Portrait Rule.** 얼굴·의상·원본 정체성을 보존하고 초상과 명패를 하나의 카드 안에 둔다.

### Facilities and containers
`facility_button.gd`는 30×30px SVG와 제목·목적 두 줄을 사용한다. 일반 패널은 12px 안쪽 여백, 8px 자식 간격을 쓴다. OptionButton은 테마의 도자기 면, 눌림의 Pale, 포커스의 Gold 테두리를 따른다. 텍스트 입력 필드 시스템은 이 문서에서 새로 정의하지 않는다.

### Transitions and loading
월드 화면이 바뀔 때 콘텐츠 알파가 0에서 1로 0.18초 동안 전환된다. 웹의 reduced-motion 설정이면 이 전환을 생략한다. 전투 프레젠테이션과 로딩 CSS에도 reduced-motion 분기가 있다. 사용자 정의 버튼의 호버와 일부 전투 숫자 피드백은 별도 구현이므로 모든 애니메이션이 이 설정으로 꺼진다고 주장하지 않는다.

로딩 화면은 동일한 밝은 풍경과 고운바탕, 진행률, 재시도 행동을 사용한다. 하단 여백에는 브라우저 safe-area를 더한다. 이 CSS의 safe-area 처리를 Godot 캔버스 전체가 자동으로 지원한다는 뜻으로 확대하지 않는다.

## Do's and Don'ts

### Do:
- Do preserve original character faces, costumes, portrait files, and the separate combat sprites.
- Do keep portrait and nameplate inside one interactive card.
- Do use the light porcelain palette, Korean serif typography, and clear action hierarchy.
- Do check long Korean labels and touch controls at both phone review sizes.
- Do preserve the implemented reduced-motion branches when extending transitions.

### Don't:
- Don't restore the dark metal shell, Nanum Gothic identity, or identical rectangular controls for every role.
- Don't replace character art to solve a framing problem.
- Don't describe menu portraits as mipmap filtered or invent a fixed button release duration.
- Don't treat schematic HTML component previews or a limited reviewer ship verdict as user visual approval.
