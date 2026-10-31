# UI R19 — 승인 시안 배치 일치 및 남은 차이

2026-10-31 · `battle-r19-20261031`

작업·출력은 `battle-r17/` 안에서만 수행했다. Git 명령을 사용하지 않았다. [비교 이미지 입구](verification/ui-r19/index.html), [전체 검사 결과](verification/ui-r19/summary.json), [원본 보존·빌드 감사](verification/ui-r19/preservation-and-build.json)를 함께 제공한다.

측정한 박스 **247개 전부**, 텍스트 기준선 **351개 전부**가 HTML 기준과 2px 이내다. 그러나 **픽셀 단위로 같은 이미지는 아니다.** 새로 작성해야 하는 붓 윤곽, 인쇄 질감, Godot/Chromium의 글리프·이미지 샘플링 차이가 남아 있다. 아래에 이를 별도로 기록한다.

## 16개 항목 대조

| 번호 | 판정 | 구현·직접 확인한 내용 / 다른 이유 |
| --- | --- | --- |
| 1 | 위치 같음, 동작 다름 | 24×24 화살표를 (12, 8.5)에 배치했다. 기존 `world_state.settle("retreat")`는 `explore/rest`에서만 허용하고 `battle`에서는 거부한다. 전투 이탈 경로가 없어 새 규칙·확인 시트를 만들지 않았다. 화살표는 비활성 알파와 설명을 표시한다. |
| 2 | 실전 다름 | 시안의 `· 2층`은 고정 비교 픽스처에만 있다. 현재 world/run 및 battle 데이터에는 실제 층 필드가 없다. `enemy-scene-values.json`의 floor 2는 산정 가정이며 실시간 층 상태로 사용하지 않았다. 탐색 화면의 2층도 world_screen.gd에 직접 적힌 UI 문자열이며 run의 층 값은 아니다. UI는 컨텍스트의 floor/layer가 있을 때 읽을 수 있지만 실전에서는 없는 층을 지어내지 않는다. |
| 3 | 배치 같음 | 작은 턴 라벨과 25px 굵은 숫자를 분리했다. 8칸 번호의 위치·배경·크기를 DOM에서 읽어 반영했다. 실전 턴은 모델, 비교 화면만 턴 3이다. |
| 4 | 배치 같음 | 작은 적 3명을 전장 전체 폭에 배치하고 112px 종이 이름표를 사용한다. `HP 37/37` 접두어를 복구했다. 집행 인형은 우하단, 이름표는 (259,344), ◆는 위쪽이다. 적 1~4명 및 모든 부분집합의 입력 영역도 검사했다. |
| 5 | 배치 같음 | 390 기준 힐데가르트 (37,232,127,145), 테이리스 (27,231,145,146), 집행 인형 (270,235,98,103)이다. 원본 포즈·UV를 사용한다. 정지 몸은 r18의 160px 목표보다 시안의 145/146px를 우선했다. r18 컷인·모션 클립·도트 효과·접촉 타이밍은 유지했다. |
| 6 | 다름 | 검정 경계와 버밀리언 튐·마른 붓 틈을 고정 시드 다각형으로 새로 작성했다. 별도 빨간 사각형을 없앴고 제목이 경계에 걸친다. 추출·트레이스를 금지한 조건에 따라 시안 잉크의 픽셀 윤곽 자체는 복제하지 않았다. |
| 7 | 일부 다름 | 제목 옆 작은 기술 버튼은 삭제했다. 4개 이하 행동은 그리드에 직접 표시하고 마나 부족 카드를 누르면 사유가 있는 기술 시트가 열린다. 10명은 행동이 5~6개여서 마지막 그리드 칸을 `기술 선택` 입구로 썼다. 모든 행동과 방어를 시트에 보존했다. 아래 명단 및 실제 포인터 입력 검사 참조. |
| 8 | 표시 형식 같음 | 의도 문구에서 `/ 심연 0이면 취소` 꼬리를 생략하고 `증기 분출 → 아군 전체` 형태로 표시한다. 생략한 취소 조건은 데이터·규칙에 그대로 있다. 심연 게이지는 정수로 표시하며 소수 부분은 화면에서 숨긴다. |
| 9 | 종류 같음 | 일반 공격은 검, 도발·방어는 방패, 고유/속성 기술은 속성 벡터다. 전방 근무 개시는 눈꽃을 쓴다. 원본 HTML의 작은 아이콘 경로와 새 속성 벡터만 사용했다. |
| 10 | 배치·형식 같음 | 투명 배경, 1px 테두리, 가방/문서 아이콘, 44px 높이로 수정했다. |
| 11 | 수치·기준선 같음, 픽셀 다름 | CSS 크기·굵기·압축 디스플레이 자간을 정적 서브셋과 line-height로 반영했다. 장소 라벨은 측정된 Chromium/Godot advance 차이를 실제 가로 스케일에 보정했다. 기준선은 전부 2px 이내지만 글리프 안티앨리어싱·힌팅과 일부 혼합 굵기의 세부 렌더는 다르다. |
| 12 | 배치·문구 같음, 붓 다름 | `공격할 적을 선택하세요`, 대상 주변 붓 원·모서리, 붉은 ◆, `일반 공격 · 적 1명 선택`, 테두리 취소, 다른 행동의 흐린 상태를 확인했다. 원의 튐 윤곽은 새 벡터라 다르다. 보급품 선택에는 적의 대상 원을 표시하지 않는다. |
| 13 | 구조 같음, 붓 다름 | 상태 제목 뒤 붓, `닫기 ×`, 원본 cutout의 위쪽 정렬, 우측 큰 HP/MP 및 막대, `상태 효과 없음`을 반영했다. 이름 아래 붓의 윤곽·문자 보호 영역은 원본과 다르다. |
| 14 | 배치·동작 같음 | 기술 시트에 닫기는 없고 취소만 있다. 제목·우측 MP·69px 행·7px 간격·마나 부족 사유를 반영했다. 충전 턴 수는 기술 데이터에서 읽는다. 넘치는 실제 기술 목록은 스크롤한다. |
| 15 | 구조 같음, 붓·세부 굵기 다름 | 원본 hp/mp/band/scroll 아이콘, 선택 행 버밀리언, 대상 이름과 HP/MP 줄, 취소/사용하기를 반영했다. 품목 이름의 ` · `는 표시에서 `·`로 줄였다. 제목 붓과 일부 숫자 혼합 굵기는 픽셀 일치하지 않는다. |
| 16 | 구조 같음, 붓 다름 | 새 행동마다 UI 전용으로 턴·행동자 id·이름·행동 이름을 쌓는다. 61px 행, 아군 원본 face/적 픽셀, 두 줄 이름/행동, 구분선, 우측 붓, `닫기 ×`를 구현했다. 복원된 기존 문장 history는 문장으로 표시한다. 이 목록은 저장 스키마에 추가하지 않는다. 시트의 실전 제목은 `전투 기록`, 예시 픽스처만 `예시 전투 기록`이다. |

