# 1c — 30명 배경 잔여·흰 테두리 정리 · 2026-10-31

**30/30명 마스터 + 30명 × 10종 = 300/300개 칸별 크롭 제작. 새 픽셀 검사 실패 0, 원본 해시 96/96 일치.** 지정한 외곽 4px 띠와 닫힌 배경 영역의 흰 계열 잔여는 버밀리언·검정·종이색 모두 **0픽셀**이다. 30명별 400% 빨간 바탕 확대 이미지와 원본/세 바탕 대조판을 직접 열었다. 게임 코드·데이터는 바꾸지 않았다.

## 방법·보존 범위

원본 525×768 WEBP를 그대로 디코딩하고 576×768 RGBA 마스터의 `(25,0)`에 1:1 배치했다. 좌 25px·우 26px는 투명 여백이다. 각 원본 좌상단 35×35의 중앙값으로 배경색을 실측했다(대부분 254, 힐데가르트·셀바·자하르 246, 마르셀린 248 등). 테두리에 연결된 배경과 직접 확인한 닫힌 배경 성분을 제거했다. 색 거리·채도·연결성·수동 영역을 함께 사용했다.

RGB 변경은 소스 실루엣 안쪽 **최대 6px** 띠에 한정한다. 가장자리 coverage `a`를 배경 `B`와 5px 이상 안쪽 전경으로 추정하고 `C=(I-(1-a)B)/a`로 분리했다. 전경 가까운 값의 +10 상한으로 밝은 압축 잔여를 억제한 뒤 **2px choke + 1px feather**를 적용했다. 안쪽(6px 띠 밖) 사람 RGB 변경 **0픽셀**, 알파 처리 띠 밖 사람 알파 변경 **0픽셀**이다. 원본 파일 바이트와 디코딩 후 새 PNG의 RGB 변경을 구분했다. 총 RGB 변경 **94,592픽셀**, 기록된 닫힌/수동 배경 정리 **95,299픽셀**. 얼굴·머리·옷·노출을 재생성하거나 색을 일괄 보정하지 않았다.

애매한 영역은 원본을 보고 지정했다. 아델린의 흰 귀·베일과 자하르의 흰 뿔은 전경 보호 다각형, 리넷·콜레트의 흰 블라우스는 몸통 보호 다각형을 사용했다. 밝은 귀 테두리는 12명에서 귀 위치 다각형을 지정한 뒤 **원본의 유색/잉크 외곽 픽셀 사이 세로 구간**으로 다시 좁혀 흰 배경까지 보호하지 않게 했다. 긴 머리 아래, 뿔 구멍, 팔/몸 사이, 꼬리 안쪽은 인물별 위치를 지정했다. 모든 좌표·실측색·색 거리·선택 성분·면적은 `manifest.json`의 각 인물 `parameters`와 `tools/dehalo_portrait_r21.py`에 있다. 검사 실루엣·구멍·RGB 띠 마스크도 각각 `reference/`, `bands/`, `matte/`에 저장했다.

## 기계 판정과 직접 확인

합성 바탕은 `#E8452A`, `#111111`, `#EEE6D6`. 출력 알파로 검사 영역을 다시 만들지 않고 **원본에서 구한 choke 전 실루엣**을 고정해 바깥 4px 띠와 표시된 닫힌 배경 영역을 검사한다. 휘도 `Y=0.2126R+0.7152G+0.0722B`, 흰 계열 조건은 `Y > min(Y_바탕+60,245)` 및 `max(R,G,B)-min(R,G,B)<24`다. 종이색에 +60만 적용하면 255를 넘는 불가능한 문턱이 되므로 종이색은 **Y>245**로 검사했다. 각 바탕의 표 숫자는 **외곽+구멍 합계**이며 두 개별 값도 `validation.json`에 있다. 투명해야 할 배경에 알파가 남은 픽셀도 **0**이다.

추가로 실루엣 안쪽 2.5px의 밝은 중성 픽셀을 찾아 원본과 대조했다. 간단한 자동 흰 소재 제외 뒤에도 **160개 후보**가 잡혔으며, 원본 귀 테두리·흰 털/머리·은색 갑옷 반사 등 전경 소재다. 이 안쪽 후보를 외부 배경 잔여 수치에 섞거나 지워서 0으로 만들지 않았다. 외곽 0이라는 숫자만으로 사람의 흰 소재까지 없다고 주장하지 않는다.

