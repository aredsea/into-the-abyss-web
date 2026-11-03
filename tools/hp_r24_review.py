from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/hp-r24';font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',17)
dims=['360x780','390x664','390x844','430x932','1280x800']
def thumb(p,w=280,h=650):
 im=Image.open(p).convert('RGB')
 if im.width>600:im=im.crop(((im.width-430)//2,0,(im.width+430)//2,im.height))
 im.thumbnail((w,h));return im
for mode in ['states','target','status','status-ko','supply-target','shield-cap']:
 sheet=Image.new('RGB',(1500,1430),'#d6d0c3');d=ImageDraw.Draw(sheet)
 for row,suffix in enumerate(['','-reduced']):
  for col,dim in enumerate(dims):
   name=f'{mode}-{dim}{suffix}.png';im=thumb(O/name);x=col*300+10;y=row*710+32
   sheet.paste(im,(x,y));d.text((x,row*710+6),dim+suffix,font=font,fill='black')
 sheet.save(O/f'review-{mode}.png')
sheet=Image.new('RGB',(1500,720),'#d6d0c3');d=ImageDraw.Draw(sheet)
for i,page in enumerate(['member','equipment','depart','status','codex']):
 im=thumb(O/f'world-{page}.png');sheet.paste(im,(i*300+10,32));d.text((i*300+10,6),page,font=font,fill='black')
sheet.save(O/'review-world.png')
ref=Image.open(R.parent/'r24-hp-ref/hp-options.png').convert('RGB').crop((48,48,828,840));ref.thumbnail((616,626))
sheet=Image.new('RGB',(1430,920),'#d6d0c3');d=ImageDraw.Draw(sheet);sheet.paste(ref,(10,40));d.text((10,8),'Approved A',font=font,fill='black')
for i,dim in enumerate(['390x844','360x780']):
 im=thumb(O/f'states-{dim}.png',w=390,h=844);sheet.paste(im,(640+i*390,40));d.text((640+i*390,8),dim,font=font,fill='black')
sheet.save(O/'compare-approved-A.png')
for prefix,output in [('trail','review-trail'),('live-trail','review-live-trail')]:
 sheet=Image.new('RGB',(1000,1020),'#f4efe3');d=ImageDraw.Draw(sheet)
 for i,t in enumerate(['0.0','0.4','0.7']):
  im=Image.open(O/f'{prefix}-{t}.png').crop((12,685,378,844));im=im.resize((732,318));sheet.paste(im,(160,i*340));d.text((8,i*340+20),t+' seconds',font=font,fill='black')
 sheet.save(O/(output+'.png'))
sheet=Image.new('RGB',(1220,880),'#d6d0c3');d=ImageDraw.Draw(sheet)
for i,name in enumerate(['world-item-target','world-explore','status-ko-390x844']):
 im=thumb(O/(name+'.png'),390,844);sheet.paste(im,(10+i*405,30));d.text((10+i*405,5),name,font=font,fill='black')
sheet.save(O/'review-extra.png')
print('review sheets written')
