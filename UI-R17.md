# r17 전투 UI — 2026-10-31

**최신 결과는 아래 「2차 수정」 절이다.** 그 앞의 내용과 수치는 1차 구현 기록으로 보존했다. 현재 `ui_build`는 `battle-r17-20261031-pass2`다.

공개 r11 작업 트리에 승인된 r17 전투 배치를 구현했다. 마을·탐색 화면과 규칙·수치·저장 형식은 유지했다. `ui_build`는 `battle-r17-20261031`이다. 커밋·체크아웃·리셋·스태시·푸시는 실행하지 않았다. 모든 작성 파일은 이 작업 트리 안에 있다.

이 결과는 시안의 동일 픽셀 복제나 사용자의 최종 시각 승인을 뜻하지 않는다. 본문 글꼴, 새 벡터 잉크의 윤곽, 기록 표현, 좁은 화면의 전장 크기에는 아래 차이가 있다. 웹 내보내기는 성공했으나 이번 작업에서 브라우저 실행과 실물 휴대폰 검사는 하지 않았다.

## 구현

- 390×844 기준 상단 41px 헤더, y=43의 8칸 순서, y=94의 전장, y=381의 압축 제목, y=438의 적 상세, y=506의 56px 행동 2×2, y=632의 44px 보조 버튼, y=685의 네 아군 카드를 배치했다. 360×780에서는 하단 UI 크기와 12px 본문을 유지하고 전장 높이와 인물 크기를 줄인다.
- 현재 행동 아군 하나만 기존 `CharacterSprite`로 그린다. 순서는 모델의 `data.queue`, 차례는 `current_id`, 숫자는 각 유닛의 HP/MP와 최대치에서 읽는다. 적 명패는 그림 발 아래 5px 간격, 종이색 띠·이름·HP 숫자·2px 막대다. 적 1~4명 배치를 검사했다.
- 직접 행동 선택 → 적 터치 실행, 선택 취소, 자신/전체 기술 실행, 아군 대상 기술 선택을 연결했다. 부족한 마나는 `cost - current MP`로 표시하고 기술 버튼을 비활성화한다. 제목 오른쪽의 44×44 `기술` 버튼으로 아래 목록을 열 수 있다.
- 기술·보급품·기록·아군 상태는 전장을 남기는 아래 시트다. 열릴 때 18px/160ms 전환을 적용하고 웹의 reduced-motion 설정에서는 생략한다. 목록은 세로 스크롤을 지원한다. 열린 시트 뒤의 행동 버튼은 만들지 않아 중복 입력을 막는다.
- 보급품 선택 → 아래 아군 카드로 대상 변경 → 사용 또는 취소를 구현했다. 회복량·개수·대상 자원은 데이터에서 읽는다. 가득 찬 HP/MP, 소생 대상, 요구 레벨 등의 사용 불가 이유를 표시한다. 취소는 소비하지 않고 사용은 실제 모델을 호출한다.
- 얼굴 카드는 원본 텍스처를 눈썹~턱 중심으로 샘플링한다. 상태 시트는 기존 초상의 실루엣 메시를 사용한다. 원본 그림 파일은 바꾸지 않았다.

## 새 잉크와 글꼴

`battle_ink_r17.gd`가 상태별 고정 시드로 찢긴 종이 경계와 붓 자국을 그린다. 기본 제목 주변, 대상 적 발밑, 상태 제목, 기술·보급품 경계, 기록 오른쪽의 위치와 모양이 다르다. 기록 자국은 긴 선들의 집합이다. r13 B, r17 잉크 PNG, 생성 이미지의 추출·트레이스·재사용은 하지 않았다. 새 검/방패 UI 아이콘도 직접 작성한 SVG다.

`print.gdshader`는 전장 배경 그림에만 채도·고정 그레인·하프톤 처리를 한다. 글자·숫자·버튼·명패·아군 카드에는 적용하지 않는다. 스프라이트 자체에도 질감 셰이더를 적용하지 않았다.

