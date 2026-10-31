# UI-R20 — 시안 잉크 벡터 / r20b 용량 개선

승인 시안의 잉크 모양을 벡터로 유지하면서 저장 형식과 렌더러를 줄였다. 현재 Web 빌드는 `battle-r20b-20261031`이다. 원본 PNG는 읽기 전용 참조이며 게임에 잉크 래스터를 추가하지 않았다. 쓰기는 `battle-r17/` 안에서만 했고 git 명령이나 원격 게시를 실행하지 않았다. r20 당시 문서와 캡처는 [이전 기록](verification/ui-r20/r20-before/UI-R20.md)에 보존했다.

## r20b 용량

| 항목 | r20 전 | r20b 후 |
| --- | ---: | ---: |
| 프로젝트 경로 JSON | 49,308,354 B | 0 B |
| PCK용 JSON gzip | 14,365,134 B | 0 B |
| 벡터 바이너리 `.res` | 0 B | 475,677 B |
| 전체 잉크 자산 PCK payload | gzip 14,365,134 B + 대상 외곽 | 478,952 B |
| 잉크 payload + PCK 정렬·디렉터리 | — | 479,224 B |
| 전체 PCK | 67,129,232 B | 53,240,060 B |

잉크 전체는 **0.479224 MB**로 1MB 상한과 0.5MB 목표를 모두 충족한다. PCK는 r20보다 **13,889,172 B (20.690%)** 작다. r19 PCK 52,761,864 B 대비 증가는 478,196 B (0.906%)다. WASM 바이트·해시는 r19/r20과 같다.

전체 잉크 수치는 `.res`뿐 아니라 기존 대상 외곽 SVG의 엔진 변환 자산과 import 메타데이터를 포함한다. [PCK 항목·MD5 전수 감사](verification/ui-r20/pck-manifest.json)로 실제 포함 바이트를 확인했다. 프로젝트와 PCK의 `ink-paths.json`·`.json.gz`는 제거했다. 이전 JSON은 `verification/ui-r20/r20-before/`에만 남고 export에 들어가지 않는다.

## 트레이스·바이너리·렌더 방식

`tools/trace_ink_r20.py`가 `compact_ink_r20b.py`를 호출한다. r20의 색 분리와 원본 알파 marching squares는 유지한다. 검정 RGB 18/22/21, 버밀리언 216/50/25, 고해상 기록 검정 17/23/21이며 종이 마스크는 원본 알파다. 각 색 층의 0.5 등고선 하나만 저장한다. 10px² 미만 섬·구멍은 단순화하지 않고 큰 경로의 허용 오차는 원본 0.075px, 좌표 양자화는 1/128px다. 합산 위치 오차 상한도 원래 0.25px 안이다.

각 외곽과 그 구멍을 묶어 even-odd scanbeam으로 오프라인 삼각분할한다. 종이 역마스크는 프레임과 교차하므로 전체 경로 집합을 함께 분할한다. 저장 배열은 양자화한 `PackedVector2Array`와 정수 `PackedInt32Array`다. Godot가 한 번에 읽는 바이너리 배열을 선택해 런타임 좌표 변환 루프를 없앴다. JSON 숫자·중복 알파 띠·색 배열은 저장하지 않는다.

`build_ink_r20b.gd`는 Godot 표준 RSCC 리소스를 단일 Zstandard 블록으로 압축한다. 기본 4KiB 블록보다 상태 간 반복 좌표·인덱스를 같은 압축 사전에서 공유할 수 있다. 저장 직후 ResourceLoader로 다시 열어 모든 Dictionary·typed array가 원본과 같은지 검사한다. [바이너리 round-trip](verification/ui-r20/binary-roundtrip.json). 시안 DOM에 없는 저해상 `gesture-log`와 `approved-*` 세 자산은 런타임에서 제외했다. 사용하는 18자산·28색 층은 전부 남았다.

`battle_ink_r17.gd`는 크기와 무관한 메시를 자산별로 공유하고 직접 그린다. 0.5px 폭·알파 0.10의 안티앨리어싱 외곽선으로 서브픽셀 페더를 만든다. 구멍도 같은 외곽선 처리다. 오프스크린 텍스처·GPU readback·래스터 캐시를 만들지 않는다. Compatibility/WebGL에서 지원되지 않는 2D MSAA도 사용하지 않는다. 종이 마스크 역영역, CSS 고정 폭/배치, 대상 붓 z=2와 적 z=3은 유지한다. 실제 프레임 교차 영역의 Control 클리핑으로 폭 밖 그리기를 막는다.

## IoU·윤곽 거리

r20 측정 도구를 그대로 사용하되 자산 메타데이터 입력만 검증용 JSON으로 바꿨다. 원본 PNG의 독립 색 분리 알파와 프로덕션 렌더러의 Godot 분리 층 캡처를 0.5 문턱으로 비교한다. 윤곽 거리는 작은 섬·구멍을 모두 포함한 양방향 Hausdorff다. 상태별 결과는 실제 Control 좌표와 승인 HTML DOM 좌표로 각각 배치한 같은 색 층 합집합이다. 허용치는 IoU ≥0.97, 거리 ≤1.5px이며 문턱·거리 계산·기대 영역을 완화하지 않았다.

