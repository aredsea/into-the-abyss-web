# UI-R20 — 시안 잉크 벡터 트레이스

승인 시안의 잉크 PNG를 색 층별 벡터 경로로 변환하고 전투 화면에 적용했다. 게임에는 원본 잉크 래스터를 추가하지 않았다. r18 컷인 사선 띠와 전투 규칙·데이터는 그대로다. 원격 게시나 git 명령은 실행하지 않았다.

## 트레이스와 렌더

`tools/trace_ink_r20.py`는 읽기 전용 시안 PNG의 불투명 픽셀 최빈색에서 서로 다른 실제 페인트 색을 찾는다. 일반 검정은 RGB 18/22/21, 버밀리언은 216/50/25, 고해상 기록 붓의 검정은 17/23/21이다. 혼합 픽셀은 두 페인트 사이의 RGB 투영값과 원본 알파로 분리한다. 종이 마스크는 원본 알파를 사용한다.

각 층의 알파 0.5 등고선을 원래 픽셀 중심 좌표에서 marching squares로 추적한다. 서브픽셀 교차점과 분리된 섬·구멍을 보존하며 기본 경로 단순화 한도는 원본 0.075px다. 반투명 가장자리는 0.125/0.375/0.5/0.625/0.875의 추가 벡터 알파 띠로 보존한다. 띠 단순화는 0.01px, 0.5 띠는 단순화하지 않는다. 고해상 기록 PNG는 342×492 경로를 114×164로 표시한다.

even-odd scanbeam으로 구멍을 포함한 면을 삼각분할한다. `battle_ink_r17.gd`는 인덱스 메시를 그리며, 4배 오프스크린에서 원본 중심과 정렬한 알파 표본을 재구성한다. 이는 이미 안티앨리어싱된 작은 페인트 섬을 다시 박스 평균해 지우지 않기 위한 방식이다. 런타임 캐시 텍스처는 벡터에서 만들어지며 프로젝트에 래스터 파일로 저장되지 않는다. 가장자리의 반투명 표본은 벡터 알파 띠가 담당한다.

[경로 JSON](project/assets/ui-r20/ink-paths.json)에 출처 파일·SHA-256·실제 색·외곽/구멍 수·경로·삼각분할을 기록했다. Web은 같은 JSON의 결정론적 gzip만 포함하며 원문 JSON은 export에서 제외한다. gzip은 이미지 데이터가 아니다. 원문과 압축 해제 바이트의 동일성도 검사했다.

전장 마스크의 역영역을 배경 위에 종이색으로 덮고, 배우·적·이름표는 그 위에 둔다. 대상 붓은 z=2, 적 그림은 z=3으로 시안처럼 겹친다. 대상의 모서리/기울어진 원은 시안 HTML의 SVG 경로와 CSS를 옮긴 벡터다. 상태·보급품 붓의 border-top 2px 오프셋도 반영했다.

390px 경계와 264/150/164/228/114px 붓 폭 등 CSS 고정 크기는 유지한다. 가로 위치는 기존 반응형 전투 기준을 따르고 기록 붓은 오른쪽 14px에 고정한다. 전장 마스크는 기존 전장 박스에 맞춰 비례 배치한다. 모든 잉크는 중앙 전투 프레임으로 잘라낸다.

## 잉크 수치

[자산별 CSV](verification/ui-r20/asset-ink-metrics.csv) · [상태/색 층 CSV](verification/ui-r20/state-ink-metrics.csv) · [잉크 위치 CSV](verification/ui-r20/ink-position-errors.csv) · [측정 방법](verification/ui-r20/ink-summary.json).

아래 값은 프로덕션 메시 렌더러의 실제 Godot 분리 층 캡처를 사용한다. 원본 PNG에서 별도로 얻은 알파와 비교하며 문턱은 0.5다. 구멍과 떨어진 작은 점까지 포함한 모든 경계 픽셀의 양방향 Hausdorff를 썼다. 상태별 표는 같은 색 층의 합집합을 실제 Control 좌표에 놓고 독립적인 시안 DOM 좌표와 비교한다. 배경 질감이나 글리프를 페인트로 오인하지 않도록 색 혼합 전 층을 측정하며, 최종 합성 화면 전체의 차이는 아래 MAE로 따로 보고한다.

