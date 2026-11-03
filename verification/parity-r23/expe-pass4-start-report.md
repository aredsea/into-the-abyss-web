# R23-expe — 3차 원본 대조

기존 같음 34행을 그대로 보존하고 남은 75행 전부를 실행·검토했다. **이번 같음 +9, 누적 43/109행 같음, 66행 남음**이다. 이번 구현·연결 근거는 8행(같음 승격과 겹침)이며 단순 가중치 추출 1행은 동작 수정으로 세지 않았다. 원본 전 기능 완료는 아니다.

|항목|결과|
|---|---:|
|이번 검토 / 승격 / 구현·연결 / 남음|75 / 9 / 8 / 66|
|새 native 검사 단언|63,491 / 실패 0|
|누적 대조·검사 단언|100,698|
|남은 원본 함수 호출|75 / 75|
|행별 명시 진입 도달(중첩 포함)|211 / 318|
|전체 프로젝트 검사|112 / 112 그룹, 실패 0|
|기존 전투 대조|6,320판 / 219,785기록, 차이 0|
|서버 검증을 통과한 새 저장 표본|3 / 3|
|보호 이미지|96개, 변경 0|
|허용 밖 기존 파일 변경|0|

승격: P3061, P3073, P3119, P3123, P3138, P3176, P3199, P3201, P3307. 행별 이전 상태·원본 위치·시험·구현 줄·동등성 범위·남은 이유는 [expe.json](verification/parity-r23/expe.json), 이번 75행 검토는 [expe-pass3-row-audit.json](verification/parity-r23/expe-pass3-row-audit.json)에 있다.

## 바뀐 동작과 대조

- 출전 편성의 전체 pm/n/avg를 장비 코드·제련 사전·선택적 기술까지 비교했다. 잘못된/중복/초과 인물과 빈 편성도 포함한다. 실제 출발의 초기 자원 계산이 이 transient 편성을 사용한다.
- 전투 후 이월을 원본의 al/empty/4슬롯 배열 계약으로 분리했다. 640입력에서 HP/MP 내림·부상자 이월·빈 슬롯 보존·fell/real을 직접 비교하고 실제 native 전투 결과에 연결했다.
- 경험치 정산은 의존 함수 부재·실패·비표·빈 표/목록과 실제 지급/중복 번호 120입력을 비교했다. 호감은 한·영 전체 문자열과 실제 지급 후 값, 솔렌 3인 이상 시너지, -100/99.9/100/199.9/200 경계를 포함했다. 명시적 provider envelope는 Lua pcall 결과를 표현하며 Godot 예외를 포착한다고 주장하지 않는다.
- 가중치 closure와 1,440개의 실제 선택, 독립 zero4 배열, 던전 정규화, 한·영 위치 라벨을 직접 비교했다. 탐색 기록과 정산 호감 표시에 연결했다.

## 실패 확인과 저장 보존

새 API 호출 전 6개 부재 guard 실패를 보존했다(expe-pass3-missing-api-before.json). 이를 기존 수치 버그 6개로 세지 않았다. 최초 새 fixture에는 Lua 빈 map/array 구분 오류와 미존재 장비 id로 만든 불완전 native entry가 있어 Script error가 났다. source-record schema를 명시해 fixture를 고쳤으며 실패 수를 제품 버그로 전파하지 않았다. 원본 계측의 closure 노출 위치 오류와 Lua nil 선택 fixture 오류도 최종 결과에 포함하지 않았다.

첫 전체 검사 시도에서 source 전용 mode/장비·제련/문구 필드를 저장에 넣으면 서버 allowlist와 충돌함을 확인했다. 기존 저장 ABI를 보존하고 source 기록과 표시 문자열을 transient 변환/재계산으로 옮겼다. 두 번째 시도에서 유효한 JSON 숫자를 float에서 int로 바꾸면 exact Dictionary 왕복 비교가 깨지는 1건을 확인해 유효 값의 자료형을 보존했다. 두 시도는 중단·보존했으며 최종 통과 그룹 수에 포함하지 않는다.

추가 호감 포맷 경계 605검사에서 12차이를 먼저 확인했다. ±0.25/1.45/1.95 등의 실제 이진 실수와 원본 C printf의 반올림을 맞췄다. 실제 native 호감 증감 범위 [-300,300]의 0.01 간격 60,001값 및 한·영 실제 정산 4검사는 총 60,005검사 / 실패 0이다. 이 수정은 단순 새 API 구현과 구분되는 실제 문자열 차이 수정이다.

