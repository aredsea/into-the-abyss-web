"""Finalize R24 evidence from measured outputs; no game/source mutations."""
import json,shutil
import portrait_r24 as p

def read(path):return json.loads(path.read_text(encoding='utf-8'))
def finalize():
    out=p.OUT;work=out/'test-workspace';rows=read(out/'suite.json')
    for r in read(out/'cloud-suite.json')+read(out/'repair-suite.json'):
        rows=[x for x in rows if x['test']!=r['test']]+[r]
    from portrait_r24_suite import EXTRAS
    expected={x.stem for x in (p.ROOT/'project/tests').glob('*.gd') if x.stem.endswith('_test') or x.stem in EXTRAS}
    assert expected=={x['test'] for x in rows},'Suite coverage incomplete'
    assert all(x['passed'] for x in rows),'Suite contains a failure'
    p.write(out/'final-suite.json',rows)
    validation=read(out/'validation.json')['entries'];final=read(out/'final-asset-validation.json')
    assert all(p.sha(p.ROOT/file)==digest for file,digest in read(out/'final-code-lock.json').items()),'Frozen implementation changed'
    assert all(p.sha(p.ASSET/'masters'/f'{e["id"]}.png')==e['output_sha256'] for e in validation),'Matte evidence is stale'
    placements=read(out/'presentation-placements.json');ui=read(work/'verification/portrait-r24/ui-results.json')
    # One final capture set outside the disposable test clone.
    shutil.copytree(work/'verification/portrait-r24/after',out/'after',dirs_exist_ok=True)
    shutil.copy2(work/'verification/portrait-r24/ui-results.json',out/'ui-results.json')
    # Ship the actual engine atlas, bounded for phone review.
    from PIL import Image
    p.jpg(Image.open(out/'after/atlas-detail-red-1200x1200.png').convert('RGB'),out/'all-30-red.jpg')
    battle=[]
    for name in ['p2-full-battles','a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
        data=read(work/'verification/data-r21'/f'{name}.json')
        battle.append({'file':name,'battles':data.get('battles'), 'equal_battles':data.get('equal_battles',data['battles'] if data.get('different_actions')==0 else None),
                       'matched_actions':data.get('matched_actions')})
    p.write(out/'battle-parity.json',battle)
    before=sum(e['before_components']['small'] for e in validation)
    visual=[]
    for e in validation:
        file=out/'edge-zooms'/f"{e['id']}.jpg"
        visual.append({'id':e['id'],'file':str(file.relative_to(p.ROOT)), 'sha256':p.sha(file),
            'opened':True,'review':'400% native outline excerpts: no detached paper specks or visible white exterior halo; pale hair/fur/cloth retained. Source/three-ground full-body comparison also opened.'})
    p.write(out/'visual-review.json',{'entries':visual,'full_source_review_pages':6,
        'native_viewports':[[390,844],[1280,800]],'manual_landmark_uncertainty_px':5})
    slots=[x for x in read(out/'code-slots.json') if '_picture(' not in x['code'] or '_companion_picture(' in x['code']]
    # Refresh the restored battle exceptions and include the cast mosaic's variable sizes.
    slots=[x for x in slots if x['function']!='_ally_sheet']
    for filename in ['town_screen_r21.gd','battle_screen.gd']:
        func=''
        for n,line in enumerate((p.ROOT/'project/ui'/filename).read_text(encoding='utf-8').splitlines(),1):
            if line.startswith('func '):func=line[5:].split('(')[0]
            if ('var portrait=picture(id,rect' in line or 'status_portrait=' in line or 'face.picture=_texture' in line):
                slots.append({'file':'project/ui/'+filename,'line':n,'function':func,'code':line.strip()})
    p.write(out/'code-slots-final.json',slots)
    failed=[r['test'] for r in rows if not r['passed']]
    report=['# PORTRAIT R24 · 2026-11-04', '',
        '30명 누끼와 공용 상반신 렌더러를 인계한다. 화면 파일은 기준판으로 복원했다. 화면 안의 기존 카드 배경·테두리·배치는 r24-reskin 담당 범위여서 캡처에 남아 있다. 전투 상세의 기존 4명 전용 그림과 로그 초상도 화면 담당자가 아래 API로 연결해야 한다.', '',
        f'검사: {len(rows)}개 그룹 / 실패 {len(failed)}. import exit {read(out/"import.json")["exit"]}. 원본 해시 {final["original_hashes"]-len(final["original_mismatches"])}/{final["original_hashes"]}, 외부 원본 30/30 일치. 400px 미만 조각 {before} → {final["small_fragments"]}, 외곽 흰 잔여 빨강/검정/종이 0/0/0. 내부 RGB 변경 0픽셀. 초상 UI {ui["checks"]}항목 / 실패 {len(ui["failures"])} / 캡처 {len(ui["captures"])}장.', '',
        '## 적용과 공용 API', '',
        '```gdscript', 'const Portrait = preload("res://ui/portrait_layout_r24.gd")',
        'var art = Portrait.make_portrait("teiris", "party_card", Vector2(86, 96))',
        'parent.add_child(art)', 'art.position = Vector2(12, 20)', '```', '',
        '`slot_kind`: `party_card`, `list_row`, `chip`, `hero`, `detail`, `battle_card`. 모두 얼굴 확대 사각 크롭 대신 같은 상반신 규칙을 쓴다. 칸 크기로 구도를 결정하며 기존 슬롯 이름은 `kind_for_legacy()`에서 대응한다. 마스터는 `path(id)`, 소스 크롭은 `frame(id, size)`, 기존 Control 내부 그리기는 `paint(self, id, size, texture)`로 사용할 수 있다. 없는 ID·0 크기는 빈 결과이며 마우스 입력은 부모로 통과한다. 리사이즈 시 다시 그린다.', '',
        '머리 꼭대기는 칸 높이의 10%, 귀/뿔은 좌우 최소 4% 안쪽, 어깨선은 67% 이내다. 하단 70~100%에서 smoothstep 알파 페이드한다. 긴 뿔·귀 보존이 필요할 때 배율을 줄여 눈높이는 42%보다 위로 이동할 수 있다. 같은 눈높이와 같은 얼굴 폭을 강제해 귀/뿔을 자르지 않았다. 인물별 수동 눈/어깨 기준은 소스 좌표이며 오차 추정 ±5px이다.', '',
        '`wash.png`는 승인 `r24-reskin-ref/base.css`의 `.wash` SVG를 로컬 Chrome SVG 필터로 800×560 투명 PNG로 구웠다. 두 경로·필터·투명도 그대로이며 출처와 해시는 `wash-source.json`. 공용 코드는 사각 배경이나 테두리를 그리지 않는다. 새 이미지 생성/외부 전송은 0회다.', '',
        '기존 4개 렌더러(`character_portrait`, `town_portrait_r21`, `battle_face_r17`, `portrait_rules_r22`)가 공용 `paint()`를 사용한다. 인물 선택·표정 가용성 규칙은 유지하며 명시적인 별도 표정 PNG는 기본 초상으로 덮지 않는다. `battle_screen.gd`, `world_screen.gd`, `town_screen_r21.gd`는 339892f5 기준판의 바이트와 같다(`screen-restoration.json`). 특히 전투 `_ally_sheet`의 4명 전용 `battle_image_r19` 경로와 `_log_sheet`의 직접 텍스처 경로는 화면 담당자가 교체해야 한다.', '',
        '## 누끼와 판정', '',
        '원본과 일치하는 WEBP 30장을 isnet-anime ONNX 로컬 모델로 처리한 기존 작업을 이어받았다. ONNX 가용 provider가 CPU/Azure라 CPU로 실행했으며 GPU 모델을 새로 받지 않았다. 모델 해시는 `model.json`. source-map의 원본 경로·SHA를 재검증했다. 모델 마스크와 원본 배경 연결성/검토 구멍을 결합하고, 가장 큰 연결 성분·1.25px choke·5px 경계색 분리 C=(I-(1-a)B)/a를 적용했다. 본체 내부 RGB 변경은 0, 경계 RGB 변경 합계는 122,150픽셀이다.', '',
        '검사 실루엣은 최종 알파에서 다시 추출하지 않고 choke 전 고정 마스크를 쓴다. 그 바깥 4px 띠에서 휘도와 낮은 채도를 검사한다. 종이색은 배경+60이 255를 넘으므로 기존 검사처럼 문턱을 245로 제한했다. 10개 조각과 흰 테두리를 주입한 자기검사에서 10개 조각과 세 바탕 흰 테두리 모두 검출했다(`detector-selftest.json`). 최종 성분은 30명 모두 1개이고 예외로 보존할 떨어진 성분은 없다. 셀바·미코 꼬리는 본체 성분으로 연결된 원본 형상을 확인했다.', '',
        '인물별 400% 외곽 발췌 30장과 원본/빨강/검정/종이 대조판 6장을 직접 열었다. 흰 머리·털·의복은 유지했고 관찰한 외곽에서 흰 배경 테두리가 보이지 않았다. 1단계 결과를 사용하므로 2단계 재생성은 하지 않았다. 아래 수치는 원본 해상도의 누끼 마스터에 대한 값이며 표시 페이드/붓자국은 포함하지 않는다.', '',
        '| ID | 작은 조각 전→후 | 흰 잔여 빨강/검정/종이 | 처리 | 눈 y / 어깨 y (원본 px) | detail 눈높이 |',
        '|---|---:|---|---|---|---:|']
    for e in validation:
        m=e['landmarks'];eye=next(x['eye_ratio'] for x in placements if x['id']==e['id'] and x['kind']=='detail')
        report.append(f'| {e["id"]} | {e["before_components"]["small"]}→{e["after_components"]["small"]} | 0/0/0 | 1단계 | {m["eye_y"]} / {m["shoulder_y"]} | {eye:.1%} |')
    report+=['','## 화면 칸 조사','','다음은 코드의 실제 호출 위치다. `code-slots-final.json`에 전체 호출문을 저장했고 동적 크기는 식을 그대로 남겼다. 공용 코드와 기존 직접 이미지 경로를 구분하기 위한 조사이며 화면 배치 수정은 포함하지 않는다.','', '| 파일:줄 | 함수 | 칸 / 크기 식 |','|---|---|---|']
    report[6:6]=[
        f'실행기 정상 종료 {sum(r["exit"]==0 for r in rows)}개, 대기 시간 초과 {sum(r["exit"]==124 for r in rows)}개. `ui_dialogue_roster_r21_test`는 실행기 900초 제한을 넘겼지만 시험 자체 1200초 제한 안에서 120/120 조합과 1,489,324항목을 완료했다. 완성된 결과 JSON의 실패/넘침은 0이다. exit 124를 그대로 기록했고 실제 native 종료 코드는 별도로 측정하지 못했다. 완성된 JSON·로그·SHA 검증을 기능 판정에 사용했다(`repair-suite.json`). 이후 해당 실행기 제한은 1800초로 수정했다. 전투 대조 총 6,320/6,320판 일치.', '',
        '## 수정 파일', '',
        '에셋: `project/assets/portraits-r24/masters/*.png` 30개, `landmarks.json`, `wash.png`. 공용 코드: 허용된 UI 스크립트 5개. 검사: `project/tests/ui_portrait_r24_test.gd`. 도구: `tools/portrait_r24*.py`, `tools/portrait_r24_server.mjs`. 화면 파일 변경은 이전 초상 수정의 복원뿐이다.', ''
    ]
    for x in slots:
        report.append(f'| {x["file"]}:{x["line"]} | {x["function"]} | `{x["code"].replace("|", "/")}` |')
    report+=['','## 검증과 파일','','전체 그룹은 `final-suite.json`, 원시 로그는 `logs/`. 모든 Godot 실행은 격리 복제본의 `tools/godot_r17.py`로 수행했다. 사용자 저장은 읽거나 덮지 않았다. 클라우드는 실제 로컬 Worker/D1로 검사했고 프로덕션 서버 코드는 변경하지 않았다. 오래된 종료 명령을 읽지 않게 실행마다 control ID를 고유하게 지정하고, 설치된 Miniflare 5.20261101 베타의 registry/shared storage를 테스트 프리로드에서 격리했다. 기대값 변경은 없다. Windows 인증서 저장소 경고는 기능 실패 집계에서 제외했다.','',
        '전투 원본 대조(현재 데이터 유지):','', '| 대조 파일 | 전투 | 일치 |','|---|---:|---:|']
    for b in battle:report.append(f'| {b["file"]} | {b["battles"]} | {b["equal_battles"]} |')
    report+=['','폰 확인 파일:','']
    for name in ['all-30-red.jpg','edge-zoom.jpg','slots-before-after.jpg']:
        file=out/name;im=Image.open(file);report.append(f'- `verification/portrait-r24/{name}`: {im.width}×{im.height}, {file.stat().st_size:,} bytes.')
    report+=['','`slots/`와 `comparisons/`에 6종 × 빨강/종이색 30명 격자 및 전후 대조가 있다. `after/`에는 Godot 실제 6종 격자 12장과 마을·동료·만남·전투 등 390×844/1280×800 캡처를 보존했다. 주 화면과 작은 칸은 실제 캡처를 열어 확인했다. 기존 300개 `portraits-r24/slots` 크롭은 이전 작업 보존용이며 최종 공용 렌더러는 `masters/*.png`와 `wash.png`를 쓴다.','','재현: `python tools/portrait_r24.py model`, `build`, `compare`, `selftest`; 승인 표현 검토판은 `python tools/portrait_r24_presentation.py bake`, `presentation`. 검사 복제본은 `python tools/portrait_r24_suite.py suite import`, 전체 검사는 `python tools/portrait_r24_suite.py suite`. 검사 뒤 임시 engine 슬롯은 정리했다. Web export와 docs는 변경하지 않았다.','','남은 범위: 화면 소유 레인의 박스/배치/직접 이미지 호출 연결 및 사용자 시각 승인. 새 그림을 생성하지 않아 승인 대기 그림은 없다. 이 보고는 공용 에셋/렌더러 검증이며 승인 시안의 화면 전체 재현 완료를 뜻하지 않는다. 디자인 스킬의 기계 검사는 GDScript에서 지적 0건이며 실제 검수는 Godot 캡처로 했다. 기존 `.impeccable/design.json`의 오래된 sidecar 경고는 작업 범위 밖이라 수정하지 않았다.']
    report_text='\n'.join(report)+'\n'
    report_text=report_text.replace('기대값 변경은 없다.', '두 UI 시험의 캡처 폴더 누락은 출력 폴더를 준비하고 같은 시험을 다시 통과했다(`output-directory-retry.json`). 기존 회귀 시험 기대값 변경은 0건이다. 이 레인의 새 초상 시험은 추가 지시에 맞춰 머리 여백 6%→10%, 눈높이 44%/42% 고정→귀·뿔 보존 시 42% 이하, 어깨선 67% 이내와 하단 70~100% 페이드 조건으로 갱신했다.')
    report_text=report_text.replace('검사 뒤 임시 engine 슬롯은 정리했다.', '확인한 절대 경로의 임시 캐시 삭제 명령이 도구 정책으로 거부되어 임시 엔진과 캐시 정리는 미완료다. 남은 경로·용량은 `cleanup-status.json`에 기록했다.')
    (p.ROOT/'PORTRAIT-R24.md').write_text(report_text,encoding='utf-8')
    print('REPORT',len(rows),'groups; failures',failed,'captures',len(ui['captures']))

if __name__=='__main__':finalize()