## 2×2를 넘는 실제 행동

공격·방어를 포함하고 아이템을 제외하여 30명 전원을 세었다. 다음 10명은 마지막 칸에서 기술 시트를 열어 모든 행동에 접근한다. 나머지 20명은 4칸 안에 들어간다.

| 동료 | 행동 수 | 모델의 행동 id |
| --- | --- | --- |
| 마르셀린 | 5 | attack, pshield, ptaunt, personal, guard |
| 레비아 | 5 | attack, rift, chaoswave, personal, guard |
| 우르다 | 5 | attack, hshield, bless, personal, guard |
| 리네트 | 5 | attack, hshield, bless, personal, guard |
| 펠리스 | 6 | attack, heal, acid, tonic, personal, guard |
| 소렐 | 6 | attack, heal, acid, tonic, personal, guard |
| 베렝가 | 5 | attack, hshield, bless, personal, guard |
| 알탄 | 6 | attack, heal, acid, tonic, personal, guard |
| 미코 | 6 | attack, heal, acid, tonic, personal, guard |
| 아델린 | 5 | attack, hshield, bless, personal, guard |

이 10명에 대해 그리드 → 시트 진입, 비공격 행동 전부 존재, 시트 열기가 상태를 바꾸지 않음을 실제 포인터 입력으로 확인했다. 마나 부족 기술은 시트 안에서는 실행할 수 없다.

## 위치·픽셀 비교