| 인물 | RGB 띠 폭 px | RGB 변경 px | 사람 경계 알파 변경 px | 내부 RGB 변경 | 흰 잔여 빨강 / 검정 / 종이 | 400% 직접 확인 |
|---|---:|---:|---:|---:|---:|---|
| marceline | 6 | 3,585 | 7,908 | 0 | 0 / 0 / 0 | 확인 |
| naran | 6 | 2,767 | 7,274 | 0 | 0 / 0 / 0 | 확인 |
| teiris | 6 | 3,187 | 7,907 | 0 | 0 / 0 / 0 | 확인 |
| haldric | 6 | 3,470 | 9,373 | 0 | 0 / 0 / 0 | 확인 |
| erdene | 6 | 3,418 | 9,694 | 0 | 0 / 0 / 0 | 확인 |
| bianca | 6 | 2,651 | 6,423 | 0 | 0 / 0 / 0 | 확인 |
| saya | 6 | 4,616 | 12,176 | 0 | 0 / 0 / 0 | 확인 |
| gerda | 6 | 2,884 | 9,038 | 0 | 0 / 0 / 0 | 확인 |
| judith | 6 | 2,811 | 7,459 | 0 | 0 / 0 / 0 | 확인 |
| levia | 6 | 2,762 | 6,809 | 0 | 0 / 0 / 0 | 확인 |
| urda | 6 | 3,239 | 8,736 | 0 | 0 / 0 / 0 | 확인 |
| lynette | 6 | 3,841 | 8,439 | 0 | 0 / 0 / 0 | 확인 |
| felice | 6 | 3,679 | 9,758 | 0 | 0 / 0 / 0 | 확인 |
| sorel | 6 | 2,741 | 6,367 | 0 | 0 / 0 / 0 | 확인 |
| tika | 6 | 4,056 | 9,489 | 0 | 0 / 0 / 0 | 확인 |
| hedwig | 6 | 2,150 | 6,402 | 0 | 0 / 0 / 0 | 확인 |
| hildegard | 6 | 3,414 | 8,672 | 0 | 0 / 0 / 0 | 확인 |
| berenga | 6 | 1,625 | 4,022 | 0 | 0 / 0 / 0 | 확인 |
| gunhild | 6 | 4,274 | 9,329 | 0 | 0 / 0 / 0 | 확인 |
| bargut | 6 | 3,675 | 10,252 | 0 | 0 / 0 / 0 | 확인 |
| altan | 6 | 2,556 | 6,262 | 0 | 0 / 0 / 0 | 확인 |
| colette | 6 | 2,343 | 6,297 | 0 | 0 / 0 / 0 | 확인 |
| selva | 6 | 4,331 | 10,552 | 0 | 0 / 0 / 0 | 확인 |
| ornel | 6 | 2,296 | 7,340 | 0 | 0 / 0 / 0 | 확인 |
| zahar | 6 | 4,785 | 10,597 | 0 | 0 / 0 / 0 | 확인 |
| jorund | 6 | 3,185 | 8,505 | 0 | 0 / 0 / 0 | 확인 |
| lavinia | 6 | 2,147 | 6,846 | 0 | 0 / 0 / 0 | 확인 |
| tove | 6 | 3,442 | 9,101 | 0 | 0 / 0 / 0 | 확인 |
| miko | 6 | 3,472 | 9,128 | 0 | 0 / 0 / 0 | 확인 |
| adeline | 6 | 1,190 | 4,000 | 0 | 0 / 0 / 0 | 확인 |

30명 모두 빨간 바탕의 외곽 발췌 6곳씩을 400%(nearest-neighbor ×4)로 직접 열어 봤다. 머리·귀/뿔·어깨·꼬리의 선택 외곽에서 흰 배경 테두리를 관찰하지 못했다. 원본/빨강/검정/종이 대조판 6장으로 전체 구도·흰 소재도 확인했다. 초기에 발견한 베일·뿔·귀·블라우스 오분류와 긴 머리 안쪽 흰 조각은 수정하고 다시 열었다. 직접 확인 기록은 `visual-review-1c.json`에 최종 이미지 SHA-256과 함께 남겼다.

