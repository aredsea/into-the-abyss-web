"""Finalize fresh evidence and the reviewable handoff, without git or export."""
from pathlib import Path
import json,hashlib,re
R=Path(__file__).resolve().parents[1];O=R/'verification/reskin-r24';Q=O/'round2'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rows={}
for p in [Q/'tests/results.json',Q/'cloud/results.json',Q/'tests/focused-results.json']:
    for row in read(p):rows[row['test']]=row
audits=read(O/'audits/results.json')
for row in audits:rows[row['test']]=row
expected={'import'}|{p.stem for p in (R/'project/tests').glob('*.gd') if p.stem.endswith('_test') or p.stem in ['export_licenses','motion_r9_integration','motion_r18_integration']}
assert expected<=set(rows),expected-set(rows)
assert all(row['passed'] for row in rows.values()),[r for r in rows.values() if not r['passed']]
write(Q/'all-tests.json',list(rows.values()))
capture=read(O/'captures.json');extra=read(Q/'diagnostics.json')
scan={key:sum(len(a[key]) for data in [capture,extra] for a in data['audit']) for key in ['missing','rails','clipped','small_type']}
assert not any(scan.values()),scan
assert not capture['failures'] and not extra['failures']
write(Q/'visual-scan.json',{'defects':scan,'method':['Actual font.has_char','Measured glyph bounds','Actual visible_line_count vs line_count','Body/scrollbar intersections','Actual label font sizes'],'checks':capture['checks']+extra['checks'],'unique_captures':len(read(O/'screen-inventory.json'))})
parity=[]
for name in ['p2-full-battles','a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
    p=R/'verification/data-r21'/f'{name}.json';d=read(p)
    parity.append({'file':p.relative_to(R).as_posix(),'battles':d['battles'],'equal':d.get('equal_battles',d['battles'] if d.get('different_actions')==0 else 0),'matched_actions':d['matched_actions'],'sha256':sha(p)})
pcount={'battles':sum(x['battles'] for x in parity),'equal_battles':sum(x['equal'] for x in parity),'matched_actions':sum(x['matched_actions'] for x in parity),'audits':parity,'fresh_execution_results':'verification/reskin-r24/audits/results.json'}
assert pcount['battles']==6320==pcount['equal_battles'];write(Q/'battle-parity.json',pcount)
assert not read(Q/'asset-check.json')['failures'] and not read(Q/'protected-check.json')['changed']
evidence=read(Q/'fix-evidence.json');inventory=read(O/'screen-inventory.json');sheets=read(O/'sheets.json');review=read(Q/'visual-review.json')
assert review['reviewed_fixes']==[x['item'] for x in evidence]
assert review['reviewed_sheets']==[x['file'] for x in sheets]
changed=[]
for p in (R/'project/ui').glob('*'):
    if not p.is_file() or p.suffix not in ['.gd','.gdshader']:continue
    old=Q/'source-before'/p.name
    if not old.exists() or sha(old)!=sha(p):changed.append({'path':p.relative_to(R).as_posix(),'sha256':sha(p),'before_sha256':sha(old) if old.exists() else None})
changed += [{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in (R/'project/assets/portraits-r24/npc').glob('*') if p.is_file()]
changed += [{'path':p.relative_to(R).as_posix(),'sha256':sha(p)} for p in [R/'project/tests/ui_reskin_r24_test.gd',R/'project/tests/ui_reskin_r24_round2_test.gd',R/'DESIGN.md']]
write(Q/'source-handoff.json',{'ui_files_compared_against':'verification/reskin-r24/round2/source-before','files':changed,'game_and_data_changes':read(Q/'protected-check.json')['changed']})
report=['# RESKIN R24 · 2차 수정',
'',
'미실행: 실물 폰 터치·Web export·배포. 이 작업은 네이티브 Godot 화면에서 확인했으며 git 명령은 사용하지 않았다. 승인 PNG와 실제 데이터·대사 길이의 차이는 아래에 적었다. 품질 최종 승인은 사장님 확인이 필요하다.',
'',
'## A~M 수정과 직접 확인',
'',
'아래 전후 사진 13장과 묶음 사진 39장을 직접 열어 확인했다. 수정 전 390px 캡처를 보존했고, 마지막 소스 수정 뒤 세 해상도를 다시 촬영했다.',
'',
'| 항목 | 바꾼 것 | 전후 비교 |',
'|---|---|---|']
for item in evidence:report.append(f"| {item['item']} | {item['title']} | [사진]({item['file']}) |")
report += ['', '## 검증 수치','',
f"- 프로젝트 검사 {len(expected)}/{len(expected)} + 전투 대조 실행 {len(audits)}/{len(audits)}: 총 {len(rows)}/{len(rows)} 통과, 최종 실패 0.",
f"- 전투 {pcount['equal_battles']:,}/{pcount['battles']:,}판, {pcount['matched_actions']:,}행동 일치. 이번 작업에서 여덟 대조를 모두 새로 실행했다.",
f"- {len(inventory)//3}개 화면·상태 × 3해상도 = {len(inventory)}장. 390×844·360×780·1280×800. 화면 검사 {capture['checks']+extra['checks']:,}개, 실패 0.",
'- 글꼴 누락 0, 측정 넘침·실제 줄 잘림 0, 스크롤바 겹침 0, 12px 미만 보조 글자 0.',
'- 원본 그림 96/96 해시 불변. 게임·대사·데이터 221/221 해시 불변. resource_gauge_r24.gd의 붓 게이지는 수정하지 않고 바깥 숫자 조판만 공용 래퍼에서 키웠다.',
'- NPC 5/5: isnet-anime, 빨강·검정·종이 대조. 작은 조각 0, 흰 외곽선 0, 경계 5px 안쪽을 제외한 인물 내부 RGB 변경 0. 원본은 덮어쓰지 않았다.',
'- 이번에 만든 격리 실행 슬롯 4개와 부속 임시 폴더를 정리했다. 기본 runtime은 보존했다. [정리 기록](verification/reskin-r24/round2/runtime-cleanup.json).',
f"- 새 sheet-1.jpg … sheet-{len(sheets)}. 폭 1200px, 최대 {max(x['bytes'] for x in sheets):,}바이트. A~M 전후 사진도 폭 1200px 이하.",
'',
'[전체 검사](verification/reskin-r24/round2/all-tests.json) · [화면 스캔](verification/reskin-r24/round2/visual-scan.json) · [전투 대조](verification/reskin-r24/round2/battle-parity.json) · [NPC 검사](verification/reskin-r24/round2/npc/validation.json) · [직접 검토](verification/reskin-r24/round2/visual-review.json) · [변경 목록](verification/reskin-r24/round2/source-handoff.json)',
'',
'## 기능과 검사 조건',
'',
'화면 표시만 바꿨다. 버튼 id·콜백·활성 조건·정본 숫자·전투 규칙·대사 데이터·저장 형식은 보존했다. 원정의 입구·1~5·휴식·보스는 가로 경로로 표시하고, 기존 source entry 메타데이터와 행동 순서를 유지했다. 기존 보상 반영과 결과 확인 경로를 그대로 사용하므로 결과를 보는 것만으로 보상이 지급되지 않는다.',
'',
'초기 검사 실패는 지우지 않고 tests/results.json에 남겼다. 합본에 없던 finish-r24 Lua 대조 파일은 기존 oracle 도구로 정본 봇을 실행해 다시 만들었다. 파일을 읽다가 멈춘 두 격리 검사 프로세스는 종료하고 같은 기대값으로 재실행했다. 클라우드 검사는 실제 로컬 Worker/D1을 시작해 11묶음을 재실행했다. 이름표 줄 잘림, 적 클릭 영역·표지 간격, 공용 초상 명부, 영문 제목은 코드에서 고쳤고 focused-results.json에 재검사 결과를 남겼다. 기존 검사의 기대값은 바꾸지 않았다. 신규 인물 소개 검사는 기존 {{user}} 치환을 거친 원문과 화면 글자를 비교한다.',
'',
'## 승인 시안과 다른 점·한계','',
'[마을 대조](verification/reskin-r24/compare-town.png) · [동료 대조](verification/reskin-r24/compare-companion.png). 실제 저장은 1일째이며 시안의 2일째·가상 HP를 넣지 않았다. 동료 대사는 현재 상황의 원문 전체라 시안보다 길고 대사판 높이도 다르다. 시설 설명은 12px 이상으로 두 줄까지 읽히도록 표지가 조금 높다. 기존 개요·기술·편성·출정 설명은 아래 스크롤에서 접근한다. 시설 의뢰는 정본 난수에 따라 전후 캡처의 이름·보상이 달라질 수 있다. 숫자 변경으로 통과시킨 것은 아니며 기능 대조와 보호 해시로 구분했다.',
'',
'그림이 없는 인물 소개에는 다른 사람의 초상을 대신 넣지 않았다. 페르소나는 기존 사람 선 아이콘을 사용한다. 실제 폰 브라우저 확인과 배포는 이번 범위에서 실행하지 않았다. Impeccable 정적 탐지는 []였으며 Godot 렌더 확인을 대체하지 않는다. 기존 .impeccable/design.json은 DESIGN.md보다 낡은 캐시라 갱신하지 않았다. 필요하면 별도 document 작업으로 갱신할 수 있다.',
'',
'## 화면·상태 목록','',
'| 화면·상태 | 390×844 | 360×780 | 1280×800 |','|---|---|---|---|']
for name in sorted({x['screen'] for x in inventory}):
    report.append('| '+name+' | '+' | '.join(f'[캡처](verification/reskin-r24/render/{name}-{w}x{h}.png)' for w,h in [(390,844),(360,780),(1280,800)])+' |')
report+=['','## 수정 파일','']
report += ['- `'+row['path']+'`' for row in changed]
report += ['','검증 도구: `tools/portrait_r24_npc.py`, `tools/reskin_r24_round2_verify.py`, `tools/reskin_r24_round2_recheck.py`, `tools/reskin_r24_test_prerequisites.py`, `tools/reskin_r24_round2_report.py`, `tools/reskin_r24_round2_finalize.py`. 공용 cloud 도구에는 결과 폴더·격리 슬롯 선택만 추가했다.','']
(R/'RESKIN-R24.md').write_text('\n'.join(report),encoding='utf-8')
print(json.dumps({'tests':len(rows),'project_tests':len(expected),'failures':0,'captures':len(inventory),'sheets':len(sheets),'checks':capture['checks']+extra['checks'],'battle_parity':pcount['equal_battles'],'ui_changed':len(changed)}))
