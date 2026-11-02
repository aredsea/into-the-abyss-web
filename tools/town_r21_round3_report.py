"""Fresh 28-panel comparisons and an honest third-pass handoff; no Git."""
from pathlib import Path
import json,hashlib,math,re
import numpy as np
from PIL import Image,ImageChops,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];O=R/'verification/town-r21';V=O/'round3';C=O/'compare-round3';C.mkdir(exist_ok=True)
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
specs=[
 ('00-town-approved-direction-0','town','기본 · 시안형','C 원본 크롭·로고·CTA·시설·5내비. 초상 비율·도시 배경·활자 질감 차이.'),
 ('01-companions-0','party','기본 · 시안형','C 칸·대각 경계·명패와 글자 함께 회전·30인 스크롤. 참조의 얼굴 확대·사선 각도 차이.'),
 ('01-companions-1','member','기본 · 시안형','C 상세 칸·실제 수치·개요/기술/편성. 원본 초상 자세·그림 밀도 차이.'),
 ('01-companions-2','skills','기본 · 시안형','C 기술 칸·원본 설명·연출 연결. 실제 설명 길이·초상 비율 차이.'),
 ('02-equipment-0','formation','기본 · 시안형','원본 4인 편성·보유 동료 선택·장비 관리. 시안 공간 투시·크롭 크기 차이.'),
 ('02-equipment-1','equipment','기본 · 시안형','초상·HP/MP·3부위·장착/해제/판매·전후 수치. 새 저장 장비 없음은 원본 보유 상태, 무기 그림은 공용 벡터.'),
 ('02-equipment-2','art','기본 · 새 외곽','마을 종이/먹색 외곽·30명 이전/재생/다음·닫기. 내부 원본 고유기 재사용, 컷인/무기 수정 없음.'),
 ('03-preparation-0','depart','기본 · 시안형','실제 층 선택·출전 4인·HP/MP 회복·균열 의뢰 출발. 시안 고정 Lv20/2층 대신 실제 저장.'),
 ('03-preparation-1','bag','기본 · 시안형','3탭·보유량·원본 모든 보급품·스크롤. 시안 4품목과 실제 품목 수 차이.'),
 ('03-preparation-2','target-selected','기본 · 시안형','명시적 대상 선택·회복 예고·사용/취소. 실제 Lv1/재고, 세부 라디오 문법 차이.'),
 ('04-guild-0','guild','기본 · 시안형','접수 초상·3탭·원본 생성 의뢰·수락/포기/출발/갱신. 원본 NPC 초상 자세와 시안 배경 차이.'),
 ('04-guild-1','recruit','기본 · 시안형','별도 소개 탭·보유 수·금화·소개비·실제 영입. 페르소나 영입 레벨·원본 영입 RNG는 미이식.'),
 ('04-guild-2','legacy-research','기본 · 기존 화면','원본 페르소나 연구 전체 이식과 시안 재구축 미완료. 기존 동료별 전술 슬롯 유지.'),
 ('05-commerce-0','shop','기본 · 시안형','피에트로·2탭·금화·보급품 그림/가격/구입. 원본 초상·건축·아이템 그림이 시안과 다름.'),
 ('05-commerce-1','shopgear','기본 · 시안형','직업/부위·원본 일일 진열·레벨 제한·품절·40bit 코드. 목록 구도·장비 그림 차이.'),
 ('05-commerce-2','smithy','기본 · 시안형','한나·원본 가공 가격/확률/회차·제련/단계/비용. 신규 저장 장비 없음, 전용 장비 그림·공방 배경 미재현.'),
 ('06-town-life-0','inn','기본 · 시안형','도로테아·동료 선택·호감·4행동·일일 제한·실제 원본 핸들러. 원본 초상 자세와 실내 배경 차이.'),
 ('06-town-life-1','journal','기본 · 시안형','실제 기록·타임라인·스크롤. 원본 모험 연대기 전체 대신 기존 40줄 로그.'),
 ('06-town-life-2','summary','기본 · 시안형','실제 금화/경험치/일수·4인 변화·중복 지급 방지. 유적·파티 구도와 질감 차이.'),
 ('07-exploration-0','explore','기본 · 시안형','원본 5탐색·전투·발견 동선. 시안 8노드 대신 실제 원본 5단계, 지도/배경 그림 미달.'),
 ('07-exploration-1','legacy-cache','옛 저장만 · 기존 화면','원본 A는 발견품 자동 적립이다. 시안형 봉인 보관함/원본 카드 사건 전체 미이식, 옛 저장의 보관함 보존.'),
 ('07-exploration-2','rest','기본 · 시안형','실제 HP30%/MP60% 자동 회복·보스 도전. 휴게실 삽화·파티 배치 차이.'),
 ('08-cards-states-0','cards','기본 · 시안형','보관한 카드·사용 가능 조건·복귀. 원본 전체 카드 생성/사건 미이식, 기존 카드 2종 보존.'),
 ('08-cards-states-1','retreat','기본 · 시안형','원정 누적 금화/경험치·취소/정산·원자적 취소. 시안 유적 구도·그림 질감 차이.'),
 ('08-cards-states-2','cards-empty','기본 · 시안형','카드 빈 상태·복귀. 시안의 빈 가방 그림/구도는 미재현.'),
 ('11-battle-results-0','cutin','기본 · 기존 전투 유지','r18~20 컷인·연출·잉크 유지. 마을 작업에서 내부 연출 파일 변경 없음.'),
 ('11-battle-results-1','victory','기본 · 새 외곽','VICTORY·유적·실제 전투 후 HP·기존 결과 확인 핸들러. 시안 파티 포즈·배경 그림 차이, 보상은 기존 원정 정산 시점.'),
 ('11-battle-results-2','defeat','기본 · 새 외곽','DEFEAT·유적·실제 전투 후 HP·정산 연결. 시안 파티 포즈·배경 그림 차이, 원본 패배 규칙은 기존 핸들러.')]