[박스 오차 CSV](verification/ui-r19/box-errors.csv) / [기준선 오차 CSV](verification/ui-r19/baseline-errors.csv) / [DOM 원자료](verification/ui-r19/reference-dom.json) / [측정 방법 및 픽셀 수치](verification/ui-r19/comparison-summary.json).

| 항목 | 비교 수 | ≤2px | 최대 오차 |
| --- | --- | --- | --- |
| 박스의 좌·상·우·하 경계 | 247 | 247 | 2.000px |
| 텍스트 기준선 | 351 | 351 | 2.000px |

박스 표에는 전장·정지 아군/적·적 이름표·순서 칸/번호·제목·아군 카드/얼굴·행동/보조 버튼·시트·상태 초상이 포함된다. 기준선 표는 HTML의 텍스트 run을 inline marker로 측정하고 native Label의 ascent/정렬값과 비교한다. 하나의 native 문장으로 합쳐진 run은 같은 줄의 실제 기준선을 비교하며 CSV에 표시했다. **이 표가 모든 글리프 외곽·붓 곡선·텍스처 픽셀의 일치를 뜻하지는 않는다.** 측정한 항목에서 2px를 넘는 예외는 없다.

승인 PNG 두 장의 패널 좌표를 계산하여 각각 390×844로 축소했다. 6상태에 대해 `*-side-by-side.png`, 50% `*-overlay.png`, 강조한 `*-difference.png`를 저장했다. 고정 픽스처는 턴 3, 지정 HP/MP/게이지·행동 순서·선택/기록을 테스트 안에서만 설정한다. 실제 데이터 파일과 사용자 저장은 바꾸지 않는다. 승인 PNG 축소본과 HTML 직접 렌더도 보간 때문에 MAE 약 4.00~4.33 차이가 있다.

| 상태 | RGB 평균 절대 차이 (0~255) | 채널 차이 >16인 픽셀 |
| --- | --- | --- |
| base | 14.215 | 18.336% |
| target | 14.042 | 18.927% |
| status | 13.276 | 19.371% |
| skills | 13.098 | 17.979% |
| supplies | 14.248 | 19.110% |
| log | 15.905 | 19.395% |

따라서 잉크·질감·네이티브 글자 렌더를 포함한 픽셀 동일성은 충족했다고 보고하지 않는다. 특히 전장 아래 경계, 상태/보급품 제목 뒤 붓, 대상 붓 원과 기록의 붓은 승인본과 윤곽이 다르다.

## 검증 결과

| 검사 | 결과 |
| --- | --- |
| import | 성공, 스크립트 오류 0 |
| world / state / route / expansion | 44 / 54 / 41 / 3,350 검사, 실패 0 |
| balance probe | 8파티 × 40시드, 320/320 승리; 밸런스 품질 보증이라는 뜻은 아님 |
| motion / motion_asset / art / licenses | 모두 통과 |
| r17 실제 입력·30명·두 폭·텍스트/잉크 | 3,299 검사, 실패 0 |
| r9 motion integration | 48사례, 944 검사, 실패 0 |
| r18 실제 상태 integration | 180사례, 3,540 검사, 실패 0; contact 전후 HP, 반복 skip, 축소 모드 상태 일치 |
| r18 렌더/효과 | 4,592 검사, 실패 0; 30종 서로 다른 효과 해시, 30개 적 부분집합 배치, 64개 컷인 글자 검사, 90개 contact 사례 |
| r19 고정 렌더·목록·저널 | 859 검사, 실패 0; 12장, 10명 overflow 실제 입력, 신규 구조화 기록·복원 문장 기록 |
| 360×780 | 6상태 렌더, 30명 텍스트 넘침/누락 글리프 0, 적 터치 영역 겹침 0, 잉크/문자 교차 0 |
| 최종 WASM Chrome | 390×844 / 360×780 / 360×780 reduced 세 경로, 실제 입력·시트·고유 행동, 브라우저 오류 0 |
| 보존 | 원본 96개 SHA-256 일치, game/data 29개 파일 바이트 불변, world_screen 외형 코드 불변 |
| Web export | 성공, ui_build 및 PCK/WASM 해시 일치 |

