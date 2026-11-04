# PORTRAIT R24 · 2026-11-04

30명 누끼와 공용 상반신 렌더러를 인계한다. 화면 파일은 기준판으로 복원했다. 화면 안의 기존 카드 배경·테두리·배치는 r24-reskin 담당 범위여서 캡처에 남아 있다. 전투 상세의 기존 4명 전용 그림과 로그 초상도 화면 담당자가 아래 API로 연결해야 한다.

검사: 160개 그룹 / 실패 0. import exit 0. 원본 해시 96/96, 외부 원본 30/30 일치. 400px 미만 조각 121 → 0, 외곽 흰 잔여 빨강/검정/종이 0/0/0. 내부 RGB 변경 0픽셀. 초상 UI 2680항목 / 실패 0 / 캡처 38장.

실행기 정상 종료 159개, 대기 시간 초과 1개. `ui_dialogue_roster_r21_test`는 실행기 900초 제한을 넘겼지만 시험 자체 1200초 제한 안에서 120/120 조합과 1,489,324항목을 완료했다. 완성된 결과 JSON의 실패/넘침은 0이다. exit 124를 그대로 기록했고 실제 native 종료 코드는 별도로 측정하지 못했다. 완성된 JSON·로그·SHA 검증을 기능 판정에 사용했다(`repair-suite.json`). 이후 해당 실행기 제한은 1800초로 수정했다. 전투 대조 총 6,320/6,320판 일치.

## 수정 파일

에셋: `project/assets/portraits-r24/masters/*.png` 30개, `landmarks.json`, `wash.png`. 공용 코드: 허용된 UI 스크립트 5개. 검사: `project/tests/ui_portrait_r24_test.gd`. 도구: `tools/portrait_r24*.py`, `tools/portrait_r24_server.mjs`. 화면 파일 변경은 이전 초상 수정의 복원뿐이다.

## 적용과 공용 API

```gdscript
const Portrait = preload("res://ui/portrait_layout_r24.gd")
var art = Portrait.make_portrait("teiris", "party_card", Vector2(86, 96))
parent.add_child(art)
art.position = Vector2(12, 20)
```

`slot_kind`: `party_card`, `list_row`, `chip`, `hero`, `detail`, `battle_card`. 모두 얼굴 확대 사각 크롭 대신 같은 상반신 규칙을 쓴다. 칸 크기로 구도를 결정하며 기존 슬롯 이름은 `kind_for_legacy()`에서 대응한다. 마스터는 `path(id)`, 소스 크롭은 `frame(id, size)`, 기존 Control 내부 그리기는 `paint(self, id, size, texture)`로 사용할 수 있다. 없는 ID·0 크기는 빈 결과이며 마우스 입력은 부모로 통과한다. 리사이즈 시 다시 그린다.

머리 꼭대기는 칸 높이의 10%, 귀/뿔은 좌우 최소 4% 안쪽, 어깨선은 67% 이내다. 하단 70~100%에서 smoothstep 알파 페이드한다. 긴 뿔·귀 보존이 필요할 때 배율을 줄여 눈높이는 42%보다 위로 이동할 수 있다. 같은 눈높이와 같은 얼굴 폭을 강제해 귀/뿔을 자르지 않았다. 인물별 수동 눈/어깨 기준은 소스 좌표이며 오차 추정 ±5px이다.

`wash.png`는 승인 `r24-reskin-ref/base.css`의 `.wash` SVG를 로컬 Chrome SVG 필터로 800×560 투명 PNG로 구웠다. 두 경로·필터·투명도 그대로이며 출처와 해시는 `wash-source.json`. 공용 코드는 사각 배경이나 테두리를 그리지 않는다. 새 이미지 생성/외부 전송은 0회다.

기존 4개 렌더러(`character_portrait`, `town_portrait_r21`, `battle_face_r17`, `portrait_rules_r22`)가 공용 `paint()`를 사용한다. 인물 선택·표정 가용성 규칙은 유지하며 명시적인 별도 표정 PNG는 기본 초상으로 덮지 않는다. `battle_screen.gd`, `world_screen.gd`, `town_screen_r21.gd`는 339892f5 기준판의 바이트와 같다(`screen-restoration.json`). 특히 전투 `_ally_sheet`의 4명 전용 `battle_image_r19` 경로와 `_log_sheet`의 직접 텍스처 경로는 화면 담당자가 교체해야 한다.

