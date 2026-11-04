**EN-R24 — 완료 / 30명·14,216개 영어 번역 및 검증**

이번 3차 실행에서 남은 18명·8,580개 표시 문구를 직접 번역했다. 기존 12명·5,636개를 합쳐 **30명·14,216개 전부 완료**했다. 실제 영어 표시 함수를 거친 authored-language-audit의 한국어 잔존은 **0개**다.

| 항목 | 결과 |
| --- | ---: |
| 완료 인물 / 표시 문구 | 30명 / 14,216개 |
| 이번 실행 추가 | 18명 / 8,580개 |
| 실제 영어 표시의 한국어 잔존 | 0개 |
| 3명 묶음 검사 | 6묶음·24회, 실패 0 |
| 최종 전체 회귀 검사 | 20종, 실패 0 |
| 화면 문구 수정 후 추가 재검사 | 영어 대사·실제 표시·영어 UI 3종, 실패 0 |
| 최종 로그에서 집계한 검사 | 291,453개, 실패 0 |
| 영어 UI 장면 / 검사 | 1,680개 / 161,220개, 실패 0 |
| 원문 바이트 복원 | 30개 파일 SHA-256 일치 |
| 보호 파일 / 원본 자산 | 2,481개 변경 0 / 96개 불일치 0 |
| 한·영 무작위 표본 | 전체 14,216개에서 300줄, 직접 대조 |

변경한 제품 파일은 `project/data/dialogue-r21/` 아래 다음 18개 JSON이다: `hildegard.json`, `jorund.json`, `judith.json`, `lavinia.json`, `levia.json`, `lynette.json`, `marceline.json`, `miko.json`, `naran.json`, `ornel.json`, `saya.json`, `selva.json`, `sorel.json`, `teiris.json`, `tika.json`, `tove.json`, `urda.json`, `zahar.json`. 각 파일에 별도 `en.display`와 `en.speech`를 추가했다. 기존 언어별 표시 연결을 사용하며 이번 실행에서는 제품의 표시 함수나 게임 규칙을 수정하지 않았다. 영어 필드를 제거하면 한국어 원문과 기존 공백까지 최초 바이트가 그대로 복원된다. 장면 구조·id·선택지 순서·호감 수치·저장 형식은 그대로다.

힐데가·요르드·마르셀린의 격식, 유디트의 자신감과 연구 질문, 레비아의 조심스러운 거절, 사야의 짧은 말, 나란의 거래 농담, 티카의 관객 앞 큰 목소리와 둘만 남았을 때의 망설임 등을 인물별 영어 지침에 적고 대사에 반영했다. 가까워져도 인물의 선택·거절·두려움·가족·신앙·이해관계가 남도록 원문과 대조했다. 기존 사전의 Hildegard, Jorund, Judith, Lavinia da Cadell, Sorel Aenwyn, the March, Berghold, Tarn Valley, Naerin, Silverbough Watch, Kern, Marento, Harben, Drum 및 Year of Isolation 표기를 확인했다. 새 설정이나 성적 장면을 추가하지 않았다. 외부 번역 서비스·API·보조 에이전트는 사용하지 않았다.

3명마다 바뀐 파일의 실제 표시 언어 스캔과 영어 선택·한국어 유지·저장 왕복 검사, dialogue_player 및 dialogue_roster 시험을 실행했다. 6개 묶음 모두 한국어 잔존 0과 실패 0이다. 300줄 표본을 읽고 어색한 영어 88개 표현을 다듬은 뒤 전체 검사를 새로 실행했다. 화면을 직접 확인한 뒤 29개 표현을 추가로 다듬어 총 117개 영어 표현을 수정했고, 영어 대사·실제 표시 감사·영어 UI 3종을 다시 통과했다. 최종 20종 로그는 이번 전체 실행 시작 시각 이후에 생성된 파일인지도 확인했다.

