import fs from 'node:fs';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','70-town.lua','71-shop.lua','72-guild.lua','74-level.lua','74-affection.lua','76-dungeon.lua','81-gear.lua'];
const raw=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));const npc=fs.readFileSync(src+'/src/79-sex.lua','utf8');
const accessors=['sx_npcst','npc_like'].map(n=>npc.match(new RegExp('function B\\.'+n+'\\([^]*?\\nend'))[0]).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));const {L,sim}=await mkSim({policy:false,extra:raw.join('\n')+'\n'+accessors+'\nB.npc_who=function(k)return k end'});
try{
 const rows=await L(`
local out={};local raw='';local get,set=getChatVar,setChatVar
getChatVar=function(id,key)if key=='dk_bag'then return raw end;return get(id,key)end
setChatVar=function(id,key,v)if key=='dk_bag'then raw=v else set(id,key,v)end end
local function cp(v)return json.decode(json.encode(v))end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,scene in ipairs({'shop','town'})do for _,arg in ipairs({'cls_warrior','cls_sanctioned','cls_unknown','slot_armor','slot_acc','slot_unknown','scroll','target_persona','target_teiris','target_unknown','gear_0','gear_1','gear_2','gear_99','buy_hp_s','buy_sh_s','buy_level_scroll','buy_charm_potion','buy_unknown','unknown','back'})do
  for variant=0,3 do
   local G=B.G_new();G.scene=scene;G.seed=4242;G.gold=variant==1 and 0 or 300;G.persona.cls='전사';G.persona.lv=variant==2 and 40 or 1;G.persona.exp=0;G.lv=G.persona.lv;G.roster={'teiris'};G.lvl={teiris=G.persona.lv};G.exp={teiris=0};G.town.day=7;G.ui.msg='stale';G.ui.tab='';G.ui.sel=variant==3 and 'level_scroll' or '';G.items.level_scroll=variant==3 and 2 or 0;G.npcs={pietro={aff=variant==0 and 50 or 0,buys=0}};raw=''
   local before=cp(G);B.H.sh(G,arg,'finish4')
   local items={};for k,v in pairs(G.items)do if v~=0 then items[k]=v end end
   out[#out+1]={lang=lang,arg=arg,before=before,after={scene=G.scene,selection={cls=G.ui.tab,slot=G.shop_slot or 'weapon',target=G.ui.sel},msg=G.ui.msg,gold=G.gold,items=items,persona_lv=G.persona.lv,persona_xp=G.persona.exp,member_lv=G.lvl.teiris,member_xp=G.exp.teiris,npc_aff=G.npcs.pietro.aff,buys=G.npcs.pietro.buys,got=G.shop_got or {},bought=G.shop_stock and G.shop_stock.bought or {},bag=B.bag_load('finish4')}}
  end
 end end
end
return out
 `);
 fs.writeFileSync('verification/finish-r24/round4/shop-oracle.json',JSON.stringify({rows,sources:names.map((file,i)=>({file,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')})),npc_accessors:{file:'79-sex.lua',sha256:crypto.createHash('sha256').update(npc).digest('hex'),scope:'sx_npcst and npc_like only; no adult scene'}}));console.log(JSON.stringify({shop_routes:rows.length}));
}finally{sim.close()}
