from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
folder=Path(__file__).resolve().parents[1]/'verification/settings-r22/render'
tags=['create-ko','settings-ko','settings-en','create-en','points-en','scenario-en','sortie-en','codex-en','status-en','inventory-en','places-en','people-en','journal-en','codex-detail-en','isolde-en','settings-town-en','reset-en','save-error-en','reset-ko']
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)
for dim in ['360x780','390x844','390x664','430x932','1280x800']:
    cw,ch=245,555;board=Image.new('RGB',(cw*4,ch*5),(211,207,195));draw=ImageDraw.Draw(board)
    for i,tag in enumerate(tags):
        im=Image.open(folder/f'{tag}-{dim}.png').convert('RGB')
        if dim=='1280x800':im=im.crop((425,0,855,800))
        im.thumbnail((cw-10,ch-30));x=(i%4)*cw;y=(i//4)*ch
        draw.text((x+7,y+5),tag,fill=(20,25,20),font=font);board.paste(im,(x+(cw-im.width)//2,y+27))
    board.save(folder/f'review-{dim}.jpg',quality=90)
print('5 native contact sheets; 95 captures')