승인 시안의 `AbyssNotoBlackCondensed.ttf`를 KS X 1001 한글 2,350자, ASCII, 시안 기호, 데이터의 모든 name/short 문자열로 서브셋했다. JSON에서 모은 고유 이름 문자열 1,376개, 최종 문자 2,456개를 검사했고 원본 글꼴에 없는 문자는 0개였다. 파일은 **6,176,392 → 440,916바이트**다. 검사는 [font-coverage.json](verification/ui-r17/font-coverage.json)에 있다. 본문은 이미 있던 **고운바탕 Bold**를 사용하며 10MB Noto 가변 글꼴은 추가하지 않았다. OFL 전문은 `project/assets/fonts/OFL-AbyssNoto.txt`에 두고 라이선스 생성기와 Web 포함 목록에도 추가했다.

## r12에서 가져온 범위

허용된 로컬 저장소의 파일을 읽었다. 전투의 `_enemy_pressed`, `_action_pressed`, `_close_sheets` 흐름 및 `_ally_pressed`의 아군 대상 처리 부분을 가져왔다. r12의 실제 마우스 down/up 입력·파티별 fixture·글자 검사 방식을 r17 테스트의 출발점으로 삼았다. 보급품 대상은 즉시 소비하는 r12 흐름에서 별도의 사용 버튼 방식으로 바꿨다.

`world_screen.gd`, `forged_button.gd`, `fantasy_theme.gd`, `portrait_card.gd` 등 r12 공용·마을 코드는 가져오지 않았다. r17 버튼과 색은 전투 파일 안에 두었고, r11의 기존 연출·충돌 시점·저장 코드를 유지했다. 기존 UI 파일에서 바뀐 것은 `battle_screen.gd` 하나다.

## 시안과의 차이 — 직접 연 비교 이미지 기준

[390 기본·대상·상태](verification/ui-r17/comparison-core-390.png), [390 기술·보급품·기록](verification/ui-r17/comparison-tools-390.png), [360 기본·대상·상태](verification/ui-r17/comparison-core-360.png), [360 기술·보급품·기록](verification/ui-r17/comparison-tools-360.png)를 직접 열었다. 승인 390 화면과 실제 Godot 화면을 상태별로 나란히 배치했다. 360 비교의 승인 쪽은 390 시안을 축소한 참고 그림이며, 360 승인 시안이 별도로 있다는 뜻은 아니다. [30명 얼굴 갤러리](verification/ui-r17/roster-faces.png)도 직접 열었다.

- 종이색, 버밀리언, 큰 압축 제목, 2×2 행동과 아래 네 카드는 유지했다. 본문은 시안 Noto Sans 대신 기존 고운바탕이어서 같은 12px에서도 더 가늘고 세리프가 보인다. 제목은 기술 진입 공간을 확보하고 긴 문구는 글자 크기를 줄이므로 시안보다 작아질 수 있다.
- 원본 보존을 위해 실제 게임의 스프라이트·초상 메시를 사용했다. 360의 작은 전장에서는 아군과 집행 인형이 390보다 작다. 시안의 정적인 크롭과 모든 픽셀이 일치하지 않는다.
- 잉크는 새 벡터이므로 시안의 복잡한 붓 윤곽과 다르다. 실제 렌더에서 적 HP 띠를 덮던 경계, 상태 제목을 가리던 잉크, 기술·보급품의 마지막 줄 잘림을 수정했다. 최종 비교에서 이 부분을 다시 확인했다.
- 실제 fixture는 처음에 턴 0, 집행 인형 HP 163/163, 테이리스 MP 92/92 등이다. 시안의 턴 3·HP 62/163·MP 20/86을 복제하지 않았다. 마나 부족 렌더는 MP를 0으로 둔 검사용 상태다. 기록 렌더는 실제 모델로 공격과 후속 적 행동을 해결해 만든 기록이다.
- 현재 모델의 약점·심연 게이지·`intent()`가 모두 있어 표시했다. 다만 시안의 `2층`에 대응하는 층 필드는 전투 데이터에 없어 **층 숫자를 빼었다**. 장소명은 기존 전장의 학술원 폐허를 유지했다. 전투 이탈 동작이 없는 뒤로 화살표도 만들지 않았다.
- 기록은 `state.history`의 실제 문장 목록이다. 독립된 턴/행위자/초상 메타데이터가 없어 시안의 행별 얼굴·턴 배지를 지어내지 않았다. 기록 장식은 빈 오른쪽 영역에 두었다.
- 보급품의 회복률과 개수는 실제 데이터다. 품목 그림 대신 텍스트 행을 사용한다. 행동 아이콘은 검·방패 두 종류로 단순화했다. 시안의 별도 냉기 아이콘, 보급품/기록 보조 아이콘은 복제하지 않았다.
- 시트는 위쪽 전장과 아래 카드를 남긴다. 기술 목록 헤더의 MP는 제목과 같은 줄, 닫기 왼쪽에 둔다. 두 기술의 `마나 36 부족` 문구와 보급품 세 줄이 동시에 보이도록 높이를 조정했다.

