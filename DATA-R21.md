# DATA-R21 — A 갈래 던전·적 데이터 이관

2026-10-31 · 작업 공간 `work/r21-a-data` · `ui_build: r21-a-data-20261031`

## 결과 수치

| 항목 | 결과 |
|---|---:|
| 적 / 계열 | 100 / 30 |
| 지역 / 실제 던전 구역 / 균열 | 10 / 9 / 6 |
| 원본 데이터 필드 불일치 | 0 |
| 편성·능력치 대조 조건 | 1,028개, 100% 일치 |
| 별도 개별 적 능력치 / 탐색 / 의뢰 규칙 대조 | 700 / 300 / 480개, 모두 일치 |
| Lua 대조 검사 항목 | 7,493개, 실패 0 |
| 던전 통합 검사 | 3,069개, 실패 0 |
| 1~420층 종결 경로 | 승리 420 / 패배 420 |
| 1~60층 자연 전투 표본 | 승리 147 / 패배 52 |
| 390·360 폭 이름표 | 3,200개, 넘침 0 |
| 원본 그림 바이트 보존 | 96/96, 변경 0 |
| 새 적 그림 미도착 시 역할별 대체 | 100/100 |
| 공통·신규 Godot 검사 | 18종 통과, 실패 0 |
| 실제 Web 입력·전투 복원·승리 후 원정 복귀 | 390·360, 2/2 통과 |
| Web export | 성공, 필수 리소스 누락 0 |

지역 10개에는 `common` 공통 적 풀이 포함된다. 원본의 실제 던전 구역은 아홉 개다. 숫자를 맞추려고 열 번째 던전을 만들지 않았다.

## 옮긴 데이터와 규칙

- `project/data/enemies-r21.json`: 원본 JSON의 적 100종과 계열·역할·등급·속성·행동·규칙·단계·tune·threat·templates를 원형대로 보존했다. 각 적에 원본 파일·JSON pointer·SHA-256과 `res://assets/enemies-r21/<id>.png`를 추가했다.
- `project/data/dungeons-r21.json`: zones 10·rifts 6, 원본 순서, 표준 적·성장 곡선·★·레벨 상한, 탐색 상수, 장비 발견용 순서·가중치, 호감·의뢰 보상 상수를 담았다. 출처와 해시를 넣었다.
- 1~27층은 아홉 구역을 3층씩 진행한다. 28층부터 27층 주기로 구역을 되풀이하고 `dk/dc`, ‘깊은’ 접두사, Lv40 하한, 심층 보상을 적용한다.
- 파티 평균 반올림 + 구역 안 순서 0~2, 구역 하한, Lv40 상한을 그대로 옮겼다.
- Park–Miller 난수 워밍업 4회, 가중 템플릿, 인원별 적 수, 전열·지원·소환·충전·공통·중복·위협·약점 합집합 제한, 40회 재시도, DFS와 `relaxed`, 빌려 온 정예·우두머리, 호위와 소환 예약 칸을 옮겼다.
- 능력치는 `stat_role`과 등급·개별 gauge를 반영한다. 층 log 곡선·단조 캐시, 구역별 우두머리/보스 보정, 심층 보스 `deep`, 탐색 전용 곡선, 3층 보정·초입 완화·소인원 완화를 반영했다.
- 탐색 5회 → 휴식 → 층 보스 → 정산을 구현했다. 전투 70%, 3층·3번째 탐색부터 정예 20%·최대 2회, 발견 50/35/15, SplitMix 방식의 int64 wrap·논리 시프트, 보스/전투 씨앗을 옮겼다.
- HP·MP 이어받기, 쓰러진 동료 HP 20%, 휴식 진입 때 전원 HP 30%·MP 60%, 금화·경험치 누적, 아이템/장비 정산, 패배 시 미정산 수확 소실·기본 소지 금화 손실, 최심층·첫 구역 보스·지름길을 연결했다.
- 균열은 한 번의 전투다. `depart_rift_quest(q, seed)`가 원본 의뢰 형식의 `rift/kind/stars/lv/gold/reward_v/difficulty/cmp/strength`를 받아 일반·정예·핵 편성, 보상, 엘리트 배율로 연결한다. 의뢰판과 마을 시설 UI는 D 갈래가 연결할 대상이다.
- 기존 r20 전투 모델에 새 적 행동 어휘, 소환 예약 칸, 보스 단계·약점 변경, 봉인·보호·고갈·기본 고유 규칙을 연결했다. 화면 렌더러의 칸 ID는 그대로 두고 원본 ID는 `foe_id`로 보존한다.
- 새 art 파일이 있으면 즉시 사용한다. 없으면 지원·소환→등불, 사격·주술→수정구, 방어/근접 정예·보스→집행 인형, 나머지 근접→견습 인형을 사용한다. `art_fallback`으로 셀 수 있다.
- 마을 파일은 모델 교체·출정/탐색 위임·현재 장소 제목 정도만 고쳤다. 기존 컨트롤을 재사용하는 최소 출정 UI는 `game/dungeon_view_r21.gd`에 있다. 전투는 이름·역할·층·빌드 표기와 긴 이름의 말줄임표/전체 툴팁, 큰 HP 숫자의 칸 안 맞춤을 바꿨다. 7칸 표본 이미지를 직접 열었을 때 HP가 이웃 칸과 겹쳐, 새 데이터 조건에서만 숫자를 가로로 맞추고 정확한 숫자는 보존했다. r20 잉크·컷인·효과·배치 자산은 수정하지 않았다.

