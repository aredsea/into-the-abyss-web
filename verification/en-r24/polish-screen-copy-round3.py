from pathlib import Path
import json,sys
root=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(root/'tools'))
from en_r24 import load,write_en
changes={
 'judith':{'Choose your other questions later.':'Other questions can wait.'},
 'miko':{'After finishing this cloth.':"Once I've finished folding this."},
 'naran':{'Skip the smile. Just agree on departure.':"No need to smile. Let's just settle the departure time."},
 'ornel':{"Just tomorrow's time.":"I'll just give you tomorrow's departure time."},
 'selva':{
  'Morning departure.':'We leave in the morning.',
  'Seeing will clear things up. Do it again.':'Seeing you do it will clear things up. Try again.',
  'We can tie this much together.':'We can at least tie this together.',
  'Hold the end. Soon done.':'Hold the end, and we will finish quickly.',
 },
 'sorel':{
  'Ask before taking, even if needed.':'Even if you need some, ask before taking it.',
  'Show me your standard once.':'Could you show me once how you choose them?',
 },
 'teiris':{
  'Only what the investigation needs.':"I'll hear only what I need for the investigation.",
  "I don't want other stories recorded now.":"I don't want to write down anything else right now.",
  "I'll organize my words for easy notes.":"I'll put it in order so it's easy to write down.",
  'Notebook packed. Questions on the way, if I may?':'I have my notebook. May I ask questions on the way?',
  'Food names first. A notebook unlike my report.':'Food names catch my eye first. This notebook is different from my report.',
  'Any dish here makes you curious?':"Is there a dish here you're curious about?",
 },
 'tove':{'Could eat here today.':'I could eat here today.', 'Tove clears her unfinished meal\'s bowl.':'Tove clears her bowl.'},
 'urda':{
  'Eat.':'Have something to eat.',
  'No obligation to agree with me.':"That doesn't mean you have to agree with me.",
  'Today my sermon shall be smaller than the bowl.':"Today I'll serve more soup than sermon.",
  "You're uncomfortable. I'll accept soup another day too.":"Since this is awkward, I'll leave the soup for another day too.",
  'Just food today. Questions rest.':"I'll just have the food today and give the questions a rest.",
  "Counted others' bellies, forgot mine.":"I checked everyone else's appetite and forgot my own.",
  'A little faith talk?':'Shall we talk a little about faith?',
  'No demand for agreeing faith first.':"You don't have to promise to share my faith.",
 },
 'zahar':{
  'You look strong still. A little more help.':"You look like you've got strength left. Help a little more.",
  'Shoulder looked sore.':'Your shoulder looked sore.',
  'Today, your eyes on the road.':'You watch the road today.',
 },
}
out=Path(__file__).resolve().parent
records=json.loads((out/'editorial-revisions-round3.json').read_text(encoding='utf8'))
for cid,replacements in changes.items():
 path,data=load(cid)
 for key,old in list(data['en']['display'].items()):
  if old in replacements:
   new=replacements[old];data['en']['display'][key]=new
   records.append({'id':cid,'field':key,'before':old,'after':new,'review':'screen copy'})
 write_en(path,data['en'])
(out/'editorial-revisions-round3.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
review=json.loads((out/'sample-review-round3.json').read_text(encoding='utf8'))
review['editorial_revisions']=len(records)
(out/'sample-review-round3.json').write_text(json.dumps(review,indent=2)+'\n',encoding='utf8')
print('Total editorial revisions:',len(records))
