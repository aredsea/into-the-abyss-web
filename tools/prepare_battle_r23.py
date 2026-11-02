"""Inputs only. Expected values are supplied by the unmodified canonical Lua."""
from pathlib import Path
import hashlib,itertools,json
R=Path(__file__).resolve().parents[1]
O=R/'verification/parity-r23';O.mkdir(parents=True,exist_ok=True)
manifest=O/'start-manifest.json'
if not manifest.exists():
 manifest.write_text(json.dumps({str(p.relative_to(R)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for folder in ['project','tools','docs','server'] for p in (R/folder).rglob('*') if p.is_file() and not any(k in p.parts for k in ['.godot','node_modules','__pycache__'])},indent=2),encoding='utf-8')
cases=[]
def add(op,**kw): cases.append(dict(case=len(cases)+1,op=op,**kw))
for race in ['', 'elf','beast']:
 for n,alive,cls,buff in itertools.product(range(5),[True,False],['warrior','gladiator','alchemist'],[0,.137,-1.2]):
  add('speed',race=race,n=n,alive=alive,cls=cls,buff=buff)
for kind in ['atk','aimed','buff','guard','heal','summon','protect','charge','special','dot']:
 for low,alive in itertools.product([False,True],range(5)):
  add('target',kind=kind,low=low,alive=alive)
for melee,hidden,other,rule in itertools.product([False,True],[False,True],[False,True],['none','melee','ranged','ally','all']):
 add('defense',melee=melee,hidden=hidden,other=other,rule=rule)
for n,alive,full in itertools.product(range(5),[False,True],[False,True]): add('kill',n=n,alive=alive,full=full)
for n,alive,double,seed in itertools.product(range(5),[False,True],[False,True],[1,12345,777]): add('double',n=n,alive=alive,double=double,seed=seed)
for cid in ['levia','marceline','naran','teiris','haldric','erdene','bianca','saya','gerda','judith','urda','lynette','sorel','tika','hedwig','hildegard','felice','selva','gunhild','jorund','bargut','berenga','altan','colette','ornel','zahar','tove','miko','adeline','lavinia']:
 for variant in range(12): add('personal',cid=cid,variant=variant)
for cid in ['levia','tika','teiris','urda','colette','marceline']:
 for variant in range(12): add('can',cid=cid,variant=variant)
for fixed,guard,shield,hp,priest in itertools.product([False,True],[False,True],[0,30,200],[1,100,1000],[False,True]):
 add('strike',fixed=fixed,guard=guard,shield=shield,hp=hp,priest=priest)
for grade,hp,rd,buff in itertools.product(['mob','chief','boss','core'],[299,300,301,1000],[0,20,21,30,40],[0,.2]):
 add('atk_mult',grade=grade,hp=hp,rd=rd,buff=buff)
skill=json.loads((R/'project/data/persona_skill.json').read_text(encoding='utf-8'))
for p,q in itertools.product(skill['prefixes'],skill['suffixes']):
 if (p['kind'] in ['attack','volley']) == (q['kind'] in ['regen','guard','crit']):continue
 for lv in [-1,'4.9',10,100]:
  raw=dict(prefix=p['id'],suffix=q['id'],prefix_lv={p['id']:lv},suffix_lv={q['id']:lv})
  for variant in range(6):add('persona',raw=raw,variant=variant)
 for lv in [-20,-.1,0,.9,1,9.99,10,11,'2','bad',True,None]:
  add('persona_meta',raw=dict(prefix=p['id'],suffix=q['id'],prefix_lv={p['id']:lv},suffix_lv={q['id']:lv}))
for raw in [{},{'prefix':'missing','suffix':'guard'},{'prefix':True,'suffix':1},{'prefix':'strike','suffix':'guard'}]:
 add('persona',raw=raw,variant=0)
 add('persona_meta',raw=raw)
for hp,rule,buff,base in itertools.product([299,300,301,1000],[False,True],[-1.2,0,.137],[100,100.137]):
 add('enemy_speed',hp=hp,rule=rule,buff=buff,base=base)
for n,kills,alive in itertools.product(range(5),range(5),[False,True]):add('pack_speed',n=n,kills=kills,alive=alive)
for bits,dot in itertools.product(range(8),['none','class','corrosion','bleed']):add('debuff',bits=bits,dot=dot)
add('persona_meta',raw=dict(prefix='strike',suffix='bane',prefix_lv={'strike':0},suffix_lv={'bane':0}),level_case='nan')
add('persona_meta',raw=dict(prefix='strike',suffix='bane',prefix_lv={p['id']:i-2 for i,p in enumerate(skill['prefixes'])},suffix_lv={p['id']:i+6 for i,p in enumerate(skill['suffixes'])}))
for raw in [None,False,1,'bad',[],['strike'],{'prefix':'strike','suffix':'bane','prefix_lv':[],'suffix_lv':False}]:add('persona_meta',raw=raw)
add('target',kind='aimed',low=True,alive=4,native_alias=True)
add('target',kind='atk',low=False,alive=4,force_random=1)
for variant in range(17):add('counter',variant=variant)
enemy_data=json.loads((R/'project/data/enemies-r21.json').read_text(encoding='utf-8'))
delay=next(f['rules']['weak_hit_delay'] for f in enemy_data['enemies'] if 'weak_hit_delay' in f.get('rules',{}))
els=['none',delay['el'],next(e for e in ['fire','ice','bolt'] if e!=delay['el'])]
for actor,element,boss,lethal in itertools.product(els,els,[False,True],[False,True]):add('element_delay',actor=actor,element=element,boss=boss,lethal=lethal,rule=delay)
(O/'inputs.json').write_text(json.dumps(cases,ensure_ascii=False,indent=2),encoding='utf-8')
print('R23 input cases',len(cases))