## 검증 결과

| 검사 | 결과 |
| --- | --- |
| Godot `--editor --import` | 완료, 프로젝트 스크립트/렌더 오류 0 |
| world / state / route | 44 / 54 / 41 검사, 실패 0 |
| expansion | 3,350 검사, 실패 0 |
| balance_probe | 8개 파티 × 40 seed = 320회 실행 완료; 밸런스 승인 아님 |
| motion_test / motion_asset_test | 타임라인 검사 및 19클립 자산 검사 통과 |
| art_test | 30명 / 60 UV 프레임 / 30 고유 연출 통과 |
| r9 연출 통합 | 944 검사, 48조건, 접촉 렌더 16장, 실패 0 |
| r17 실제 입력 | 758 검사, 실패 0 |
| 30명 × 두 폭 | 기본·기술·상태 문구의 폭 초과/누락 글리프 0 |
| 행동·아군 터치 | 검사한 버튼의 가로/세로 경계 및 최소 44px 조건 통과 |
| 원본 자산 | ASSET-HASHES 96개 일치, 변경 0 |
| game / data / 공용 UI | 작업 전 SHA-256과 일치; 전투 UI 외 변경 0 |
| 렌더 | 390×844와 360×780 각각 여섯 상태, PNG 12장 및 비교 4장 |
| Web release | 성공; `docs/version.json`의 ui_build 및 SHA-256 갱신 |

실제 입력 검사는 행동 선택 → 적 터치 피해, 선택 취소, 마나 부족 비활성 버튼 입력, 기술 시트 취소, 보급품 열기/선택/대상/취소/실제 사용, 기록·아군 상태 열기/닫기를 포함한다. 검사 수는 독립된 기능 수가 아니다. 원자료는 `verification/ui-r17/battle-input-results.json`, `existing-tests.json`, `motion-r9/results.json`, `preservation-and-build.json`이다.

엔진은 이 실행 환경에서 Windows root certificate store를 읽지 못했다는 메시지를 공통 출력한다. 이를 숨기지 않고 로그에 남겼다. 최종 import·입력·연출·export 로그에서 이 메시지를 제외한 스크립트/렌더 ERROR는 0개다. 네트워크 기능이 정상이라는 검증은 아니다.

`docs/index.pck`: **49,885,048 → 50,159,484바이트**, **+274,436바이트 (+0.5501%)**. 최종 해시는 `docs/version.json`과 보존 검사 JSON에 있다. WASM SHA-256은 기존과 같다.

## 바뀐 파일과 재실행

- 전투: `project/ui/battle_screen.gd`, 새 `battle_ink_r17.gd`, `battle_face_r17.gd` 및 Godot 생성 UID.
- 자산: 새 `project/assets/ui-r17/{sword.svg,shield.svg,print.gdshader}`, 서브셋 TTF, OFL 전문 및 Godot import 메타데이터.
- 검사·리뷰: 새 `project/tests/ui_battle_r17_test.gd`, `project/tools/review_ui_r17.gd`, `review_faces_r17.gd` 및 UID. 기존 `motion_r9_integration.gd`는 출력 폴더만 이 트리 안으로 변경했다.
- 라이선스·빌드: `project/tests/export_licenses.gd`, `project/licenses/GODOT_AND_THIRD_PARTY.txt`, `project/export_presets.cfg`, `tools/update_version.py`, 재내보낸 `docs/index.*`와 `docs/version.json`.
- 보조 도구: `tools/prepare_r17.py`(글꼴 서브셋), `godot_r17.py`(트리 내부 런타임 경로), `review_r17.py`(비교 합성), `audit_r17.py`(보존/로그/PCK 검사).
- 문서·증거: 이 문서, README 첫 줄, `verification/ui-r17/`. 런타임·임시 폴더는 해당 폴더의 `.gitignore`로 구분했다.