Web은 기존 360×780 canvas stretch를 전투가 열려 있는 동안만 CSS viewport 크기로 맞춘다. 종료할 때 기존 크기를 복구한다. [브라우저 결과와 화면](verification/ui-r19/web/results.json)에 실제 논리 viewport를 기록했다. 로딩·마을·탐색의 소스와 전역 프로젝트 stretch 설정은 바꾸지 않았다.

PCK: **50,708,932 → 52,761,480바이트**, **+2,052,548바이트 (+4.0477%)**. 기존에 export에서 제외되었던 네 원본 cutout PNG를 상태 시트가 사용할 수 있게 포함했고, CSS 굵기/자간용 작은 정적 서브셋 글꼴을 추가했다. 새 캐릭터·이펙트 래스터 파일은 만들지 않았다. WASM 해시는 기존과 같다. 원격 게시·커밋은 하지 않았다.

## 변경 파일 및 검사 갱신

UI 수정: `project/ui/battle_screen.gd`, `battle_ink_r17.gd`, `battle_face_r17.gd`. 얼굴의 84px 고정 프레이밍은 전투 하단 카드에만 켜고 컷인 기본 동작은 유지했다. 새 `battle_image_r19.gd`는 CSS object-fit/object-position에 맞춰 기존 이미지만 그린다. `project/assets/ui-r17/`에 작은 UI 아이콘 SVG, `project/assets/fonts/`에 이름을 바꾼 OFL 서브셋을 추가했다.

`project/export_presets.cfg`의 원본 cutout 제외만 해제했다. `project/tests/export_licenses.gd`에 추가 서브셋 고지를 더했고 생성된 라이선스 문서를 갱신했다.

기존 테스트 변경은 세 가지다. `ui_battle_r17_test.gd`는 없어진 작은 `skills` 버튼 대신 실제 `action:burst` 카드를 눌러 부족 사유 시트를 여는 것으로 바꿨다. `motion_r18_integration.gd`는 화면 제거 뒤 프레임을 처리하고 종료 전 0.5초 동안 마지막 WAV를 배출한다. `motion_r9_integration.gd`에도 종료 전 같은 배출 시간을 추가했다. fast-forward 검사 종료 때 AudioStreamPlaybackWAV가 남던 감사 오류를 해결한 것이며 contact·상태 기대값은 약화하지 않았다. `ui_battle_r18_test.gd`는 변경하지 않았다.

새 도구: `reference_r19.py`, `prepare_type_r19.py`, `verify_r19.py`, `review_r19.py`, `web_smoke_r19.py`, `audit_r19.py`, `report_r19.py`. 새 테스트: `ui_battle_r19_test.gd`. `tools/update_version.py`, README, Web 산출물 및 이 보고서도 갱신했다.

## 직접 연 이미지와 미확인 범위

승인 두 보드와 6개 native 390 결과, 360 6상태 시트, 나란히/겹침/차분을 직접 열어 위 16항목을 대조했다. [390 전체](verification/ui-r19/all-states-390.png), [360 전체](verification/ui-r19/all-states-360.png), [겹침 전체](verification/ui-r19/all-overlay.png), [차분 전체](verification/ui-r19/all-difference.png)를 함께 저장했다. 최종 Web의 상태 초상과 고유 컷인도 직접 열어 원본 포함 및 표시를 확인했다. 붓·텍스트 렌더의 차이는 숨기지 않았다.

실물 iPhone/Android, Safari/Firefox, 360px 미만, 장시간 플레이·저사양 성능, 실제 사용자 저장파일 전체 모음은 검사하지 않았다. 이어하기 문장 기록은 고정 복원 테스트로 확인했다. Windows 인증서 저장소를 읽지 못했다는 기존 엔진 메시지는 남으며 로컬 Web 검사는 외부 네트워크 검증을 뜻하지 않는다.

재실행 순서:

```powershell
python tools/reference_r19.py
python tools/verify_r19.py checks
python tools/verify_r19.py input
python tools/verify_r19.py motion
python tools/verify_r19.py state
python tools/verify_r19.py r18
python tools/verify_r19.py render
python tools/review_r19.py
python tools/verify_r19.py export
python tools/update_version.py
python tools/web_smoke_r19.py
python tools/audit_r19.py
python tools/report_r19.py
```
