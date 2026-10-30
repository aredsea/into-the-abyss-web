# Review ledger

(`docs/` is the GitHub Pages web root in this repo, so the ledger lives at the repo root.)

## 누적 판정 — 다시 묻지 마라

| 모델 | 지적 | 판정 | 근거 |
|---|---|---|---|
| openai/gpt-5.6-luna | P1 보급품 사용 시 모델에 남은 `selected_ally` 로 소비 | 채택·수정(a15f82b) | 아군 미탭 상태에서 사용하기 가능 — 회귀 시험 red→green |
| openai/gpt-5.6-luna | P2 360×780 작은 적/집행 인형 터치 영역 6px 겹침 | 채택·수정(a15f82b) | controls rect 교차 — 회귀 시험 red→green |
| openai/gpt-5.6-luna | P2 `small_height` 하한 없음(전장 < ~57px 에서 음수) | 기각 | 전장 높이 = 288+(뷰포트h−844), stretch aspect=expand·기준 360×780 → 논리 높이 ≥780, 전장 ≥224 |
| claude-opus-4-7 | P1 레거시 BattleState 전투에서 보급품 → `selected_ally` 접근 충돌 | 채택·수정 | 이전 파일은 ModernBattle 일 때만 버튼 표시; 진행 중 구규칙 전투(expansion_world.gd:382)로 도달 가능 — red(크래시)→green |

## 회차

### 2026-10-31 · r17 전투 UI 구현 (b21156a..)
- 대상 diff: project/ui, project/tests/ui_battle_r17_test.gd, print.gdshader, export 설정·라이선스 (docs/·verification/·tools/*.py 제외)
- 등급: **T2** — battle_screen.gd 723줄 재작성, 보급품 사용·대상 지정 등 실제 모델 호출과 얽힘. 게임 규칙·데이터 불변, 되돌리기 쉬움(브랜치).
- 구현: 로컬 Codex gpt-6.1-sol high(304bb11). 수정: Claude Opus 5.5(a15f82b, 레거시 수정).
- 외부: openai/gpt-5.6-luna (OpenRouter, high) R1 지적 2 / 채택 2 · R2 지적 1 / 기각 1.
- Opus 자리: claude-opus-4-7 (`opus47-reviewer`, Claude 가 수정 일부를 짰으므로 자기 검수 회피) R1 지적 1 / 채택 1 · R2 지적 0.
- 결과: 채택 지적 잔여 0. 결정론 게이트 전부 실패 0 (world 44 · state 54 · route 41 · expansion 3,350 · r17 입력 2,931 · r9 944 · motion/asset/art/licenses PASS).
