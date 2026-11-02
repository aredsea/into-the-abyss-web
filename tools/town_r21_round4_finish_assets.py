"""Pack image_gen cleanup plates; source provenance is kept outside the PCK."""
from pathlib import Path
import json,hashlib
from PIL import Image
R=Path(__file__).resolve().parents[1];V=R/'verification/town-r21/round4';A=R/'project/assets/ui-r21'
mapping=json.loads((V/'imagegen-files.json').read_text(encoding='utf-8-sig'))
specs=json.loads((V/'asset-provenance.json').read_text(encoding='utf-8'))['background_edit_targets']
records=[]
for n,data in mapping.items():
    src=Path(data['path']);im=Image.open(src).convert('RGB');original=next(x for x in specs if x['name']==n);c=original['crop'];size=(2*(c[2]-c[0]),2*(c[3]-c[1]))
    out=A/f'bg-{n}.webp';im.resize(size,Image.Resampling.LANCZOS).save(out,quality=85,method=6)
    records.append({'name':n,'source':original,'generated_path':str(src),'generated_sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'output':out.relative_to(R).as_posix(),'dimensions':size,'bytes':out.stat().st_size,'prompt':data.get('prompt','See conversation image_gen cleanup prompt; reference-only background, remove people and UI')})
total=sum(x['bytes'] for x in records);assert total<=10000000,total
(V/'background-pack.json').write_text(json.dumps({'tool':'built-in image_gen','bytes':total,'budget':10000000,'assets':records},ensure_ascii=False,indent=2),encoding='utf-8')
print(len(records),'backgrounds,',total,'bytes')
