"""Produce labeled contact sheets; human inspection remains required."""
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw,ImageFont
R=Path(__file__).resolve().parents[1];O=R/'verification/look-r24/review';O.mkdir(exist_ok=True)
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
for phase in ['before','after']:
 files=sorted((O.parent/phase).glob('*.png'))
 for start in range(0,len(files),12):
  sheet=Image.new('RGB',(1200,1300),'#ddd8cd');draw=ImageDraw.Draw(sheet)
  for i,p in enumerate(files[start:start+12]):
   im=Image.open(p).convert('RGB');im.thumbnail((284,382))
   x=10+(i%4)*300;y=10+(i//4)*430
   sheet.paste(im,(x+(284-im.width)//2,y));draw.text((x,y+385),p.stem[:34],font=font,fill='#111715')
  sheet.save(O/f'{phase}-{start//12+1:02d}.jpg',quality=90)
print('Review sheets',len(list(O.glob('*.jpg'))))
reference=R.parent.parent/'outputs/r13-b-all/00-town-approved-direction.png'
if reference.exists():
 sheet=Image.new('RGB',(1600,900),'#ddd8cd');draw=ImageDraw.Draw(sheet)
 for i,(label,path) in enumerate([
  ('Approved 00',reference),
  ('Rejected round 1',O.parent/'round1-after/loading-loading-390x844.png'),
  ('Round 2 loading',O.parent/'after/loading-loading-390x844.png'),
  ('Round 2 creation rows',O.parent/'after/create-race-390x844.png')]):
  im=Image.open(path).convert('RGB');im.thumbnail((390,844))
  sheet.paste(im,(i*400+(390-im.width)//2,35));draw.text((i*400+10,8),label,font=font,fill='#111715')
 sheet.save(O/'round2-approved-comparison.png')