| 사용 자산 | 색 층 | 최소 IoU | 최대 윤곽 거리(px) |
| --- | --- | ---: | ---: |
| edge-base | 2 | 0.999541 | 1.000 |
| edge-target | 2 | 1.000000 | 0.000 |
| edge-status | 2 | 0.999627 | 1.000 |
| edge-skills | 2 | 1.000000 | 0.000 |
| edge-supplies | 2 | 1.000000 | 0.000 |
| edge-log | 2 | 1.000000 | 0.000 |
| battle-mask-base | 1 | 1.000000 | 0.000 |
| battle-mask-target | 1 | 1.000000 | 0.000 |
| battle-mask-status | 1 | 1.000000 | 0.000 |
| battle-mask-skills | 1 | 1.000000 | 0.000 |
| battle-mask-supplies | 1 | 1.000000 | 0.000 |
| battle-mask-log | 1 | 1.000000 | 0.000 |
| gesture-base | 2 | 1.000000 | 0.000 |
| gesture-target | 1 | 1.000000 | 0.000 |
| gesture-status | 1 | 1.000000 | 0.000 |
| gesture-skills | 2 | 0.999225 | 1.000 |
| gesture-supplies | 2 | 1.000000 | 0.000 |
| gesture-log-r17-hires | 2 | 0.999622 | 1.000 |

사용하는 18개 자산의 28개 색 층이 모두 IoU ≥0.97·거리 ≤1.5px를 통과했다. 원래 저해상 `gesture-log.png`와 세 `approved-*` PNG는 실제 시안 DOM에서 쓰지 않으므로 런타임 화면에는 놓지 않았다. 트레이스와 별도 측정은 남겼으며 사용 여부를 CSV에 표시했다.

| 상태 | 검정 IoU | 버밀리언 IoU | 종이 마스크 IoU | 최대 거리(px) |
| --- | ---: | ---: | ---: | ---: |
| base | 0.999803 | 0.999561 | 1.000000 | 1.000 |
| target | 1.000000 | 1.000000 | 1.000000 | 0.000 |
| status | 1.000000 | 0.999789 | 1.000000 | 1.000 |
| skills | 1.000000 | 1.000000 | 1.000000 | 0.000 |
| supplies | 1.000000 | 1.000000 | 1.000000 | 0.000 |
| log | 1.000000 | 0.999787 | 1.000000 | 1.000 |

시안 DOM과 비교한 잉크 사각형의 위치/크기 오차는 0px다. 기존 요소의 247개 박스 경계와 351개 텍스트 기준선은 모두 2px 이내다. [박스](verification/ui-r20/box-errors.csv) / [기준선](verification/ui-r20/baseline-errors.csv).

## 글자 보호와 폭별 검사

r17의 이전 검사는 모든 Label 사각형에서 붓을 빼냈다. 상태 이름과 기록 글자 뒤에 붓이 있는 시안의 의도까지 잘라 버려 r20에서는 사용할 수 없다. 새 검사는 원본 경로를 유지하고, 기준 시안의 페인트 영역 밖으로 새로 침범하는지와 실제 글자가 붓보다 앞에 그려지는지를 각각 확인한다. 텍스트 사각형 비교에는 브리프의 경계 허용치 1.5px 이내를 적용하며, 글리프 위로 올라온 새 잉크는 허용하지 않는다.

[시안 대비 글자 검사](verification/ui-r20/ink-text-reference.csv)의 새 침범은 0이다. r17 실제 입력 검사를 30명×390/360/430폭으로 확장해 6,085개 검사가 통과했고 누락 글리프·텍스트 넘침·글자 위 잉크는 0이다. 시안에서도 겹치는 status/log의 배경 붓은 남아 있다.

360×780·390×844·430×844와 중앙 430px 프레임을 가진 640×844에서 여섯 상태를 렌더했다. 640폭에서는 잉크를 보일 때/숨길 때 프레임 밖 픽셀 변화가 여섯 상태 모두 0이고 안쪽 변화는 양수다. 루트 viewport의 자동 클리핑만으로 통과한 검사가 아니다. [원자료](verification/ui-r20/r20-results.json).

## 전체 화면 픽셀 차이

승인 보드의 패널을 390×844로 맞춘 뒤 비교했다. [비교 갤러리](verification/ui-r20/index.html)에는 여섯 상태의 나란히·50% 겹침·강조 차분과 360/430 캡처가 있다. [MAE CSV](verification/ui-r20/mae-r19-r20.csv).

| 상태 | r19 MAE | r20 MAE | 감소 |
| --- | ---: | ---: | ---: |
| base | 14.215 | 12.250 | 1.965 |
| target | 14.042 | 11.795 | 2.247 |
| status | 13.276 | 11.349 | 1.927 |
| skills | 13.098 | 10.695 | 2.403 |
| supplies | 14.248 | 12.114 | 2.134 |
| log | 15.905 | 10.759 | 5.146 |

