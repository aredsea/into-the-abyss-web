from pathlib import Path
from PIL import Image, ImageDraw

root=Path(__file__).resolve().parents[2]
out=Path(__file__).resolve().parent
target=out/'review-sheets-round3'
target.mkdir(exist_ok=True)
for source in sorted((root/'project/data/dialogue-r21').glob('*.json')):
    cid=source.stem
    paths=sorted((out/'render').glob(cid+'-*-en-*.png'))
    assert len(paths)==5,(cid,paths)
    images=[Image.open(p).convert('RGB') for p in paths]
    sheet=Image.new('RGB',(sum(im.width for im in images),max(im.height for im in images)+32),'#151515')
    draw=ImageDraw.Draw(sheet)
    x=0
    for path,im in zip(paths,images):
        draw.text((x+4,5),path.stem,fill='white')
        sheet.paste(im,(x,32))
        x+=im.width
        im.close()
    sheet.save(target/(cid+'.jpg'),quality=90)
    print(cid,sheet.size)
