// Execute canonical Lua without modifying the read-only source tree.
import fs from 'node:fs';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const src='C:/Clauede Code/dungeon-bot/bot';
const files=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','70-town.lua','71-shop.lua','73-inn.lua','74-level.lua','74-affection.lua'];
const raw=files.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const npcSource=fs.readFileSync(src+'/src/79-sex.lua','utf8');
// Only the read-only affection accessor; no adult scene code is loaded/executed.
const npcAff=npcSource.match(/function B\.npc_aff\(G, nid\)[\s\S]*?\nend/)[0];
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {L,sim}=await mkSim({policy:false,extra:raw.join('\n')+'\n'+npcAff});
try{
 const result=await L(`
local out={initial=B.G_new(),inn={},npcs={}}
local function cp(x)return json.decode(json.encode(x))end
B.pend_busy=function(G)return G.busy==true end
-- NPC side effect is an observed callback here; its own numeric rule is covered separately.
B.npc_like=function(G,key)G.npc_calls[#G.npc_calls+1]=key end
for _,a in ipairs({-100,99.99,100,199.99,200})do
 for _,gold in ipairs({0,19,20,24,25,29,30,300})do
  for _,verb in ipairs({'talk','meal','gift','rest'})do for _,done in ipairs({false,true})do
   local G=B.G_new();G.scene='inn';G.roster={'teiris'};G.aff={teiris=a};G.gold=gold;G.npc_calls={};G.town.day=7
   if done then G.town.acts['teiris_'..verb]=7 end
   local before=cp(G);B.H['in'](G,verb..'_teiris','finish')
   out.inn[#out.inn+1]={verb=verb,before=before,after=G}
  end end
 end
end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,provider in ipairs({'none','invalid','html'})do
  for _,useG in ipairs({false,true})do for _,aff in ipairs({-1,0,19.99,200})do
   B.portrait=provider=='none' and nil or function(id)return provider=='html' and '<img src="source-'..id..'">' or 'broken' end
   B.NPC_G=useG and {npcs={dorothea={aff=aff}}} or nil
   local list={{'dorothea','도로테아','여관 주인'},{'pietro','피에트로','상회 주인'}}
   out.npcs[#out.npcs+1]={lang=lang,provider=provider,useG=useG,aff=aff,list=list,html=B.tw_npcs(list)}
  end end
 end
end
return out
 `);
 const plain=s=>s.replace(/<[^>]*>/g,' ').replace(/\s+/g,' ').trim();
 for(const r of result.npcs){r.text=plain(r.html);delete r.html;}
 result.provenance=files.map((f,i)=>({file:'bot/src/'+f,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')}));
 result.provenance.push({file:'bot/src/79-sex.lua',sha256:crypto.createHash('sha256').update(npcSource).digest('hex'),scope:'B.npc_aff read-only accessor only'});
 fs.writeFileSync('verification/finish-r24/round3/oracle.json',JSON.stringify(result));
 console.log(JSON.stringify({inn:result.inn.length,npcs:result.npcs.length}));
}finally{sim.close();}