작업 트리에서 다음 순서로 재실행할 수 있다. `godot_r17.py`는 지정된 Godot를 사용하며 APPDATA/LOCALAPPDATA/TEMP/TMP를 이 트리의 `verification/ui-r17/` 아래로 지정한다. 도구체인 폴더는 읽고, 엔진 자체의 self-contained 데이터 기록만 엔진에 맡긴다.

```powershell
python tools/godot_r17.py --headless --editor --import --quit
python tools/godot_r17.py --position -10000,-10000 --script res://tools/review_ui_r17.gd
python tools/godot_r17.py --position -10000,-10000 --script res://tools/review_faces_r17.gd
python tools/review_r17.py
python tools/godot_r17.py --position -10000,-10000 --script res://tests/motion_r9_integration.gd
python tools/godot_r17.py --headless --script res://tests/export_licenses.gd
python tools/godot_r17.py --headless --export-release Web ../docs/index.html
python tools/update_version.py
python tools/audit_r17.py
```

## 확인하지 못한 범위

브라우저에서의 최종 WASM 실행, IndexedDB 실저장 왕복, iPhone/Android·Safari/Firefox, 저사양 성능과 장시간 진행은 이번에 검사하지 않았다. 기존 모델의 저장 왕복 테스트 통과가 실기기 저장 검사를 대신하지 않는다. 30명 각각의 모든 기술을 실제 입력으로 실행한 검사는 아니며, 전원 문구/글리프와 기존 모델의 기술 실행 검사를 조합했다. 임의로 만든 초장문 번역 이름이나 360px 미만 폭은 보장 범위 밖이다.

기존 `.impeccable/design.json`과 DESIGN.md의 시점 불일치는 스킬이 보고했으나 전투 구현 범위에서 수정하지 않았다. 필요하면 별도 `document` 작업으로 갱신할 수 있다. 기계 디자인 검사 결과는 `design-detector.json`의 빈 목록이지만, GDScript에 대한 시각 승인이나 접근성 인증을 의미하지 않는다.

## 2차 수정

`r17-impl-pass2-brief.md`의 네 항목을 수정했다. 모든 쓰기는 `work/battle-r17/` 안에서 수행했고 git 명령은 실행하지 않았다. 아래 판정은 구현·검사 결과이며 시안과의 픽셀 일치나 사용자 시각 승인을 뜻하지 않는다.

| 요청 | 판정과 실제 변경 | 남은 차이 |
| --- | --- | --- |
| 굵은 산세리프 본문 | 맞음. Noto Sans KR에서 정적 500·800 두 굵기를 만들었다. 전투 라벨·이름·적 HP·아군 HP/MP·행동 비용·목록은 800, 기록 문장은 500을 쓴다. 압축 디스플레이는 유지했다. | 시안의 500~850 가변 굵기를 두 단계로 표현하므로 보조 정보 일부는 시안보다 굵다. |
| 제목·숫자·버튼과 잉크 겹침 제거 | 맞음. 시트 위의 긴 가로 붓 자국을 제거하고 실제 글자 Control rect에 3px 여유를 둬 잉크 다각형을 잘라낸다. 동적 기록 행·스크롤 영역도 포함한다. | 글리프 외곽선보다 넓은 rect를 보호하므로 글자 주변 여백이 시안보다 커지는 곳이 있다. |
| 전장 아래 찢긴 경계 | 맞음. 상태마다 다른 고정 시드로 종이 경계·검정 입술 부분·버밀리언 덧칠·작은 파편을 만든다. 여섯 상태의 윤곽 해시가 각 폭에서 모두 다르다. 기본은 왼쪽 잉크와 제목을 경계 가까이 두되 글자 공간을 비웠다. 적 명패 아래로 종이를 내려 HP도 가리지 않는다. | 새 벡터 윤곽은 시안과 다르다. 시안의 넓고 길게 번진 붓질에 비해 더 짧은 파편과 가는 띠가 이어진다. |
| 기록의 굵은 붓 몸통 | 맞음. 가는 빨간 선 묶음을 검정 어깨·넓은 버밀리언 몸통·갈라진 붓끝을 가진 한 덩어리로 교체했다. 오른쪽 88×153px 장식 공간을 확보하고 실제 문장은 왼쪽에서 줄바꿈한다. | 시안 장식 공간 114×164px보다 작다. 시안과 붓끝 방향·검정 비중·번짐이 다르며, 기록은 기존 실제 문장 목록이다. 시안의 얼굴/턴 메타데이터는 추가하지 않았다. |

