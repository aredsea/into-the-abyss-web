부족한 점: 개발 중인 검수판입니다. 8개 장소의 고정 갈림길 지도이며 절차 생성은 없습니다. 마지막 전투와 순찰로는 같은 정예전 구성을 사용합니다. 길드·영입·장비·대장간·파견·페르소나·층 보스·다층 진행은 아직 없습니다. 카드 효과와 보상량은 검수용 예시입니다. 일부 전투 스킬은 규칙 미확정으로 비활성화되어 있습니다.

확인하지 못한 점: 실제 iPhone·Android 기기, Safari·Firefox, 다른 네트워크의 실물 기기, 장시간 밸런스는 검증하지 않았습니다. 클라우드 저장은 미구현입니다. 공개 HTTPS 주소에서 Chromium 두 화면 크기의 실행·전투·저장 복원과 합성 터치를 확인했습니다. [검증 기록](VERIFICATION.md)

# Into the Abyss

Godot 4.7.2로 만든 세로 화면 RPG 웹 검수판입니다. 토르바에서 보급품을 사고 동료를 살핀 뒤, 탐색 카드와 CTB 전투를 거쳐 귀환합니다.

**[웹에서 플레이](https://aredsea.github.io/into-the-abyss-web/)**

[웹 원정 구조·게임 6종·UI 레퍼런스 조사](https://aredsea.github.io/into-the-abyss-web/research/) · [로딩 화면 시안](https://aredsea.github.io/into-the-abyss-web/research/loading.html)

새 원정부터 갈림길 지도를 사용합니다. 서가에서 탐색 카드를 얻거나 순찰로 전투 보상을 노릴 수 있고, 보관함에서 카드를 쓰거나 아껴 둘 수 있습니다. 카드를 쓰지 않아도 목표에 도달할 수 있습니다. 새 로딩 삽화는 실제 엔진 다운로드에 연결했습니다. PNG 2.37 MB 경량화는 남아 있습니다.

진행 중이던 이전 원정은 기존 5회 탐색으로 이어집니다. 귀환한 뒤 다시 출발하면 새 지도가 적용됩니다. 저장을 지울 필요가 없습니다. [지도 구현·검수 기록](ROUTE-PROTOTYPE.md)

GitHub 로그인이나 Tailscale, 개발 PC 없이 열 수 있습니다. WebGL 2를 지원하는 브라우저가 필요하며 첫 실행에는 엔진과 게임 데이터를 내려받습니다.

## 저장

진행 상황은 현재 브라우저의 IndexedDB에 저장됩니다. 다른 기기·브라우저와 자동으로 동기화되지 않으며, 사이트 데이터를 지우면 저장도 지워집니다. 이전 localhost/Tailscale 주소와도 별도 저장입니다.

## 구성

- `project/`: Godot 프로젝트와 GDScript 게임 소스, 원본 초상 및 도트 사본.
- `docs/`: GitHub Pages에 게시하는 웹 실행 파일. HTML·JS·WASM·PCK를 함께 배포합니다.
- `ASSET-HASHES.json`: 공개용 사본의 에셋 SHA-256. 원본 픽셀은 변경하지 않았습니다.
- `project/tests/`: 이전 원정 44개, 새 지도 41개, 전투 모델 54개 검사.

봇 원본 코드, 외부 작품 레퍼런스, 로컬 호스팅 설정과 개인 작업 로그는 이 저장소에 포함하지 않습니다. 게임에서 쓰지 않는 성격유형·이전 특성 메타데이터도 공개 사본에서 제외했습니다.

## 실행과 업데이트

Godot 4.7.2 Standard와 같은 버전의 Web export templates를 설치하고 `project/project.godot`를 엽니다. F6가 아닌 프로젝트 실행(F5)으로 거점에서 시작합니다.

```sh
godot --headless --path project --editor --import
godot --headless --path project --script tests/world_test.gd
godot --headless --path project --script tests/state_test.gd
godot --headless --path project --script tests/route_test.gd
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
| 봇·기획에서 가져온 값 | 캐릭터 기본 능력치와 성장 곡선, 최대 레벨 40, 물약 가격·회복률, 여관 비용·일일 제한, 출발 시 회복과 휴식 회복률. 기존 봇의 탐색 5회는 이전 저장에서만 유지 |
| 사용자 결정 | 별도 탐색 손패에 카드를 획득하고, 사용한 카드는 소모. 전투·탐색 사건에서 획득 |
| 검수용 예시 | 8개 장소와 연결·명칭, 시작 200금과 물품, 고정 사건, 전투당 40금·14XP, 발견 20금, 카드 이름·효과·지급량, 패배/귀환 시 카드 보존 |
| 연결 시험 | 마지막 전투에 기존 정예전 재사용. 보스 처치나 지름길 해금 기록은 지급하지 않음 |

## 라이선스 안내

Godot 및 엔진 의존성 고지는 `project/licenses/GODOT_AND_THIRD_PARTY.txt`, NanumGothic 고지는 `project/assets/fonts/OFL.txt`에 있습니다. 웹 빌드에도 `docs/licenses/`로 제공합니다. 저장소 공개는 게임 코드와 캐릭터 이미지의 별도 재배포·변경 라이선스를 부여하지 않습니다.
