import fs from 'node:fs';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-level.lua','74-affection.lua'];
const raw=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));const {L,sim}=await mkSim({policy:false,extra:raw.join('\n')});
try{
 const rows=await L(`
local out={};B.pend_busy=function()return false end;B.npc_like=function(g,key)g.npc_calls=(g.npc_calls or 0)+1 end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,scene in ipairs({'inn','town'})do for _,arg in ipairs({'back','list','pick_teiris','pick_unknown','talk_teiris','meal_teiris','gift_teiris','rest_teiris','unknown_teiris','talk_unknown','bad'})do
  for _,gold in ipairs({0,25,300})do for _,done in ipairs({false,true})do
   local G=B.G_new();G.scene=scene;G.roster={'teiris'};G.party={'teiris'};G.gold=gold;G.aff={teiris=99.99};G.ui.sel='teiris';G.ui.msg='stale';G.town.day=7;G.npc_calls=0
   if done then for _,verb in ipairs({'talk','meal','gift'})do G.town.acts['teiris_'..verb]=7 end end
   local before=json.decode(json.encode(G));B.H['in'](G,arg,'finish4')
   out[#out+1]={lang=lang,arg=arg,before=before,after={scene=G.scene,sel=G.ui.sel,msg=G.ui.msg,gold=G.gold,day=G.town.day,acts=G.town.acts,aff=G.aff.teiris,npc=G.npc_calls},host_next=B.U('보내기를 누르면 이어집니다.')}
  end end
 end end
end
return out
 `);
 for(const r of rows){r.after.msg=r.after.msg.replace(r.host_next,'').trim();delete r.host_next;}
 fs.writeFileSync('verification/finish-r24/round4/inn-oracle.json',JSON.stringify({rows,sources:names.map((file,i)=>({file,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')}))}));
 console.log(JSON.stringify({inn_routes:rows.length}));
}finally{sim.close()}