## 누끼와 판정

원본과 일치하는 WEBP 30장을 isnet-anime ONNX 로컬 모델로 처리한 기존 작업을 이어받았다. ONNX 가용 provider가 CPU/Azure라 CPU로 실행했으며 GPU 모델을 새로 받지 않았다. 모델 해시는 `model.json`. source-map의 원본 경로·SHA를 재검증했다. 모델 마스크와 원본 배경 연결성/검토 구멍을 결합하고, 가장 큰 연결 성분·1.25px choke·5px 경계색 분리 C=(I-(1-a)B)/a를 적용했다. 본체 내부 RGB 변경은 0, 경계 RGB 변경 합계는 122,150픽셀이다.

검사 실루엣은 최종 알파에서 다시 추출하지 않고 choke 전 고정 마스크를 쓴다. 그 바깥 4px 띠에서 휘도와 낮은 채도를 검사한다. 종이색은 배경+60이 255를 넘으므로 기존 검사처럼 문턱을 245로 제한했다. 10개 조각과 흰 테두리를 주입한 자기검사에서 10개 조각과 세 바탕 흰 테두리 모두 검출했다(`detector-selftest.json`). 최종 성분은 30명 모두 1개이고 예외로 보존할 떨어진 성분은 없다. 셀바·미코 꼬리는 본체 성분으로 연결된 원본 형상을 확인했다.

인물별 400% 외곽 발췌 30장과 원본/빨강/검정/종이 대조판 6장을 직접 열었다. 흰 머리·털·의복은 유지했고 관찰한 외곽에서 흰 배경 테두리가 보이지 않았다. 1단계 결과를 사용하므로 2단계 재생성은 하지 않았다. 아래 수치는 원본 해상도의 누끼 마스터에 대한 값이며 표시 페이드/붓자국은 포함하지 않는다.

| ID | 작은 조각 전→후 | 흰 잔여 빨강/검정/종이 | 처리 | 눈 y / 어깨 y (원본 px) | detail 눈높이 |
|---|---:|---|---|---|---:|
| marceline | 6→0 | 0/0/0 | 1단계 | 247 / 385 | 42.0% |
| naran | 2→0 | 0/0/0 | 1단계 | 299 / 405 | 42.0% |
| teiris | 10→0 | 0/0/0 | 1단계 | 236 / 390 | 40.9% |
| haldric | 4→0 | 0/0/0 | 1단계 | 285 / 428 | 42.0% |
| erdene | 10→0 | 0/0/0 | 1단계 | 302 / 445 | 42.0% |
| bianca | 4→0 | 0/0/0 | 1단계 | 256 / 402 | 42.0% |
| saya | 5→0 | 0/0/0 | 1단계 | 295 / 440 | 42.0% |
| gerda | 3→0 | 0/0/0 | 1단계 | 248 / 390 | 42.0% |
| judith | 1→0 | 0/0/0 | 1단계 | 236 / 385 | 41.6% |
| levia | 0→0 | 0/0/0 | 1단계 | 287 / 427 | 42.0% |
| urda | 3→0 | 0/0/0 | 1단계 | 313 / 454 | 42.0% |
| lynette | 3→0 | 0/0/0 | 1단계 | 285 / 440 | 42.0% |
| felice | 8→0 | 0/0/0 | 1단계 | 247 / 390 | 42.0% |
| sorel | 0→0 | 0/0/0 | 1단계 | 274 / 410 | 42.0% |
| tika | 7→0 | 0/0/0 | 1단계 | 272 / 417 | 42.0% |
| hedwig | 2→0 | 0/0/0 | 1단계 | 267 / 420 | 42.0% |
| hildegard | 8→0 | 0/0/0 | 1단계 | 275 / 417 | 42.0% |
| berenga | 0→0 | 0/0/0 | 1단계 | 288 / 430 | 42.0% |
| gunhild | 3→0 | 0/0/0 | 1단계 | 259 / 409 | 41.9% |
| bargut | 14→0 | 0/0/0 | 1단계 | 233 / 379 | 41.7% |
| altan | 4→0 | 0/0/0 | 1단계 | 245 / 404 | 40.7% |
| colette | 0→0 | 0/0/0 | 1단계 | 270 / 415 | 42.0% |
| selva | 2→0 | 0/0/0 | 1단계 | 292 / 442 | 42.0% |
| ornel | 1→0 | 0/0/0 | 1단계 | 271 / 418 | 42.0% |
| zahar | 9→0 | 0/0/0 | 1단계 | 306 / 444 | 42.0% |
| jorund | 3→0 | 0/0/0 | 1단계 | 282 / 424 | 42.0% |
| lavinia | 3→0 | 0/0/0 | 1단계 | 282 / 420 | 42.0% |
| tove | 3→0 | 0/0/0 | 1단계 | 291 / 445 | 42.0% |
| miko | 3→0 | 0/0/0 | 1단계 | 282 / 425 | 42.0% |
| adeline | 0→0 | 0/0/0 | 1단계 | 280 / 425 | 42.0% |

