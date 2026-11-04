"""Rebuild review sheets and concise evidence, without copying large traces."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json,math
R=Path(__file__).resolve().parents[1];O=R/'verification/reskin-r24'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
write=lambda p,v:p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
data=read(O/'captures.json')
capture_errors=[]
if (O/'capture-latest.log').exists():
 raw=(O/'capture-latest.log').read_bytes();log=raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8',errors='replace')
 capture_errors=[s for s in log.splitlines() if (s.startswith('SCRIPT ERROR:') or s.startswith('ERROR:')) and 'root certificate store' not in s]
rows=read(O/'tests/results.json') if (O/'tests/results.json').exists() else []
if (O/'cloud/results.json').exists():
 for r in read(O/'cloud/results.json'):rows=[x for x in rows if x['test']!=r['test']]+[r]
if (O/'audits/results.json').exists():
 for r in read(O/'audits/results.json'):rows=[x for x in rows if x['test']!=r['test']]+[r]
if (O/'late-results.json').exists():
 for r in read(O/'late-results.json'):rows=[x for x in rows if x['test']!=r['test']]+[r]
rows=[r for r in rows if r['test']!='ui_reskin_r24_test']+[{'test':'ui_reskin_r24_test','passed':not capture_errors and not data['failures'] and not any(a[k] for a in data['audit'] for k in ['missing','rails','clipped']),'errors':data['failures']+capture_errors,'summary':[f"RESKIN CHECKS {data['checks']} FAILURES {len(data['failures'])} CAPTURES {len(data['inventory'])}"]}]
write(O/'all-tests.json',rows)
assets=read(R/'ASSET-HASHES.json');af=[a['path'] for a in assets if sha(R/a['path'])!=a['sha256']]
write(O/'asset-check.json',{'checked':len(assets),'unchanged':len(assets)-len(af),'failures':af})
before=read(O/'protected-before.json');changed=[p for p,h in before.items() if not (R/p).exists() or sha(R/p)!=h]
write(O/'protected-check.json',{'checked':len(before),'unchanged':len(before)-len(changed),'changed':changed})
audits=[]
for name in ['p2-full-battles','a6-mixed-audit','p3-mixed-audit','a7-gear-audit','a7-gear-balanced-audit','a8-audit','a9-native-10-audit','a9-native-40-audit']:
 p=R/'verification/data-r21'/f'{name}.json'
 if not p.exists():continue
 d=read(p);audits.append({'file':str(p.relative_to(R)),'battles':d['battles'],'equal_battles':d.get('equal_battles',d['battles'] if d.get('different_actions')==0 else 0),'matched_actions':d['matched_actions'],'sha256':sha(p)})
parity={'battles':sum(a['battles'] for a in audits),'equal_battles':sum(a['equal_battles'] for a in audits),'matched_actions':sum(a['matched_actions'] for a in audits),'audits':audits}
write(O/'battle-parity.json',parity)
font=ImageFont.truetype(str(R/'project/assets/fonts/AbyssNotoText800.ttf'),16)
small=ImageFont.truetype(str(R/'project/assets/fonts/AbyssNotoText500.ttf'),13)
inventory=data['inventory']
# The existing natural result integration test renders every contracted size.
for result in ['victory','defeat']:
 for w,h in [(390,844),(360,780),(1280,800)]:
  source=R/'verification/town-r21/round3/render'/f'{result}-{w}.png'
  if source.exists():
   dst=O/'render'/f'result-{result}-{w}x{h}.png';Image.open(source).save(dst)
   item={'screen':'result-'+result,'file':dst.name,'size':[w,h]}
   if not any(x['file']==dst.name for x in inventory):inventory.append(item)
write(O/'screen-inventory.json',inventory)
sheet_rows=[]
for size in [(390,844),(360,780),(1280,800)]:
 group=[x for x in inventory if tuple(x['size'])==size]
 for start in range(0,len(group),12):
  batch=group[start:start+12];cellw=300;cellh=690 if size[0]<500 else 240
  im=Image.new('RGB',(1200,cellh*3+36),'#EEE6D6');draw=ImageDraw.Draw(im)
  draw.text((12,5),f'R24 / {size[0]} x {size[1]} / '+str(len(sheet_rows)+1),font=font,fill='#16130F')
  for i,row in enumerate(batch):
   x=i%4*cellw;y=i//4*cellh+36;draw.text((x+8,y+3),row['screen'],font=small,fill='#16130F')
   pic=Image.open(O/'render'/row['file']).convert('RGB');pic.thumbnail((290,cellh-35),Image.Resampling.LANCZOS);im.paste(pic,(x+(300-pic.width)//2,y+28))
  path=O/f'sheet-{len(sheet_rows)+1}.jpg';quality=86
  while True:
   im.save(path,quality=quality,optimize=True)
   if path.stat().st_size<=800000 or quality<45:break
   quality-=5
  sheet_rows.append({'file':path.name,'screens':[r['file'] for r in batch],'bytes':path.stat().st_size,'width':im.width})
write(O/'sheets.json',sheet_rows)
for name,ref,actual in [('town','b.png','town-390x844.png'),('companion','c.png','member-390x844.png')]:
 im=Image.new('RGB',(800,880),'#EEE6D6');draw=ImageDraw.Draw(im);draw.text((8,6),'승인 기준',font=font,fill='#16130F');draw.text((408,6),'실제 Godot · 원본 데이터',font=font,fill='#16130F')
 for x,p in [(0,R.parent/'r24-reskin-ref'/ref),(400,O/'render'/actual)]:
  pic=Image.open(p).convert('RGB');pic=pic.resize((390,844),Image.Resampling.LANCZOS);im.paste(pic,(x,32))
 im.save(O/f'compare-{name}.png')
defects={k:sum(len(a[k]) for a in data['audit']) for k in ['missing','rails','clipped']};write(O/'visual-scan.json',{'captures':len(data['inventory']),'sizes':[[390,844],[360,780],[1280,800]],'defects':defects,'method':'Actual rendered font.has_char; measured multiline bounds; reserved scrollbar body/rail intersection. Direct review is separately recorded.'})
design='''# Into the Abyss · 종이와 먹 r24

승인 계약은 `../r24-reskin-ref/b.png`(마을), `c.png`(동료), `battle-approved.jpg`(전투)다. 이전 청백자 체계를 대체한다.

| 역할 | 값 |
|---|---|
| 종이 / 보조 종이 | #EEE6D6 / #E4DAC6 |
| 먹 / 보조 먹 / 작은 정보 | #16130F / #4E463B / #7A6F60 |
| 구분선 | rgba(22,19,15,.16) |
| 주 행동 / 위험 | #C9321D / #8E1F12 |
| MP / 금화 | #2C3E63 / #9A7432 |

제목은 AbyssNotoBlackCondensed, 본문은 AbyssNotoText500/800. 기존 OFL 글꼴을 쓴다. 숫자 조판과 HP 붓 게이지는 resource_gauge_r24.gd를 보존한다.

마을은 위 약 60%의 먹 풍경에 시설 원형 표지와 검은 이름표를 꽂는다. 찢긴 종이 아래에는 상자 없는 파티 상반신 네 자리, 이름·역할·HP·붓 게이지·MP 선과 큰 원정 버튼이 이어진다. 원본의 추가 장소·출정 선택·설명은 스크롤 아래에 보존한다.

동료는 오른쪽 큰 상반신과 흐린 장소, 왼쪽 세로 파티 선택, 검은 대사판, 주 행동과 시설 행으로 구성한다. 대사는 실제 dialogue-r21의 현재 호감 단계·열람 기록으로 선택한다. 표시만으로 열람 상태나 난수를 바꾸지 않는다. 기존 개요·기술·편성·특성 기능은 아래로 이어진다. 대화도 같은 인물 무대를 쓴다.

생성·도감·기록·설정은 제목과 2px 먹 선, 촘촘한 정보 행, 선택 밑줄과 고정 하단 행동을 쓴다. 선택 면을 붉게 채우지 않는다. 주 행동만 버밀리언 면을 쓴다. 동료 목록은 상반신·이름·역할·레벨·파티 여부의 행이다. 여관 행동도 아이콘·이름·비용의 행이다.

하단 내비게이션은 검은 한 띠, 마을·동료·원정·가방·기록의 선 아이콘과 글자, 활성 탭 위 빨간 선이다. 초상 카드·회색 타일·알약 버튼·깨진 문자 아이콘을 쓰지 않는다. 전투의 승인 배치·컷인·효과는 유지한다.

공용 부품은 project/ui/reskin_components_r24.gd 한 파일에 모은다. town_theme_r21.gd와 fantasy_theme.gd는 호환 진입점이다. 아이콘은 승인 icons.html의 24×24·1.75px 선 세트와 같은 규격의 확장이다. 화살표·별은 글꼴 대신 선 그림을 쓴다. 실제 장비·보급품 그림은 보존한다.

화면의 초상은 portrait_slot_r24.gd.make(id, slot_kind, size)로 만든다. 기존 upperbody 원본의 머리 여백·어깨를 보이고, 기준 .wash SVG를 구운 PNG 뒤에 놓고 아래 약 33%를 투명하게 만든다. 흰 바탕 그림은 실제 곱하기로 합성한다. 없는 페르소나는 사람 선 아이콘이다. 초상 레인 소유 코드·그림은 수정하지 않는다.

스크롤바는 별도 폭과 간격을 예약한다. 생성 선택 후 같은 페이지에서는 스크롤을 복원하고 포커스가 선택 행을 숨기지 않게 한다. 검증은 실제 Godot 390×844·360×780·1280×800 캡처, 렌더 글꼴 검사, 텍스트 측정, 겹침 스캔, 직접 이미지 검토를 함께 한다. 데이터가 시안과 다르면 원본 게임 데이터가 우선이다. 최종 결과와 한계는 RESKIN-R24.md를 따른다.
'''
(R/'DESIGN.md').write_text(design,encoding='utf-8')
failed=[r['test'] for r in rows if not r['passed']]
expected={p.stem for p in (R/'project/tests').glob('*_test.gd')}|{'export_licenses','motion_r9_integration','motion_r18_integration','combat_p2_r22_trace','combat_a6_mixed_audit','combat_p3_mixed_audit','combat_a7_gear_audit','combat_a7_gear_balanced','combat_a8_audit','combat_a9_native_10_audit','combat_a9_native_40_audit','import'}
missing=sorted(expected-{r['test'] for r in rows}-{'ui_reskin_r24_test'})
report=f'''# RESKIN R24

미완료·병합 전 사항: 초상 레인 결과는 아직 합치지 않았으며 기존 상반신을 얇은 어댑터로 표시한다. 공통 규칙의 git 명령 금지를 지켜 단계 커밋은 하지 않았다. 새 Web export·docs 배포와 실물 폰 검증은 하지 않았다. DESIGN.md는 교체했으나 수정 허용 범위 밖인 기존 .impeccable/design.json 캐시는 갱신하지 않았다. 필요하면 impeccable document로 별도 갱신할 수 있다.

회귀 검사 통과 {sum(r['passed'] for r in rows)}/{len(rows)}, 실패 {len(failed)}, 미실행 {len(missing)}. 실패·미실행이 있으면 아래 목록에 그대로 남긴다.

실제 게임 UI 코드에 종이·먹·버밀리언 체계를 적용했다. 게임 규칙·대사·저장 형식은 바꾸지 않았다. 코드에서 먼저 추출한 화면/함수/분기 목록은 [source-inventory.json](verification/reskin-r24/source-inventory.json), 실제 상태별 목록은 아래 표다.

- 캡처 {len(inventory)}장, 세 해상도. 입력·캡처 검사 {data['checks']}개, 실패 {len(data['failures'])}.
- 실제 렌더 글꼴 누락 {defects['missing']}, 측정 텍스트 넘침 {defects['clipped']}, 스크롤바 겹침 {defects['rails']}건.
- 원본 이미지 {len(assets)-len(af)}/{len(assets)} 해시 불변. 보호 파일 {len(before)-len(changed)}/{len(before)} 불변.
- 기존 전투 대조 출력 집계 {parity['equal_battles']:,}/{parity['battles']:,}판, {parity['matched_actions']:,}행동 일치. 신규 실행 여부는 all-tests.json의 audit 그룹과 함께 확인한다.
- 폰 검토용 sheet-1.jpg … sheet-{len(sheet_rows)}. 각 장 폭 1200, 최대 {max(x['bytes'] for x in sheet_rows):,}바이트.

## 바뀐 것

1. 공용 부품: reskin_components_r24.gd에 종이·제목·선·행·주 행동·선택·선 아이콘·내비·찢긴 가장자리·스크롤을 통합. UI-r24의 wash는 승인 CSS SVG를 Chromium으로 구운 것이다. 그림 생성 없음.
2. 마을 B: 시설 네 곳을 지도 표지로, 파티 네 자리를 상자 없는 상반신과 자원으로, 다음 원정을 큰 행동으로 교체. 원본의 설명과 추가 출정 선택은 아래 스크롤에 보존. 동료 C: 오른쪽 상반신·세로 선택·실제 단계 대사·시설 행. 생성 5단계: 본문과 선택 분리·화살표 선 아이콘·스크롤 복원. 목록·상세·시설·가방·장비·원정·기록·도감·설정·클라우드는 같은 공용 문법을 사용. 여관 행동은 네모 타일에서 행으로 변경.
3. 전투: 하단 파티·상태·기록의 인물만 초상 어댑터로 연결. 전장 배치·규칙·효과·컷인은 유지. 원본 자원 게이지 보존. DESIGN.md를 새 체계로 재작성.

## 기준 PNG와의 차이

[마을 대조](verification/reskin-r24/compare-town.png), [동료 대조](verification/reskin-r24/compare-companion.png). 시안의 2일째·가상 HP와 실제 저장의 날짜·금화·HP는 다르며 게임 데이터가 우선이다. 동료의 대사는 현재 단계 원문 전체를 사용하므로 시안의 한 줄보다 길다. 기존 상반신의 구도·먹 번짐 가장자리는 별도 초상 레인 결과를 기다린다. 원본의 개요·기술·편성·출정 설명은 첫 화면 아래에 남아 있어 시안보다 스크롤이 길다. 여관의 붉은 새 소식 표지는 실제 현재 단계의 미열람 대화가 있고 오늘 대화가 가능한 경우에만 표시한다. 읽기만으로 저장·난수를 바꾸지 않는 검사도 포함한다.

## 화면·상태 목록

아래 각 행은 390×844·360×780·1280×800에서 캡처했다. 첫 화면과 끝 상태, 빈 상태·오류·확인·입력 상태를 별도로 표기한다. 데이터에 따른 수치 조합은 기존 기능 검사와 원본 대조 검사가 맡는다.

| 화면 / 상태 | 390×844 | 360×780 | 1280×800 |
|---|---|---|---|
'''
for screen in sorted({x['screen'] for x in inventory}):
 links=[]
 for size in [(390,844),(360,780),(1280,800)]:
  item=next((x for x in inventory if x['screen']==screen and tuple(x['size'])==size),None)
  links.append(f"[캡처](verification/reskin-r24/render/{item['file']})" if item else '미캡처')
 report+='| '+screen+' | '+' | '.join(links)+' |\n'
report+='\n## 검사 결과와 변경한 시험\n\n[전체 로그/결과](verification/reskin-r24/all-tests.json). Windows root certificate store 메시지는 환경 진단으로 별도 취급하며, 다른 ERROR·SCRIPT ERROR는 실패다. 초기 클라우드의 서버 부재 실패는 격리된 실제 Worker/D1로 재검사했다. 대사 전수 UI 검사는 최초 래퍼의 360초 제한과 네이티브의 1200초 감시 제한 때문에, 오류 없이 완료한 인물·언어·크기 블록을 보존하고 나머지를 같은 기대값으로 이어 검사했다. [연속 검사 근거](verification/reskin-r24/dialogue-continuation.json)는 120/120블록과 실제 재개 프로세스 종료 0을 기록한다. 반복 재구성 시 동일 셰이더를 공유해 다시 만드는 비용도 줄였다.\n\n실패: '+(', '.join(failed) or '없음')+'\n\n미실행: '+(', '.join(missing) or '없음')+'\n\n위치 보정: [목록](verification/reskin-r24/test-position-updates.json)의 11개 포인터 도우미는 기존 버튼을 스크롤 안으로 가져온 뒤 같은 마우스 입력을 보낸다. ui_town_r21_test는 스크롤 안 컨트롤도 실제로 끝까지 도달할 수 있는지 검사한다. 기능 기대값·활성 조건·순서·상태 변화는 바꾸지 않았다. 외형 보정: ui_town_r21_round9_test는 같은 인물 수를 새 어댑터에서 세고 승인 계약대로 활성 막대가 글자 위에 있는지 검사한다. ui_town_r21_round11_test는 SVG 파일명 대신 동일한 번역 제목과 실제 Label을 검사한다. ui_semantics_native_r23_test는 흰 글자 대신 선택 상태와 실제 밑줄 그림을 검사한다. ui_expe_pass5_r23_test는 원본 문구와 별표 개수를 그대로 비교하고 각 별이 실제 승인 SVG로 그려지는지도 확인한다. 대사 검사 감시 시간은 3600초로 늘리고 완료 블록의 재개 근거를 남긴다.\n\n[컨트롤 id 대조](verification/reskin-r24/control-id-audit.json): 변경한 주요 5개 화면의 기존 리터럴 컨트롤 id 누락 0. 승인 C 구성에 필요한 동료 칩·시설 행만 추가했다. [디자인 탐지](verification/reskin-r24/design-detector.json)는 지적 0이며 직접 렌더 검토를 대체하지 않는다.\n'
(R/'RESKIN-R24.md').write_text(report,encoding='utf-8')
print(json.dumps({'captures':len(inventory),'sheets':len(sheet_rows),'tests':len(rows),'failed':failed,'missing':len(missing),'scan':defects,'protected_changes':changed},ensure_ascii=False))