### 글꼴·라이선스·용량

`tools/prepare_r17_body.py`로 `C:/Windows/Fonts/NotoSansKR-VF.ttf`(10,415,532바이트)를 정적 인스턴스화한 뒤 서브셋했다. KS X 1001 한글 **2,350자**, ASCII·기호·데이터 이름 고유 문자열 **1,376개**를 포함한 **2,456자**를 저장한 TTF에서 다시 검사했다. 두 파일 모두 누락 **0**, `fvar` 없음, OS/2 굵기 500·800을 확인했다.

- `AbyssNotoText500.ttf`: **444,012바이트**.
- `AbyssNotoText800.ttf`: **443,832바이트**.
- 합계 **887,844바이트**(약 867KiB). 가변 원본은 배포에 포함하지 않았다.
- 파생 글꼴 이름은 `Abyss Noto Text`로 변경했다. `OFL-AbyssNotoText.txt`에 저작권·변경 설명·OFL 전문을 넣고 `export_licenses.gd`, 생성된 통합 라이선스, Web 포함 목록을 갱신했다.
- 공용 `fantasy_theme.gd`와 마을·탐색 글꼴은 수정하지 않았다. 기존 압축 제목 서브셋도 변경하지 않았다.

근거: [body-font-coverage.json](verification/ui-r17/body-font-coverage.json).

### 새 검사와 재검증 결과

잉크 검사는 렌더에 사용하는 최종 검정/버밀리언 다각형과 화면에 보이는 전체 Label rect를 별도로 교차 판정한다. 경계상자로 먼저 거른 뒤 `Geometry2D.intersect_polygons`의 면적을 검사하며, 판정 오차 기준은 0.01px²다. 종이색은 배경이므로 잉크 겹침 수에서 제외한다. 이름 길이가 다른 30명 각각을 기본·대상·상태·기술·보급품·기록에 놓았고 기록 스크롤 끝도 검사했다. 같은 입력으로 다각형을 두 번 생성해 결정론도 확인했다.

| 검사 | 2차 결과 |
| --- | --- |
| import | 성공, 인증서 저장소 메시지 외 엔진/스크립트 오류 0 |
| world / state / route / expansion | 44 / 54 / 41 / 3,350 검사, 실패 0 |
| balance | 7파티×40시드, 280/280 승리; 판정 기준은 기존 probe 그대로 |
| motion / motion_asset / art | 통과; 19클립, 30인물·60 UV프레임·30연출 |
| r9 연출 통합 | 48사례, 944검사, 실패 0, 접촉 렌더 16장 |
| `ui_battle_r17_test.gd` 실제 입력·렌더 | **2,899검사, 실패 0**, PNG 12장 |
| 30명×두 폭×여섯 상태 | **360사례**, 가로 글자 넘침·누락 글리프 0; 기록 실제 Label도 검사 |
| 잉크 검사 전체 | **440사례**, 다각형/글자 rect 후보 **2,010,473쌍**, 겹침 **0** |
| 겹침 검사의 양성 대조 | 보호 처리를 하지 않은 원시 다각형에서는 **17,050쌍** 교차 검출. 검사가 빈 장식만 확인한 결과가 아님 |
| 상태별 경계·기록 몸통 | 폭마다 서로 다른 여섯 경계; 기록 몸통 다각형 면적 2,000px² 초과 검사 통과 |
| 보존 | 원본 96개 SHA-256 일치; game/data·기존 공용 UI 변경 0 |
| Web export | 성공, `ui_build=battle-r17-20261031-pass2`; SHA-256 갱신 |