## 산출·변경 파일

- `project/assets/portraits-r21/*-upperbody.png`: 마스터 **30개**, 576×768 RGBA.
- `project/assets/portraits-r21/slots/*.png`: 원본 해상도 칸별 안쪽 크롭 **300개**. `preview-placement.json`에 300개 좌표·실제 파일 크기·목표 칸 크기 기록. 기존 실측 10종 치수 유지. 생성·outpaint **0회 / 0픽셀**.
- `verification/portraits-r21/all-30.jpg`: 빨간 바탕 상세 칸 30명 격자, **1200×1140, 387,507 bytes** (폭≤1200, ≤500,000 bytes).
- `verification/portraits-r21/edge-zoom.jpg`: 힐데가르트·마르셀린·나란 400% 외곽, **960×2076, 162,894 bytes** (≤300,000 bytes).
- `verification/portraits-r21/edge-zooms/*.jpg`: 인물별 확대 **30장**. `composites/*.png`: 세 바탕 합성 **90장**. `review-pages/*.jpg`: 원본·세 바탕 대조 **6장**. `slot-previews/*.png`: 목표 치수·사선 마스크 적용 RGBA **300개**. 리사이즈는 premultiplied alpha로 처리해 투명 RGB의 흰색이 섞이지 않게 했다.
- `verification/portraits-r21/{manifest,validation,preview-placement,visual-review-1c,sheet-info,baseline-1c,suite-results-1c,final-import}.json`, `logs-1c/*`: 수치·회귀 검사 근거.
- `tools/dehalo_portrait_r21.py`: 재현은 `build` → `review` → `verify`. `suite`는 격리 복제본 공통 검사, `final-import`는 최종 PNG 갱신 후 추가 import. `report`는 실제 직접 확인을 끝낸 뒤에만 사용한다.
- `UI-R21-C.md`: 이 1c 절을 맨 위에 추가. 시작 시 1b 자료는 `verification/portraits-r21/attempt-1c-before/`에 복사 보존했다. 아래 1b·1단계 본문은 과거 결과다.

## 공통 검사·수정 범위

공통 규칙의 **15/15 명령 exit 0**. 수치를 출력한 시험 합계 **21,168 checks / 0 failures**. 최종 330 PNG를 SHA-256까지 대조해 복제본에 갱신한 **추가 import도 exit 0**이다. 기대값 변경 0. 결과 파일·저장·라이선스 생성은 허용 경로 안의 `verification/portraits-r21/test-workspace-1c/` 복제본에서만 일어나게 했고, Godot는 그 안에서도 `tools/godot_r17.py`(격리 APPDATA·Dummy 오디오)로만 실행했다.

| 검사 | 종료 | 결과 |
|---|---|---|
| import | exit 0 | 완료 |
| world_test | exit 0 | WORLD TESTS: 44 checks, 0 failures |
| state_test | exit 0 | COMBAT CHECKS: 54; FAILURES: 0 |
| route_test | exit 0 | ROUTE TESTS: 41 checks, 0 failures |
| expansion_test | exit 0 | EXPANSION CHECKS 3350 FAILURES 0 |
| motion_test | exit 0 | MOTION TIMELINE PASS: contact, hitstop, pause, speed, skip, large delta |
| motion_asset_test | exit 0 | MOTION ASSET PASS: 19 clips, original starts, natural recovery, timing, attachments and mappings |
| art_test | exit 0 | PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion |
| export_licenses | exit 0 | 완료 |
| ui_battle_r17_test | exit 0 | R17 BATTLE UI 6085 CHECKS / 0 FAILURES |
| ui_battle_r18_test | exit 0 | R18: 4592 checks / 0 failures; 30 distinct effect hashes |
| ui_battle_r19_test | exit 0 | R19: 859 checks / 0 failures |
| ui_battle_r20_test | exit 0 | R20: 1659 checks / 0 failures |
| motion_r9_integration | exit 0 | R9 INTEGRATION: 944 checks / 0 failures |
| motion_r18_integration | exit 0 | R18 STATE INTEGRATION: 3540 checks / 0 failures |

