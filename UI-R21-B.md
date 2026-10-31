# UI-R21-B — 적 도트 제작 보고서

## 2단계 — 100종 제작 완료

2026-10-31. 지시서·공통 규칙·1단계 보고서·style-spec.json·manifest.json을 UTF-8로 읽고 B 작업 공간에서 수행했다. **승인 샘플 3장의 바이트를 보존하고 나머지 97종을 기본 image_gen으로 제작했다. 최종 PNG는 정본 id와 대응하는 100장이다.**

- 사장님 확인용: [all-100.jpg](verification/enemy-art-r21/all-100.jpg) — **10×10, 1200×1660, 491,208 B**, 이름 표시. 폭 1200 이하·500,000 B 이하.
- 전체 목록: [manifest.json](verification/enemy-art-r21/manifest.json)의 **enemies 100개**. samples는 승인된 3종의 보존 기록이다.
- 계열별 시트: [sheets/](verification/enemy-art-r21/sheets/)의 family-1.jpg~family-30.jpg **30장을 전부 직접 열었다.** 전체 시트와 근접 쌍 16개도 직접 열었다.
- **공통 검사 15개 통과 / 실패 0, 새 아트 검사 1,711개 통과 / 실패 0.** 최종 100장 import도 재실행해 종료 코드 0·엔진 ERROR 0을 확인했다.

### 최종 수치

| 항목 | 결과 |
|---|---|
| 최종 파일 | 100장 = 승인 보존 3 + 신규 97 |
| 캔버스·모드·격자 | 100/100: 1120×1400 RGBA, 정확한 10px 정수 격자 |
| 팔레트 | 공통 32색 안에서만 사용, 개별 사용색 18~32색 |
| 반투명 / 투명 영역 RGB 잔색 | **0 / 0 픽셀** |
| 바닥선 / 생성 원본 가장자리 접촉 | 100/100: y=1329 / **0장** |
| 잡몹 62종 불투명 면적 | 110,800~179,800 px |
| 우두머리 아트 23종 불투명 면적 | 191,700~538,500 px |
| 보스 아트 15종 불투명 면적 | 587,900~702,600 px |
| 전역 면적 순서 | **179,800 < 191,700**, **538,500 < 587,900** |
| SHA-256 / 지각 해시 | 100장 모두 서로 다름, 4,950쌍 비교 |
| 63-bit DCT pHash 최소 Hamming 거리 | **4** — 전체 캔버스 / **12** — 불투명 bbox 정규화 |
| 불변 원본 / 비교한 production 파일 | **96개 변경 0 / 121개 변경 0** |

아트 크기 분류는 mob·swarm→잡몹, elite→우두머리 크기, boss·core→보스 크기다. 원본 게임의 grade·수치·zones.chiefs는 수정하지 않았다. 우두머리 크기 23종 중에는 균열 elite와 공통 elite도 있으며, 실제 zone chief 여부는 개별 기록에 구분했다. 기존 등급별 bbox 한도와 후처리 기준도 유지했다.

전체 100종 시트는 작은 적의 형태도 읽히도록 불투명 bbox를 칸에 맞춰 축소했다. **계열별 시트는 동일 배율 19%**로 실제 크기 차이를 보여 준다. 등급 면적 검사는 원본 크기의 최종 PNG에서 계산했다.

### 재생성과 이유

**17종, 재생성 총 19회.** 철 전차만 최초 포함 4회(재생성 3회), 나머지는 최초 포함 2회다. 지시의 재생성 최대 3회를 넘긴 적은 없다. 기본 도구에는 숫자 seed 인자가 없어 새 독립 호출과 필요한 부분의 편집으로 재생성했으며, seed 값을 직접 지정했다고 주장하지 않는다.