근거: [입력](verification/ui-r17/battle-input-results.json), [잉크](verification/ui-r17/ink-text-results.json), [기존 검사](verification/ui-r17/existing-tests.json), [r9](verification/ui-r17/motion-r9/results.json), [보존·빌드](verification/ui-r17/preservation-and-build.json). 최종 import·review·motion·export 단계의 종료 코드와 엔진 오류도 `pass2-*.json`에 남겼다.

PCK는 1차 **50,159,484 → 50,700,856바이트**, **+541,372바이트 (+1.0793%)**다. 공개 r11 기준 49,885,048바이트와 비교하면 누적 **+815,808바이트 (+1.6354%)**다. TTF 원시 크기의 합과 PCK 증가량은 내보내기 리소스 패킹 때문에 다르다. 최종 PCK/WASM 해시는 `docs/version.json`에 있으며 WASM은 기존과 같다.

### 직접 연 렌더와 범위

390×844·360×780의 여섯 상태를 실제 Godot로 다시 렌더했다. [core 390](verification/ui-r17/comparison-core-390.png), [tools 390](verification/ui-r17/comparison-tools-390.png), [core 360](verification/ui-r17/comparison-core-360.png), [tools 360](verification/ui-r17/comparison-tools-360.png)를 직접 열어 네 항목을 확인했다. 기술·보급품·기록에서 제목 밑을 가로지르던 검은 띠가 사라졌고, 본문 숫자/라벨은 산세리프로 굵게 보인다. 적 HP 띠, 기록 문장과 오른쪽 붓 자국 사이도 분리되어 있다. 360 비교의 승인 쪽은 종전처럼 390 시안을 축소한 참고다.

변경 파일은 전투 화면·잉크 코드, 두 본문 TTF와 OFL/import 메타데이터, UI 검사, 라이선스 생성기/내보내기 목록, 빌드 버전 도구, README와 이 보고서, 검증 산출물이다. 추가한 `prepare_r17_body.py`는 글꼴 재생성, `verify_r17_pass2.py`는 단계별 재검증을 맡는다. `audit_r17.py`에는 1차 대비 PCK 변화도 추가했다.

Godot self-contained 엔진이 실행 파일 옆에 설정을 쓰므로 `godot_r17.py`는 지정 엔진의 콘솔/본체와 Web 템플릿을 **이 트리의 `verification/ui-r17/runtime/engine/`로 복사**해 실행한다. 엔진 원본 폴더에는 쓰지 않는다. APPDATA/LOCALAPPDATA/TEMP/TMP도 트리 내부다. 이 복사본은 기존 runtime 제외 규칙을 따른다.

```powershell
python tools/prepare_r17_body.py
python tools/verify_r17_pass2.py checks
python tools/verify_r17_pass2.py review
python tools/review_r17.py
python tools/verify_r17_pass2.py motion
python tools/verify_r17_pass2.py export
python tools/update_version.py
python tools/audit_r17.py
```

이번에도 브라우저에서 최종 WASM을 실행하거나 실물 휴대폰·Safari·Firefox·장시간 진행을 검사하지 않았다. Windows 인증서 저장소 메시지는 남아 있으며 네트워크 검증을 뜻하지 않는다. 기존 시안 차이 중 데이터 기반 숫자, 전장/인물 크롭, 아이콘, 기록 메타데이터 차이는 네 항목의 수정 범위 밖이므로 유지했다. Impeccable 검사 결과는 빈 목록이고, 기존 DESIGN.md/sidecar 불일치는 이번 범위에서 수정하지 않았다.
