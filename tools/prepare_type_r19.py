"""CSS-matching font metrics; subset and rename derivatives under the OFL."""
from pathlib import Path
from fontTools.ttLib import TTFont
from fontTools import subset
from fontTools.varLib.instancer import instantiateVariableFont
R=Path(__file__).resolve().parents[1]; F=R/'project/assets/fonts'
REF=R.parents[1]/'outputs/r17-battle/src/fonts'
chars=set(TTFont(F/'AbyssNotoBlackCondensed.ttf').getBestCmap())
def write(font,name,tracking=0):
    if tracking:
        em=font['head'].unitsPerEm
        for key,(advance,lsb) in list(font['hmtx'].metrics.items()): font['hmtx'].metrics[key]=(max(0,round(advance+tracking*em)),lsb)
    for n in font['name'].names:
        if n.nameID in [1,4,6]: n.string=name.encode(n.getEncoding())
    s=subset.Subsetter(options=subset.Options()); s.populate(unicodes=chars); s.subset(font)
    font.save(F/(name+'.ttf'))
write(TTFont(REF/'AbyssNotoBlackCondensed.ttf'),'AbyssDisplayR19',-.025)
for weight in [750,850]:
    write(instantiateVariableFont(TTFont(REF/'NotoSansKR-VF.ttf'),{'wght':weight},inplace=False),'AbyssTextR19W'+str(weight))
write(instantiateVariableFont(TTFont(REF/'NotoSansKR-VF.ttf'),{'wght':850},inplace=False),'AbyssTextR19Tight',-.035)
print('Prepared CSS tracking and body weights; original fonts untouched.')