## 저장과 기존 시험

기존 schema 1·2 저장을 읽는다. 진행 중인 옛 원정·기존 네 적 전투는 해당 원정이 끝날 때까지 기존 모델을 사용한다. 새 원정은 기존 schema 2에 `dungeon_r21`과 run의 `data_version=21`을 추가한다. 저장 파일을 지우거나 초기화하지 않는다. 새 전투의 단계와 소환 roster도 저장·복원한다.

검사에는 schema 1, schema 2의 진행 중 전투, 새 원정 JSON 왕복, 같은 씨앗의 이어하기, 단계 2 + 하수인 2명 복원, 잘못된 층·roster·진행 정보 거부를 포함했다. 기존 시험의 기대값은 바꾸지 않았다.

JSON은 숫자를 float로 읽고 GDScript Dictionary 키에는 StringName도 있으므로 새 이어하기 검사는 저장 형식의 타입 차이를 정규화하고 숫자 값은 정확히 비교한다. Web 진단 JSON에는 CTB remaining 값의 약 1e-11 반올림 차이가 있어 해당 브라우저 비교만 절대 오차 1e-8을 허용했다. HP·MP·RNG·차례·게임 결과는 보존했다.

## 원본 조사와 대조 방식

정본 루트: `C:/Clauede Code/dungeon-bot`. JSON은 전체 파싱·필드 대조했고, Lua는 원본 하네스의 wasmoon으로 실행하면서 아래 파일과 관련 함수 구간을 검토했다. 파일별 정확한 해시는 `verification/data-r21/source-inventory.json`, 출처 pointer는 새 데이터에 남겼다.

| 조사 파일 | 파일 범위 |
|---|---|
| `design/enemies.json` | 1–5533 |
| `design/ENEMIES.md` | 1–803 |
| `design/DUNGEON.md` | 1–346 |
| `design/EXPEDITION.md` | 1–166 |
| `design/stats.json` | 1–2561 |
| `bot/src/20-state.lua` | 1–370 |
| `bot/src/24-stats.lua` | 1–184 |
| `bot/src/26-start.lua` | 1–86 |
| `bot/src/27-compose.lua` | 1–403 |
| `bot/src/31-foes.lua` | 1–545 |
| `bot/src/72-guild.lua` | 1–370 |
| `bot/src/74-affection.lua` | 1–65 |
| `bot/src/76-dungeon.lua` | 1–117 |
| `bot/src/77-explore.lua` | 1–924 |
| `bot/src/51-raid.lua` | 1–99 |
| `bot/src/81-gear.lua` | 1–1204 |