new_names={'town','party','member','skills','equipment','art','guild','recruit','shop','shopgear','smithy','inn','explore','rest','cards-empty','retreat','victory','defeat'}
def actual(name):
    if name=='cutin':return R/'verification/ui-r18/frames/hildegard-cutin-390.png'
    return (V if name in new_names else O)/'render'/f'{name}-390.png'
def bounds(a,kind,roi):
    mask=np.max(a,axis=2)<90 if kind=='ink' else (a[:,:,0]>160)&(a[:,:,1]<110)&(a[:,:,2]<85)
    x,y,w,h=roi;yy,xx=np.where(mask[y:y+h,x:x+w])
    return [int(xx.min()+x),int(yy.min()+y),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)] if len(xx) else None
font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',14)
sheet=Image.new('RGB',(1170,math.ceil(len(specs)/3)*459),'#f4efe3');draw=ImageDraw.Draw(sheet);screens=[];regions=[]
for i,(key,name,status,reason) in enumerate(specs):
    ref=Image.open(O/'panels'/f'{key}.png').convert('RGB');path=actual(name)
    got=Image.open(path).convert('RGB');assert got.size==(390,844),(name,got.size)
    both=Image.new('RGB',(780,844));both.paste(ref,(0,0));both.paste(got,(390,0));both.save(C/f'{key}-side-by-side.png')
    ImageChops.difference(ref,got).save(C/f'{key}-difference.png')
    a=np.array(ref);b=np.array(got);diff=np.abs(a.astype(float)-b)
    screens.append({'panel':key,'render':path.relative_to(R).as_posix(),'route':status,'reason':reason,'mae':round(float(diff.mean()),3),'pixels_gt30_percent':round(float((diff.max(2)>30).mean()*100),3)})
    rois=[('header','ink',[5,10,280,45]),('navigation','ink',[10,760,370,84]),('lower_action','red',[0,630,390,130])]
    if key.startswith('11'):rois=[('result_region','ink',[0,40,390,550])]
    for element,kind,roi in rois:
        rb=bounds(a,kind,roi);gb=bounds(b,kind,roi);delta=[v-u for u,v in zip(rb,gb)] if rb and gb else None
        regions.append({'panel':key,'element':element,'reference':rb,'render':gb,'delta':delta,'max_error':max(map(abs,delta)) if delta else None})
    x=i%3*390;y=i//3*459;draw.text((x+4,y+2),key,fill='#111715',font=font);draw.text((x+4,y+20),'시안 | 게임 · '+status,fill='#111715',font=font)
    sheet.paste(ref.resize((195,422),Image.Resampling.LANCZOS),(x,y+37));sheet.paste(got.resize((195,422),Image.Resampling.LANCZOS),(x+195,y+37))
