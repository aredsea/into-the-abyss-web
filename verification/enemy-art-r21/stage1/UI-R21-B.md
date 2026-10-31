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