| 사용 자산 | 색 층 수 | 최소 IoU | 최대 거리(px) |
| --- | ---: | ---: | ---: |
| edge-base | 2 | 0.995773 | 1.414 |
| edge-target | 2 | 0.997010 | 1.000 |
| edge-status | 2 | 0.997023 | 1.414 |
| edge-skills | 2 | 0.994421 | 1.000 |
| edge-supplies | 2 | 0.993218 | 1.000 |
| edge-log | 2 | 0.992487 | 1.414 |
| battle-mask-base | 1 | 1.000000 | 0.000 |
| battle-mask-target | 1 | 1.000000 | 0.000 |
| battle-mask-status | 1 | 1.000000 | 0.000 |
| battle-mask-skills | 1 | 1.000000 | 0.000 |
| battle-mask-supplies | 1 | 1.000000 | 0.000 |
| battle-mask-log | 1 | 1.000000 | 0.000 |
| gesture-base | 2 | 0.994311 | 1.000 |
| gesture-target | 1 | 0.998269 | 1.000 |
| gesture-status | 1 | 0.999119 | 1.000 |
| gesture-skills | 2 | 0.992112 | 1.000 |
| gesture-supplies | 2 | 0.994898 | 1.000 |
| gesture-log-r17-hires | 2 | 0.999622 | 1.000 |

| 상태 | 검정 IoU | 버밀리언 IoU | 종이 IoU | 최대 거리(px) |
| --- | ---: | ---: | ---: | ---: |
| base | 0.998228 | 0.996054 | 1.000000 | 1.414 |
| target | 0.997010 | 0.997890 | 1.000000 | 1.000 |
| status | 0.998281 | 0.998522 | 1.000000 | 1.414 |
| skills | 0.997691 | 0.994747 | 1.000000 | 1.000 |
| supplies | 0.996970 | 0.993577 | 1.000000 | 1.000 |
| log | 0.997124 | 0.996808 | 1.000000 | 1.414 |

[자산 CSV](verification/ui-r20/asset-ink-metrics.csv) · [상태 CSV](verification/ui-r20/state-ink-metrics.csv) · [측정 요약](verification/ui-r20/ink-summary.json). 28색 층과 18개 상태/색 조합 모두 통과했다. 잉크 위치·크기 오차는 0px, 기존 박스 247개와 텍스트 기준선 351개는 모두 2px 이내다. 시안 페인트 영역 밖으로 새로 침범하는 글자 영역은 0이며 실제 글자는 잉크 앞에 있다.

## 첫 전투 준비 시간·메모리

헤드리스 Chrome 156.0.8078.49에서 CDP `Emulation.setCPUThrottlingRate`를 4로 설정하고 390×844 새 컨텍스트 5개를 측정했다. 첫 잉크 리소스 로드·압축 해제부터 초기 세 자산(마스크·경계·제목 붓)의 메시·외곽선 캐시 생성과 GPU 버퍼 제출까지 연속 구간을 잰 값이다. 중앙값 **24.140ms**, 최댓값 **25.515ms**로 150ms 목표를 통과했다. 초기 캐시 텍스처 수는 0이다.

| 새 세션 | 로드·해제(ms) | 메시·외곽선(ms) | 총 준비(ms) |
| --- | ---: | ---: | ---: |
| 1 | 17.680 | 7.835 | 25.515 |
| 2 | 16.555 | 7.080 | 23.635 |
| 3 | 18.090 | 7.035 | 25.125 |
| 4 | 17.860 | 6.280 | 24.140 |
| 5 | 17.060 | 6.440 | 23.500 |

릴리스 Web은 `OS.get_static_memory_usage()` 카운터가 비활성이라 0을 반환한다. 이 0을 메모리 사용량으로 해석하지 않았다. 같은 최종 자산·렌더러를 `--export-debug Web`으로 별도 내보내고 같은 Chrome 4배 감속 조건에서 3회 측정한 정적 메모리 증가는 매회 **2,086,008 B (1.989 MiB)**다. 리소스 로드부터 초기 메시 캐시 생성까지 엔진의 활성 정적 할당량 차이이며 GPU 드라이버·WASM 고정 힙 예약량은 포함하지 않는다.

최종 벡터 packed-array payload는 1,853,660 B, 초기 메시 버퍼 payload는 293,212 B다. Dictionary·할당자·GPU 오버헤드를 제외한 정확한 배열 바이트 수이며 정적 메모리 실측과 구별한다. [릴리스 5회 원자료](verification/ui-r20/r20b-performance.json) · [디버그 메모리 3회](verification/ui-r20/r20b-memory-debug.json).

측정 시작 시 PCK는 이미 브라우저에 마운트돼 있다. 네트워크 다운로드, 전투 전체 UI 구성, 브라우저의 첫 프레임 스케줄링은 이 잉크 준비 시간에 포함하지 않는다. 첫 전투의 전체 클릭→화면 지연을 150ms라고 주장하는 값은 아니다.

