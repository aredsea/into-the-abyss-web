from pathlib import Path
import json
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[3]
out=Path(__file__).resolve().parent
for tag,folder,result in [('cloud',root/'verification/cloud-r22/render',root/'verification/cloud-r22/native-ui-results.json'),('town',root/'verification/town-r21/round11/render',root/'verification/town-r21/round11/ui-results.json')]:
    data=json.loads(result.read_text(encoding='utf-8'))
    for dim in ['360x780','390x844','390x664','430x932','1280x800']:
        names=sorted(n for n in data['captures'] if n.endswith('-'+dim+'.png'))
        if not names:continue
        cw,ch=(320,235) if dim=='1280x800' else (240,540);cols=6
        sheet=Image.new('RGB',(cw*cols,ch*((len(names)+cols-1)//cols)),'#dedbd0');draw=ImageDraw.Draw(sheet)
        for i,name in enumerate(names):
            im=Image.open(folder/name).convert('RGB');im.thumbnail((cw-8,ch-32),Image.Resampling.LANCZOS)
            x=(i%cols)*cw;y=(i//cols)*ch
            sheet.paste(im,(x,y+28));draw.text((x+3,y+5),name.removesuffix('-'+dim+'.png'),fill='black')
        sheet.save(out/(tag+'-'+dim+'.jpg'),quality=92)
        print(tag,dim,len(names))