주요 검토 구간: `24-stats` 전체, `27-compose` 전체, `20-state`의 `foe_def/blank_u/fresh`, `31-foes`의 행동·단계·보상, `76-dungeon` 전체, `77-explore` 14–76(상수·추첨), 98–120(입장 씨앗), 199–525(전투·휴식·정산), 650–924(진행 버튼·화면·이관), `51-raid` 전체, `72-guild`의 전투 종류·레벨 보상·의뢰 금화, `81-gear`의 `gear_drop/gear_code`이다. 문서에서는 `DUNGEON` 101–145의 확정 흐름과 `ENEMIES`의 조합·심층·레이드·최신 튜닝을 우선했다. 폐기된 갈림길 설계를 되살리지 않았다.

`tools/oracle_data_r21.mjs`는 원본 `lua_sim.mjs`/RisuSim/wasmoon을 읽기 전용으로 사용하며, 원본 src를 다시 올려 실행한다. 원본 파일을 생성·빌드·수정하지 않는다. 각 표본의 ctx·seed·enc·el·stats·탐색/의뢰 결과는 `lua-oracle.json`에 남겼다.

편성 표본은 1~60층 × 1~4인 × 일반/정예/층 보스, 81·108·135·270·420층 추가 표본, 균열 6개 × ★1~4 × 1~4인 × 일반/정예/핵이다. 개별 적은 100종 × 1·2·3·27·28·55·420층이다. 탐색은 60층 × 5회, 의뢰는 Lv1~40 × 난이도 4 × 목표 3이다. 편성·레벨·금화·아이템/장비 코드 등 이산 값은 정확히 같고, Lua JSON이 표시하는 능력치 실수는 상대 오차 1e-12/절대 1e-10 이내로 대조했다.

1~420층의 승리·패배 840건은 결과 경로를 모두 통과시키기 위해 공격력만 조절한 시험 fixture다. 별도로 1~60층에서는 수치를 바꾸지 않고 기본 공격 정책으로 탐색부터 종결까지 진행했다. 자연 전투 승패는 밸런스 목표나 원본 Lua 승률과의 동등성을 뜻하지 않는다. 끝없는 층 전체를 유한 검사로 전부 검증했다고 주장하지 않는다.

## 검사 결과

| 검사 | 결과 | 실패 |
|---|---|---:|
| import | 통과 | 0 |
| world_test | 통과 | 0 |
| state_test | 통과 | 0 |
| route_test | 통과 | 0 |
| expansion_test | 통과 | 0 |
| motion_test | 통과 | 0 |
| motion_asset_test | 통과 | 0 |
| art_test | 통과 | 0 |
| export_licenses | 통과 | 0 |
| data_r21_test | 통과 | 0 |
| dungeon_r21_test | 통과 | 0 |
| ui_battle_r17_test | 통과 | 0 |
| ui_battle_r18_test | 통과 | 0 |
| ui_battle_r19_test | 통과 | 0 |
| ui_battle_r20_test | 통과 | 0 |
| motion_r9_integration | 통과 | 0 |
| motion_r18_integration | 통과 | 0 |
| ui_data_r21_test | 통과 | 0 |

실행 명령과 전체 로그는 `verification/data-r21/`에 있다. 재현 명령:

```powershell
node tools/oracle_data_r21.mjs
python tools/import_data_r21.py
python tools/audit_data_r21.py
python tools/verify_data_r21.py
python tools/export_data_r21.py
python tools/web_data_r21.py
python tools/report_data_r21.py
```

Windows 격리 환경에서 Godot가 출력하는 `Failed to read the root certificate store`는 모든 실행에 반복되는 환경 진단이다. 검사/스크립트 오류와 분리해 기록했으며, 그 외 엔진 오류는 0이다. 네트워크 기능을 시험한 것은 아니다.

Web은 지시한 `python tools/godot_r17.py --headless --export-release Web ../docs/index.html` 뒤 `python tools/update_version.py`로 생성했다. PCK 53,576,236 bytes, SHA-256 `812d35e1fb38310ca1d71becd01e29fbc6e4ebe0794624ae2337bf77cf99bf0a`. 필수 JSON·게임 스크립트 6개 포함을 확인했다. 두 브라우저 폭에서 실제 포인터로 출정·탐색·공격·새로고침·승리 후 원정 복귀를 검증했다.

직접 연 이미지: `battle-390-5.png`, `battle-360-7.png`, Web의 `selector-360.png`, `battle-390.png`, `return-360.png`. 말줄임표와 전체 툴팁, 역할·약점·HP·층 표기를 확인했다. 새 적 전용 그림 100종은 아직 없으므로 대체 그림의 적별 외형 적합성까지 확인한 결과는 아니다.