각 실행에는 환경 진단 `ERROR: Failed to read the root certificate store.`가 있다(공통 15회 + 최종 import 1회). 스크립트 시험 실패와 구분하며 로그 오류 0으로 보고하지 않는다. 시작 보호 파일 **2,587개 변경 0**, 허용 밖 새 파일 **0**, `ASSET-HASHES.json` **96/96 일치**. git 명령을 실행하지 않았다.

## 원본 대비 차이·못 한 것

원본의 옆/아래 프레임 잘림은 그대로다. 2px choke로 아주 가는 잔머리와 바깥 선 일부가 줄었고 400%에서 픽셀 계단이 보인다. RGB 수정과 알파 변경은 보고한 가장자리 띠에 있다. 흰 귀·털·옷 자체는 보존했으나, 모든 외곽 픽셀을 한 픽셀씩 육안 대조했다는 뜻은 아니다. 얼굴 작은 칸은 원본 안쪽 크롭이라 긴 귀·머리 끝이 일부 잘린다. 원본 안에 들어가는 300개 크롭으로 처리해 새로운 몸·옷·무기를 만들지 않았다.

게임 화면 연결, 실제 UI에서의 샘플링·배율별 실행 확인, 웹 내보내기는 하지 않았다. 게임에서 축소할 때도 premultiplied-alpha 리사이즈 또는 동등한 투명 경계 처리가 필요하다. 이 보고서의 육안 판정 범위는 저장된 확대 발췌와 세 바탕 대조판이다.

---

# 1b — 원본 RGB 복사 + 알파 매트 · 2026-10-31

**힐데가르트·마르셀린·나란 3명 보존 검사 3/3 통과, 실패 0.** 3명 × 실측 칸 10종 = **30/30건을 원본 프레임 안쪽 자르기로 처리**, 생성 **0회**다. 게임 코드·데이터와 기존 초상 파일은 변경하지 않았다. 지시한 3명 검토 범위에서 멈춘다.

원본 WEBP를 디코딩한 525×768 RGB를 576×768 RGBA PNG의 `(25,0)`에 리샘플링 없이 그대로 복사했다. 좌 25px·우 26px는 완전 투명 여백이며 몸을 생성한 부분이 아니다. **숨겨진 배경 RGB까지 포함해 원본 영역 1,209,600픽셀 전체가 동일**하다. 배경 제거는 알파만 바꿨고, PNG 압축 바이트의 동일성을 RGB 동일성과 혼동하지 않았다. 원본 WEBP 파일 바이트는 SHA-256으로 별도 검사했다.

**수치와 판정**

| 인물 | 원본 영역 픽셀 | RGB 변경 픽셀 | 최대 채널 차 | RGB 디프린지 픽셀 | 1px 알파 경계 픽셀 | 닫힌 배경 정리 픽셀 |
|---|---:|---:|---:|---:|---:|---:|
| hildegard | 403,200 | 0 | 0 | 0 | 3,495 | 2,990 |
| marceline | 403,200 | 0 | 0 | 0 | 2,197 | 2,716 |
| naran | 403,200 | 0 | 0 | 0 | 1,726 | 0 |

- RGB 디프린지 **폭 0px / 0픽셀**, 원본 영역 RGB MAE **0**, 얼굴 영역 RGB 차이 **0픽셀**. 경계 RGB 예외를 사용하지 않았다.
- 알파 경계 정리는 안쪽 **1px**에 한정했다. 색 거리·테두리 연결 배경 매트에 원본을 직접 보고 지정한 머리카락 사이 배경 영역을 더했다. 나란의 흰 머리·털·옷에는 내부 흰색 제거를 적용하지 않았다. 임계값과 정리 영역 좌표는 `manifest.json`에 기록했다.
- 칸별 자르기 PNG **30개도 원본 해상도의 RGB를 그대로 보존**, 변경 **0픽셀**. 미리보기 합성에서만 칸 크기로 리샘플링했다. 파일 자체의 해상도와 목표 칸 해상도는 `preview-placement.json`에 각각 기록했다.
- 생성/확장 **0회 / 0픽셀**, 이음매 혼합 **0px**. 확장 검수 대상은 없다. 기존 실측 10개 칸 모두 기록된 crop 좌표가 `[0,0,525,768]` 안에 들어간다.
- 원본 자산 해시 **96/96 일치**, 실패 **0**. 이번 시작 보호 파일 **2,587개 변경 0**, 허용 경로 밖 새 파일 **0**. 이전 기준 **2,179개도 변경 0**. 게임 코드·데이터 불변이므로 1b 지시대로 공통 Godot 검사는 재실행하지 않았다. 이번 수치를 이전 공통 시험의 새 실행 결과로 주장하지 않는다.

