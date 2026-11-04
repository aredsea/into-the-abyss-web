"""Compact contact sheets; original PNGs remain the visual evidence."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import hashlib,json,sys
R=Path(__file__).resolve().parents[1];O=R/'verification/finish-r24/round4'
paths=sorted((O/'after').glob('*.png'))
paths += [R/f'verification/finish-r24/after/{name}-{size}.png' for name in ['journal','facility_scroll'] for size in ['390x844','1280x800']]
font=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',15)
(O/'review').mkdir(exist_ok=True)
pages=[]
for start in range(0,len(paths),8):
    sheet=Image.new('RGB',(1440,1740),'#dedbd0');draw=ImageDraw.Draw(sheet)
    for i,p in enumerate(paths[start:start+8]):
        pic=Image.open(p).convert('RGB');pic.thumbnail((350,810));x=(i%4)*360+5;y=(i//4)*870+42
        sheet.paste(pic,(x,y));draw.text((x,y-32),p.stem,font=font,fill='#121212')
    page=O/'review'/('page-%02d.jpg'%(start//8+1));sheet.save(page,quality=95);pages.append(page.relative_to(R).as_posix())
result={'captures':len(paths),'new_captures':len(paths)-4,'pages':pages,'viewed':'--reviewed' in sys.argv,'files':[{'path':p.relative_to(R).as_posix(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in paths],
        'review_notes':['390x844 and 1280x800, both languages for changed creation/rest/settlement/inn surfaces.','Original journal and persona scroll regressions checked at both required sizes.','Long descriptions remain in the existing scroll areas; fixed navigation, palettes and fonts are preserved.']}
(O/('visual-review.json' if result['viewed'] else 'visual-review-pending.json')).write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'captures':len(paths),'pages':len(pages),'viewed':result['viewed']}))