여섯 상태 모두 감소했다. 시안과 전체 픽셀이 같다는 뜻은 아니다. 기존 전장 인쇄 질감·Godot/Chromium 글꼴 힌팅·일부 아이콘 선과 혼합 굵기·승인 보드 축소 보간 차이가 남는다. 반투명 붓 알파도 유한한 벡터 띠로 근사한다. 뒤로 화살표 비활성 및 데이터에서 없는 정보의 처리 등 r19에서 보고한 동작/데이터 차이는 [UI-R19.md](UI-R19.md)를 따른다.

## 회귀·보존·Web

| 검사 | 결과 |
| --- | --- |
| r17 | 6,085 검사, 실패 0 |
| r9 | 944 검사, 실패 0 |
| r18_integration | 3,540 검사, 실패 0 |
| r18 | 4,592 검사, 실패 0 |
| r19 | 859 검사, 실패 0 |
| r20 | 1,664 검사, 실패 0 |
| import / world / state / route / expansion / balance / motion / motion_asset / art / licenses | 모두 종료 코드 0, 스크립트/엔진 오류 0 |
| 원본·게임 데이터 | 원본 96개 SHA-256 일치, game/data 29개 파일 불변 |
| r18 보존 | 고유 효과 30종·contact/skip·축소 모드 회귀 통과, signature_sequence.gd 바이트 불변 |
| Web 실제 입력 | 390×844, 360×780, 360×780 reduced, 390×664, 1280×800 모두 통과 |
| Web 빌드 | battle-r20-20261031, PCK/WASM SHA-256 일치, 승리 후 원래 viewport 복원 |

PCK는 **52,761,864 → 67,129,232바이트**, **+14,367,368바이트 (+27.231%)**다. 고밀도 윤곽·알파 띠와 구멍을 보존한 메시 데이터가 증가 원인이다. 경로 JSON 원문은 49,308,354바이트, 내보낸 gzip은 14,365,134바이트다. 용량 증가가 남아 있으며 저사양 기기의 파싱 시간/메모리는 실측하지 않았다. WASM 해시는 r19와 같다.

[최종 종합 JSON](verification/ui-r20/summary.json) / [보존·빌드 감사](verification/ui-r20/preservation-and-build.json) / [Web 결과](verification/ui-r20/web/results.json). 각 실행 모드의 JSON 및 전체 로그도 같은 디렉터리에 보관했다. Windows 인증서 저장소를 읽지 못한다는 기존 엔진 메시지는 그대로이며 외부 네트워크 검증을 뜻하지 않는다.

## 변경 파일과 직접 확인

UI는 `battle_screen.gd`, `battle_ink_r17.gd`만 수정했다. `project/assets/ui-r20/`에 경로 JSON·같은 내용의 gzip·대상 외곽 SVG를 추가하고 export 포함/제외 규칙을 갱신했다. `ui_battle_r17_test.gd`의 잉크 기준과 폭 검사를 갱신했으며 `ui_battle_r20_test.gd`를 추가했다. 도구는 trace/verify/review/measure/audit/report_r20, update_version, web_smoke_r19를 추가·갱신했다. README와 Web 산출물도 갱신했다.

나란히 비교 여섯 장을 직접 열어 기본 경계·대상 붓/원·상태 이름 뒤 붓·기술 시트 윗붓·보급품 제목 붓·기록 고해상 붓을 확인했다. 대상 붓이 적 몸을 덮던 z 순서를 수정한 뒤 최종 대상 화면을 다시 열었다. 360/430 전체 시트, 겹침/차분 시트, Web의 정지 화면과 컷인도 직접 열어 확인했다.

실물 iPhone/Android, Safari/Firefox, 360px 미만 화면, 장시간 플레이, 저사양 기기의 성능·메모리 및 실제 사용자 저장파일 전체 모음은 검사하지 않았다. 기존 저장 복원/문장 기록은 고정 테스트로 확인했다.

## 재실행

```powershell
python tools/trace_ink_r20.py
python tools/verify_r20.py checks
python tools/verify_r20.py input
python tools/verify_r20.py motion
python tools/verify_r20.py state
python tools/verify_r20.py r18
python tools/verify_r20.py render
python tools/verify_r20.py r20
python tools/review_r20.py
python tools/measure_ink_r20.py
python tools/verify_r20.py export
python tools/update_version.py
python tools/web_smoke_r19.py
python tools/audit_r20.py
python tools/report_r20.py
```
