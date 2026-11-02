from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1];folder=root/'verification/panels-r22/render'
tags=['codex','unmet-page3','recruited','favorite-cap','detail','skills','filtered-bag','comparison','sale-confirm','bag-all','status','favorites','empty-filter','persona','inn-stage']
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)
for dim in ['360x780','390x844','390x664','430x932','1280x800']:
    cell_w,cell_h=245,555
    board=Image.new('RGB',(cell_w*4,cell_h*4),(211,207,195));draw=ImageDraw.Draw(board)
    for i,tag in enumerate(tags):
        path=folder/f'{tag}-{dim}.png';im=Image.open(path).convert('RGB')
        # Desktop has a central mobile frame; keep that frame legible in QA boards.
        if dim=='1280x800':im=im.crop((425,0,855,800))
        im.thumbnail((cell_w-10,cell_h-30))
        x=(i%4)*cell_w;y=(i//4)*cell_h;draw.text((x+7,y+5),tag,fill=(20,25,20),font=font);board.paste(im,(x+(cell_w-im.width)//2,y+27))
    board.save(folder/f'review-{dim}.jpg',quality=90)
print('5 native contact sheets / 75 source captures')
