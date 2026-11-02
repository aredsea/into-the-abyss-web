import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source='C:/Clauede Code/dungeon-bot/bot/src/';
const files=['73-inn.lua','74-affection.lua','34-traits.lua','77-explore.lua','79-sex.lua'];
const raw=Object.fromEntries(files.map(f=>[f,fs.readFileSync(source+f,'utf8')]));
// Only nonsexual NPC affinity helpers from 79, no scenes or adult actions.
const lines=raw['79-sex.lua'].split('\n');
const extra=raw['74-affection.lua']+'\n'+raw['73-inn.lua']+'\n'+lines.slice(379,407).join('\n')+'\n'+lines.slice(423,430).join('\n');
const {mkSim}=await import(pathToFileURL('C:/Clauede Code/dungeon-bot/bot/lua_sim.mjs').href);
const {sim,L}=await mkSim({policy:false,extra});
const result=await L(`
local out={inn={},party={},npc={}}
B.pend_busy=function() return false end
for _,a in ipairs({-100,-60,-20,0,19,49,79,99.5,100,149.8,199.9,200}) do
 for _,act in ipairs(B.INN_ORDER) do
  for _,gold in ipairs({0,19,20,24,25,29,30,100}) do
   for _,used in ipairs({false,true}) do
    local G={scene="inn",gold=gold,roster={"hildegard"},aff={hildegard=a},town={day=3,acts={}},ui={},settings={nsfw=0}}
    if used then G.town.acts["hildegard_"..act]=3 end
    B.H["in"](G,act.."_hildegard","k")
    out.inn[#out.inn+1]={a=a,act=act,gold=gold,used=used,after=G.aff.hildegard,money=G.gold,day=G.town.day,npc=B.npc_aff(G,"dorothea")}
   end
  end
 end
end
for _,a in ipairs({0,99,99.5,100,149.8,199.9,200}) do
 for _,amount in ipairs({1,2,3,5,8}) do
  for _,ids in ipairs({{"hildegard","bargut","teiris","berenga"},{"marceline","colette","adeline","teiris"}}) do
   local G={roster=ids,aff={}};local pm={}
   for _,cid in ipairs(ids) do G.aff[cid]=a;pm[#pm+1]={id=cid} end
   local got=B.aff_party(G,pm,amount)
   out.party[#out.party+1]={a=a,amount=amount,ids=ids,after=G.aff,got=got,mult=B.tx_aff(pm)}
  end
 end
end
for _,a in ipairs({0,99,99.5,100,130}) do
 local G={npcs={dorothea={aff=a}}};B.npc_like(G,"dorothea")
 out.npc[#out.npc+1]={a=a,after=G.npcs.dorothea.aff}
end
return out`);
const dir=path.join(root,'verification/town-r21/round7');fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'hooks-oracle.json'),JSON.stringify(result)+'\n');
fs.writeFileSync(path.join(dir,'hooks-provenance.json'),JSON.stringify({sources:files.map(f=>({file:source+f,sha256:crypto.createHash('sha256').update(raw[f]).digest('hex')})),method:'Unmodified inn handler, affection functions, source tx_aff and nonsexual NPC helpers; pend_busy=false (no AI generation).'},null,2)+'\n');
console.log('HOOKS LUA',result.inn.length,result.party.length,result.npc.length);
if(sim.close)await sim.close();