## 화면 칸 조사

다음은 코드의 실제 호출 위치다. `code-slots-final.json`에 전체 호출문을 저장했고 동적 크기는 식을 그대로 남겼다. 공용 코드와 기존 직접 이미지 경로를 구분하기 위한 조사이며 화면 배치 수정은 포함하지 않는다.

| 파일:줄 | 함수 | 칸 / 크기 식 |
|---|---|---|
| project\ui\battle_screen.gd:418 | _party | `var face=FaceR17.new(); face.reference_party=true; face.configure(a.id); _put(face,Rect2(0,0,col,51),b); _mark("face:"+a.id,face)` |
| project\ui\battle_screen.gd:824 | _effect_feedback | `_companion_picture(a.id,Rect2(3,3,48,52),banner)` |
| project\ui\codex_screen_r22.gd:32 | build | `var p=portrait(cid,tile,Vector2(0,138));p.size_flags_horizontal=SIZE_EXPAND_FILL` |
| project\ui\codex_screen_r22.gd:45 | detail | `h=row();portrait(id,h,Vector2(130,190));var copy=VBoxContainer.new();h.add_child(copy);copy.size_flags_horizontal=SIZE_EXPAND_FILL` |
| project\ui\create_screen.gd:167 | scenario | `var portrait=preload("res://ui/town_portrait_r21.gd").new();portrait_frame.add_child(portrait);portrait.custom_minimum_size=Vector2(minf(frame.size.x-36,340),280);portrait.configure(selected.companion,"detail-overview")` |
| project\ui\expedition_screen_r22.gd:15 | small_party | `picture(id,Rect2(x,y,86,64),"town-party-face")` |
| project\ui\expedition_screen_r22.gd:63 | source_entries | `picture(e.id,Rect2(0,y,72,64),"town-party-face").set_meta("expe_entry",e);y+=68` |
| project\ui\expe_sortie_legacy_r23.gd:61 | build | `picture(id,Rect2(x,y,48,66),"formation-face")` |
| project\ui\expe_sortie_legacy_r23.gd:103 | formation_row | `picture(id,Rect2(px,0,83,78),"formation-face")` |
| project\ui\facilities_screen_r22.gd:106 | recruit_roster | `picture(id,Rect2(0,y,48,59),"target-face")` |
| project\ui\facilities_screen_r22.gd:120 | recruit_result | `picture(id,Rect2(0,y,82,98),"target-face")` |
| project\ui\panel_screen_r22.gd:112 | favorite_card | `var h=row(card);portrait(id,h,Vector2(76,108),c.name);var copy=VBoxContainer.new();h.add_child(copy);copy.size_flags_horizontal=SIZE_EXPAND_FILL` |
| project\ui\panel_screen_r22.gd:133 | persona | `var p=host.model.s.get("persona",{});var name=p.get("name","");var h=row();portrait("persona",h,Vector2(72,110));var b=VBoxContainer.new();h.add_child(b);b.size_flags_horizontal=SIZE_EXPAND_FILL` |
| project\ui\persona_sortie_screen.gd:112 | formation_slots | `var m=members[i];picture(m.id,Rect2(x,359,84,64),"town-party-face")` |
| project\ui\persona_sortie_screen.gd:131 | formation_row | `picture(id,Rect2(px,0,83,78),"formation-face")` |
| project\ui\town_art_r21.gd:8 | build_art | `ink(Rect2(-10,130,430,200));picture(id,Rect2(0,130,390,190),"detail-skills")` |
| project\ui\town_result_r21.gd:27 | build_result | `picture(id,Rect2(x,597,86,43),"town-party-face")` |
| project\ui\town_screen_r21.gd:235 | home | `picture(lead,Rect2(50,103,340,428),"town-main")` |
| project\ui\town_screen_r21.gd:250 | home | `else:picture(id,Rect2(x+2,550,83,58),"town-party-face")` |
| project\ui\town_screen_r21.gd:357 | small_party | `picture(id,Rect2(x,y,86,181 if tall else 64),"party-tall" if tall else "town-party-face")` |
| project\ui\town_screen_r21.gd:389 | departure | `picture(id,Rect2(x,520,71,67),"formation-face")` |
| project\ui\town_screen_r21.gd:435 | target_item | `picture(id,Rect2(42,y+3,88,93),"target-face")` |
| project\ui\town_screen_r21.gd:465 | formation | `picture(id,Rect2(x,y,79,72),"formation-face"); label(host.model.person(id).name,Rect2(x,y+73,79,21),10)` |
| project\ui\town_screen_r21.gd:475 | exploration | `for i in range(w.s.party.size()):picture(w.s.party[i],Rect2(12+i*94,273,94,171),"party-tall")` |
| project\ui\town_screen_r21.gd:495 | cards | `picture(host.model.s.party[0] if not host.model.s.party.is_empty() else host.model.s.owned[0],Rect2(160,53,230,275 if not host.model.s.hand.is_empty() else 382),"town-main")` |
| project\ui\town_screen_r21.gd:531 | npc_hero | `picture(id,Rect2(99,43,291,height-3),"town-main")` |
| project\ui\town_screen_r21.gd:656 | inn | `picture(host.who,Rect2(18,480,139,127),"detail-skills")` |
| project\ui\town_screen_r21.gd:709 | dialogue_frame | `picture(who,Rect2(173,22,207,297),"detail-overview")` |
| project\ui\town_screen_r21.gd:768 | journey_dialogue | `picture(row.who,Rect2(0,y,77,104),"target-face")` |
| project\ui\town_screen_r21.gd:834 | equipment | `picture(host.who,Rect2(0,128,163,300),"detail-overview")` |
| project\ui\town_screen_r21.gd:947 | overview | `picture(host.who,Rect2(0,123,390,360),"detail-overview")` |
| project\ui\town_screen_r21.gd:972 | skills | `ink(Rect2(-10,30,430,255)); plate("detail-city",Rect2(286,0,104,141)); picture(host.who,Rect2(83,27,307,257),"town-main")` |
| project\ui\world_screen.gd:279 | _portrait | `companion_image(id,row,Vector2(128,170) if large else Vector2(76,104))` |
| project\ui\world_screen.gd:598 | _npc | `companion_image(id,row,Vector2(86,112))` |
| project/ui/town_screen_r21.gd:319 | roster | `var portrait=picture(id,rect,["cast-feature","cast-secondary","cast-lower-left","cast-lower-left"][i%4])` |
| project/ui/battle_screen.gd:576 | _log_sheet | `var face=preload("res://ui/battle_image_r19.gd").new(); face.picture=_texture("res://assets/portraits-r10/"+entry.actor+"-face.png") if entry.actor in ["hildegard","bargut","teiris","berenga"] else _texture("res://assets/"+entry.actor+".webp"); face.alignment=Vector2(.5,.7); _put(face,Rect2(44,8,39,45),row)` |
| project/ui/battle_screen.gd:602 | _ally_sheet | `status_portrait=preload("res://ui/battle_image_r19.gd").new();status_portrait.picture=_texture("res://assets/portraits-r10/"+a.id+"-cutout.png");_put(status_portrait,Rect2(7,52,153,192),p);_mark("status-portrait",status_portrait)` |
| project/ui/battle_screen.gd:604 | _ally_sheet | `status_portrait=preload("res://ui/character_portrait.gd").new();status_portrait.configure(a.id);_put(status_portrait,Rect2(7,52,153,192),p)` |

