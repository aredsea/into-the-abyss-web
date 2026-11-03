// Reuse the reviewed complete-battle observation harness with a broader input policy.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const root=process.env.R21_BOT || 'C:/Clauede Code/dungeon-bot';
const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/retained-p3.json',JSON.stringify(pack.coverage));return pack.result;}};};
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
src=src.replace(/local parties=.+/,"local parties={{\"marceline\",\"naran\",\"teiris\",\"haldric\"},{\"erdene\",\"bianca\",\"saya\",\"gerda\"},{\"judith\",\"levia\",\"urda\",\"lynette\"},{\"felice\",\"sorel\",\"tika\",\"hedwig\"},{\"hildegard\",\"berenga\",\"gunhild\",\"bargut\"},{\"altan\",\"colette\",\"selva\",\"ornel\"},{\"zahar\",\"jorund\",\"lavinia\",\"tove\"},{\"miko\",\"adeline\",\"marceline\",\"naran\"}}");
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
const {L}=await mkSim({policy:false,extra});
const result=await L('local out={battles={},raid_battles={}}\n'+src+'\nout.no_self=B.NOSELF\nreturn out');
fs.writeFileSync('verification/data-r21/p3-mixed-oracle.json',JSON.stringify(result)+'\n');
const rows=[...result.battles,...result.raid_battles], actions={};
for(const row of rows) for(const d of row.decisions) actions[d.id]=(actions[d.id]||0)+1;
console.log(JSON.stringify({battles:rows.length,actions:rows.reduce((n,r)=>n+r.trace.length,0),inputs:actions}));
process.exit(0);
