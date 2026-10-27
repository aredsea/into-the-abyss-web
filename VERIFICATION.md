# 검증 기록 — 2026-10-27

빌드: `world-public-20261027-r1`. [공개 Pages 주소](https://aredsea.github.io/into-the-abyss-web/)에서 인증 없는 새 Chromium 세션으로 실행과 저장을 확인했습니다. Pages 게시 상태 `built`, HTTPS 활성화를 확인했습니다.

- 공개용 소스에서 Godot 모델 검사: 원정 44개, 전투 54개, 실패 0개.
- 공개용 Web 빌드를 하위 경로 `/docs/`에서 Chromium 390×844, 360×780으로 실행.
- 구매, 하루 교류 제한, 동료 상세, 가방, 카드 획득과 1회 소모, 탐색 5회, 실제 전투 2번, 휴식, 정산과 성장 확인.
- 탐색 도중·전투 도중·정산 후 새로고침 시 IndexedDB 저장 복원 확인.
- 두 크기에서 가로 넘침과 브라우저 콘솔 오류 없음. 거점 스크린샷 두 장은 직접 열어 확인.
- 공개용 에셋 사본 31개를 이전 검수본과 바이트 대조. 원본 캐릭터 이미지와 도트 변경 없음.
- 원본 OFL 라이선스 파일은 바이트 그대로 보존.
- Windows headless Godot의 루트 인증서 저장소 경고는 남음. 내보내기와 엔진 검사는 정상 종료.
- 실제 휴대폰·Safari·Firefox·다른 네트워크는 미검증. 시각 품질 합격 판정은 사용자에게 있음.

## 공개 주소에서 다시 확인한 내용

- 390×844와 360×780에서 구매·교류·동료 상세·카드·탐색 5회·전투 두 번·휴식·정산·레벨 상승을 실제 UI로 진행했습니다.
- 전투 및 탐색 도중, 정산 후 새로고침해 저장 복원을 확인했습니다.
- 합성 터치로 목록 스크롤, 전열 자리 교환, 숙박, 귀환 취소와 확인, 보상 중복 방지를 확인했습니다.
- 브라우저 콘솔 오류 0개, 가로 넘침 없음. 공개 주소의 거점 스크린샷 두 장을 직접 열어 확인했습니다.
- PCK와 WASM 응답은 HTTP 200이며 공개 파일의 SHA-256이 로컬 빌드와 일치합니다. WASM MIME 타입은 `application/wasm`입니다.
- 결과: `verification/qa.json`, `verification/public-touch-qa.json`, `verification/files.json`. 화면: `verification/town_390.png`, `verification/town_360.png`.

Pages 게시 원본은 [`main` 브랜치 `/docs` 방식](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)을 사용하도록 준비했습니다.
