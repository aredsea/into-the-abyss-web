# r18 전투 크기·도트 이펙트·고유 스킬 컷인

2026-10-31 · `battle-r18-20261031`

`battle-r17/` 안에서 구현·검증·Web 내보내기를 수행했다. Git 명령은 사용하지 않았다. 규칙·수치·저장 구조는 변경하지 않았다. 검수 입구는 [움직이는 미리보기와 렌더 목록](verification/ui-r18/index.html)이다.

## 바뀐 동작

- 전장의 동료를 75/80px 높이의 논리 도트로 원본에서 메모리 샘플링한 뒤 **정수 2배 + NEAREST**로 표시한다. 원본 파일을 다시 저장하거나 새 캐릭터·무기·자세를 그리지 않았다. 기존 네 명의 대기·공격·돌진 클립도 같은 전투 크기를 쓴다. 무기 부착과 회전은 기존 클립 좌표를 따른다.
- 동료는 왼쪽 앞쪽, 적은 오른쪽 뒤쪽에 배치했다. 전장 높이·아래 제목·행동·시트·아군 카드 위치는 유지했다. 적 터치 영역은 후방 영역을 서로 겹치지 않게 나눈다. 이동하는 몸보다 이름표를 위에 표시하고, 컷인 동안은 이름표를 숨긴다. 좁은 적 이름표에서는 `HP` 접두어를 생략하고 현재/최대 숫자와 2px 막대를 유지했다.
- **30명 모두** 버밀리언/검정 사선 붓 띠, 원본 얼굴 크롭, 압축 Noto 제목을 거친다. 기존 네 명의 고유 스킬 클립은 0.6초 컷인 뒤에 시작한다. 원본 얼굴은 `battle_face_r17.gd`를 그대로 사용한다. 제목과 이름/속성, 초상은 별도 공간을 사용한다.
- 시전 집결 → 이동 궤적 → 명중 문양과 굵은 파편 → 0.4초 이내 잔상을 공통 코드로 그린다. 모든 효과 획은 3px 격자의 사각 블록이며 안티앨리어싱 선을 쓰지 않는다. 명중 파편은 대상 높이의 약 1.0~1.4배 범위를 덮는다. 전장 밖으로 나가는 효과 블록은 잘라 UI 글자를 침범하지 않게 했다. 속성색 화면 표시는 최대 알파 0.18, 피격 흰 실루엣은 엔진의 두 process 프레임이다.
- 고유 스킬은 컷인 포함 **최대 1.685초**(1.65초 타임라인 + 최대 0.035초 hitstop)다. 일반 행동은 기존 클립/일반 행동 길이를 유지한다. 건너뛰기는 즉시 종료한다. 피해·자원·행동 결과는 기존 모델의 단일 해석을 유지하고, 화면 HP는 기존 contact 콜백에서 갱신한다.
- 모션 축소에서는 0.36초, contact 0.12초의 정적 표시를 쓴다. 돌진·흔들림·화면 번쩍임·흰 피격 번쩍임·입자 이동을 생략한다. 피해 숫자도 위로 이동하지 않는다. 기존 마을 미리보기 호출부는 변경하지 않았고, 완료 후 원래 도트가 다시 나타나는 경로를 검사했다.

## 크기 측정

투명한 Godot SubViewport에서 원본 표시 코드와 새 표시 코드의 알파 > 0.1 픽셀 경계를 측정했다. 두 폭 × 30명 × 전후 = **120회**다. 전장의 픽셀 단위와 같다.

| 인물/대상 | 390×844 전 → 후 | 360×780 전 → 후 |
| --- | --- | --- |
| 힐데가르트·바르구트·테이리스·베렝가의 대기 몸 | 145 → 160px | 96 → 148px |
| 동료 30명 전체 새 몸 | 160px | 148~150px |
| 작은 적 3종의 표시 래스터 높이 | 75 → 106px | 68 → 96px |
| 마도 집행 인형의 표시 래스터 높이 | 103 → 140px | 65 → 92px |

브리프의 기존 몸 약 80px는 추정치였다. 실제 코드/알파 측정은 위와 달랐으며, 특히 390폭의 기존 네 명은 145px였다. 따라서 **전원을 기존 실측의 정확히 2배로 키웠다는 주장은 하지 않는다**. 새 몸을 요청 범위인 약 150~170px에 맞췄다. 메모리 샘플링으로 미세 디테일은 줄지만 흐린 보간은 생기지 않는다. 적은 약 1.36~1.41배다.

## 고유 효과 목록

기존 fx ID의 아이디어를 유지하고 블록 획·규모·파편을 확장했다. [30종 효과만 모은 시트](verification/ui-r18/all-30-effects.png)에는 이름·초상·캐릭터를 제외한 실제 Godot 효과 프레임을 담았다.