## 원본 대비 차이·남은 통합

1. 데이터·편성·초기 능력치·탐색 추첨·기본 의뢰 보상은 위 Lua 표본과 일치한다. **전투 전체의 턴별 결과가 Lua와 같은 엔진으로 교체된 것은 아니다.** 기존 `battle_v3.gd`의 아군·CTB·난수 모델을 유지했다. 지속 피해 중첩/갱신, 광폭화 라운드 계산, 일부 고유 행동의 부가 효과·출신/장비 보상 훅 등은 웹 모델의 호환 구현이며 전체 Lua 전투 동등성은 검증하지 않았다.
2. 원본의 rest 정비·서사/채팅 게이트·다음 층 즉시 이동 UI와 길드 의뢰판 생성 전체는 이번 A UI에서 옮기지 않았다. 다음 열린 층은 출정 선택에서 고른다. 균열은 `depart_rift_quest` API로 연결하며, 원본 의뢰판에 현재 없는 네 균열의 해금 조건은 만들지 않았다. API의 원본 의뢰 스펙을 넘기지 않은 내부 균열 시험에는 고정 금화 보상 ‘없음’(0)으로 처리한다.
3. 원본 북동 화산의 데이터는 ★4지만 `compose`가 균열 ★를 3으로 누르는 원본 동작을 보존했다. 문서의 옛 곡선/드랍 설명과 현재 JSON·Lua 값이 다르면 현재 JSON·실행 코드를 따랐다.
4. 원본 `B.tx_*` 출신 시너지의 탐색 추가 수확·휴식 추가 회복·패배 보존과 원본 장비 효과의 모든 보상 훅은 추가 이관하지 않았다. 기본 파티/기본 규칙 기준 검증이며 이 훅을 포함한 결과 일치를 주장하지 않는다. 새 전투 전용 적 그림은 B 갈래 파일 도착 시 자동 선택한다.
5. 성적 콘텐츠는 이관하지 않았다. 해당 원본 파일 목록: `bot/src/79-sex.lua`(참조 목록만 기록). 성적 장면·친밀도 장면 생성이나 UI는 추가하지 않았다.

## 바꾼 파일과 D/B 갈래 연결 지점

- 데이터: `project/data/enemies-r21.json`, `project/data/dungeons-r21.json`.
- 게임: 새 `dungeon_rules_r21.gd`, `dungeon_world_r21.gd`, `dungeon_enemy_r21.gd`, `dungeon_view_r21.gd`; 기존 `battle_v3.gd`의 새 데이터 조건부 처리.
- UI: `project/ui/world_screen.gd`의 최소 진입/위임, `project/ui/battle_screen.gd`의 이름·역할·숫자 맞춤·빌드 표시. `_location()`의 기존 floor 지원을 새 데이터로 활성화했다.
- 검사: `project/tests/data_r21_test.gd`, `dungeon_r21_test.gd`, `ui_data_r21_test.gd`.
- 도구: `tools/oracle_data_r21.mjs`, `import_data_r21.py`, `audit_data_r21.py`, `verify_data_r21.py`, `export_data_r21.py`, `web_data_r21.py`, `report_data_r21.py`; 기존 `update_version.py`의 ui_build. README 맨 위 한 줄.
- 산출물: `verification/data-r21/**`, `DATA-R21.md`. 공통 검사/명시된 Web export가 요구한 기존 verification·라이선스·`docs/index.*`·`docs/version.json` 재생성도 포함한다. 새 게임/시험 스크립트의 Godot `.uid`는 자동 생성됐다.

B: `project/assets/enemies-r21/<원본 id>.png`를 넣으면 대체가 해제된다. D: `dungeon_world_r21.gd`를 모델로 사용하고 `depart_dungeon(floor, seed)` / `depart_rift_quest(source_quest, seed)` / `advance()` / `final_battle()` / `battle_data()` / `record_battle()` / `finish_battle()`를 호출하면 된다. 원본 수치 조회·순수 편성 검증은 `dungeon_rules`를 사용한다. 다른 worktree에는 쓰지 않았고 git 명령은 실행하지 않았다.
