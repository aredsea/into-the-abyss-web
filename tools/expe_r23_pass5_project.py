"""Extract observable text/actions/meters from real Lua output, never HTML equality."""
from html.parser import HTMLParser
from pathlib import Path
import json,re
O=Path(__file__).resolve().parents[1]/'verification/parity-r23'
class Visible(HTMLParser):
 def __init__(self,html):
  super().__init__(convert_charrefs=True);self.parts=[];self.buttons=[];self.stack=[];self.pips=[];self.bars=[];self.feed(html)
 def handle_starttag(self,tag,attrs):
  a=dict(attrs);classes=a.get('class','').split();item={'tag':tag,'classes':classes,'button':None}
  if tag=='button' or ('dk-btn' in classes and 'off' in classes):
   b={'action':a.get('risu-btn','') if 'off'not in classes else '','enabled':'off' not in classes,'text':[]};self.buttons.append(b);item['button']=b
  if 'ex-pip' in classes:
   p={'state':'cur' if 'cur' in classes else 'done' if 'done' in classes else '', 'text':[]};self.pips.append(p);item['pip']=p
  if 'dk-bar' in classes:item['bar_kind']=next((k for k in ['hp','mp','aff']if k in classes),'')
  m=re.search(r'scaleX\(([^)]+)\)',a.get('style',''))
  if m:self.bars.append({'kind':next((x['bar_kind']for x in reversed(self.stack)if 'bar_kind'in x),''),'ratio':float(m[1])})
  if tag not in ['img','br','input','hr']:self.stack.append(item)
 def handle_endtag(self,tag):
  for i in range(len(self.stack)-1,-1,-1):
   if self.stack[i]['tag']==tag:self.stack=self.stack[:i];break
 def handle_data(self,data):
  # Portrait macro tokens are transport handles, not displayed text.
  if '{{asset::' in data:return
  self.parts.append(data)
  for item in self.stack:
   if item.get('button'):item['button']['text'].append(data)
   if item.get('pip'):item['pip']['text'].append(data)
 def result(self):
  norm=lambda x:re.sub(r'\s+','',x)
  return {'text':norm(''.join(self.parts)),'buttons':[dict(b,text=norm(''.join(b['text'])))for b in self.buttons], 'pips':[dict(p,text=''.join(p['text']))for p in self.pips],'bars':self.bars}
def main():
 x=json.loads((O/'expe-pass5-oracle-raw.json').read_text(encoding='utf-8'))
 root=O.parents[1]
 code='\n'.join((root/p).read_text(encoding='utf-8')for p in ['project/game/expedition_ui_r23.gd','project/ui/expedition_screen_r22.gd','project/game/expedition_world_r22.gd'])
 facade=(root/'project/game/expedition_world_r22.gd').read_text(encoding='utf-8')
 locale=x.pop('locale')
 selected={'ui':{k:v for k,v in locale['ui'].items()if k in code},'words':{k:v for k,v in locale['words'].items()if k in code or k in facade.split('func expedition_item_name')[0]}}
 (root/'project/data/expe-ui-r23.json').write_text(json.dumps(selected,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 for r in x['view']:r['visible']=Visible(r['html']).result()
 for r in x['sortie']:r['visible']=Visible(r['html']).result()
 for r in x['town']:
  for k in ['html','hint','face']:
   if k in r:r[k+'_visible']=Visible(r[k]).result()
 (O/'expe-pass5-oracle.json').write_text(json.dumps(x,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 print(json.dumps({k:len(v)for k,v in x.items()}))

if __name__=="__main__":main()