| 인물 | fx ID / 문양 |
| --- | --- |
| 마르셀린 | `shelter` 방패·방사선 |
| 나란 | `fox_brand` 화살·낙인·불티 |
| 테이리스 | `ice_nova` 얼음 결정·환형 폭발 |
| 할드리크 | `contract_wall` 세 계약 방벽 |
| 에르데네 | `wolf_roar` 연속 포효 파동 |
| 비앙카 | `crosscut` 교차 참격 |
| 사야 | `shadow_snare` 그림자 속박 격자 |
| 게르다 | `bolt_pierce` 관통 화살·전격 고리 |
| 유디트 | `three_curses` 세 저주 인장 |
| 레비아 | `void_charge` 공허 핵·회전 고리 |
| 우르다 | `ice_amplify` 얼음 결정·증폭 표식 |
| 리네트 | `sanctuary` 성역 돔·십자 |
| 펠리스 | `antidote` 해독 약병·기포 |
| 소렐 | `sap_rain` 수액 비·바닥 파문 |
| 티카 | `flame_combo` 이중 화염 참격 |
| 헤드비히 | `thunder_sigil` 전격 인장·낙뢰 |
| 힐데가르트 | `frost_guard` 서리 방패·결정 |
| 베렝가 | `triage` 치유 십자·회전 파문 |
| 군힐트 | `command_strike` 수직 일격·파편 |
| 바르구트 | `blink_slash` 수평 잔격·번개 참격 |
| 알탄 | `flask_network` 연결된 네 약병 |
| 콜레트 | `silence_seal` 봉인 고리·침묵선 |
| 셀바 | `execution` 처형 반월·파편 |
| 오르넬 | `root_arrow` 화살·뿌리 |
| 자하르 | `fire_sweep` 화염 횡격 |
| 요르드 | `contract_interest` 회전 계약 인장 |
| 라비니아 | `stamp_bolt` 사각 날인·낙뢰 |
| 토베 | `ice_challenge` 빙결 도전·사방 결정 |
| 미코 | `infusion` 주입 약병·증폭 표식 |
| 아델린 | `prayer_guard` 기도 돔·성표 |

일반 공격·공용 기술은 ice/bolt/fire/holy/wind/dark/none 색과 해당 계열의 작은 문양을 쓴다. 방어는 방패, 도발은 파동, 회복/보급품은 십자를 쓴다. 적 공격도 같은 시전·이동·명중·잔상 경로다. `frames/general-*.png`에 7속성 × 공격/방어/도발/보급품/적 행동 **35장**을 저장했다.

## 검증 결과

| 검사 | 결과 |
| --- | --- |
| import | 성공, 인증서 저장소 메시지 외 엔진/스크립트 오류 0 |
| world / state / route / expansion | 44 / 54 / 41 / 3,350 검사, 실패 0 |
| balance | 7파티 × 40시드, 280/280 승리; 기존 probe 결과이며 난이도 합격 판정은 아님 |
| motion / motion_asset / art / licenses | 통과; 19클립, 30인물·60 UV프레임·30연출 |
| 기존 r17 실제 입력 | 2,931검사, 실패 0; 여섯 상태 × 두 폭 렌더 |
| 기존 r9 통합 | 48사례, 944검사, 실패 0 |
| r18 실제 게임 상태 통합 | 30명 × 두 폭 × 일반/skip/reduced = 180사례, 3,540검사, 실패 0; 결과 상태 일치·contact 전 HP 유지·contact 후 HP 일치·재해석 없음 |
| r18 렌더·크기·컷인·효과 | 4,592검사, 실패 0 |
| 적 조합 | 가능한 비어 있지 않은 15조합 × 두 폭 = 30사례, 터치 rect 겹침·이름 넘침 0 |
| 컷인 | 전투 60 + 마을 미리보기 4 = 64사례, 줄 넘침·누락 글리프·초상/글자 겹침·전경 잉크/글자 교차 0 |
| 30종 효과 프레임 해시 | 서로 다른 SHA-256 30개; 동일 시각 재렌더 픽셀 불일치 0 |
| 반복 건너뛰기·모션 축소 | 30명 × 3모드 = 90사례, contact 정확히 1회; 축소 모드 이동/흔들림/flash 없음 |
| 보존 | 원본 96개 SHA-256 일치; game/data 29개 파일 바이트 일치; 마을/탐색 화면 코드 불변 |
| Web export | 성공; `docs/version.json`의 PCK/WASM 해시 일치 |

근거: [단계별 기존 검사](verification/ui-r18/checks.json), [r17 입력 실행](verification/ui-r18/input.json), [r9 실행](verification/ui-r18/motion.json), [실제 게임 상태 180사례](verification/ui-r18/state-integration/results.json), [r18 세부 측정·효과 해시](verification/ui-r18/r18-results.json), [보존·빌드 감사](verification/ui-r18/preservation-and-build.json).

