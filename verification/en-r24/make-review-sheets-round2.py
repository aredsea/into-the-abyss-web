from pathlib import Path
from PIL import Image, ImageDraw

out = Path(__file__).resolve().parent
render = out / 'render'
target = out / 'review-sheets-round2'
target.mkdir(exist_ok=True)
for cid in ['adeline', 'altan', 'bargut', 'berenga', 'bianca', 'colette',
            'erdene', 'felice', 'gerda', 'gunhild', 'haldric', 'hedwig']:
    paths = sorted(render.glob(cid + '-*-en-*.png'))
    assert len(paths) == 5, (cid, paths)
    images = [Image.open(p).convert('RGB') for p in paths]
    width = sum(im.width for im in images)
    height = max(im.height for im in images) + 32
    sheet = Image.new('RGB', (width, height), '#151515')
    draw = ImageDraw.Draw(sheet)
    x = 0
    for path, im in zip(paths, images):
        draw.text((x + 4, 5), path.stem, fill='white')
        sheet.paste(im, (x, 32))
        x += im.width
    sheet.save(target / (cid + '.jpg'), quality=90)
    for im in images:
        im.close()
    print(cid, width, height)
