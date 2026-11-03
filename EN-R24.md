**EN-R24 — 미완료 / 첫 3명 번역 및 표시 연결**

전체 30명·14,216개 중 아델린·알탄·바르굿 3명의 1,398개를 직접 번역했다. **나머지 27명·12,818개는 아직 한국어 원문으로 표시된다.** 전체 영어화 완료로 보고하지 않는다.

각 캐릭터 JSON 끝에 `en.display`(원래 필드 경로 → 영어 문구), `en.speech`(영어 말투·호칭·관계 진행 지침)를 추가했다. 기존 키, 한국어 문자열, id, 선택지 순서, 호감 수치, 장면 구조와 저장 형식은 바꾸지 않았다. 새 영어 필드를 제거하면 세 파일의 원본 바이트 해시가 정확히 복원된다. 나머지 27개 JSON은 원본 그대로다.

영어 설정의 `authored_display`가 같은 JSON의 영어 문구를 찾아 표시한다. 저장된 응답·전환·탐색 대사는 계속 한국어이며, 불러온 뒤에도 표시 단계에서 영어로 바뀐다. 번역이 없는 문구는 원문을 그대로 남겨 감사에서 검출한다. 일반 UI 템플릿으로 대사를 대체하지 않는다. 영어 줄 길이로 본문·선택지 높이를 계산하고, 대화 제목이 초상화와 겹치지 않게 영어 제목 폭만 조정했다. UI 제목 3개와 관계 단계 제목도 영어로 표시한다.

아델린은 정중한 부탁·감사와 승부 앞의 짧고 빠른 문장, 알탄은 격식 있는 업무 어휘와 축약을 피한 문장, 바르굿은 짧은 구어와 축약형으로 구별했다. Adeline de Arcas, Altan, Bargut, Marceline, Gunhild, Urda, Leopard Banner 등은 기존 `localization-r22` 및 `ui-source-locale-r23` 사전의 표기를 참조했다. 새 고유명사와 성적 장면은 추가하지 않았다.

| 항목 | 결과 |
| --- | --- |
| 완료 캐릭터 | 3 / 30 |
| 번역 문구 | 1,398 / 14,216 |
| 전체 실제 표시 언어 감사의 한국어 잔존 | 12,818 |
| 첫 3명만 재검사한 한국어 잔존 | 0 / 1,398 |
| 회귀 검사 | 20개 실행, 실패 0 |
| 로그에서 집계 가능한 검사 | 94,081개, 실패 0 |
| 영어 UI | 168개 대화 화면, 15,390개 검사, 실패 0 |
| 보호 파일 | 2,481개, 변경 0 |
| ASSET-HASHES 원본 | 96개, 불일치 0 |
| 영어화 배포 게이트 | 미통과: 미번역 12,818개 |

필수 import, world/state/route/expansion/motion/motion_asset/art/export_licenses, ui_battle_r17/r18/r19/r20, motion_r9/r18 검사를 모두 직접 실행했다. 추가로 dialogue_player 34,229개, dialogue_roster 17,670개, 영어 표시·저장 보존 5,624개 검사도 실패 0이다. 루트 인증서 저장소를 읽지 못하는 환경 메시지는 로그에 따로 남아 있으며, 이를 제외한 스크립트 오류는 0이다. 검사 기대값은 낮추지 않았다. 언어 감사 스크립트의 정상 종료를 영어화 완료로 해석하지 않는다.

300줄 표본은 [sample.md](verification/en-r24/sample.md)에 있다. seed 20261104, 중복 없는 무작위 추출이며, **현재 번역한 3명·1,398개만 모집단**이다. 30명 전체 표본은 전체 번역 후 다시 추출해야 한다. 표본 300줄을 한국어와 대조해 검토하고 어색한 직역·축약형을 수정했다. 영어 360/430px 화면 및 하단 선택지 스크롤 캡처 15개를 직접 열어 확인했다. 긴 본문과 선택지는 스크롤로 이어지며, 하단 선택지까지 읽을 수 있음을 확인했다.

바뀐 제품 파일:

- `project/data/dialogue-r21/{adeline,altan,bargut}.json` — 영어 필드 추가.
- `project/game/dialogue_locale_r24.gd` — 저장 데이터를 변경하지 않는 영어 표시 인덱스.
- `project/game/localization_r22.gd` — `authored_display` 연결.
- `project/ui/town_screen_r21.gd` — 번역 길이 측정, 제목 폭, 관계 단계 표시.
- `project/data/native-locale-r24.json` — 대화 화면 제목 3개 번역 추가.

검사·도구 파일은 `project/tests/en_r24_test.gd`, `project/tests/ui_en_r24_test.gd`, `project/tests/finish_locale_data_audit.gd`(캐릭터 필터와 감사 범위 설명), `tools/en_r24.py`, `tools/en_r24_verify.py` 및 생성된 UID다. 근거는 `verification/en-r24/summary.json`, `regression.json`, `dialogue-test.json`, `ui-test.json`, `batch-language-audit.json`, `baseline.json`에 있다. 전체 실제 표시 감사는 `verification/finish-r24/authored-language-audit.json`에도 갱신했다.

아래 미번역 항목은 아직 직접 번역하지 않은 원문이다. 외부 번역용 fal 모델 호출은 자동 승인 검토에서 `MCP tool call requires approval, but approval policy is never`로 거절되어 실행되지 않았다. 보조 에이전트는 명시적 허용을 받지 않아 사용하지 않았다. 남은 문구를 영어로 가장하거나 범용 문장으로 덮지 않고 실제 잔존 수를 기록한다.

| 캐릭터 | 표시 문구 | 번역 | 미번역 |
| --- | ---: | ---: | ---: |
| adeline | 462 | 462 | 0 |
| altan | 468 | 468 | 0 |
| bargut | 468 | 468 | 0 |
| berenga | 468 | 0 | 468 |
| bianca | 475 | 0 | 475 |
| colette | 462 | 0 | 462 |
| erdene | 481 | 0 | 481 |
| felice | 468 | 0 | 468 |
| gerda | 470 | 0 | 470 |
| gunhild | 468 | 0 | 468 |
| haldric | 478 | 0 | 478 |
| hedwig | 468 | 0 | 468 |
| hildegard | 518 | 0 | 518 |
| jorund | 462 | 0 | 462 |
| judith | 477 | 0 | 477 |
| lavinia | 462 | 0 | 462 |
| levia | 471 | 0 | 471 |
| lynette | 468 | 0 | 468 |
| marceline | 518 | 0 | 518 |
| miko | 462 | 0 | 462 |
| naran | 490 | 0 | 490 |
| ornel | 462 | 0 | 462 |
| saya | 478 | 0 | 478 |
| selva | 462 | 0 | 462 |
| sorel | 468 | 0 | 468 |
| teiris | 518 | 0 | 518 |
| tika | 468 | 0 | 468 |
| tove | 462 | 0 | 462 |
| urda | 472 | 0 | 472 |
| zahar | 462 | 0 | 462 |

재검사 명령:

```powershell
python tools/en_r24.py audit adeline altan bargut
python tools/en_r24.py audit  # 현재 12,818개 미번역으로 종료 코드 1
python tools/en_r24.py sample
python tools/en_r24_verify.py
```

Web export는 실행하지 않았으며 `docs/`, 다른 작업 공간, 사용자 저장 파일은 수정하지 않았다. 이번에 만든 Godot runtime 슬롯은 검사가 끝난 뒤 정리했다.
