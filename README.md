부족한 점: 개발 중인 검수판입니다. 고정된 5회 탐색과 기존 정예전 두 번으로 구성되며, 길드·영입·장비·대장간·파견·페르소나·층 보스·다층 진행은 아직 없습니다. 카드 효과와 보상량은 검수용 예시입니다. 일부 전투 스킬은 규칙 미확정으로 비활성화되어 있습니다.

확인하지 못한 점: 실제 iPhone·Android 기기, Safari·Firefox, 장시간 밸런스와 클라우드 저장은 검증하지 않았습니다. 공개 주소의 배포 검증 결과는 별도로 기록합니다.

# Into the Abyss

Godot 4.7.2로 만든 세로 화면 RPG 웹 검수판입니다. 토르바에서 보급품을 사고 동료를 살핀 뒤, 탐색 카드와 CTB 전투를 거쳐 귀환합니다.

**[웹에서 플레이](https://aredsea.github.io/into-the-abyss-web/)**

주소가 배포된 뒤에는 GitHub 로그인이나 Tailscale, 개발 PC 없이 열 수 있습니다. WebGL 2를 지원하는 브라우저가 필요하며 첫 실행에는 엔진과 게임 데이터를 내려받습니다.

## 저장

진행 상황은 현재 브라우저의 IndexedDB에 저장됩니다. 다른 기기·브라우저와 자동으로 동기화되지 않으며, 사이트 데이터를 지우면 저장도 지워집니다. 이전 localhost/Tailscale 주소와도 별도 저장입니다.

## 구성

- `project/`: Godot 프로젝트와 GDScript 게임 소스, 원본 초상 및 도트 사본.
- `docs/`: GitHub Pages에 게시하는 웹 실행 파일. HTML·JS·WASM·PCK를 함께 배포합니다.
- `ASSET-HASHES.json`: 공개용 사본의 에셋 SHA-256. 원본 픽셀은 변경하지 않았습니다.
- `project/tests/`: 원정 모델 44개와 전투 모델 54개 검사.

봇 원본 코드, 외부 작품 레퍼런스, 로컬 호스팅 설정과 개인 작업 로그는 이 저장소에 포함하지 않습니다. 게임에서 쓰지 않는 성격유형·이전 특성 메타데이터도 공개 사본에서 제외했습니다.

## 실행과 업데이트

Godot 4.7.2 Standard와 같은 버전의 Web export templates를 설치하고 `project/project.godot`를 엽니다. F6가 아닌 프로젝트 실행(F5)으로 거점에서 시작합니다.

```sh
godot --headless --path project --editor --import
godot --headless --path project --script tests/world_test.gd
godot --headless --path project --script tests/state_test.gd
godot --headless --path project --export-release Web ../docs/index.html
python tools/update_version.py
```

내보낸 `docs/`를 소스와 함께 커밋하여 `main`에 올리면 GitHub Pages가 갱신됩니다. Pages 게시 원본은 `main` 브랜치의 `/docs`입니다. 웹 실행 파일은 `file://`로 직접 열지 말고 HTTP 서버로 확인합니다.

```sh
python -m http.server 8000 --directory docs
```

단일 스레드 내보내기를 사용하므로 SharedArrayBuffer용 추가 헤더가 필요하지 않습니다. 파일 이름과 대소문자를 유지하고, WASM·PCK를 Git LFS 포인터로 바꾸지 않습니다.

## 문서값과 검수용 예시값

| 구분 | 내용 |
|---|---|
| 봇·기획에서 가져온 값 | 캐릭터 기본 능력치와 성장 곡선, 최대 레벨 40, 물약 가격·회복률, 여관 비용·일일 제한, 출발 시 회복, 탐색 5회와 휴식 |
| 사용자 결정 | 별도 탐색 손패에 카드를 획득하고, 사용한 카드는 소모. 전투·탐색 사건에서 획득 |
| 검수용 예시 | 시작 200금과 물품, 고정 사건, 전투당 40금·14XP, 발견 20금, 카드 이름·효과·지급량, 패배/귀환 시 카드 보존 |
| 연결 시험 | 마지막 전투에 기존 정예전 재사용. 보스 처치나 지름길 해금 기록은 지급하지 않음 |

## 라이선스 안내

Godot 및 엔진 의존성 고지는 `project/licenses/GODOT_AND_THIRD_PARTY.txt`, NanumGothic 고지는 `project/assets/fonts/OFL.txt`에 있습니다. 웹 빌드에도 `docs/licenses/`로 제공합니다. 저장소 공개는 게임 코드와 캐릭터 이미지의 별도 재배포·변경 라이선스를 부여하지 않습니다.