기존 battle_r23_test와 gear_r23_test가 oracle.json을 공유해 전투 검사에 rows가 없는 fixture가 들어가는 사전 충돌도 발견했다. 전투 검사의 fixture 경로 1줄만 분리하고, 원래 oracle 도구는 수정하지 않은 채 in-memory 출력 경로만 바꾸는 wrapper로 실제 Lua 2,508입력을 재생성했다. 전투 제품·비교 기대값/단언 변경은 없다.

전체 111그룹 실행을 보존한 뒤, 마지막 포맷·fixture 경로 수정의 전이 GDScript 의존성과 각 실행 시작 시각을 대조했다. 수정 전에 시작한 영향 검사와 새 검사만 다시 실행했고, 그 외에는 변경 파일을 읽지 않거나 수정 뒤 새 engine으로 시작한 결과를 유지했다. 세부 목록·시각·해시는 expe-pass3-refinement.json, 원래 전체 실행은 suite-expe-pass3-main/, 최종 그룹별 결과는 suite-expe-pass3-final/에 있다. 최종 잠금은 재검사 중 변경 0이다.

추가 native 표본 검사 최초의 persona.member 오류는 숫자 대조 fixture가 persona.lv만 변경하고 native member mirror를 갱신하지 않은 fixture 문제였다. 별도 save probe에서 native 불변식을 맞춘 마을/진행/정산 3저장을 만들었고, 수정하지 않은 서버 validate로 전부 통과했다. native JSON 왕복 전체도 정확히 일치했다.

저장 schema/version 변경·기존 사용자 저장 접근 없음. 옛 저장 회귀도 전체 검사에 포함한다. 서버 파일은 변경하지 않았다.

## 실행 근거와 제한

원본 Lua는 정본 dist/bot.lua와 lua_sim/Wasmoon으로 실행했다. 지시에서 제외한 79-sex의 화면 hook 3개는 양쪽 oracle에서 비활성화했고 해당 HTML 동등성은 주장하지 않는다. source 복사본에 함수·then/else/do 진입 probe를 넣었고 계측 전후 출력이 정확히 같았다. 75함수 호출과 211/318 진입은 실행 근거이며 조건 조합 완전성이나 native 전체 일치를 뜻하지 않는다. 남은 HTML·호스트·전투/장비/시설 행에는 실행 근거만 추가했다.

원본 파일·docs/·server/·보호 이미지 바이트는 시작 manifest 대비 동일하다. Web export·버전 갱신·git 변경 명령·커밋 없음. 실제 D1 로컬 서버는 serve.mjs 진입점을 실행했고 loopback 고유 포트/격리 TEMP/제어 파일로 준비·쿼터 초기화·정상 종료를 확인했다. 긴 TEMP 경로에서 workerd 초기화가 실패해 기존 짧은 .p6tmp를 사용했다. root certificate store 진단만 제외하고 Script error/다른 ERROR는 실패로 센다.

정산·360px 탐색 기록·360px 저장 재개 퇴각 화면 3장을 직접 열었다. 정산 호감 문자열과 다음 층/귀환 버튼, 탐색 기록의 위치·물품 이름, 퇴각 확인/취소 버튼을 확인했다. 긴 정산 안내는 두 줄로 감긴다. 이미지 목록과 해시는 expe-pass3-visual-review.json에 있다. 전수 이미지·Web/WASM·실기기는 확인하지 않았다.

변경한 기존 제품 파일: project/game/dungeon_world_r21.gd, project/game/expedition_world_r22.gd, project/ui/expedition_screen_r22.gd. 기존 검사 변경은 project/tests/battle_r23_test.gd의 fixture 경로 1줄이다. 새로운 oracle/test/coverage/report/검사 도구는 tools/, project/tests/, verification/에 있다. 전체 로그: verification/parity-r23/suite-expe-pass3-final/. 새로 전부 재실행할 때는 python tools/coverage_expe_r23_pass3.py → node tools/expe_r23_format_oracle.mjs → node tools/expe_r23_battle_fixture.mjs → python tools/verify_expe_r23_pass3.py → python tools/expe_r23_pass3_save_verify.py → python tools/report_expe_r23_pass3.py.

남은 66행은 원본 HTML/버튼 전체 반환, Risu 호스트 pending·메시지/장면/옛 저장 ABI, 전투 기록·장비 가방·마을/시설 규칙의 허용 밖 작업이 핵심이다. 성적 콘텐츠는 이식하지 않았고 charm_potion 이름 등 제외 항목은 이전 이유를 유지했다. 세부 이유는 ledger 각 행에 있다.
