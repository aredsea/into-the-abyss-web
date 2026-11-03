import crypto from 'node:crypto';
// Reuse the reviewed complete-battle observation harness with a broader input policy.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const root=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/retained-a9-10.json',JSON.stringify(pack.coverage));return pack.result;}};};
import {isDeepStrictEqual as __r23_equal} from 'node:util';
const __r23_write=fs.writeFileSync.bind(fs);
fs.writeFileSync=(file,data,...args)=>{const name=String(file).replaceAll('\\','/');
 if((name.startsWith('verification/parity-r23/')||name.startsWith('verification/data-r21/'))&&!name.includes('/coverage/')&&name.endsWith('.json')){
  const expected=JSON.parse(fs.readFileSync(file,'utf8')),got=JSON.parse(String(data));
  if(expected&&typeof expected==='object')delete expected.provenance;
  if(got&&typeof got==='object')delete got.provenance;
  for(const value of [expected,got])if(value?.parts)for(const part of value.parts){delete part.bytes;delete part.sha256;}
  if(!__r23_equal(expected,got))throw Error('Instrumentation changed oracle: '+name);
  return;
 }return __r23_write(file,data,...args);
};
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join('C:/Users/asone/Documents/Codex/2026-10-30/into-the-abyss-handoff/work/r21-a-data/verification/parity-r23/coverage/instrumented',f),'utf8')}\nend`).join('\n');
let src=fs.readFileSync('tools/oracle_combat_p2_r22.lua','utf8');
src=src.slice(src.indexOf('local parties='),src.indexOf('for _,n in ipairs({0,399,400,401})'));
src=src.replace(/local parties=.+/,"local parties={{\"hildegard\",\"bargut\",\"teiris\",\"berenga\"},{\"marceline\",\"naran\",\"levia\",\"teiris\"},{\"sorel\",\"adeline\",\"tove\",\"urda\"},{\"marceline\",\"naran\",\"teiris\",\"haldric\"},{\"erdene\",\"bianca\",\"saya\",\"gerda\"},{\"judith\",\"levia\",\"urda\",\"lynette\"},{\"felice\",\"sorel\",\"tika\",\"hedwig\"},{\"hildegard\",\"berenga\",\"gunhild\",\"bargut\"},{\"altan\",\"colette\",\"selva\",\"ornel\"},{\"zahar\",\"jorund\",\"lavinia\",\"tove\"},{\"miko\",\"adeline\",\"marceline\",\"naran\"},{\"haldric\",\"urda\",\"jorund\",\"miko\"},{\"levia\",\"zahar\",\"tove\",\"berenga\"}}");
src=src.replace('local trace={};','local trace={}; local decisions={}; local stock={mp_s=3,hp_s=3};');
src=src.replace('ev.k=="atk" or ev.k=="eatk" or ev.k=="eall"','ev.k=="atk" or ev.k=="eatk" or ev.k=="eall" or ev.k=="snipe" or ev.k=="wave" or ev.k=="burst"');
src=src.replace('B.begin_ev(st); B.player(st,1,tgt); B.run(st)',`
  local slot=1; local sk=B.SK[st.cur][1]; local item=nil; local target=tgt
  if guard%3==1 then
   for k,s in ipairs(B.SK[st.cur]) do if s.pv and B.can_use(st,st.cur,s) then slot=k; sk=s; break end end
  elseif guard%3==0 then
   for k,s in ipairs(B.SK[st.cur]) do if not s.pv and s.mp>0 and B.can_use(st,st.cur,s) then slot=k; sk=s; break end end
  else
   for _,iid in ipairs({"mp_s","hp_s"}) do
    if stock[iid]>0 then for j=1,4 do if B.it_ok(st,iid,j) then item=iid; target=j; break end end end
    if item then break end
   end
  end
  if not item then
   if sk.tgt=="none" then target=0
   elseif sk.tgt=="ally" then
    target=0
    for j=1,4 do if st.u[j].al==1 and (not B.NOSELF[sk.cid or ""] or j~=st.cur) then target=j; break end end
    if target==0 then slot=1; sk=B.SK[st.cur][1]; target=tgt end
   end
  end
  decisions[#decisions+1]={n=st.n+1,actor=st.cur,id=item and ("item:"..item) or sk.id,cid=sk.cid or "",target=target}
  B.begin_ev(st)
  if item then
   stock[item]=stock[item]-1; st.n=st.n+1; B.rbegin(st); B.ACT=st.u[st.cur]; B.SKON=nil
   B.it_apply(st,item,target); B.end_turn(st,st.cur,10000); B.ACT=nil
  else B.player(st,slot,target) end
  B.run(st)`);
src=src.replace('party=party,foe=foe,bn=bn,','party=party,decisions=decisions,foe=foe,bn=bn,');


src=src.replace('"raging_lecturer","frost_contractor"','"raging_lecturer","frost_contractor","swamp_leeches","swamp_leeches"');
src=src.replace('local raid=ei>2;', 'local raid=ei==3 or ei==4;');
src=src.replace('local fl=raid and {foe} or {foe,foe}', 'local fl=raid and {foe} or ((ei==6) and {foe,"rusted_shieldman"} or {foe,foe})');
src=src.replace('el=10','el='+process.env.A9_ENEMY_LEVEL);

src=src.replace('pm[i]={id=id,cls=c.id,L=10}', `pm[i]={id=id,cls=c.id,L=40,eq={},forge={}}
 local gr=B.gear()
 for si,slot in ipairs({"weapon","armor","acc"}) do
  local pool={}; local rarities={"common","fine","rare","epic","legend"}
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
  pm[i].eq[slot]=code; pm[i].forge[code]={lv=(bn+si)%4}
 end`);
src=src.replace('local parties=', `local init0=B.gear_init
B.gear_init=function(st,u,m) u.a7_base={hp=u.hp,mhp=u.mhp,mp=u.mp,mmp=u.mmp,sp=u.sp,cs=u.cs,de=u.de,ag=u.ag,cr=u.cr}; init0(st,u,m) end
local parties=`);
src=src.replaceAll('cr=u.cr}', 'cr=u.cr,base=u.a7_base,gq=u.gq,gu=u.gu}');

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


if(!['10','40'].includes(process.env.A9_ENEMY_LEVEL)) throw Error('Set A9_ENEMY_LEVEL=10 or 40');
const {L}=await mkSim({policy:false,extra});
const result=await L('local out={battles={},raid_battles={}}\n'+src+'\nout.no_self=B.NOSELF\nlocal gr=B.gear()\nfor _,rows in ipairs({out.battles,out.raid_battles}) do for _,row in ipairs(rows) do\n row.rarity={}; row.reflect=0; row.heal=0; row.haste=0\n for i,m in ipairs(row.pm) do\n  m.native_eq={}\n  for slot,code in pairs(m.eq) do\n   local gid,seed=B.gear_parse(code); m.native_eq[slot]={id=gid,seed=seed,code=code,source_r21=true,forge=m.forge[code].lv}\n   local rarity=gr.items[gid].rarity; row.rarity[rarity]=(row.rarity[rarity] or 0)+1\n  end\n  row.reflect=row.reflect+(row.initial[i].gq.reflect or 0)\n  row.heal=row.heal+(row.initial[i].gq.heal or 0)\n  for _,un in ipairs(row.initial[i].gu or {}) do if un.key=="heal_haste" then row.haste=row.haste+1 end end\n end\nend end\nreturn out');
result.provenance=Object.fromEntries(files.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'bot/src',f))).digest('hex')]));
fs.writeFileSync('verification/data-r21/a9-native-'+process.env.A9_ENEMY_LEVEL+'-oracle.json',JSON.stringify(result)+'\n');
const rows=[...result.battles,...result.raid_battles], actions={};
for(const row of rows) for(const d of row.decisions) actions[d.id]=(actions[d.id]||0)+1;
console.log(JSON.stringify({battles:rows.length,actions:rows.reduce((n,r)=>n+r.trace.length,0),inputs:actions}));
process.exit(0);