| 대상 | 재생성 이유와 조치 |
|---|---|
| 잿빛 수강생 | 참조 인형의 얼굴판·황동 관절이 섞여, 책상에 엉킨 재가 된 학생 셋으로 재생성 |
| 번진 잉크 | 인형처럼 나온 형상을 일어선 검은 잉크와 떠다니는 추상 글자 흔적으로 수정 |
| 던전 감시관 | 참조 갑옷·망치 형태를 제거하고 쇠사슬을 감은 거구의 옥졸로 수정 |
| 먹물 기사 | 황동 갑옷처럼 나온 재질을 번지는 검은 잉크 윤곽으로 수정 |
| 입 꿰맨 낭독자 | 인형 형태를 사서 망령·꿰맨 입·펼친 금서로 수정 |
| 엉킨 피난민 | 나무 인형처럼 나온 몸을 보따리째 엉킨 피난민으로 수정 |
| 깃펜 사수 | 누락된 사다리를 넣고, 사다리에 매달려 쇠 깃펜을 든 필경사로 수정 |
| 마도 집행 인형 | 생성 원본의 가장자리 접촉을 해소하고 망치 팔을 온전히 포함 |
| 근위 기수 | 원본에 없는 말을 제거하고 찢긴 제국기를 든 도보 기수로 수정 |
| 철 전차 | 운전수·차양 추가 제거 → 면적 170,500 px 부족을 밀집 구도로 수정 → 잘린 바퀴 날과 여백 보완 |
| 쇠관의 왕 | 가장자리 접촉을 해소하고 몸의 쇠관·방패로 든 관 뚜껑을 명확히 표현 |
| 녹아든 군중 | 도구가 첫 출력을 차단해 이미지가 반환되지 않음. 비유혈·비노출의 합쳐진 형태로 두 번째 호출 성공 |
| 가시 순례자 | 원본에 없는 지팡이 제거 |
| 밑바닥의 메아리 | 고정된 해골·이빨 괴물 형태를 제거하고 모양이 변하는 거대한 그림자로 수정 |
| 뒤엉킨 기마 | 오른쪽에서 잘린 꼬리를 복원하고 여백 확보 |
| 문지기 석상 | 녹슨 방패병과 너무 비슷한 금속 경비병 형태를 회색 석재·깊은 균열·석재 방패로 구분 |
| 바람 무당 | 원본에 없는 손에 든 지팡이 제거, 깃털 장식과 빈손 유지 |

[stage2-revisions.json](verification/enemy-art-r21/stage2-revisions.json), 각 호출 JSON·원본 PNG에 전후 이력과 실제 프롬프트를 남겼다. 최초 참조 4장의 인형 형태가 다른 적에 섞인 것을 중간 시트에서 확인한 뒤, 1단계 프롬프트 형식을 유지하면서 **원문과 충실한 영문 직역**을 함께 강조하고 피사체를 복사하지 않도록 조정했다. 서술·이름·행동에 없는 신규 설정을 프롬프트에 추가하지 않았다.

기록된 2단계 호출은 **116건 = 반환 원본 PNG 115건 + 출력 차단 1건**이다. 초기 대량 흐름 중지 때 결과가 반환되지 않은 진행 중 요청은 이 수치에 포함하지 않는다. 초기 Windows 샌드박스 저장 오류와 중지 직전 출력은 recovery-contact*.jpg를 직접 대조해 복구했으며, 관련 JSON에 복구 근거를 남겼다. CLI·직접 API·다른 생성 서비스는 사용하지 않았다.

### 직접 확인과 남은 문제

[stage2-visual-review.json](verification/enemy-art-r21/stage2-visual-review.json)에 최종 시트 30장의 해시와 검수한 근접 쌍 16개를 기록했다. [nearest-canvas.jpg](verification/enemy-art-r21/nearest-canvas.jpg), [nearest-cropped.jpg](verification/enemy-art-r21/nearest-cropped.jpg)도 직접 열었다. 전체 캔버스 최소 거리 4인 쇠 투구 전사/청동 방패 수비병은 검·가죽 갑옷과 수평 창·청동 방패로 구분되며, 정규화 거리는 18이다. 정규화 최소 거리 12인 먹물 기사/그물 던지는 어부는 번지는 잉크 윤곽과 그물·작살로 구분했다.

