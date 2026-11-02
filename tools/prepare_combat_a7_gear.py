from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
ids=[c['id'] for c in json.loads((R/'project/data/world.json').read_text(encoding='utf-8'))['companions']]
parties=[['hildegard','bargut','teiris','berenga'],['marceline','naran','levia','teiris'],['sorel','adeline','tove','urda']]+[ids[i:i+4] for i in range(0,len(ids),4)]
parties[-1]+=[i for i in ids if i not in parties[-1]][:4-len(parties[-1])]
lua='local parties={'+','.join('{'+','.join(json.dumps(i) for i in p)+'}' for p in parties)+'}'
s=(R/'tools/oracle_combat_p3_mixed.mjs').read_text(encoding='utf-8')
start=s.index('src=src.replace(/local parties=')
end=s.index('\n',start)
s=s[:start]+'src=src.replace(/local parties=.+/,'+json.dumps(lua)+');'+s[end:]
insertion=r'''
src=src.replace('local trace={};', 'local trace={};');
src=src.replace('pm[i]={id=id,cls=c.id,L=10}', `pm[i]={id=id,cls=c.id,L=40,eq={},forge={}}
 local gr=B.gear()
 for si,slot in ipairs({"weapon","armor","acc"}) do
  local pool={}
  for _,gid in ipairs(gr.by[c.id][slot]) do local it=gr.items[gid]; if (slot=="acc" and it.unique and it.unique.sig) or (slot~="acc" and it.rarity=="legend") then pool[#pool+1]=gid end end
  local gid=pool[(pi+bn+ei+i+si-5)%#pool+1]
  local code=B.gear_code(gid,12345+pi*10007+bn*1009+ei*101+i*7+si)
  pm[i].eq[slot]=code; pm[i].forge[code]={lv=(bn+si)%4}
 end`);
src=src.replace('local parties=', `local init0=B.gear_init
B.gear_init=function(st,u,m) u.a7_base={hp=u.hp,mhp=u.mhp,mp=u.mp,mmp=u.mmp,sp=u.sp,cs=u.cs,de=u.de,ag=u.ag,cr=u.cr}; init0(st,u,m) end
local parties=`);
src=src.replaceAll('cr=u.cr}', 'cr=u.cr,base=u.a7_base}');
src=src.replace('party=party,decisions=', 'party=party,pm=pm,decisions=');
'''
s=s.replace('const {L}=await mkSim',insertion+'\nconst {L}=await mkSim')
s=s.replace('p3-mixed-oracle.json','a7-gear-oracle.json')
(R/'tools/oracle_combat_a7_gear.mjs').write_text(s,encoding='utf-8')
# A second set keeps enemy level equal to the Lv40 legendary wearers.
(R/'tools/oracle_combat_a7_gear_balanced.mjs').write_text(s.replace('const {L}=await mkSim',"src=src.replace('el=10','el=40');\nconst {L}=await mkSim").replace('a7-gear-oracle.json','a7-gear-balanced-oracle.json'),encoding='utf-8')
s=(R/'project/tests/combat_p3_mixed_audit.gd').read_text(encoding='utf-8').replace('p3-mixed-oracle.json','a7-gear-oracle.json').replace('p3-mixed-audit.json','a7-gear-audit.json').replace('P3 mixed parity','A7 gear parity')
s=s.replace('var u=row.initial[i]','var u=row.initial[i].base')
s=s.replace('a.base[a.line]=u.cs;', 'a.gear_member=row.pm[i]; a.gear_fx={}; a.gear_special=[]\n\t\t\ta.base[a.line]=u.cs;')
(R/'project/tests/combat_a7_gear_audit.gd').write_text(s,encoding='utf-8')
(R/'project/tests/combat_a7_gear_balanced.gd').write_text(s.replace('plan.el=10','plan.el=40').replace('a7-gear-oracle.json','a7-gear-balanced-oracle.json').replace('a7-gear-audit.json','a7-gear-balanced-audit.json'),encoding='utf-8')
print(len(parties)*16,'battles')