## 검증과 파일

전체 그룹은 `final-suite.json`, 원시 로그는 `logs/`. 모든 Godot 실행은 격리 복제본의 `tools/godot_r17.py`로 수행했다. 사용자 저장은 읽거나 덮지 않았다. 클라우드는 실제 로컬 Worker/D1로 검사했고 프로덕션 서버 코드는 변경하지 않았다. 오래된 종료 명령을 읽지 않게 실행마다 control ID를 고유하게 지정하고, 설치된 Miniflare 5.20261101 베타의 registry/shared storage를 테스트 프리로드에서 격리했다. 두 UI 시험의 캡처 폴더 누락은 출력 폴더를 준비하고 같은 시험을 다시 통과했다(`output-directory-retry.json`). 기존 회귀 시험 기대값 변경은 0건이다. 이 레인의 새 초상 시험은 추가 지시에 맞춰 머리 여백 6%→10%, 눈높이 44%/42% 고정→귀·뿔 보존 시 42% 이하, 어깨선 67% 이내와 하단 70~100% 페이드 조건으로 갱신했다. Windows 인증서 저장소 경고는 기능 실패 집계에서 제외했다.

전투 원본 대조(현재 데이터 유지):

| 대조 파일 | 전투 | 일치 |
|---|---:|---:|
| p2-full-battles | 48 | 48 |
| a6-mixed-audit | 48 | 48 |
| p3-mixed-audit | 128 | 128 |
| a7-gear-audit | 176 | 176 |
| a7-gear-balanced-audit | 176 | 176 |
| a8-audit | 5120 | 5120 |
| a9-native-10-audit | 312 | 312 |
| a9-native-40-audit | 312 | 312 |

