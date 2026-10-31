# Review ledger

(`docs/` is the GitHub Pages web root in this repo, so the ledger lives at the repo root.)

## 누적 판정 — 다시 묻지 마라

| 모델 | 지적 | 판정 | 근거 |
|---|---|---|---|
| openai/gpt-5.6-luna | P1 보급품 사용 시 모델에 남은 `selected_ally` 로 소비 | 채택·수정(a15f82b) | 아군 미탭 상태에서 사용하기 가능 — 회귀 시험 red→green |
| openai/gpt-5.6-luna | P2 360×780 작은 적/집행 인형 터치 영역 6px 겹침 | 채택·수정(a15f82b) | controls rect 교차 — 회귀 시험 red→green |
| openai/gpt-5.6-luna | P2 `small_height` 하한 없음(전장 < ~57px 에서 음수) | 기각 | 전장 높이 = 288+(뷰포트h−844), stretch aspect=expand·기준 360×780 → 논리 높이 ≥780, 전장 ≥224 |
| claude-opus-4-7 | P1 레거시 BattleState 전투에서 보급품 → `selected_ally` 접근 충돌 | 채택·수정 | 이전 파일은 ModernBattle 일 때만 버튼 표시; 진행 중 구규칙 전투(expansion_world.gd:382)로 도달 가능 — red(크래시)→green |
| openai/gpt-5.6-luna | P1 signature_sequence.gd:43 · battle_screen.gd:475 따옴표 누락(파싱 오류) | 기각 | 검수자 콘솔이 한글을 깨뜨린 착시 — 파일은 정상 UTF-8, 스크립트 로드·r18 4,592/r17 2,931 검사 통과 |
| openai/gpt-5.6-luna | P2 360폭 작은 적 4마리 겹침 | 기각 | 전투 데이터는 늘 lantern/apprentice/orb+executor 고정(작은 적 ≤3), expansion_world 는 수치만 조정 |
| openai/gpt-5.6-luna | P2 적 래스터를 재구성마다 다시 샘플링 | 채택·수정 | 크기별 정적 캐시(`enemy_pixels`) — R2 확인 지적 0 |
| openai/gpt-5.6-luna | P1 5~6행동 동료의 방어(guard)가 기술 시트에서 빠져 도달 불가 | 기각 | `_skill_ids()` 는 행동이 4개 초과면 guard 를 남긴다(`id!="guard" or ids.size()>4`); r19 실제 포인터 입력 검사가 10명 전원의 비공격 행동 존재를 확인 |
| openai/gpt-5.6-luna | P2 시트 하단 버튼이 시트(245px)보다 2px 아래로 나옴 | 기각 | 시안 DOM 대비 ≤2px 위치이고, 아래 아군 카드는 시트 시작+255px 에서 시작해 겹치는 요소 없음, 배경도 같은 종이색 |

## 회차

### 2026-10-31 · r17 전투 UI 구현 (b21156a..)
- 대상 diff: project/ui, project/tests/ui_battle_r17_test.gd, print.gdshader, export 설정·라이선스 (docs/·verification/·tools/*.py 제외)
- 등급: **T2** — battle_screen.gd 723줄 재작성, 보급품 사용·대상 지정 등 실제 모델 호출과 얽힘. 게임 규칙·데이터 불변, 되돌리기 쉬움(브랜치).
- 구현: 로컬 Codex gpt-6.1-sol high(304bb11). 수정: Claude Opus 5.5(a15f82b, 레거시 수정).
- 외부: openai/gpt-5.6-luna (OpenRouter, high) R1 지적 2 / 채택 2 · R2 지적 1 / 기각 1.
- Opus 자리: claude-opus-4-7 (`opus47-reviewer`, Claude 가 수정 일부를 짰으므로 자기 검수 회피) R1 지적 1 / 채택 1 · R2 지적 0.
- 결과: 채택 지적 잔여 0. 결정론 게이트 전부 실패 0 (world 44 · state 54 · route 41 · expansion 3,350 · r17 입력 2,931 · r9 944 · motion/asset/art/licenses PASS).

### 2026-10-31 · r18 전투 크기·이펙트·고유 스킬 컷인 (f8f77dc..)
- 대상 diff: project/ui, project/tests (docs/·verification/·tools/*.py 제외)
- 등급: **T1** — 표시 계층만, game/data 불변, 되돌리기 쉬움(브랜치). contact 1회·skip 불변식은 r18 상태 통합 3,540 검사가 덮음.
- 구현: 로컬 Codex gpt-6.1-sol high(e30c454). 수정: Claude Opus 5.5(적 래스터 캐시).
- 외부: openai/gpt-5.6-luna (OpenRouter, high) R1 지적 4 / 채택 1 · 기각 3 · R2 지적 0.
- 결과: 채택 지적 잔여 0. 게이트 실패 0 (world 44 · state 54 · route 41 · expansion 3,350 · r17 입력 2,931 · r9 944 · r18 4,592 · r18 상태 3,540 · motion/asset/art/licenses PASS · export exit 0).

### 2026-10-31 · r19 승인 시안 배치 일치 (d23627c..)
- 대상 diff: project/ui, project/tests, export_presets.cfg
- 등급: **T1** — 표시 계층(배치·시트 진입·표시용 기록·웹 배율), game/data 불변, 되돌리기 쉬움(브랜치).
- 구현: 로컬 Codex gpt-6.1-sol high. 수정: Claude Opus 5.5(테스트 무음 오디오, 웹 1:1 배율을 휴대폰 세로·360×780 하한으로 제한, 전장 경계 잉크 프레임 클리핑).
- 외부: openai/gpt-5.6-luna (OpenRouter, high) R1 지적 2 / 기각 2.
- 결과: 채택 지적 잔여 0. 게이트 실패 0 (r17 입력 3,299 · r18 4,592 · r18 상태 3,540 · r19 859 · 기존 전부) · 웹 5개 크기(390×844·360×780·360 축소·390×664·1280×800) 통과.
