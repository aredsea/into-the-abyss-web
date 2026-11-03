# R23-expe — 6차 기능 등가 대조

남은 38행을 끝까지 재검토했다. **같음 7행 추가, 누적 같음 77행 / 제외 1행 / 남음 31행**이다. 수정·보강한 행은 17행이며 이 중 10행은 전체 차이가 남아 승격하지 않았다. 원본 기능 전체 이식은 완료하지 못했다.

|항목|이번 결과|
|---|---:|
|검토 / 같음 승격 / 수정·보강 / 남음|38 / 7 / 17 / 31|
|새 native 단언|272, 실패 0|
|새 실제 UI 단언|1,908, 실패 0|
|실제 표시 입력을 정본 Lua로 재실행|44/44 일치|
|원본 실행 fixture|228 (표시 196 + 초상 20 + 정산 12)|
|전체 프로젝트 검사|120/120 그룹, 실패 0|
|전투 대조|6,320판 / 219,785기록, 차이 0|
|서버 저장 validate|6/6|
|기존 같음 / 제외 행 보존|70 / 1, 행 객체 변경 0|
|보호 이미지 / 정본 Lua|96개 변경 0 / 46개 변경 0|
|기존 변경 파일|7개, 허용 범위 밖 0|
|새 대조 자료 최대 크기|1,137,776 bytes, 40MB 이하|

승격: P2752(초상 실패 fallback), P2753(아이콘/제목), P2754(시설 버튼 전체 이름과 설명), P2755(의뢰 별 반복), P2756(빈/임의 안내), P3017(의뢰 카드 묶음), P3018(4칸 슬롯/번호/순서/제거).

의뢰의 제목·설명·종류·난이도·금화·적 레벨·별을 함께 표시했다. 4칸은 persona부터 파티 순서로 표시하며 빈 칸에는 원본 번호를 붙였다. persona 칸은 지휘로 전환하고 동료 칸은 제거한다. 직접 참전/지휘 문구, 마지막 동료 대기·만석 메시지와 모드 전환을 연결했다. 층 목록은 잠김 이유·추천/돌파·쪽 수·보스/일반 금화·4인 추천 설명을 추가했다. 후보/요약과 원본 데이터·초상 바이트는 유지한다.

마을은 기존 hero·파티·출정·시설 위치와 색·서체를 보존하고, 기존 시설 영역 안의 스크롤에 본문·전체 장소 설명·의뢰 출정·최고층 안내를 추가했다. 새 단축 버튼은 실제 이동/모드 선택에 연결한다. 퇴각 확인은 별도 안내 아래 원본처럼 층/발견/파티/물약 정보를 함께 보존한다. 패배 뒤 live run을 없애고 마을로 돌아가며, 원본 손실 알림과 D.last/native summary를 보존한다. 케른 유지·중복 정산·저장 재개도 대조했다.

실패를 보존한 첫 대조는 expe-pass6-before-results.json(216/216 미구현 경계 실패)이다. 그 같은 표시/초상 216건은 최종 모두 통과하며 정산/이관 56개 단언을 더해 272개다. 모든 텍스트·버튼·활성·순서는 Lua HTML에서 추출해 native 결과와 비교했다. 실제 그린 입력 44건도 다시 Lua에 넣어 일치했다. native 렌더러의 DTO끼리만 비교한 결과를 원본 대조로 세지 않았다.

클라우드 검사에서 source 전용 dungeon.mode를 서버가 거부했다. 첫 전체 실행(expe-pass6-suite-final)은 26그룹 통과 시점에 중단하고 완료 증거로 쓰지 않았다. ui.sel의 기존 자유 문자열 필드에 모드를 보존하도록 고쳐 native/서버 계약을 맞췄고, 먼저 생긴 local mode 저장은 복사본에서 이관한다. 서버·저장 schema·기존 검증 규칙을 바꾸지 않았다. 이후 expe-pass6-suite-verified는 로컬 node server/abyss-save/test/serve.mjs에서 전부 새로 돌렸고, 검사 중 GDScript 변경은 0이다. 기존 시험 기대값 수정은 없다.

남은 31행의 원본 위치·이전 상태·새 시험/수정 위치·이유는 [expe.json](verification/parity-r23/expe.json)과 [expe-pass6-row-audit.json](verification/parity-r23/expe-pass6-row-audit.json)에 있다. 단순 HTML/캔버스·저장 매체 차이를 남은 이유로 삼지 않았다. 시설/장비/전투 파일은 수정하지 않았다. 실제품 의뢰 정산 override, 전투 HUD와 아이템, inline 정비 후보, overflow 보존 정책은 해당 갈래 수정 금지와 연결된다. 그 외 남은 전체 화면 순서, legacy 출정/옛 stage/canonical 저장 입력, continuation 무효 경계도 아직 미완료다. 클래스가 없는 옛 저장의 참전 비활성·persona host 아바타 차이가 있어 관련 전체 행은 승격하지 않았다.

24장(360×780/390×844, 한국어/영어)을 직접 열어 확인했다. 렌더 결과는 expe-pass6-render/와 expe-pass6-sheet-*.png, 검수 기록은 expe-pass6-visual-review.json이다. native 합성 마우스/스크롤 시험이며 브라우저·Web/WASM·물리 기기는 확인하지 않았다. Impeccable detector는 []였다. 기존 DESIGN.md/.impeccable/design.json의 갱신 시점 차이는 유지했고, 별도 document 작업으로 동기화할 수 있다.

재현: node tools/expe_r23_pass6_oracle.mjs → python tools/expe_r23_pass6_project.py → python tools/godot_r17.py --headless --script res://tests/expe_pass6_r23_test.gd. UI는 같은 래퍼로 --position -10000,-10000 --script res://tests/ui_expe_pass6_r23_test.gd 실행 후 node tools/expe_r23_pass6_ui_oracle.mjs → python tools/expe_r23_pass6_ui_verify.py. 저장은 node tools/expe_r23_pass6_saves.mjs. 전체 검사는 새 EXPE_SUITE_NAME으로 tools/expe_r23_pass5_verify.py를 실행한다. 사용자 실제 저장 파일 접근/삭제·git 명령·commit·Web export·docs 수정·버전 갱신은 없다.