for block in range(7):
    review=Image.new('RGB',(1560,1688),'#f4efe3')
    for offset in range(4):
        index=block*4+offset
        review.paste(Image.open(C/f'{specs[index][0]}-side-by-side.png'),((offset%2)*780,(offset//2)*844))
    review.save(C/f'review-{block+1}.jpg',quality=87)
sheet=sheet.resize((900,round(sheet.height*900/1170)),Image.Resampling.LANCZOS);quality=88
while True:
    sheet.save(O/'owner-sheet.jpg',quality=quality,optimize=True,subsampling=2)
    if (O/'owner-sheet.jpg').stat().st_size<=400000:break
    quality-=3
    assert quality>=10
comparison={'method':'Independent pixel-mask bounds within shared image ROIs; includes overlapping art and is not glyph/element acceptance','screens':screens,'regions':regions}
(C/'comparison.json').write_text(json.dumps(comparison,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# 3차 · 28패널 위치 오차','', '모든 이미지 390×844. 색 마스크 경계는 겹친 그림을 포함하며 글자 기준선이나 의미 요소의 2px 합격이 아니다. 시안형도 원본 그림·수치로 인해 차이가 남는다.','', '|패널|영역|시안 xywh|게임 xywh|오차 xywh|최대 px|','|---|---|---|---|---|---:|']
for row in regions:lines.append('|'+ '|'.join(str(row[k]) for k in ['panel','element','reference','render','delta','max_error'])+'|')
(C/'comparison.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
base=read(V/'baseline.json')['files'];changed=[p for p,h in base.items() if not (R/p).exists() or sha(R/p)!=h]
new=[p.relative_to(R).as_posix() for f in ['project','tools'] for p in (R/f).rglob('*') if p.is_file() and '.godot' not in p.parts and p.suffix not in ['.pyc','.import'] and p.relative_to(R).as_posix() not in base]
# This helper was created immediately before it took the immutable snapshot.
if 'tools/town_r21_round3_baseline.py' not in new:new.append('tools/town_r21_round3_baseline.py')
protected=[p for p in changed if Path(p).name.startswith(('battle_','combat_','signature_')) or Path(p).name in ['dungeons-r21.json','enemies-r21.json','dungeon_rules_r21.gd','dungeon_enemy_r21.gd'] or p.startswith(('project/assets/enemies-r21/','project/assets/portraits-r21/'))]
hashes=read(R/'ASSET-HASHES.json');asset_changes=[p['path'] for p in hashes if sha(R/p['path'])!=p['sha256']]
assert not protected and not asset_changes,(protected,asset_changes)
common=read(O/'common-results.json');ui=read(V/'ui-results.json');ui2=read(O/'ui-round2-results.json');ui1=read(O/'ui-results.json');result=read(V/'result-ui-results.json');commerce=read(V/'commerce-results.json');rules=read(O/'rules-results.json');pack=read(V/'portrait-pack.json');sizes=read(V/'export-sizes.json');web=read(O/'web/results.json');version=read(R/'docs/version.json')
assert all(not x['failures'] for x in [ui,ui2,ui1,result,commerce,rules])
assert all(not x['errors'] and x['exit_code']==0 for x in common)
assert len(web)==6 and all(not x['errors'] and not x['text_errors'] for x in web)
web_commerce=read(V/'web-commerce/results.json')
assert len(web_commerce)==6 and all(not x['errors'] and x['source_purchase'] and x['sold_out'] and x['source_equipped'] for x in web_commerce)
summary={'default_styled_panels':25,'original_combat_panel':1,'remaining_legacy_panels':2,'lua_samples':len(rules['oracle_samples'])+commerce['lua_samples'],'lua_matches':sum(x['match'] for x in rules['oracle_samples'])+commerce['lua_matches'],'rule_checks':rules['checks']+commerce['checks'],'ui_checks':ui1['checks']+ui2['checks']+ui['checks']+result['checks'],'failed_groups':0,'groups':len(common),'portrait_characters':pack['characters'],'portrait_slots':pack['slots'],'enemy_art_fallbacks':ui['enemy_art_fallbacks'],'pck':sizes,'owner_sheet':{'size':list(sheet.size),'bytes':(O/'owner-sheet.jpg').stat().st_size,'quality':quality},'web_sizes':len({(x['width'],x['height']) for x in web}),'web_configs':len(web),'web_errors':sum(len(x['errors']) for x in web),'asset_hashes':len(hashes),'asset_changes':asset_changes,'protected_changes':protected,'changed':changed,'new':new}
(V/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
archive=V/'UI-R21-D-round2.md'
if not archive.exists():archive.write_text((R/'UI-R21-D.md').read_text(encoding='utf-8'),encoding='utf-8')
report=['# UI-R21-D','', '## 3차 — 검증 통과 부분 인계 · 시안 전패널 일치 미완료','',
'시안형 화면 **25 / 28패널**을 기본 동선에 연결했다(기존 기본6 + 미리보기8 활성화 + 추가11). 전투 컷인 1패널은 기존 r18~20을 유지했다. **연구·봉인 보관함 2패널은 기존 UI**이며, 원본 페르소나 연구/영입 레벨·영입 RNG·카드 사건 전체 이식은 남았다. 시안형 25개도 그림 비율·배경·질감 차이가 남아 있고 전패널 동일이나 2px 일치로 승인하지 않는다. 지시서의 부분 인계 조항에 따라 검사 실패 0인 상태로 인계한다.','',
'### 핵심 수치','', '|항목|3차 최종|','|---|---:|',
f"|시안형 기본 동선 / 전체|25 / 28|",f"|원본 Lua 대조|{summary['lua_matches']} / {summary['lua_samples']}|",f"|마을 규칙 검사 / 실패|{summary['rule_checks']} / 0|",f"|마을 UI 검사 / 실패|{summary['ui_checks']} / 0|",f"|공통·추가 검사 그룹 / 실패|{len(common)} / 0|",'|적 그림 / 대체|100 / 0|','|C 초상 / 동일 RGBA 칸|30명 / 300칸|',f"|PCK / 2차 대비 증가|{sizes['pck_bytes']:,} / +{sizes['increase_from_round2_bytes']:,} bytes|",f"|Web 구성 / 서로 다른 크기 / 오류|{len(web)} / {summary['web_sizes']} / {summary['web_errors']}|",f"|owner-sheet.jpg|{sheet.width}×{sheet.height}, {(O/'owner-sheet.jpg').stat().st_size:,} bytes|",f"|원본 SHA / 변경|{len(hashes)} / 0|",'|금지된 전투·A/B/C 원본 파일 변경|0|','',
'### 웹 용량·C 칸·B 적 연결','',
f"이전 docs PCK는 {sizes['round2_pck_bytes']:,} bytes, A/B/C 합류 파일을 필터 없이 다시 내보낸 PCK는 {sizes['merged_unfiltered_pck_bytes']:,} bytes였다. 최종 {sizes['pck_bytes']:,} bytes로 무필터 대비 {sizes['reduction_from_unfiltered_bytes']:,} bytes 줄었고, 이전판 대비 증가 {sizes['increase_from_round2_bytes']:,} bytes는 15,000,000 제한 이하다. 전후 로그와 SHA는 round3/export-sizes.json·export-before.log·export-after.log에 있다.",
'`pack_portrait_slots_r21.py`는 C의 576×768 마스터 30장을 같은 크기의 무손실 WebP로 바꾸고, 300칸을 C가 기록한 원본 좌표의 AtlasTexture로 묶는다. 투명 RGB까지 포함한 마스터 RGBA와 300칸의 RGBA·크기를 원본 PNG와 직접 대조했다. 바뀐 픽셀 0. 원본 PNG는 그대로 보존한다. WebP 30장 합계 7,156,102 bytes. export 필터로 중복 PNG 칸 300장·마스터 30장을 제외하고 실제 UI에서 사용하는 10종×30명 AtlasTexture만 내보낸다. 내보내기 로그에 Atlas 300개, 원본 슬롯 PNG 0개를 검사한다.',
'`town_portrait_r21.gd`는 이 C 크롭 Atlas를 최우선으로 선택한다. native에서 30명×10칸을 전부 로드하고 원본 해상도를 검사했다. A의 art_for는 100종 모두 B의 실제 파일을 반환하며 fallback 0이다. Web 기본 진입에서도 C Atlas와 B 그림을 사용한다.','',
'### 원본 규칙과 저장 이관','',
'추가 oracle은 현재 원본 01-game/71-shop/81-gear/82-smithy/74-level.lua를 Wasmoon으로 직접 실행했다. 상점 480표본(10직업×3부위×4일×4씨앗), 가공 1,200표본(1~40레벨), 강화 660표본, 옵션 6,180표본(장비 1,030종×2씨앗×3레벨) = 8,520 / 8,520 일치. 원본 Lua와 입력·출력·SHA·호스트 대체 범위는 round3/commerce-oracle.json·commerce-provenance.json·commerce-results.json이다. 기존 2,544표본도 다시 검사했다.',
'상점은 계정 씨앗·날짜별 고정 진열/원본 40bit 코드/착용 레벨 제한/할인 반올림/당일 품절을 적용한다. 직업 선택 UI는 보유 동료 기준이며 원본의 모든 10직업 직접 선택 메뉴는 남았다(순수 진열 함수는 10직업 모두 대조). 가공은 보유 동료 직업 풀과 최고 레벨 구간, 계정 씨앗·회차로 정한다. 강화는 코드 해시·시도 수·다음 단계로 원본과 같이 정한다. 재로드로 결과를 재추첨할 수 없다. 돈/용량 부족·중복 구매는 원자적으로 거절한다.',
'저장 schema2와 기존 파일 경로를 유지했다. 추가 commerce_r21(process_n,sold_day,bought)은 옛 저장에서 결정적으로 초기화한다. 새 상점/가공 장비에만 source_r21=true를 추가해 원본 옵션 계산을 적용한다. **기존 장비·A의 기존 장비 드롭은 이전 옵션 계산을 유지**해 저장을 불러왔을 때 능력치가 바뀌지 않는다. 이 예외는 원본 완전 일치로 세지 않는다. 기존 장비 인스턴스·장착·rng·보유량·진행 중 전투를 보존하고 입력 불변/이관/roundtrip/불량 저장 원자적 거절/재로드 결정론을 검사했다. 사용자 저장 초기화·삭제·덮어쓰기 없음, UI 시험은 fixture 경로에만 쓴다.',
'여관과 길드 의뢰·정산은 앞선 원본 대조를 다시 통과했다. 성적 콘텐츠(79-sex.lua, 친밀도 장면, 매혹 비약)·AI 대화·NPC 장면 송신은 옮기거나 실행하지 않았다. 상점/대장간 NPC 호감 부가 훅은 미이식이다. 현재 게임에 페르소나 데이터가 없어 가공 기준은 실제 보유 동료만 사용하며, 원본 oracle도 페르소나 직업 없음/레벨1 입력으로 맞춰 비교했다. 영입은 여전히 기존 웹 RNG와 파티 최고 레벨이다.','',
'### UI와 전투 경계','',
'홈·동료·탐색·휴식·카드·빈 상태는 기본 URL에서 열린다. URL 미리보기 플래그를 읽는 코드를 제거했고, 옛 공개 지표 town_r21_preview는 호환용 false만 남겼다. 5내비의 원정은 진행 중 원정을 계속한다. 콜라주 기하 경계와 명패/글자 회전을 함께 보정했다.',
'상회·길드 접수/소개·여관·장비·대장간·귀환 확인·연출 외곽을 새 UI에 연결했다. 전투 결과는 world_screen 외곽의 결과 뷰이며 전투의 기존 retry/session_finished 핸들러를 호출한다. 표시만으로 보상을 지급하지 않고, 원정 상태에 한 번 반영한다. 전투 busy가 끝난 뒤에만 보여 컷인을 가리지 않는다. 전투 내부 z_index보다 높은 외곽층에서 결과를 그린다. victory/defeat를 5크기로 자연 전투 결과와 실제 포인터를 통해 검사했다. 전투·연출 파일은 읽기만 했다.','',
'### 직접 실행한 검사','', '|검사|결과|','|---|---|']
for x in common:report.append('|'+x['name']+'|'+'; '.join(x['summary'][-2:]).replace('|','/')+f" (exit {x['exit_code']}, errors {len(x['errors'])})|" )
report+=['', '고립된 Windows root certificate store 경고는 기존 환경 경고로 분리했고 로그를 보존했다. 전투·공통 데이터 기대값은 바꾸지 않았다. 마을 UI 시험의 1차 기대값 한 곳만 “후보가 기본에서 꺼져 있음”에서 “3차 기본 동선”으로 변경했다. JSON roundtrip은 JSON의 float 표현과 비교하고 40bit 씨앗은 별도로 정수 일치를 검사한다.',
 '추가 `web_smoke_r19.py --town-r21 --commerce-only`도 같은 6구성/5크기에서 구매→당일 품절→장비 장착을 실제 포인터로 검사했다. 6 / 6 통과, 오류0. 결과는 round3/web-commerce/results.json이다.',
f"Web build는 `{version['ui_build']}`, PCK SHA-256 `{version['pck_sha256']}`. 로컬 export이며 원격 배포 없음. Web은 390×844, 360×780, 390×664, 1280×800, 430×932 및 360×780 reduced-motion. 기본 URL의 마을/동료/가방/편성/원정/기록/상회/장비/길드/소개/기존 연구/여관/대장간/연출·실제 전투·결과 확인·viewport 복귀를 포인터로 검사했다. JS 상태 변경 브리지는 추가하지 않았다.",
'', '28패널의 기본 동선·구현 수준·남은 차이 표는 이 파일 맨 끝에 있다.']
report+=['','모든 패널의 나란히·차분·위치 오차 표: [compare-round3](verification/town-r21/compare-round3/comparison.md). 원시 좌표와 색 마스크 한계를 comparison.json에 보존했다. [owner-sheet.jpg](verification/town-r21/owner-sheet.jpg)는 폭900·400KB 이하의 28화면 시트다. 실제 생성 이미지를 열어 확인했으며 시각 승인은 받지 않았다.','',
'### 남은 작업','',
'연구 시안·페르소나 연구 전체 규칙, 원본 카드/사건 전체와 시안형 보관함, 영입 레벨/RNG, 원본 모험 연대기·NPC 호감 부가 훅이 남았다. 기존 저장 장비와 A 드롭의 옵션은 보존 예외다. 새 시안형도 배경 삽화·아이템 전용 그림·초상 자세/비율·타이포 질감·사선 구성에서 차이가 남는다. 전체 동일·전패널 2px 달성으로 보고하지 않는다. DESIGN.md와 sidecar의 기존 r11 문맥은 오래되어 작업 범위를 넓혀 수정하지 않았고, 별도 document 갱신 대상이다. 디자인 detector 결과 []는 GDScript 시각 완성의 증거가 아니다.','',
'### 변경 파일','']
report+=['- '+p for p in changed if not p.endswith('.uid')]
report+=['- '+p for p in new if not p.endswith('.uid') and not p.startswith('project/assets/portraits-r21-web/')]
report+=['- project/assets/portraits-r21-web/masters/*.webp (30개)','- project/assets/portraits-r21-web/slots/*.tres (300개)','', '검사·비교·보고 산출물은 verification/town-r21/**, export는 docs/**. 모든 쓰기는 현재 worktree 안에서 했다. 원본 SHA96개와 금지된 전투/A/B/C 파일 변경0을 직접 확인했다.','', '## 이전 차수 기록','',archive.read_text(encoding='utf-8')]
report+=['','## 3차 최종 28패널 표','', '|시안 패널|기본 동선 / 시안 일치 정도|남은 차이와 이유|','|---|---|---|']
for key,name,status,reason in specs:
    degree='미재구축' if name in ['legacy-research','legacy-cache'] else '기존 전투 유지' if name=='cutin' else '부분 일치 · 미승인'
    report.append(f'|{key}|{status} · {degree}|{reason}|')
(R/'UI-R21-D.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['new','changed']},ensure_ascii=False,indent=2))
