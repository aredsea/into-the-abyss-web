"""Reviewable second-pass evidence. Keep incomplete screens visibly incomplete."""
from pathlib import Path
import json,hashlib,math,re
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageChops
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';C=O/'compare-round2';C.mkdir(exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
specs=[
 ('00-town-approved-direction-0','town','후보·플래그','로고·도시·CTA·내비 벡터 보정. 초상 비율·질감·라틴 활자 차이.'),
 ('01-companions-0','party','후보·플래그','칸별 크롭과 차등 배치. 대각 콜라주·초상 스케일·명패 회전 미달.'),
 ('01-companions-1','member','후보·플래그','이름·HP/MP 막대·탭 좌표 보정. 원본 방어17.68·특성 문구 유지. 그림 밀도 차이.'),
 ('01-companions-2','skills','후보·플래그','텍스트형 활성 탭·기술 아이콘·제목 폭 보정. 원본 설명·초상·배경 차이.'),
 ('02-equipment-0','formation','기본·새 화면','편성/부위 관리 경로와 4자리·보유 동료 선택. 시안의 공간 투시·초상 스케일 차이.'),
 ('02-equipment-1','legacy-equipment','기본·기존 화면','시안 재현 미구현. 기존 장착/판매/비교. 장비 옵션은 기존 웹 RNG.'),
 ('02-equipment-2','legacy-art','기본·기존 화면','전투/연출 파일 수정 금지. 기존 미리보기 유지, 시안형 외곽 UI 미구현.'),
 ('03-preparation-0','depart','기본·새 화면','시안 유적을 벡터 추적. 실제 선택층·출전4명·HP/MP 규칙·층 보스 동선. 2층 고정 숫자는 복제하지 않음.'),
 ('03-preparation-1','bag','기본·새 화면','3탭·스크롤·보유량·레벨 제약·실제 보급품 사용. 시안 4품목 대신 원본 전체 목록.'),
 ('03-preparation-2','target-selected','기본·새 화면','4대상·선택/회복 예고·사용/취소. 실제 Lv.1·보유량·회복 반올림. 라디오/선택 세부 문법 차이.'),
 ('04-guild-0','legacy-guild','기본·기존 화면','시안 재현 미구현. 원본 의뢰 생성·균열 출정·정산을 기존 UI에 연결.'),
 ('04-guild-1','legacy-recruit','기본·기존 화면','별도 소개 화면 미구현. 현재 길드 화면을 대체 현황으로 캡처. 영입 레벨은 기존 파티 최고 레벨.'),
 ('04-guild-2','legacy-research','기본·기존 화면','시안 재현·원본 페르소나 연구 전체 이식 미구현. 기존 전술 슬롯 유지.'),
 ('05-commerce-0','legacy-shop','기본·기존 화면','시안 재현 미구현. 기존 원본 가격 반올림 보정 유지.'),
 ('05-commerce-1','legacy-shopgear','기본·기존 화면','시안 재현·원본 일일 장비 진열/품절/옵션 전체 이식 미구현.'),
 ('05-commerce-2','legacy-smithy','기본·기존 화면','시안 재현·원본 강화/가공 RNG 전체 이식 미구현.'),
 ('06-town-life-0','legacy-inn','기본·기존 화면','시안 재현 미구현. 일반 여관 수치의 기존 Lua 대조 유지. 성적/AI 장면 제외.'),
 ('06-town-life-1','journal','기본·새 화면','기록 제목·타임라인·빈 상태·스크롤. 기존 40줄 기록, 원본 모험 연대기 전체 아님.'),
 ('06-town-life-2','summary','기본·새 화면','실제 금화/경험치·일수·4인 레벨 변화·중복 지급 방지. 유적/초상 구도·세부 질감 차이.'),
 ('07-exploration-0','explore','후보·플래그','A의 탐색5회/발견/전투로 연결. 시안의 8노드 지도와 실제 원본 층 상태가 달라 새 지도 구도 미완료.'),
 ('07-exploration-1','legacy-cache','기본·기존 저장 전용','시안형 보관함·원본 전체 카드 사건 미구현. 옛 8노드 저장의 기존 보관함을 캡처.'),
 ('07-exploration-2','rest','후보·플래그','A의 자동 HP30%·MP60% 회복/보스 이동. 시안의 휴게실 그림·배치 미달.'),
 ('08-cards-states-0','cards','후보·플래그','카드 보기 UI 후보. 기존 저장의 2종 카드만 유지, 원본 전체 카드 생성/사건 미이식.'),
 ('08-cards-states-1','retreat','기본·기존 확인창','시안형 귀환 확인 미구현. 실제 보수/경험치 확인·취소/정산은 기존 확인창.'),
 ('08-cards-states-2','cards-empty','후보·플래그','카드 빈 상태와 복귀. 시안의 빈 가방 그림/가방 전용 구도는 미구현.'),
 ('11-battle-results-0','cutin','기본·기존 전투','r18~20 연출 유지. 이 작업의 전투 파일 변경 없음.'),
 ('11-battle-results-1','legacy-victory','기본·기존 전투','기존 전투 결과 패널. 시안의 VICTORY/파티 구도 미구현.'),
 ('11-battle-results-2','legacy-defeat','기본·기존 전투','기존 전투 결과 패널. 시안의 DEFEAT/파티 구도 미구현.')]