**검수에서 확인한 잘림·추가 장비·참조 인형 혼입·과도한 유사 형태의 미해결 목록은 0건이다.** 원문이 정체나 고정 외형을 정하지 않은 목소리·그림자는 추상 형태로 표현했고, 정본에 없는 혈통 이름·인물 정체·고유 속성을 게임 설정으로 추가하지 않았다. 약점은 외형 능력으로 바꾸지 않았다. 공통 팔레트 때문에 녹·혈흔·불씨 등의 세부 색은 승인된 32색 안에서 근사되며, 고정된 그림 한 장으로 시간에 따른 형태 변화 자체를 재현한 것은 아니다.

회귀 검사의 대표 화면 5장은 [stage2-regression-preview.jpg](verification/enemy-art-r21/stage2-regression-preview.jpg)로 직접 열어 전투·컷인 배치를 확인했다. 모든 통합 검사 프레임을 육안으로 확인한 것은 아니다. 새 적의 실제 전투 연결·웹 내보내기는 이 갈래에서 하지 않았으며, 게임 코드·데이터 변경 허용 범위 밖이다.

### 검사와 변경 파일

| 검사 묶음 | 2단계 결과 |
|---|---|
| import / export_licenses | 종료 코드 0, 엔진 ERROR 0. 완성 100장 import 최종 재실행 통과 |
| world / state / route / expansion | 44 / 54 / 41 / 3,350 checks, 실패 0 |
| motion / motion_asset / art | 타임라인 PASS / 19 clips PASS / 30명·60 UV·30 cinematics PASS |
| ui_battle r17 / r18 / r19 / r20 | 6,085 / 4,592 / 859 / 1,659 checks, 실패 0 |
| motion r9 / r18 integration | 944 / 3,540 checks, 실패 0 |
| 새 적 아트 검사 | **1,711 checks / 0 failures**, 100장·원문·격자·팔레트·알파·바닥·면적·고유 해시·시트·보존 원본 검사 |

숫자로 출력된 기존 게임 검사 합계는 **21,168 checks / 0 failures**다. 게임 검사 기대값·테스트 코드는 변경하지 않았다. 새 아트 검사의 대상만 지시대로 3종 샘플에서 100종과 30계열·4,950쌍으로 확장했다. 모든 Godot 실행은 허용 경로의 validation-worktree 복사본에서 **python tools/godot_r17.py**를 통해 진행했다. APPDATA 격리·Dummy 오디오·UI의 --position -10000,-10000을 유지했다. 1단계와 같은 검사 전용 CA 설정만 복사본에 사용했다.