PCK: **50,701,272 → 50,708,868바이트**, **+7,596바이트 (+0.0150%)**. 래스터 이펙트 파일을 추가하지 않았다. WASM 해시는 기존과 같다. 최종 배포 식별자와 두 파일 해시는 [version.json](docs/version.json)에 있다. `docs/`를 갱신했으며 원격 게시·커밋은 수행하지 않았다.

## 직접 연 산출물

- [기본 390](verification/ui-r18/base-390.png), [기본 360](verification/ui-r18/base-360.png): 앞쪽 동료와 적의 확대, 발/머리, 적 이름표와 제목 간격을 확인했다.
- `contact-390-01.png`~`06.png`, `contact-360-01.png`~`06.png`: 각 인물의 실제 고유 행동을 모델에서 실행한 뒤 컷인과 contact 직후 프레임을 캡처했다. 방벽/치유는 아군 쪽, 공격은 실제 적 대상 쪽에 표시된다. [검수 목록](verification/ui-r18/index.html)에 12개 시트 링크가 있다.
- [테이리스 고유 스킬](verification/ui-r18/teiris-personal-360.webp), [나란 고유 스킬](verification/ui-r18/naran-personal-360.webp), [힐데가르트 일반 공격](verification/ui-r18/hildegard-attack-360.webp): 폭 360, Godot 프레임 캡처를 묶은 animated WebP다. 각각 **503,384 / 425,130 / 398,840바이트**로 1.5MB 이하이며, 원본 프레임·인코딩 크기는 [previews.json](verification/ui-r18/previews.json)에 있다. 각 애니메이션과 시점별 스트립을 열어 컷인 진입/종료·이동·명중·복귀를 확인했다.
- 마을 미리보기에서는 컷인 동안 도트 몸을 숨겨 초상과 겹치지 않게 했다. `world-preview-*-*.png` 네 장과 완료 후 원래 도트 복귀 경로를 확인했다.

## 변경 파일과 재실행

기존 UI 수정: `battle_screen.gd`, `combat_presentation.gd`, `combat_fx.gd`, `signature_sequence.gd`, `motion_library.gd`. `motion_library.gd`의 전투 도트 옵션 기본값은 꺼져 있어 기존 마을 표시 경로를 유지한다.

새 UI: `battle_body_r18.gd`(원본의 메모리 샘플링), `pixel_brush_r18.gd`(격자 블록·전장 클리핑), `signature_fx_r18.gd`(30종 문양). 새 검사: `ui_battle_r18_test.gd`, `motion_r18_integration.gd`. Godot가 해당 `.uid`를 생성했다. 기존 `ui_battle_r17_test.gd`와 `motion_r9_integration.gd`는 수정하지 않았다.

도구: `verify_r18.py`, `review_r18.py`, `audit_r18.py`를 추가하고 `update_version.py`의 빌드 식별자를 갱신했다. README 상단 요약, 이 보고서, Web 산출물과 `verification/ui-r18/`도 변경/추가했다. Godot는 계속 `godot_r17.py`를 거쳐 실행했고 APPDATA·임시 파일·self-contained 엔진 설정은 이 트리의 기존 격리 runtime 경로에 썼다.

```powershell
python tools/verify_r18.py checks
python tools/verify_r18.py input
python tools/verify_r18.py motion
python tools/verify_r18.py state
python tools/verify_r18.py render
python tools/review_r18.py
python tools/verify_r18.py export
python tools/update_version.py
python tools/audit_r18.py
```

## 남은 한계

실물 iPhone/Android, Safari/Firefox, 저사양 기기 성능, 장시간 플레이와 최종 WASM의 브라우저 실행은 이번에 확인하지 않았다. 로컬 Playwright 모듈이 없어 브라우저 재검사를 진행하지 않았으며, Godot 렌더·입력·모델 검사와 Web export를 근거로 보고한다. 원격 공개판도 이번에 게시/검사하지 않았다. 360px 미만 화면은 검증 범위 밖이다.

원본 해상도와 75/80px 논리 도트의 샘플링 때문에 세부 장식이 단순해진다. 일부 큰 무기·적 실루엣은 서로 가까이 보인다. 이름표는 별도 전경으로 보호하지만, 고유 효과가 큰 순간에는 대상 몸을 의도적으로 가린다. UI의 시각적 최종 수용 여부는 사용자 검토가 필요하다.

Windows 인증서 저장소를 읽지 못했다는 기존 엔진 메시지는 남아 있다. 네트워크 동작을 검증했다는 뜻은 아니다. 디자인 기계 검사 목록은 비어 있지만 GDScript 시각 품질 인증은 아니다. 기존 DESIGN.md와 `.impeccable/design.json`의 시점 불일치는 이번 범위에서 수정하지 않았다. 필요하면 별도 `document` 작업으로 갱신할 수 있다.
