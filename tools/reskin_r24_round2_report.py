"""Compose bounded phone-review evidence using only actual native captures."""
from pathlib import Path
import json,hashlib,math
from PIL import Image,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];O=R/'verification/reskin-r24';Q=O/'round2'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def write(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
font=ImageFont.truetype(str(R/'project/assets/fonts/AbyssNotoText800.ttf'),17)
small=ImageFont.truetype(str(R/'project/assets/fonts/AbyssNotoText500.ttf'),13)
def jpg(im,p,limit=800000):
    for quality in range(92,39,-4):
        im.save(p,quality=quality,optimize=True)
        if p.stat().st_size<=limit:return
    raise RuntimeError('oversized '+str(p))
fixes={
 'A':('새 공용 초상·전투 상세·로그 연결',['member','battle-status','battle-log']),
 'B':('NPC 누끼와 일반 알파 합성',['guild','research','shop','inn','smithy']),
 'C':('시설의 왼쪽 제목·오른쪽 인물·검은 이름표',['guild','shop','research','smithy']),
 'D':('원정 그림 띠·가로 진행·보상·준비·결과',['depart','explore','retreat-confirm','explore-rest','summary-retreat','result-victory','result-defeat','summary-empty']),
 'E':('적 이름표를 각 적 머리 위로',['battle','battle-target']),
 'F':('동료 상세의 능력치 격자와 실제 기술 아이콘',['member_details','skills']),
 'G':('초상과 소제목으로 나눈 인물 소개',['person-fenella','person-dorothea','person-hanna']),
 'H':('어깨 뒤에 작고 옅은 먹 번짐',['meeting','codex','status','member_details']),
 'I':('3px·먹 25% 스크롤바와 마을 숨김',['town','settings','codex']),
 'J':('붉은 행의 세로 가운데 정렬',['cloud-offline','journal','places']),
 'K':('본문 14px·보조 12px 기준의 가독성',['settings','member_details','town']),
 'L':('마을 종이 가장자리와 파티 한 줄 표기',['town']),
 'M':('빈 상태의 문구와 다음 행동',['party-empty','inn-empty','cards-empty','shop-receipt']),
}
evidence=[]
for letter,(title,names) in fixes.items():
    # Four columns compare two states on each row, keeping each phone legible.
    width=1200;cellw=300;phoneh=650;rowh=690;rows=math.ceil(len(names)/2)
    im=Image.new('RGB',(width,rows*rowh+48),'#EEE6D6');d=ImageDraw.Draw(im)
    d.text((12,10),letter+' · '+title,font=font,fill='#16130F')
    for i,name in enumerate(names):
        x=(i%2)*600;y=(i//2)*rowh+48
        for j,(label,path) in enumerate([('수정 전',Q/'before'/f'{name}-390x844.png'),('수정 후',O/'render'/f'{name}-390x844.png')]):
            assert path.exists(),path
            d.text((x+j*300+10,y+5),name+' · '+label,font=small,fill='#16130F')
            pic=Image.open(path).convert('RGB');pic.thumbnail((290,phoneh),Image.Resampling.LANCZOS)
            im.paste(pic,(x+j*300+(300-pic.width)//2,y+30))
    path=Q/f'fix-{letter}.jpg';jpg(im,path)
    evidence.append({'item':letter,'title':title,'file':path.relative_to(R).as_posix(),'width':im.width,'bytes':path.stat().st_size,'screens':names})
write(Q/'fix-evidence.json',evidence)
data=read(O/'captures.json');extra=read(Q/'diagnostics.json')
inventory=data['inventory'].copy()
for item in extra['inventory']:
    if not any(x['file']==item['file'] for x in inventory):inventory.append(item)
write(O/'screen-inventory.json',inventory)
for name,ref,actual in [('town','b.png','town-390x844.png'),('companion','c.png','member-390x844.png')]:
    im=Image.new('RGB',(800,880),'#EEE6D6');d=ImageDraw.Draw(im);d.text((8,6),'승인 기준',font=font,fill='#16130F');d.text((408,6),'실제 게임 · 원본 데이터',font=font,fill='#16130F')
    for x,p in [(0,R.parent/'r24-reskin-ref'/ref),(400,O/'render'/actual)]:im.paste(Image.open(p).convert('RGB').resize((390,844),Image.Resampling.LANCZOS),(x,32))
    im.save(O/f'compare-{name}.png')
sheets=[]
for dims in [(390,844),(360,780),(1280,800)]:
    group=[row for row in inventory if tuple(row['size'])==dims]
    for start in range(0,len(group),12):
        batch=group[start:start+12];cellh=690 if dims[0]<500 else 240
        im=Image.new('RGB',(1200,cellh*3+36),'#EEE6D6');d=ImageDraw.Draw(im);d.text((12,5),f'R24 round 2 / {dims[0]} x {dims[1]} / {len(sheets)+1}',font=font,fill='#16130F')
        for i,row in enumerate(batch):
            x=i%4*300;y=i//4*cellh+36;d.text((x+8,y+3),row['screen'],font=small,fill='#16130F')
            pic=Image.open(O/'render'/row['file']).convert('RGB');pic.thumbnail((290,cellh-35),Image.Resampling.LANCZOS);im.paste(pic,(x+(300-pic.width)//2,y+28))
        path=O/f'sheet-{len(sheets)+1}.jpg';jpg(im,path);sheets.append({'file':path.name,'screens':[r['file'] for r in batch],'bytes':path.stat().st_size,'width':im.width})
write(O/'sheets.json',sheets)
assets=read(R/'ASSET-HASHES.json');af=[a['path'] for a in assets if sha(R/a['path'])!=a['sha256']]
write(Q/'asset-check.json',{'checked':len(assets),'unchanged':len(assets)-len(af),'failures':af})
before=read(Q/'protected-before.json');changed=[p for p,h in before.items() if not (R/p).exists() or sha(R/p)!=h]
write(Q/'protected-check.json',{'checked':len(before),'unchanged':len(before)-len(changed),'changed':changed})
print(json.dumps({'fixes':len(evidence),'captures':len(inventory),'sheets':len(sheets),'max_sheet_bytes':max(s['bytes'] for s in sheets),'originals_unchanged':len(assets)-len(af),'protected_unchanged':len(before)-len(changed)}))