def actual(name):
    if name=='cutin':return R/'verification/ui-r18/frames/hildegard-cutin-390.png'
    return O/'render'/f'{name}-390.png'
def bound(a,kind,roi):
    mask=np.max(a,axis=2)<90 if kind=='ink' else (a[:,:,0]>160)&(a[:,:,1]<110)&(a[:,:,2]<85)
    x,y,w,h=roi; yy,xx=np.where(mask[y:y+h,x:x+w])
    return [int(xx.min()+x),int(yy.min()+y),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)] if len(xx) else None
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',14)
sheet=Image.new('RGB',(1170,math.ceil(len(specs)/3)*459),'#f4efe3');draw=ImageDraw.Draw(sheet)
rows=[];screens=[]
for i,(key,name,status,reason) in enumerate(specs):
    ref=Image.open(O/'panels'/f'{key}.png').convert('RGB'); path=actual(name)
    if not path.exists():raise FileNotFoundError(path)
    got=Image.open(path).convert('RGB').resize((390,844),Image.Resampling.LANCZOS)
    both=Image.new('RGB',(780,844));both.paste(ref,(0,0));both.paste(got,(390,0));both.save(C/f'{key}-side-by-side.png')
    ImageChops.difference(ref,got).save(C/f'{key}-difference.png')
    a=np.array(ref);b=np.array(got);d=np.abs(a.astype(float)-b)
    screens.append(dict(panel=key,render=str(path.relative_to(R)),route=status,reason=reason,mae=round(float(d.mean()),3),pixels_gt30_percent=round(float((d.max(2)>30).mean()*100),3)))
    # A deliberately narrow common measurement, independent of authored boxes.
    # Masks include overlapping art: these are image-region bounds, not glyphs.
    regions=[('header','ink',[5,10,280,45]),('navigation','ink',[10,760,370,84]),('lower_action','red',[0,630,390,130])]
    if key.startswith('11'):regions=[('result_region','ink',[0,40,390,550])]
    for element,kind,roi in regions:
        expected=bound(a,kind,roi);gotbox=bound(b,kind,roi)
        delta=[v-u for u,v in zip(expected,gotbox)] if expected and gotbox else None
        error=max(map(abs,delta)) if delta else None
        rows.append(dict(panel=key,element=element,reference=expected,render=gotbox,delta=delta,max_error=error,within_2px=error is not None and error<=2,route=status,reason=reason))
    x=(i%3)*390;y=(i//3)*459
    draw.text((x+4,y+2),key,fill='#111715',font=font)
    draw.text((x+4,y+20),'시안 | 게임 · '+status,fill='#111715',font=font)
    sheet.paste(ref.resize((195,422),Image.Resampling.LANCZOS),(x,y+37));sheet.paste(got.resize((195,422),Image.Resampling.LANCZOS),(x+195,y+37))
for block in range(math.ceil(len(specs)/4)):
    review=Image.new('RGB',(1560,1688),'#f4efe3')
    for offset in range(4):
        idx=block*4+offset
        if idx>=len(specs):break
        review.paste(Image.open(C/f'{specs[idx][0]}-side-by-side.png'),((offset%2)*780,(offset//2)*844))
    review.save(C/f'review-{block+1}.jpg',quality=85)
sheet=sheet.resize((900,round(sheet.height*900/1170)),Image.Resampling.LANCZOS)
quality=85
while True:
    sheet.save(O/'owner-sheet.jpg',quality=quality,optimize=True,subsampling=2)
    if (O/'owner-sheet.jpg').stat().st_size<=400000:break
    quality-=5
    if quality<15:raise ValueError('Owner sheet exceeds size limit')
(C/'comparison.json').write_text(json.dumps(dict(method='color-mask bounds in common image ROIs, including art; not element/glyph acceptance',screens=screens,regions=rows),ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# 2차 화면별 위치 차이','', '시안과 게임은 각각 390×844로 정규화했다. 공통 ROI 안의 색 마스크 경계이며 겹친 그림을 포함한다. 구현한 노드의 좌표를 정답으로 돌려쓰지 않는다. 기존 화면과 미구현은 경로 열에 명시한다. **≤2px나 모든 패널 완성을 뜻하지 않는다.**','', '|패널|영역|시안 xywh|게임 xywh|오차 xywh|최대 px|경로|이유|','|---|---|---|---|---|---:|---|---|']
for row in rows:lines.append('|'+ '|'.join(str(row[k]) for k in ['panel','element','reference','render','delta','max_error','route','reason'])+'|')
(C/'comparison.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
baseline=read(O/'round2-before.json');changed=[];protected=[]
for rel,old in baseline.items():
    p=R/rel
    if not p.exists() or sha(p)!=old:
        changed.append(rel)
        if p.name.startswith(('battle_','combat_','signature_')) or p.name in ['dungeons-r21.json','enemies-r21.json','dungeon_rules_r21.gd']: protected.append(rel)
new=[p.relative_to(R).as_posix() for base in ['project','tools'] for p in (R/base).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.import','.pyc'] and p.relative_to(R).as_posix() not in baseline]
hashes=read(R/'ASSET-HASHES.json');asset_changes=[r['path'] for r in hashes if sha(R/r['path'])!=r['sha256']]
assert not protected,protected
assert not asset_changes,asset_changes
rules=read(O/'rules-results.json');ui=read(O/'ui-results.json');ui2=read(O/'ui-round2-results.json');common=read(O/'common-results.json');web=read(O/'web/results.json');comp=read(O/'compare/comparison.json');version=read(R/'docs/version.json')
summary=dict(new_panels=14,default_new_panels=6,preview_panels=8,not_rebuilt_panels=14,source_samples=len(rules['oracle_samples']),source_matches=sum(x['match'] for x in rules['oracle_samples']),rule_checks=rules['checks'],rule_failures=len(rules['failures']),ui_checks=ui['checks']+ui2['checks'],ui_failures=len(ui['failures'])+len(ui2['failures']),common_groups=len(common),failed_groups=sum(x['exit_code']!=0 or bool(x['errors']) for x in common),web_configs=len(web),web_distinct_sizes=len({(x['width'],x['height']) for x in web}),web_errors=sum(len(x['errors']) for x in web),first_four_2px=comp['within_2px'],first_four_regions=comp['elements_measured'],owner_sheet_bytes=(O/'owner-sheet.jpg').stat().st_size,owner_sheet_size=list(sheet.size),owner_sheet_jpeg_quality=quality,asset_hashes=len(hashes),asset_changes=asset_changes,protected_changes=protected,changed=changed,new=new,version=version)
(O/'round2-summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
first=O/'UI-R21-D-first.md'
if not first.exists():first.write_text((R/'UI-R21-D.md').read_text(encoding='utf-8'),encoding='utf-8')
report=['# UI-R21-D','', '## 2차 — 부분 인계, 28패널 전체 완료 아님','',
f"새 시안형 화면은 **14 / 28패널**까지 만들었다(기존 후보4 재작업 + 신규10). 그중 출발·편성·가방·대상·기록·정산 **6패널은 기본 동선**, 홈/동료4 및 탐색/휴식/카드/카드 빈 상태 **8패널은 `?town_r21_preview=1` 뒤**다. 나머지 **14패널은 시안 재구축 미완료**이며 기존 기능 화면을 유지한다. 시각 승인은 받지 않았다. 전체 시안 동일·≤2px 목표를 달성했다고 보고하지 않는다.", '',
'### 수치','', '|항목|2차 최종|','|---|---:|',
f"|원본 Lua 대조|{summary['source_matches']} / {summary['source_samples']} (100%)|",f"|마을 규칙 검사 / 실패|{rules['checks']} / {len(rules['failures'])}|",f"|마을 UI 검사 합계 / 실패|{summary['ui_checks']} / {summary['ui_failures']}|",f"|공통 및 새 검사 그룹 / 실패|{len(common)} / {summary['failed_groups']}|",f"|Web 구성 / 서로 다른 크기 / 콘솔·페이지 오류|{len(web)} / {summary['web_distinct_sizes']} / {summary['web_errors']}|",f"|후보4의 기존18 ROI 중 ≤2px|{comp['within_2px']} / 18 (1차 5 / 18)|",f"|원본 자산 SHA / 변경|{len(hashes)} / {len(asset_changes)}|",f"|읽기 전용 전투·A 데이터 변경|{len(protected)}|",f"|owner-sheet.jpg|{sheet.width}×{sheet.height}, {summary['owner_sheet_bytes']:,} bytes (400,000 이하)|",'',
'### 화면별 같음·다름과 기본 동선','', '|시안 패널|게임 캡처|기본/플래그|같은 점·차이와 이유|','|---|---|---|---|']
for key,name,status,reason in specs:report.append(f'|{key}|{name}|{status}|{reason}|')
report+=['', '### 2px 미달 원인과 수정','',
'좌표·테마 문제: 홈 로고 y/높이·개요 이름 폭·HP/MP 막대·탭 높이/밑줄·솔리드 내비/기술 아이콘을 보정했다. 17개 새 장식은 시안 색 마스크에서 SVG로 벡터 추적했다. 생산 래스터 잉크는 없다. 생성 시안의 글자 자체는 추적하지 않고 r19 실제 글꼴을 쓴다.',
'초상/구도 문제: `town_portrait_r21.gd`는 C의 `slots/<id>-<slot>.png` 10종 이름을 우선한다. C의 preview-placement.json을 출처 그대로 project/data/portrait-slots-r21.json에 기록했다. 파일이 없으면 기존 원본 cutout의 해당 안쪽 크롭, 이후 원본 메시 초상으로 돌아간다. D에는 C의 그림 파일을 복사하지 않았다. 현재 D가 사용하는 fallback에서 머리·의상·RGB를 다시 그리지 않았다. 27명에게는 아직 C 개별 크롭이 없어 힐데가르트 칸 프레임을 원본 범위 안에 적용한다.',
'시안/데이터 문제: 생성 이미지의 Lv20·2층·보급품 수량·짧은 특성 문구는 정답 데이터가 아니다. 게임은 실제 저장의 레벨·선택층·재고·원본 설명/방어17.68을 표시한다. 그림 질감과 원본 초상의 얼굴·옷 비율 차이, 동료 콜라주, 지도/휴게실/빈 상태 그림과 전체 문법은 아직 남아 있다.',
'측정 한계: 기존18 ROI와 28패널의 공통 ROI는 색 마스크 경계다. 겹친 그림과 글자가 함께 들어가므로 글자 베이스라인이나 모든 의미 요소의 2px 합격으로 해석하면 안 된다. 원시 좌표·차분·잔차를 보존했다.', '',
'### 데이터·원본 규칙·저장','',
'`dungeon_catalog()`는 A의 9대던전·층 범위·개방 여부를 반환한다. 출발 화면은 실제 개방층을 선택하고 `depart_dungeon`으로 출발한다. A의 최소 출발 UI 대신 새 기본 출발 화면을 사용한다. 기본 탐색은 A의 기능 화면이며 새 지도 시안 후보만 플래그 뒤다.',
'길드는 01-game.lua의 splitmix64 G_rnd와 72-guild.lua의 gd_new를 이식했다. 4난이도·2개 원본 의뢰 균열·종류·중복 재추첨·레벨·엘리트 강도·의뢰번호가 원본과 맞는다. A의 6균열 정의 중 원본 길드가 의뢰를 생성하는 것은 남서 설산/남동 숲 2곳이다. 길드 UI가 A의 depart_rift_quest를 호출하고 수락 원본 계약을 run.source_quest에 보존한다.',
'마렌토 보수 보너스와 원본 정예 확정 장비 수/등급·직업·부위·코드·40bit 시드를 이식하고 Lua 대조했다. 승리·패배 시 수락 의뢰 제거/게시판 보충/갱신 비용 초기화, 포기 시 해당 의뢰 교체, 중복 정산 거절을 검사했다. A의 이미 지급한 기본 보수를 다시 더하지 않는다. 장비 코드의 생성 일치와 장비 옵션 계산 일치는 별개이며 **장비 roll/일일 진열/강화/가공은 기존 웹 규칙**이다.',
'저장 schema/path를 유지하고 additive town_r21(seed,counter,qn)을 추가했다. 옛 저장은 기존 rng에서 결정적으로 초기화하며 이미 존재하는 source_id의 번호를 이어간다. 기존 의뢰는 저장 이름·레벨·보수 값을 유지한 계약으로 출발한다. 옛 schema1→2 이관, 입력 불변, 진행 중 v3/원본층·균열 전투 roundtrip, 잘못된 RNG 원자적 거절을 시험했다. 사용자 저장은 삭제/초기화하지 않았다. UI 시험은 user://*fixture.json에만 쓴다.',
'Lua 원본을 Python/JS로 번역한 정답은 사용하지 않았다. tools/town_r21_oracle.mjs가 읽기 전용 원본을 Wasmoon으로 실행한다. 출처 SHA/호스트 대체는 oracle-provenance.json, 모든 입력과 Lua/Godot 결과는 rules-results.json이다. 성적 콘텐츠·79-sex.lua 장면·친밀도 장면·AI 송신은 실행/이식하지 않는다.', '',
'### 검사·산출물','', '|검사|결과|','|---|---|']
for x in common:report.append('|'+x['name']+'|'+'; '.join(x['summary'][-2:]).replace('|','/')+f" (exit {x['exit_code']}, errors {len(x['errors'])})|" )
report += ['', '모든 엔진 실행은 tools/godot_r17.py를 썼다. 격리 Windows의 기존 root certificate store 경고는 로그에 보존하고 검사 오류와 구분했다. 공통 전투 기대값은 변경하지 않았다. 마을 검사의 1곳 고정 catalog 기대는 실제9곳/개방 조건으로 바꿨다. Web의 옛 travel:patrol 경로와 battle-r20b 기대는 실제 A 탐색/전투 build로 교체했다.',
'Web은 390×844, 360×780, 390×664, 1280×800, 430×932 + 360×780 reduced-motion이다. 기본 URL에서 가방/대상 취소/출발/편성/기록, 플래그에서 후보4, 실제 원본 층 전투 진입·공격·대상·보급·기록·고유기·승리 후 뷰포트 복귀를 실제 포인터로 검사했다. 상태 변경 JavaScript 브리지는 추가하지 않았다.',
f"Web export ui_build: **{version['ui_build']}**. PCK SHA-256 `{version['pck_sha256']}`. 로컬 내보내기이며 원격 배포하지 않았다.",
'시안/게임 28쌍과 차분: [compare-round2](verification/town-r21/compare-round2/comparison.md). 후보4 세부18 ROI: [compare](verification/town-r21/compare/comparison.md). 확인용 [owner-sheet.jpg](verification/town-r21/owner-sheet.jpg). 현재 결과를 직접 열어 검수했으며 시각 승인/전 패널 일치라고 판단하지 않는다.', '',
'### 남은 일','',
'기본 연결6도 전체 픽셀 일치가 아니다. 후보8의 구성 보정, 장비/연출 외곽·길드3·상회3·여관·보관함·귀환 확인·전투 결과3의 시안 재구축14, 원본 장비 RNG/전술 연구/페르소나 영입 레벨/카드와 사건 전체·모험 연대기/가변 파티 이식이 남았다. 전투 화면 파일은 허용 범위 밖이라 그대로 유지했다. 이번 작업은 지시서의 “한 번에 다 못 끝내면 끝낸 데까지 검사 통과 상태로 멈추고 남은 것을 적어라”에 따른 부분 인계다.', '',
'### 2차 변경 파일','']
report+=['- '+p for p in changed+new if not p.endswith('.uid')]
report += ['', '비교/로그/요약/Web export 산출물은 verification/town-r21/** 및 docs/**. 모든 쓰기는 이 worktree 안에서 했다. 최초 읽기 쉘에 금지된 git status --short를 잘못 포함했으나 소유권 오류로 실패했고 이후 Git 명령/설정 변경은 하지 않았다. 디자인 스킬 detector는 GDScript 대상에서 []였지만 시각 완성의 근거로 사용하지 않는다. DESIGN.md의 r11 토큰과 sidecar는 오래되어 보고만 하고 범위 밖 문서는 바꾸지 않았다.', '', '## 1차 기록 — 아래 수치는 1차 당시 상태','',first.read_text(encoding='utf-8')]
(R/'UI-R21-D.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['new','changed','version']},ensure_ascii=False,indent=2))
