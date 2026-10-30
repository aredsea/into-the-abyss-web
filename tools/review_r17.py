"""Compose approved boards and actual Godot captures, without modifying either."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
root=Path(__file__).resolve().parents[1]
out=root/'verification/ui-r17'
source=root.parents[1]/'outputs/r17-battle'
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',16)
for width,height in [(390,844),(360,780)]:
    for board,states,file in [('core',['base','target','status'],'r17-09-battle-core.png'),('tools',['skills','supplies','log'],'r17-10-battle-tools.png')]:
        approved=Image.open(source/file).convert('RGB'); scale=approved.width/1248
        canvas=Image.new('RGB',(width*6+20*7,height+50),'#d9d6ca'); d=ImageDraw.Draw(canvas)
        for i,state in enumerate(states):
            x=20+i*410
            crop=approved.crop(tuple(round(v*scale) for v in [x,54,x+390,898])).resize((width,height),Image.Resampling.LANCZOS)
            actual=Image.open(out/f'{state}-{width}.png').convert('RGB')
            for j,im in enumerate([crop,actual]):
                left=20+(i*2+j)*(width+20)
                d.text((left,12),f'{state} / '+('approved 390 scaled' if width==360 and j==0 else 'approved r17' if j==0 else 'Godot r17'),font=font,fill='#111715')
                canvas.paste(im,(left,40))
        canvas.save(out/f'comparison-{board}-{width}.png')
print('4 comparison boards written')