## 비교 이미지·남은 차이

승인 시안과의 여섯 상태 나란히·겹침·차분, 360×780·390×844·430×844 캡처를 다시 생성했다. [갤러리](verification/ui-r20/index.html)에는 이전 r20과 현재 r20b 나란히 여섯 장도 있다. 이를 직접 열어 기본 경계, 대상 붓/원, 상태 이름 뒤 붓, 기술 시트 윗붓, 보급품 제목 붓, 기록 오른쪽 고해상 붓을 확인했다. 굵은 실루엣·작은 튐·구멍이 눈에 띄게 다른 형태로 바뀌지 않았다. 360/430 전체 시트도 직접 열어 봤다.

| 상태 | r19→시안 MAE | r20b→시안 MAE | r20↔r20b MAE |
| --- | ---: | ---: | ---: |
| base | 14.215 | 12.378 | 0.248 |
| target | 14.042 | 11.871 | 0.233 |
| status | 13.276 | 11.426 | 0.248 |
| skills | 13.098 | 10.801 | 0.231 |
| supplies | 14.248 | 12.186 | 0.213 |
| log | 15.905 | 10.820 | 0.146 |

전체 화면 MAE는 여섯 상태 모두 r19보다 작다. r20의 여러 알파 띠를 단일 등고선과 얇은 페더로 바꾸면서 경계의 반투명 농도는 조금 다르다. 작은 점의 문턱 통과 픽셀도 일부 달라진다. 전체 화면의 r20↔r20b MAE는 0.15~0.25/255 수준이다. 기존 전장 인쇄 질감, Chromium/Godot 글꼴 힌팅, 일부 아이콘 선, 승인 보드 축소 보간 차이는 남는다. 비활성 뒤로 화살표와 게임 데이터에 없는 정보 등 기존 동작 차이는 [UI-R19.md](UI-R19.md)를 따른다.

## 회귀·보존·Web

| 검사 | 결과 |
| --- | --- |
| r17 | 6,085 검사 / 실패 0 |
| r9 | 944 검사 / 실패 0 |
| r18_integration | 3,540 검사 / 실패 0 |
| r18 | 4,592 검사 / 실패 0 |
| r19 | 859 검사 / 실패 0 |
| r20 | 1,659 검사 / 실패 0 |
| import/world/state/route/expansion/balance/motion/motion_asset/art/licenses | 전부 종료 0, 스크립트·엔진 오류 0 |
| 원본·게임 데이터 | 원본 96개 SHA-256 일치 / game·data 29개 파일 불변 |
| r18 보존 | 30종 효과, contact/skip, reduced-motion 통과 / signature_sequence.gd 불변 |
| 레이아웃 | 30명×390/360/430폭 텍스트 넘침·누락 글리프 0 / 640폭 프레임 밖 잉크 변화 0 |
| Web 실제 입력 | 390×844 / 360×780 / 360×780 reduced / 390×664 / 1280×800 전부 통과 |
| Web 빌드 | battle-r20b-20261031 / PCK·WASM 해시 일치 / 승리 후 viewport 복원 |

r20 검사 수가 1,664→1,659로 줄어든 5개는 런타임에서 제외한 미사용 네 자산의 분리 색 층 캡처다. 사용하는 28색 층과 화면·입력·클리핑 검사는 그대로다. 검사 기대 영역과 허용치를 완화하지 않았다. 기존 Windows 인증서 저장소 접근 메시지는 엔진 실행에서 계속 나타나며 다른 엔진 오류는 0이다.

실물 휴대폰, Safari/Firefox, 360px 미만 화면과 장시간 플레이는 검사하지 않았다. 메모리 카운터 측정은 디버그 템플릿이며 릴리스 전체 프로세스 RSS나 GPU 메모리의 실측값은 아니다.

## 변경 파일·재실행

UI는 `battle_ink_r17.gd`의 바이너리 로더·직접 메시·클리핑·성능 계측과 `battle_screen.gd`의 빌드 식별자를 바꿨다. `.res` 추가 및 JSON/gzip 제거, export 규칙, trace/compact/build 도구, 비교·성능·감사·보고 도구, README와 Web 산출물을 갱신했다. 게임 규칙·데이터·마을 UI·r18 컷인 소스는 수정하지 않았다.

[종합 결과](verification/ui-r20/summary.json) · [보존·PCK 감사](verification/ui-r20/preservation-and-build.json). 모든 모드의 로그와 JSON은 `verification/ui-r20/`에 있다.

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
python tools/compare_r20b.py
python tools/verify_r20.py export
python tools/update_version.py
python tools/web_perf_r20b.py
python tools/web_smoke_r19.py
python tools/godot_r17.py --headless --export-debug Web ../verification/ui-r20/memory-web/index.html
python tools/web_perf_r20b.py --memory-debug
python tools/audit_r20.py
python tools/report_r20.py
```