- project/assets/enemies-r21/**: 정본 id별 최종 100장. 승인된 abyss_hound·chained_tome·imperial_remnant 해시 보존.
- verification/enemy-art-r21/**: 생성 요청·실제 호출 기록·원본 PNG·100종 manifest·시트·검수·검사 로그·1단계 보존본.
- tools/process_enemy_art_stage2_r21.py: 승인 후처리의 100종 확장, 등급 면적 상한·계열/전체 시트.
- tools/verify_enemy_art_r21.py, tools/verify_enemy_art_stage2_r21.py: 기존 진입점에 2단계 분기 및 100종 검사·격리 회귀 검사.
- UI-R21-B.md: 이 2단계 절을 맨 위에 추가. Python 소스 3개의 문법 검사 통과, 생성된 bytecode 캐시는 제거.

근거: [verification-summary.json](verification/enemy-art-r21/verification-summary.json), [stage2-asset-checks.json](verification/enemy-art-r21/stage2-asset-checks.json), [stage2-perceptual-hashes.json](verification/enemy-art-r21/stage2-perceptual-hashes.json), [stage2-regression-results.json](verification/enemy-art-r21/stage2-regression-results.json), [stage2-import-result.json](verification/enemy-art-r21/stage2-import-result.json), [stage2-final-stats.json](verification/enemy-art-r21/stage2-final-stats.json), checks-stage2/*.log.

게임 코드·데이터·기존 픽셀 원본·기존 초상·사용자 저장은 수정하지 않았다. git 명령도 실행하지 않았다. 공통 규칙의 제외 대상 C:/Clauede Code/dungeon-bot/bot/src/79-sex.lua는 존재만 확인해 이 경로만 목록으로 남긴다. 해당 내용의 참조·이관은 하지 않았다.

---

아래는 1단계 승인 당시의 기록이다.

# UI-R21-B — 적 도트 샘플 1단계

2026-10-31. 작업 지시서와 공통 규칙을 UTF-8로 읽고 B 작업 공간에서만 작업했다. 기본 image_gen으로 서로 다른 계열의 잡몹·우두머리·보스 3종만 제작했다. 나머지 97종은 생성하지 않았으며 승인 후 별도 지시 대상이다.

## 산출물

| 원본 id | 이름 | 계열 | 샘플 등급 | PNG | 불투명 영역 | 사용 색 | 파일 크기 |
|---|---|---:|---|---|---|---:|---:|
| abyss_hound | 심연 사냥개 | 14 | mob | project/assets/enemies-r21/abyss_hound.png | 680×460 | 25 | 14,036 B |
| chained_tome | 쇠사슬 금서 | 4 | chief | project/assets/enemies-r21/chained_tome.png | 790×940 | 30 | 26,015 B |
| imperial_remnant | 제국 근위대의 잔해 | 8 | boss | project/assets/enemies-r21/imperial_remnant.png | 1040×1180 | 30 | 33,966 B |

최종 PNG는 모두 1120×1400 RGBA, 10px 정수 격자, 공통 32색 팔레트 안의 색만 사용한다. 반투명 픽셀 0개, 투명 영역의 RGB 잔색 0개, 바닥 y=1329다. 불투명 면적은 179,800 < 538,500 < 702,600 px로 잡몹 < 우두머리 < 보스를 확인했다.

- 비교 시트: [sample-sheet.jpg](verification/enemy-art-r21/sample-sheet.jpg), **1176×272 / 104,859 B (102.4 KiB)**. 기존 v2 4종 + 새 3종, 모두 원본 픽셀의 14%라는 동일 배율로 배치하고 하단 실루엣을 정렬했다. 폭 1200px 이하·300KB 이하.
- 기준 측정: [style-spec.json](verification/enemy-art-r21/style-spec.json). 원본별 색 수·알파·도트 간격·윤곽선·명암 프로브·바닥 위치, 공통 팔레트 RGB와 선택 방법을 기록했다.
- 이력: [manifest.json](verification/enemy-art-r21/manifest.json), generation-requests.json, generated-paths.json, generated-originals/*.png, boss-correction-prompt.txt. 원본 id·서술·출처 선택자·프롬프트·생성 원본·SHA-256·후처리·최종 측정값을 보관했다.
- 도구: tools/measure_enemy_art_r21.py, tools/process_enemy_art_r21.py, tools/verify_enemy_art_r21.py. 모두 허용된 tools/*enemy_art* 경로다.
- 검사와 복사본, 진단 이력은 verification/enemy-art-r21/** 안에만 있다.

## 원본 측정과 제작 기준

| v2 원본 | 캔버스 | 불투명 RGB 색 수 | 도트 간격 추정 | 어두운 외곽선 추정 | 명암 프로브 단계 | 바닥 y / 높이 |
|---|---|---:|---:|---:|---:|---|
| executor | 1136×1384 | 71,180 | 5px | 11px | 7 | 1313 / 1384 |
| apprentice | 1109×1418 | 50,189 | 9px | 11px | 3 | 1377 / 1418 |
| orb | 1078×1459 | 59,009 | 11px | 13px | 3 | 1382 / 1459 |
| lantern | 1143×1376 | 52,588 | 10px | 13px | 4 | 1298 / 1376 |

도트 간격은 alpha≥128 실루엣 극점의 5~16px 평탄 구간 최빈값, 외곽선은 가장자리에서 RGB 모든 채널≤75인 어두운 구간의 중앙값이다. 명암은 기록한 재질 사각 영역의 휘도를 32 단위로 나누어 면적 5% 이상인 구간 수로 셌다. 서로 다른 재질이 일부 섞이는 추정치이며, 엄격한 수작업 픽셀 규격이라고 주장하지 않는다. 바닥은 alpha≥128 불투명 영역의 최하단이며 발이 없는 구체·등불에는 하단 실루엣을 썼다.

기존 4종에는 미세 색 변화와 반투명 알파가 있어 정확한 공통 원시 격자·제한 팔레트는 없다. 이 사실을 숨기지 않고 측정값과 제작 근사치를 구분했다. 실측 간격 중앙값 9.5px를 반올림해 **10px**, 윤곽선은 **1~2블록**, 명암은 측정 범위인 **3~7단계**, 바닥은 원본 범위 94.3~97.1% 안의 **95%**로 잡았다. 32색 근사에서 원본별 평균 채널 절대오차는 4.906 / 4.096 / 5.586 / 4.037이다. 공통 팔레트는 네 원본의 불투명 픽셀을 모아 근흑색 중복을 합치고 31색 양자화 + 외곽선 1색으로 추출했다. 원본 바이트는 수정하지 않았다.

후처리는 알파 임계값 128 → 불투명 영역 자르기 → 종횡비 유지한 등급별 크기 → nearest 다운샘플 → 3 논리 픽셀 미만 분리 조각 정리 → 공통 32색에 RGB 최근접 양자화(디더 없음) → 내부 1블록 외곽선 → 바닥 정렬 → nearest 10배 확대 순서다. 세부 수치와 제거 조각 수는 manifest에 있다.

## 서술 근거와 원본 대비 차이

정본은 C:/Clauede Code/dungeon-bot/design/enemies.json의 100종과 ENEMIES.md다. families·zones·looks·acts·role·weak를 확인했고 world/의 공개 서술만 맥락으로 사용했다. 비공개 세계관 절은 프롬프트에 넣지 않았다.

- 심연 사냥개: 원본의 검은 개·엉킨 짐승 뼈와 털·물어뜯기를 사용했다. 무기·갑옷·불꽃·새 능력은 추가하지 않았다.
- 쇠사슬 금서: 사람 키의 책과 칭칭 감긴 사슬을 사용했다. JSON 본체의 grade는 elite이며, zones[academy_library].chiefs와 ENEMIES.md 245행에 우두머리로 명시되어 있어 chief 샘플로 택했다. 원본 등급 데이터는 바꾸지 않았다.
- 제국 근위대의 잔해: 뒤엉킨 갑옷·방패 수레 같은 덩어리·창 숲을 사용했다. 실제 바퀴·말·대포를 추가하지 않았다. 최초 생성 방패에 원본에 없는 별/마름모 문양이 생겨 기본 image_gen으로 해당 문양만 제거했다. 수정 전후를 모두 보관했다.

기본 image_gen 호출은 **새 피사체 3회 + 같은 보스의 문양 수정 1회**다. 다른 생성 모델·CLI는 사용하지 않았다. weak는 약점이지 고유 속성이 아니므로 시각 능력으로 바꾸지 않았고, 별도 고유 속성은 원본에 없어 “없음”으로 기록했다. 등급별 픽셀 크기는 검수용 아트 지침이며 원본 게임 수치가 아니다.

## 직접 확인

비교 시트와 최종 PNG 3장을 view_image로 직접 열었다. 뼈·황동·암회색의 색 관계와 왼쪽 위 빛 방향은 기존 적과 이어지고, 개·책·방패/창 덩어리는 실루엣으로 구분된다. strict 10px 격자와 32색·이진 알파를 적용한 새 그림은 미세하게 부드러운 v2 원본보다 외곽선이 단단하고 거칠다. 작은 사냥개는 비교 시트에서 뼈 세부가 줄지만 개 형태는 읽힌다. 이 차이를 승인 판단에 남긴다.

회귀 검사 대표 화면 5종도 [regression-preview.jpg](verification/enemy-art-r21/regression-preview.jpg)로 직접 열어 기존 전투·컷인 배치가 유지되는지 확인했다. 테스트가 만든 모든 개별 프레임을 육안 검사한 것은 아니다. 새 적을 실제 전투에 연결한 상태는 확인하지 않았다. 연결은 갈래 A의 범위다.

## 검증

**최종 결과: 공통 검사 15개 실행 통과 / 실패 0, 새 아트 검사 40개 통과 / 실패 0.** 숫자로 출력된 게임 검사 합계는 **21,168 checks / 0 failures**이며, 별도로 타임라인·19개 모션 클립·30명/60 UV 프레임 아트 검사를 통과했다. 최종 로그의 엔진 ERROR도 0개다.

| 검사 | 결과 |
|---|---|
| import | 종료 코드 0 / ERROR 0 |
| world_test | 44 checks / 0 failures |
| state_test | 54 checks / 0 failures |
| route_test | 41 checks / 0 failures |
| expansion_test | 3350 checks / 0 failures |
| motion_test | 타임라인 PASS |
| motion_asset_test | 19 clips PASS |
| art_test | 30 characters / 60 UV frames / 30 cinematics PASS |
| export_licenses | 정상 출력 / 종료 코드 0 |
| ui_battle_r17_test | 6085 checks / 0 failures |
| ui_battle_r18_test | 4592 checks / 0 failures / 30 distinct effect hashes |
| ui_battle_r19_test | 859 checks / 0 failures |
| ui_battle_r20_test | 1659 checks / 0 failures |
| motion_r9_integration | 944 checks / 0 failures |
| motion_r18_integration | 3540 checks / 0 failures |

원본 보존: **ASSET-HASHES.json 96개 중 변경 0개**. production의 game/ui/data/scenes/tests/licenses/assets/src에서 비교한 **121파일 변경 0개**다. 새 도구 3개의 Python 문법 검사도 통과했다. 기대값·게임 테스트 코드 변경은 0개다.

근거: [verification-summary.json](verification/enemy-art-r21/verification-summary.json), [regression-results.json](verification/enemy-art-r21/regression-results.json), [asset-checks.json](verification/enemy-art-r21/asset-checks.json), checks/*.log, production-source-hashes-before/after.json, validation-copy-proof.json. 40개 새 검사는 최종 파일 수, 정본 id/서술, 서로 다른 계열, 등급 크기 순서, 캔버스, 격자, 팔레트, 알파, 바닥, 여백, 해시, 비교 시트 상한과 불변 원본을 확인한다.

**실행 위치:** 허용 경로 안인 verification/enemy-art-r21/validation-worktree에 production 프로젝트와 기존 tools/godot_r17.py를 바이트 그대로 복사했다. 모든 Godot 실행은 이 복사본에서 python tools/godot_r17.py를 통했고, 기본 APPDATA 격리·Dummy 오디오를 유지했다. UI 검사는 --position -10000,-10000을 사용했다. 원래 프로젝트에 import 캐시·검사 화면·라이선스 결과를 쓰지 않기 위한 격리다.

**재검사 이력:** 관리형 Windows 환경에서 루트 인증서 저장소를 읽지 못해 Godot 시작 시 오류가 반복됐다. 검사 복사본의 override.cfg에 network/tls/certificate_bundle_override, 검사 전용 편집기 설정에 network/tls/editor_tls_certificates를 지정해 설치된 certifi CA 번들을 읽도록 했다. 해당 설정의 용도는 [공식 ProjectSettings 문서](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-network-tls-certificate-bundle-override)와 [공식 EditorSettings 문서](https://docs.godotengine.org/en/stable/classes/class_editorsettings.html#class-editorsettings-property-network-tls-editor-tls-certificates)를 확인했다. production 설정은 수정하지 않았다.

r18은 4592 checks / 0 failures 뒤 리소스 1개가 종료 시 사용 중이라는 오류가 한 번 나왔다. 같은 테스트를 --verbose로 다시 실행하자 종료 코드 0, ERROR 0이며 재현되지 않았다. 원인을 고쳤다고 주장하지 않고 이전 로그를 retry-before-editor-fix에 남겼다. 초기 인증서 진단은 initial-certificate-diagnostic, 설정 이력은 validation-environment.json에 있다. 수집기의 성공 판정은 테스트마다 다른 기존 “PASS/0 failures/FAILURES 0” 출력 형식을 인식하도록 수정했으며 게임 검사의 기대값은 바꾸지 않았다.


## 범위와 중지 상태

게임 코드·데이터·기존 초상·기존 픽셀 원본·저장 데이터는 수정하지 않았다. git 명령은 실행하지 않았다. 웹 내보내기나 배포는 이번 1단계에서 하지 않았다. 100종 전체 제작과 게임 연결은 이번 결과에 포함하지 않는다. **샘플 3장 단계에서 중지하며 나머지 97종은 승인 후 다음 지시로 진행한다.**
