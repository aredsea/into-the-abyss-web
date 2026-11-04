import sys, json
from polish4 import *
sys.stdout.reconfigure(encoding='utf-8')
overrides = {
 ('adeline','inn/8/choices/2/text'): 'Say a brief prayer, then come straight with me.',
 ('adeline','inn/12/choices/1/text'): 'Still, you were singled out for recognition. You should be pleased.',
 ('bargut','transitions/0/situation'): 'Bargut moves the pack she had stopped you from touching.',
 ('colette','transitions/8/lines/1'): 'Please let me laugh a little longer before I tell you.',
 ('erdene','dungeon/26/variants/1'): 'Even if it leaves the front line open, I want to stay by their side for now.',
 ('haldric','dungeon/41/variants/1'): 'Today, I would rather hear you tell me to come back than recite another clause.',
 ('ornel','inn/13/choices/0/response/1'): 'I do not want to seek out more of them just to get used to them.',
 ('tove','inn/19/lines/2'): 'Holding the cup helped my fingers warm up.',
 ('urda','inn/19/choices/0/response/0'): 'Even someone as talkative as I am has nights when I owe someone my thanks.',
 ('zahar','inn/19/lines/2'): 'I need to keep my hands open for a while.',
 ('zahar','dungeon/23/variants/1'): 'Do not wait just to see how much more you can endure.',
 ('zahar','dungeon/32/variants/1'): 'When I wake up, I will have some water first.',
}
rows=json.loads((OUT/'polish-review-items.json').read_text(encoding='utf-8'))
for cid in dict.fromkeys(r['id'] for r in rows):
 edits={r['path']:overrides.get((cid,r['path']),r['proposed']) for r in rows if r['id']==cid}
 assert all(edits.values())
 apply(cid,edits,'independent review; checked against scene context')
for r in rows:
 _,d=load(r['id']);r['after']=d['en']['display'][r['path']];r['status']='revised'
 r['context_adjusted']=(r['id'],r['path']) in overrides
(OUT/'polish-review-items.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