최종 검사는 import, en_r24, dialogue_player/roster, finish_locale_data_audit, world/state/route/expansion/motion/motion_asset/art/export_licenses, ui_battle_r17/r18/r19/r20, motion_r9/r18, ui_en_r24이다. 기대값을 낮추지 않았다. 루트 인증서 저장소를 읽지 못한다는 기존 환경 메시지를 제외한 스크립트 오류는 0이다.

[300줄 한·영 표본](verification/en-r24/sample.md)은 전체 30명·14,216개에서 seed 20261104로 중복 없이 추출했다. 표본에는 30명 모두 포함되어 있다. 300줄을 직접 읽고 원문과 대조했으며 수정 후 동일한 표본을 다시 생성했다. 도구 변경은 `tools/en_r24.py`의 표본 범위 설명을 실제 완료 상태에 맞춘 것이며, 새 보조 스크립트와 검증 기록은 `verification/en-r24/` 안에 있다.

영어 360/430px 캡처 150개를 30명 대조 이미지로 직접 열어 확인했다. 제목과 초상이 겹치지 않고, 긴 본문과 선택지는 줄바꿈된다. 첫 화면 아래에 있는 선택지는 360px 스크롤 하단 캡처에서 마지막 항목까지 표시된다. 응답·관계 전환 문구와 탐색 전환의 마지막 문장이 보이며, 본문과 이동 버튼이 분리되어 있다. 문구 수정 뒤 달라진 10명·50개 캡처도 다시 열어 확인했다. 수동 검토는 인물별 대표 5개 화면이며 전체 1,680개 장면은 자동 UI 검사로 확인했다.

Web export·`docs/`·다른 작업 공간·사용자 저장 파일은 수정하지 않았다. 이번 검사의 runtime-en-r24, runtime-local-en-r24, tmp-en-r24 슬롯은 정리했다. 번역 미완료 항목은 없다. 화면 시각 검토는 인물별 첫 선택지·스크롤 하단·응답·탐색 장면 표본이며, 모든 장면의 수동 시각 검토를 뜻하지 않는다.

근거: [summary.json](verification/en-r24/summary.json), [regression.json](verification/en-r24/regression.json), [원문 보존 감사](verification/en-r24/authored-language-audit.json), [실제 표시 감사](verification/finish-r24/authored-language-audit.json), [dialogue-test.json](verification/en-r24/dialogue-test.json), [ui-test.json](verification/en-r24/ui-test.json), [표본 대조](verification/en-r24/sample-review-round3.json), [표현 수정 기록](verification/en-r24/editorial-revisions-round3.json), [시각 검토](verification/en-r24/visual-review-round3.json). 묶음별 근거는 `batch-*-results.json`과 해당 로그다.

| 인물 | 표시 문구 | 미번역 |
| --- | ---: | ---: |
| adeline | 462 | 0 |
| altan | 468 | 0 |
| bargut | 468 | 0 |
| berenga | 468 | 0 |
| bianca | 475 | 0 |
| colette | 462 | 0 |
| erdene | 481 | 0 |
| felice | 468 | 0 |
| gerda | 470 | 0 |
| gunhild | 468 | 0 |
| haldric | 478 | 0 |
| hedwig | 468 | 0 |
| hildegard | 518 | 0 |
| jorund | 462 | 0 |
| judith | 477 | 0 |
| lavinia | 462 | 0 |
| levia | 471 | 0 |
| lynette | 468 | 0 |
| marceline | 518 | 0 |
| miko | 462 | 0 |
| naran | 490 | 0 |
| ornel | 462 | 0 |
| saya | 478 | 0 |
| selva | 462 | 0 |
| sorel | 468 | 0 |
| teiris | 518 | 0 |
| tika | 468 | 0 |
| tove | 462 | 0 |
| urda | 472 | 0 |
| zahar | 462 | 0 |

재검사:

```powershell
python tools/en_r24.py audit
python tools/en_r24.py sample
python tools/en_r24_verify.py
```
