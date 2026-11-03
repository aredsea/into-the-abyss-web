"""Observe visible text/buttons of real Lua HTML; tags/classes are not parity targets."""
from pathlib import Path
from html.parser import HTMLParser
import json
R=Path(__file__).resolve().parents[1];O=R/'verification/parity-r23'
class Visible(HTMLParser):
    def __init__(self):super().__init__(convert_charrefs=True);self.texts=[];self.buttons=[];self.button=None
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'risu-btn' in a:
            self.button={'id':a['risu-btn'],'texts':[],'selected':'on' in a.get('class','').split(),'disabled':any(x in a.get('class','').split() for x in ['off','dim'])};self.buttons.append(self.button)
    def handle_endtag(self,tag):
        if tag=='button':self.button=None
    def handle_data(self,data):
        text=data.strip()
        if not text:return
        # Risu asset macro is a portrait image, never visible caption text.
        if text.startswith('{{asset::') and text.endswith('}}'):return
        self.texts.append(text)
        if self.button is not None:self.button['texts'].append(text)
d=json.loads((O/'gear-round4-oracle.json').read_text(encoding='utf-8'))
for group in ['tabs','cells','rosters','quests','boards','recruit_results','forges','processes','cards','screens']:
    for row in d[group]:
        p=Visible();p.feed(row['html']);row['visible_texts']=p.texts;row['visible_buttons']=p.buttons
(O/'gear-round4-semantics.json').write_text(json.dumps(d,ensure_ascii=False)+'\n',encoding='utf-8')
print({k:len(v) for k,v in d.items()})