**산출·변경 파일**

- `project/assets/portraits-r21/{hildegard,marceline,naran}-upperbody.png`: 3:4 RGBA 원본 보존 마스터 3개, 576×768. 실제 원본 영역은 `(25,0,525,768)`.
- `project/assets/portraits-r21/slots/*.png`: 인물당 10종, 총 30개 원본 크롭. D가 쓸 경우 `preview-placement.json`의 목표 크기·좌표를 함께 참고한다.
- `verification/portraits-r21/sample-sheet.jpg`: 원본 | 체커 결과 | 상세·준비·얼굴 시안 칸 합성, **1176×1140, 293,481 bytes**, JPEG 품질 88. 폭 1200 이하·300,000 bytes 이하 통과.
- `verification/portraits-r21/{manifest,validation,preview-placement,slots,sheet-info,baseline-1b}.json`, `matte/*-alpha.png`, `*-checker.jpg`, `*-dark.jpg`, `*-matte-review.jpg`, `*-all-slots.jpg`, `slot-previews/*.png`: 수치·매트·육안 검토 자료.
- `verification/portraits-r21/attempt-1b-before/`: **1,491개 파일** 보존. 이전 PNG·메타데이터·로그·시험 복제본을 이동했고, 이전 도구 4개와 보고서 원문도 넣었다. 이전 최종 PNG 3개는 이전 manifest SHA-256과 일치한다. 실측 `slots.json`과 이전 `baseline.json`만 현재 검사에 필요한 사본을 다시 두었다. 아래 1단계 본문도 원문을 유지한다.
- `tools/matte_portrait_r21.py`: 재현 도구. 제작은 `python tools/matte_portrait_r21.py build`, 검사만 재현하려면 `python tools/matte_portrait_r21.py verify`. `archive`는 중복 실행을 거부한다. 검토 기록/보고서 갱신은 직접 육안 검토 후에만 `finalize`로 한다.
- `UI-R21-C.md`: 이 1b 절을 맨 위에 추가.

**직접 연 결과와 남은 한계**

원본 3장, 체커/어두운 배경 합성 3장씩, 최종 인물별 10칸 갤러리 3장, 최종 비교 시트를 직접 열었다. 넓은 얼굴 칸에서 턱이 잘리던 구도는 원본 안에서 crop을 아래로 옮겨 얼굴이 보이도록 수정하고 다시 열었다. 얼굴·머리·옷·노출·색의 재그림은 없고, 원본 갑옷과 털 형태가 유지된다.

일부 머리 외곽과 갑옷 가장자리에는 어두운 배경에서 가는 밝은 테두리가 남는다. 이를 없애기 위한 RGB 디프린지는 하지 않았다. 원본의 좌우·아래 잘림도 마스터에는 그대로 남아 있으며, 확장 완성품으로 판정하지 않는다. 큰 초상 칸은 시안 경계로 어깨·몸통을 자르고, 작은 얼굴 칸은 나란의 귀 및 인물의 머리 윗부분을 일부 자른다. 시트의 시안 합성은 실측 크기·사선 마스크를 적용한 깨끗한 패널이며 실제 게임 스크린샷은 아니다. 실측 오차 ±4px는 이전과 같다. 게임 연결, 실제 UI에서의 실행 검증, 나머지 27명 제작은 하지 않았다.

---

UI-R21-C — 2026-10-31 · 1단계 검토용 산출

