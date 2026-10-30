from pathlib import Path
import json, shutil
from fontTools import subset
from fontTools.ttLib import TTFont

root = Path(__file__).resolve().parents[1]
reference = root.parents[1] / 'outputs/r17-battle/src'
font_source = reference / 'fonts/AbyssNotoBlackCondensed.ttf'
chars = set(chr(n) for n in range(32, 127))
for a in range(0xB0, 0xC9):
    for b in range(0xA1, 0xFF):
        try: chars.update(bytes([a,b]).decode('euc_kr'))
        except UnicodeDecodeError: pass
chars.update('·×→○◇−–—「」…%')
names = []
def walk(v):
    if isinstance(v, dict):
        for k, x in v.items():
            if k in ['name','short'] and isinstance(x,str): names.append(x)
            walk(x)
    elif isinstance(v,list):
        for x in v: walk(x)
for p in (root/'project/data').glob('*.json'):
    walk(json.loads(p.read_text(encoding='utf-8')))
# Keep KS X 1001 plus actual data names (including names outside the standard).
chars.update(''.join(names))
f=TTFont(font_source)
available=f.getBestCmap()
missing=sorted(c for c in chars if ord(c) not in available)
assert not missing, missing
s=subset.Subsetter(options=subset.Options())
s.populate(unicodes=sorted(map(ord,chars))); s.subset(f)
f.save(root/'project/assets/fonts/AbyssNotoBlackCondensed.ttf')
shutil.copyfile(reference/'fonts/OFL.txt',root/'project/assets/fonts/OFL-AbyssNoto.txt')
(root/'verification/ui-r17/font-coverage.json').write_text(json.dumps({'source_bytes':font_source.stat().st_size,'subset_bytes':(root/'project/assets/fonts/AbyssNotoBlackCondensed.ttf').stat().st_size,'ks_hangul':2350,'characters':len(chars),'data_names':len(set(names)),'missing':missing},ensure_ascii=False,indent=2),encoding='utf-8')
