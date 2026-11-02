"""Extend A7's independent full-battle policy with native equipment records."""
from pathlib import Path
R=Path(__file__).resolve().parents[1]
s=(R/'tools/oracle_combat_a7_gear.mjs').read_text(encoding='utf-8')
s=s.replace(r'\"miko\",\"adeline\",\"marceline\",\"naran\"}}',r'\"miko\",\"adeline\",\"marceline\",\"naran\"},{\"haldric\",\"urda\",\"jorund\",\"miko\"},{\"levia\",\"zahar\",\"tove\",\"berenga\"}}')
s=s.replace("src=src.replace('local trace={};', 'local trace={};');", """
src=src.replace('"raging_lecturer","frost_contractor"','"raging_lecturer","frost_contractor","swamp_leeches","swamp_leeches"');
src=src.replace('local raid=ei>2;', 'local raid=ei==3 or ei==4;');
src=src.replace('local fl=raid and {foe} or {foe,foe}', 'local fl=raid and {foe} or ((ei==6) and {foe,"rusted_shieldman"} or {foe,foe})');
src=src.replace('el=10','el='+process.env.A9_ENEMY_LEVEL);
""")
start=s.index('  local pool={}')
end=s.index('\n end`);',start)
s=s[:start]+'''  local pool={}; local rarities={"common","fine","rare","epic","legend"}
  local rarity=rarities[(pi+bn+ei+i+si-5)%5+1]
  for _,gid in ipairs(gr.by[c.id][slot]) do
   local it=gr.items[gid]
   if it.rarity==rarity then pool[#pool+1]=gid end
  end
  local gid=pool[(pi+bn+ei+i+si-5)%#pool+1]
  -- Real source items carrying heal% / healing haste, in the demon party too.
  if slot=="weapon" and c.id=="priest" then gid="pr32" end
  if slot=="weapon" and c.id=="alchemist" then gid="al32" end
  local seed=12345+pi*10007+bn*1009+ei*101+i*7+si
  if slot=="armor" then
   for attempt=0,100 do
    local roll=B.gear_roll(B.gear_code(gid,seed+attempt),40,0)
    if (roll.fx.reflect or 0)>0 then seed=seed+attempt; break end
   end
  end
  local code=B.gear_code(gid,seed)
  pm[i].eq[slot]=code; pm[i].forge[code]={lv=(bn+si)%4}'''+s[end:]
s=s.replace("src=src.replaceAll('cr=u.cr}', 'cr=u.cr,base=u.a7_base}');", "src=src.replaceAll('cr=u.cr}', 'cr=u.cr,base=u.a7_base,gq=u.gq,gu=u.gu}');")
s=s.replace("src=src.replace('party=party,decisions=', 'party=party,pm=pm,decisions=');", """
src=src.replace('party=party,decisions=', 'party=party,pm=pm,coverage=coverage,decisions=');
src=src.replace('local trace={};', 'local trace={}; local coverage={drain_reflect_hits=0,counters=0,skill_kill_heal_gear=0}; active_cov=coverage;');
src=`local active_cov=nil
local after0=B.e_after_hit
B.e_after_hit=function(st,i,act,t,res,at)
 if active_cov and act.drain and (st.u[t].gq or {}).reflect then active_cov.drain_reflect_hits=active_cov.drain_reflect_hits+1 end
 return after0(st,i,act,t,res,at)
end
local line0=B.trait_line
B.trait_line=function(st,i,txt,at)
 if active_cov and txt:find("반격") then active_cov.counters=active_cov.counters+1 end
 return line0(st,i,txt,at)
end
local kill0=B.kill_credit
B.kill_credit=function(st,a,at)
 local demons=0
 for i=1,4 do if st.u[i].al==1 and st.u[i].rc=="demon" then demons=demons+1 end end
 if active_cov and B.SKON and a and a<=4 and demons>=2 then
  local u=st.u[a]; local gear=(u.gq or {}).heal~=nil
  for _,un in ipairs(u.gu or {}) do if un.key=="heal_haste" then gear=true end end
  if gear then active_cov.skill_kill_heal_gear=active_cov.skill_kill_heal_gear+1 end
 end
 return kill0(st,a,at)
end
`+src;
""")
s=s.replace('out.no_self=B.NOSELF', '''out.no_self=B.NOSELF
local gr=B.gear()
for _,rows in ipairs({out.battles,out.raid_battles}) do for _,row in ipairs(rows) do
 row.rarity={}; row.reflect=0; row.heal=0; row.haste=0
 for i,m in ipairs(row.pm) do
  m.native_eq={}
  for slot,code in pairs(m.eq) do
   local gid,seed=B.gear_parse(code); m.native_eq[slot]={id=gid,seed=seed,code=code,source_r21=true,forge=m.forge[code].lv}
   local rarity=gr.items[gid].rarity; row.rarity[rarity]=(row.rarity[rarity] or 0)+1
  end
  row.reflect=row.reflect+(row.initial[i].gq.reflect or 0)
  row.heal=row.heal+(row.initial[i].gq.heal or 0)
  for _,un in ipairs(row.initial[i].gu or {}) do if un.key=="heal_haste" then row.haste=row.haste+1 end end
 end
end end'''.replace('\n','\\n'))
s=s.replace('a7-gear-oracle.json', "a9-native-'+process.env.A9_ENEMY_LEVEL+'-oracle.json")
s="import crypto from 'node:crypto';\n"+s
s=s.replace("const {L}=await mkSim", "if(!['10','40'].includes(process.env.A9_ENEMY_LEVEL)) throw Error('Set A9_ENEMY_LEVEL=10 or 40');\nconst {L}=await mkSim")
s=s.replace('fs.writeFileSync(', "result.provenance=Object.fromEntries(files.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'bot/src',f))).digest('hex')]));\nfs.writeFileSync(")
(R/'tools/oracle_combat_a9_native.mjs').write_text(s,encoding='utf-8')
for level in [10,40]:
 t=(R/'project/tests/combat_a7_gear_audit.gd').read_text(encoding='utf-8')
 t=t.replace('a7-gear-oracle.json',f'a9-native-{level}-oracle.json').replace('a7-gear-audit.json',f'a9-native-{level}-audit.json').replace('A7 gear parity',f'A9 native {level} parity')
 t=t.replace('plan.el=10',f'plan.el={level}')
 t=t.replace('a.gear_member=row.pm[i];', 'a.gear_member={"native_eq":row.pm[i].native_eq,"cls":row.pm[i].cls,"L":row.pm[i].L};')
 t=t.replace('var b=Battle.new(d); var used=[]; var step=0','''var b=Battle.new(d); var used=[]; var step=0
		var initial_fields=[]
		for i in range(4):
			var a=b.data.allies[i]; var u=row.initial[i]
			var got={"hp":a.hp,"mhp":a.mhp,"mp":a.mp,"mmp":a.mmp,"sp":a.base.spd,"cs":a.base[a.line],"de":a.base.def,"ag":a.combat_ag,"cr":a.base.crit,"gq":a.gear_fx,"gu":a.gear_special}
			for key in got:
				if not same(got[key],u.get(key,[] if key=="gu" else {})): initial_fields.append(str(i)+":"+key)''')
 t=t.replace('b.record(); var first={}; var matched=0','b.record(); var first={} if initial_fields.is_empty() else {"fields":initial_fields,"step":"native initialization"}; var matched=0')
 (R/f'project/tests/combat_a9_native_{level}_audit.gd').write_text(t,encoding='utf-8')
print('A9 native policy: 13 parties x 6 encounters x 4 seeds x 2 enemy levels')