폰 확인 파일:

- `verification/portrait-r24/all-30-red.jpg`: 1200×1200, 347,148 bytes.
- `verification/portrait-r24/edge-zoom.jpg`: 960×2076, 157,526 bytes.
- `verification/portrait-r24/slots-before-after.jpg`: 1200×1200, 317,442 bytes.

`slots/`와 `comparisons/`에 6종 × 빨강/종이색 30명 격자 및 전후 대조가 있다. `after/`에는 Godot 실제 6종 격자 12장과 마을·동료·만남·전투 등 390×844/1280×800 캡처를 보존했다. 주 화면과 작은 칸은 실제 캡처를 열어 확인했다. 기존 300개 `portraits-r24/slots` 크롭은 이전 작업 보존용이며 최종 공용 렌더러는 `masters/*.png`와 `wash.png`를 쓴다.

재현: `python tools/portrait_r24.py model`, `build`, `compare`, `selftest`; 승인 표현 검토판은 `python tools/portrait_r24_presentation.py bake`, `presentation`. 검사 복제본은 `python tools/portrait_r24_suite.py suite import`, 전체 검사는 `python tools/portrait_r24_suite.py suite`. 확인한 절대 경로의 임시 캐시 삭제 명령이 도구 정책으로 거부되어 임시 엔진과 캐시 정리는 미완료다. 남은 경로·용량은 `cleanup-status.json`에 기록했다. Web export와 docs는 변경하지 않았다.

남은 범위: 화면 소유 레인의 박스/배치/직접 이미지 호출 연결 및 사용자 시각 승인. 새 그림을 생성하지 않아 승인 대기 그림은 없다. 이 보고는 공용 에셋/렌더러 검증이며 승인 시안의 화면 전체 재현 완료를 뜻하지 않는다. 디자인 스킬의 기계 검사는 GDScript에서 지적 0건이며 실제 검수는 Godot 캡처로 했다. 기존 `.impeccable/design.json`의 오래된 sidecar 경고는 작업 범위 밖이라 수정하지 않았다.
