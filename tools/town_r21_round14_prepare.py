"""Record initial bytes and resolve the two content conflicts without Git."""
from pathlib import Path
import hashlib, json, re
R=Path(__file__).resolve().parents[1]
O=R/'verification/town-r21/round14'; O.mkdir(parents=True,exist_ok=True)
if not (O/'baseline.json').exists():
    files=[p for prefix in ['project','server/abyss-save/src','server/abyss-save/test','tools','docs'] for p in (R/prefix).rglob('*') if p.is_file() and not any(x in p.parts for x in ['.godot','node_modules','__pycache__'])]
    (O/'baseline.json').write_text(json.dumps({p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files},indent=2),encoding='utf-8')
pat=re.compile(r'^<<<<<<<[^\n]*\n(.*?)^=======\n(.*?)^>>>>>>>[^\n]*\n',re.M|re.S)
p=R/'project/data/localization-r22.json'; raw=p.read_text(encoding='utf-8')
if '<<<<<<<' in raw:
    left=json.loads(pat.sub(lambda m:m[1],raw)); right=json.loads(pat.sub(lambda m:m[2],raw))
    conflicts=[]
    for section,entries in right.items():
        if not isinstance(entries,dict): continue
        for k,v in entries.items():
            if k in left[section] and left[section][k]!=v:conflicts.append([section,k,left[section][k],v])
            left[section][k]=v
    assert not conflicts,conflicts
    p.write_text(json.dumps(left,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (O/'localization-merge.json').write_text(json.dumps({'conflicting_values':conflicts,'counts':{k:len(v) for k,v in left.items() if isinstance(v,dict)},'town_key':left['ui']['장비 가공'],'combat_key':left['ui']['심연']},ensure_ascii=False,indent=2),encoding='utf-8')
p=R/'project/game/localization_r22.gd'; raw=p.read_text(encoding='utf-8')
p.write_text(pat.sub(lambda m:m[2],raw),encoding='utf-8')
print('Content conflicts resolved; baseline recorded.')
