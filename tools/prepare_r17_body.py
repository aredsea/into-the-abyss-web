"""Two static Noto body faces; coverage is checked again after saving."""
from pathlib import Path
import hashlib, json
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

root = Path(__file__).resolve().parents[1]
out = root / 'verification/ui-r17'
source = Path('C:/Windows/Fonts/NotoSansKR-VF.ttf')
chars = set(map(chr, range(32, 127)))
hangul = set()
for a in range(0xB0, 0xC9):
    for b in range(0xA1, 0xFF):
        hangul.add(bytes([a, b]).decode('euc_kr'))
assert len(hangul) == 2350
chars.update(hangul)
chars.update('·×→○◇−–—「」…%')
names = []
def walk(v):
    if isinstance(v, dict):
        for k, x in v.items():
            if k in ('name', 'short') and isinstance(x, str): names.append(x)
            walk(x)
    elif isinstance(v, list):
        for x in v: walk(x)
for p in (root / 'project/data').glob('*.json'):
    walk(json.loads(p.read_text(encoding='utf-8')))
chars.update(''.join(names))
report = {'source_bytes': source.stat().st_size, 'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
          'ks_hangul': len(hangul), 'characters': len(chars), 'data_names': len(set(names)), 'faces': []}
for weight in (500, 800):
    face = instantiateVariableFont(TTFont(source), {'wght': weight}, inplace=True)
    # Explicit derivative names: the source has a reserved name in its OFL.
    family = f'Abyss Noto Text {weight}'
    for name_id, text in {1: family, 2: 'Regular', 3: family + ' Static Subset', 4: family, 6: f'AbyssNotoText{weight}'}.items():
        face['name'].setName(text, name_id, 3, 1, 0x409)
    s = subset.Subsetter(options=subset.Options())
    s.populate(unicodes=sorted(map(ord, chars))); s.subset(face)
    target = root / f'project/assets/fonts/AbyssNotoText{weight}.ttf'
    face.save(target)
    saved = TTFont(target)
    missing = sorted(c for c in chars if ord(c) not in saved.getBestCmap())
    assert not missing, missing
    assert 'fvar' not in saved and saved['OS/2'].usWeightClass == weight
    report['faces'].append({'weight': weight, 'bytes': target.stat().st_size, 'missing': missing, 'static': True})
license_text = (root / 'project/assets/fonts/OFL-AbyssNoto.txt').read_text(encoding='utf-8')
license_text = license_text[license_text.index('SIL OPEN FONT LICENSE'):]
(root / 'project/assets/fonts/OFL-AbyssNotoText.txt').write_text(
    "Noto Sans KR font software\nCopyright © 2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'.\n\n"
    "Source: C:/Windows/Fonts/NotoSansKR-VF.ttf.\n"
    "Derivatives: AbyssNotoText500.ttf and AbyssNotoText800.ttf, static weights 500 and 800,\n"
    "subset to KS X 1001 Hangul, ASCII, symbols and game data names; renamed Abyss Noto Text.\n\n" + license_text, encoding='utf-8')
(out / 'body-font-coverage.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(report, ensure_ascii=False))
