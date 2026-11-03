"""Review only changed enemy plates; keep the first-pass ally/trail captures."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/hp-r24/round2'
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
dims=['360x780','390x664','390x844','430x932','1280x800']
def frame(name):
    im=Image.open(O/name).convert('RGB')
    if im.width>600:im=im.crop(((im.width-430)//2,0,(im.width+430)//2,im.height))
    return im
for mode in ['states','target']:
    sheet=Image.new('RGB',(2200,1000),'#d6d0c3');d=ImageDraw.Draw(sheet)
    for row,suffix in enumerate(['','-reduced']):
        for col,dim in enumerate(dims):
            name=f'{mode}-{dim}{suffix}.png';im=frame(name)
            # Entire battlefield at native pixel scale (up to 470px tall).
            im=im.crop((0,88,im.width,min(560,im.height-450)))
            sheet.paste(im,(col*440,row*500+30));d.text((col*440+4,row*500+5),dim+suffix,font=font,fill='black')
    sheet.save(O/f'review-{mode}.png')
sheet=Image.new('RGB',(1320,880),'#d6d0c3');d=ImageDraw.Draw(sheet)
for row,mode in enumerate(['multi','multi-target']):
    for col,dim in enumerate(['360x780','390x844','1280x800']):
        im=frame(f'{mode}-{dim}.png').crop((0,88,int(dim.split('x')[0]) if dim!='1280x800' else 430,400))
        sheet.paste(im,(col*440,row*440+30));d.text((col*440+4,row*440+5),mode+' '+dim,font=font,fill='black')
sheet.save(O/'review-multi.png')
sheet=Image.new('RGB',(1200,500),'#d6d0c3');d=ImageDraw.Draw(sheet)
ref=Image.open(R.parent/'r24-hp-ref/hp-options.png').crop((90,660,445,790)).convert('RGB')
ref=ref.resize((580,220));sheet.paste(ref,(10,40));d.text((10,8),'Approved A: name / brush / numbers',font=font,fill='black')
im=frame('states-390x844.png').crop((257,181,380,234)).resize((492,212))
sheet.paste(im,(650,40));d.text((650,8),'Round 2: actual 390x844 plate, 4x',font=font,fill='black')
sheet.save(O/'compare-approved-A.png')
print('round2 review sheets written')
