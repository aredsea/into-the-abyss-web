"""Author title outlines using the existing r21 display font; no new portrait art."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
import hashlib,json
R=Path(__file__).resolve().parents[1]
font_path=R/'project/assets/fonts/AbyssDisplayR19.ttf'
font=TTFont(font_path);glyphs=font.getGlyphSet();cmap=font.getBestCmap()
records=[]
for key,title in [('create','새 모험가'),('meeting','첫 만남')]:
    x=0;paths=[]
    for c in title:
        name=cmap[ord(c)];pen=SVGPathPen(glyphs);glyphs[name].draw(pen)
        paths.append(f'<path transform="translate({x},0)" d="{pen.getCommands()}"/>')
        x+=font['hmtx'][name][0]
    units=font['head'].unitsPerEm
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{x}" height="{units}" viewBox="0 0 {x} {units}"><g fill="#111715" transform="translate(0,{int(units*.86)}) scale(1,-1)">{"".join(paths)}</g></svg>'
    (R/f'project/assets/ui-r21/title-{key}.svg').write_text(svg,encoding='utf-8')
    records.append({'title':title,'path':f'project/assets/ui-r21/title-{key}.svg','method':'existing r21 font outlines; not a reference-image trace'})
(R/'verification/town-r21/round8/title-provenance.json').write_text(json.dumps({'font':str(font_path),'font_sha256':hashlib.sha256(font_path.read_bytes()).hexdigest(),'titles':records},ensure_ascii=False,indent=2),encoding='utf-8')