**상태: 3명 제작·각 1회 재생성 후 보존 기준 불합격 3명. 승인용 완성품으로 판정하지 않음.** 원본 얼굴·옷·색을 그대로 유지하는 요구를 충족하지 못했다. PNG는 비교 검토를 위해 보존했으며 갈래 D에서 연결하면 안 된다. 지시한 3명 범위에서 멈춘다. 나머지 플레이어 동료 27명은 작업하지 않았다.

작업 지시서와 공통 규칙을 UTF-8로 읽었다. 기본 image_gen.imagegen에 각 원본 webp를 참조 이미지로 넣어 총 6회 편집했다. CLI/API로 전환하지 않았다. 첫 시도는 배경 제거와 잘린 가장자리의 최소 확장, 두 번째는 원본 픽셀 보존을 우선해 배경 제거·투명 캔버스 추가만 요청했다. 재생성 후에도 원본 영역 변화가 남았다. 원본 덧씌우기, 얼굴 패치, 색 보정으로 수치를 맞추지 않았다.

**산출 파일**

- project/assets/portraits-r21/{hildegard,marceline,naran}-upperbody.png — RGBA 1086×1448, 3:4, 각 알파 범위 0~255. 세 장 모두 검토용 불합격.
- verification/portraits-r21/slots.json — 시안 3장의 동료 목록·상세·출발 준비·마을 칸 10종을 원본 픽셀 좌표로 측정. 사선 마스크·머리 여백·절단선·파생 얼굴 크롭 기준 포함. 육안 경계 측정 오차 약 ±4px이며 실제 생산 레이아웃의 확정 치수로 주장하지 않음.
- verification/portraits-r21/manifest.json — 원본/결과 SHA-256, 두 시도 프롬프트 전문, 참조 경로, 편집 범위, 전체 및 얼굴·몸통 개별 정렬 행렬/차이 수치, 직접 확인 판정.
- verification/portraits-r21/sample-sheet.jpg — 원본 | 결과 | 시안 실측 상세·준비·얼굴 칸 합성. **1140×1130, 253274 bytes (253.3KB)**. JPEG 품질 87. 시안 칸의 비율과 자르기를 검사한 합성 검토 자료이며 완성 UI 스크린샷은 아님.
- verification/portraits-r21/{prompts,measurements,preview-placement,validation,suite-results,baseline}.json, *-alignment-review.jpg, *-aligned.png, attempt-1/**, 검사 로그, test-workspace/**.
- tools/{verify,analyze,sheet,check}_portrait_r21.py — 회귀 검사 복제본 실행, SSIM/픽셀차 측정, 비교판 제작, 해시·구조·보존 판정 검사. 재현: python tools/analyze_portrait_r21.py → python tools/sheet_portrait_r21.py → python tools/check_portrait_r21.py. 마지막 검사는 보존 실패를 숨기지 않고 exit 1을 반환한다.

**원본 대비 차이와 수치**

SSIM은 원본 해상도에서 RGB 11×11 Gaussian(σ=1.5) 윈도우로 계산했다. SIFT+RANSAC 유사변환으로 전체 정렬과 영역별 정렬을 각각 기록했다. 아래는 얼굴·몸통을 각각 정렬한 값이다. MAE는 RGB 0~255 평균 절대차, ΔE는 Lab ΔE76이다. 정렬·리샘플링 오차도 포함되므로 수치는 동일성의 증명이 아니며, 사용자가 지정하지 않은 수치 합격선을 만들지 않았다. 육안에서 금지된 변화가 보여 불합격으로 판단했다.

| 인물 | 얼굴 SSIM | 얼굴 MAE | 얼굴 ΔE76 | 몸통 SSIM | 몸통 MAE | 판정 |
|---|---:|---:|---:|---:|---:|---|
| 힐데가르트 | 0.8546 | 8.9792 | 4.8847 | 0.8344 | 7.2425 | 불합격 |
| 마르셀린 | 0.8957 | 6.3801 | 3.6140 | 0.8766 | 6.0560 | 불합격 |
| 나란 | 0.7916 | 9.0890 | 4.7939 | 0.7395 | 12.6684 | 불합격 |

힐데가르트는 피부 음영·입술 선과 갑옷 반사/흠집이 달라졌고 아래 소매 측면 잘림도 남았다. 마르셀린은 눈·입 주변과 갑옷 표면선·반사·팔 비율에 차이가 남았다. 나란은 눈·입 선, 코트 버튼과 명암·금속색, 귀와 털 외곽 잔여가 보였다. 큰 귀를 보존하면 작은 얼굴 칸에서 얼굴이 작아지는 구도 문제도 확인했다. 원본과 최종 정렬 비교 3장, 생성 6장, sample-sheet.jpg를 직접 열어 확인했다.

원본 menu-portraits.json과 webp는 35개다. 게임 플레이어 동료는 30명이며 이번 3명은 모두 그 목록에 포함된다. 지시서의 30명과 파일 개수 차이는 새 인물을 추가한 것이 아니다. face-portraits.json에는 힐데가르트 기준만 있고 이번 마르셀린·나란 기준은 없어 manifest에 수동 얼굴 ROI와 “없음”을 구분했다. companions-r4는 원본 상황을 읽는 참고로만 사용하고 픽셀 화풍이 초상 편집에 섞이지 않도록 imagegen에는 webp만 넣었다. 원본의 기존 장비 외 새 무기를 추가하지 않았다. 실측 칸에는 다리·발이 없어 전신 의상을 생성하지 않았다.

**검사 결과**

원본 ASSET-HASHES.json **96/96 일치, 실패 0**. 시작 시 보호 파일 **2179개 비교, 변경 0**. 게임 코드·데이터·기존 초상 바이트 변경 없음. 새 파일만 허용 경로에 작성했다. git 명령은 실행되지 않았다. 구조 검사 **6개, 실패 0**. 자체 보존 검사 **3개, 실패 3, exit 1**.

공통 검사와 생성된 라이선스/스크린샷/저장 파일이 허용 경로 밖을 바꾸지 않도록 verification/portraits-r21/test-workspace에 게임·래퍼의 바이트 동일 복사본을 만들고 그 안에서 python tools/godot_r17.py로 실행했다. APPDATA 격리와 Dummy 오디오가 유지된다. 원본 tests의 기대값은 수정하지 않았다.

| 공통 검사 | 수치/결과 |
|---|---|
| import | exit 0 |
| world_test | 44 checks / 0 failures |
| state_test | 54 checks / 0 failures |
| route_test | 41 checks / 0 failures |
| expansion_test | 3350 checks / 0 failures |
| motion_test | PASS |
| motion_asset_test | 19 clips PASS |
| art_test | 30 characters / 60 frames / 30 cinematics PASS |
| export_licenses | exit 0 |
| ui_battle_r17_test | 6085 checks / 0 failures |
| ui_battle_r18_test | 4592 checks / 0 failures; 30 distinct effect hashes |
| ui_battle_r19_test | 859 checks / 0 failures |
| ui_battle_r20_test | 1659 checks / 0 failures |
| motion_r9_integration | 944 checks / 0 failures |
| motion_r18_integration | 3540 checks / 0 failures |

공통 **15/15 명령 exit 0**, 수를 출력한 시험 합계 **21168 checks / 0 failures**. 최종 PNG 3장을 복제본에 추가한 import도 exit 0이다. 복제본 r20 base-390.png를 직접 열어 확인했다. 전투 수백 장 전체를 육안으로 확인한 것은 아니다.

각 Godot 실행은 환경 진단 ERROR: Failed to read the root certificate store.를 출력했다. 공통 실행 15회와 추가 import 1회에 해당한다. 스크립트 시험 실패와 구분해 기록하며 로그 오류 0이라고 주장하지 않는다. 일반 셸 도구는 Windows sandbox setup missing/out of date로 시작하지 못해 Node 실행 도구에서 파일을 UTF-8로 읽고 Python 프로세스를 실행했다.

**남은 일**

엄격한 원본 보존을 통과한 3명 초상은 확보하지 못했다. 어깨/팔/허리 확장 완성, 남은 27명 제작, 게임 화면 연결은 하지 않았다. 이번 결과는 승인 대기 완성품이 아닌 실패 원인과 구도 확인 자료다. 사장님이 정한 1단계 범위대로 여기서 멈춘다.
