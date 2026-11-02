from pathlib import Path
from PIL import Image,ImageDraw
folder=Path(__file__).resolve().parents[1]/'verification/persona-r22/render'
modes=['race','nation','blocked','class','points','confirm','scenario','town','sortie','empty','solo','explore']
for dim in ['360x780','390x844','390x664','430x932','1280x800']:
    sheet=Image.new('RGB',(1280,1920),'#dfdfdf');draw=ImageDraw.Draw(sheet)
    for i,mode in enumerate(modes):
        im=Image.open(folder/f'{mode}-{dim}.png').convert('RGB')
        if im.width>800:
            im=im.crop(((im.width-460)//2,0,(im.width+460)//2,im.height))
        im.thumbnail((320,610));x=(i%4)*320+(320-im.width)//2;y=(i//4)*640+25
        sheet.paste(im,(x,y));draw.text(((i%4)*320+8,(i//4)*640+5),mode+' '+dim,fill='#111111')
    sheet.save(folder/f'review-{dim}.jpg')
