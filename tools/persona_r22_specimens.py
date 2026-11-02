"""Copy read-only historical test saves and record their byte provenance."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[1]
folder=root/'verification/persona-r22';dest=folder/'legacy';dest.mkdir(exist_ok=True)
sources=[root.parent/'battle-r17/verification',root.parent/'r21-d-town/verification',root.parent/'r21-parity/verification']
seen=set();out=[]
for source in sources:
    for p in sorted(source.rglob('*.json*')):
        if p.stat().st_size>524288:continue
        raw=p.read_bytes()
        try:d=json.loads(raw)
        except (ValueError,UnicodeDecodeError):continue
        if not isinstance(d,dict) or d.get('schema') not in [1,2] or 'members' not in d or 'party' not in d:continue
        digest=hashlib.sha256(raw).hexdigest()
        if digest in seen:continue
        seen.add(digest);target=dest/f'{len(out)+1:02d}-{p.name.removesuffix(".bak")}'
        target.write_bytes(raw)
        out.append({'path':'res://../'+target.relative_to(root).as_posix(),'schema':d['schema'],'source':str(p),'sha256':digest})
(folder/'legacy-specimens.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf-8')
print('Historical saves:',len(out),'schemas:',sorted(set(d['schema'] for d in out)))
