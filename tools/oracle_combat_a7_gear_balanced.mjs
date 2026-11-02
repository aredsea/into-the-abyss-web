// Reuse the reviewed complete-battle observation harness with a broader input policy.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const root=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join(root,'bot/src',f),'utf8')}\nend`).join('\n');
let src=fs.readFileSync('tools/oracle_combat_p2_r22.lua','utf8');
src=src.slice(src.indexOf('local parties='),src.indexOf('for _,n in ipairs({0,399,400,401})'));
src=src.replace(/local parties=.+/,"local parties={{\"hildegard\",\"bargut\",\"teiris\",\"berenga\"},{\"marceline\",\"naran\",\"levia\",\"teiris\"},{\"sorel\",\"adeline\",\"tove\",\"urda\"},{\"marceline\",\"naran\",\"teiris\",\"haldric\"},{\"erdene\",\"bianca\",\"saya\",\"gerda\"},{\"judith\",\"levia\",\"urda\",\"lynette\"},{\"felice\",\"sorel\",\"tika\",\"hedwig\"},{\"hildegard\",\"berenga\",\"gunhild\",\"bargut\"},{\"altan\",\"colette\",\"selva\",\"ornel\"},{\"zahar\",\"jorund\",\"lavinia\",\"tove\"},{\"miko\",\"adeline\",\"marceline\",\"naran\"}}");
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

src=src.replace('el=10','el=40');
const {L}=await mkSim({policy:false,extra});
const result=await L('local out={battles={},raid_battles={}}\n'+src+'\nout.no_self=B.NOSELF\nreturn out');
fs.writeFileSync('verification/data-r21/a7-gear-balanced-oracle.json',JSON.stringify(result)+'\n');
const rows=[...result.battles,...result.raid_battles], actions={};
for(const row of rows) for(const d of row.decisions) actions[d.id]=(actions[d.id]||0)+1;
console.log(JSON.stringify({battles:rows.length,actions:rows.reduce((n,r)=>n+r.trace.length,0),inputs:actions}));
process.exit(0);
