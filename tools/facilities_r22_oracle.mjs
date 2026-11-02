// Read-only execution of the original Lua. No translated formulas in this oracle.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source='C:/Clauede Code/dungeon-bot/bot/src';
const {mkSim}=await import(pathToFileURL('C:/Clauede Code/dungeon-bot/bot/lua_sim.mjs').href);
const names=['01-game.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-level.lua','74-affection.lua','81-gear.lua','82-smithy.lua'];
const files=names.map(name=>({name,text:fs.readFileSync(path.join(source,name),'utf8')}));
const {sim,L}=await mkSim({policy:false,extra:files.map(f=>f.text).join('\n')});
const result=await L(`
local out={stock={},process={},quests={},forge={},scroll={},guild_flow={},settlement={},smithy_flow={}}
local g=B.gear();local classes={};local seen={}
for _,gid in ipairs(g.order) do local c=g.items[gid].cls;if not seen[c] then seen[c]=true;classes[#classes+1]=c end end
out.classes=classes
for _,seed in ipairs({1,20261027,2147483646}) do
 for _,day in ipairs({1,2,101}) do
  for _,cls in ipairs(classes) do for _,slot in ipairs({'weapon','armor','acc'}) do
   local rows={};for _,v in ipairs(B.shop_stock({seed=seed,town={day=day}},cls,slot)) do rows[#rows+1]={id=v.item.id,code=v.code,price=v.price} end
   out.stock[#out.stock+1]={seed=seed,day=day,cls=cls,slot=slot,rows=rows}
  end end
 end
 for _,cls in ipairs(classes) do
  for _,lv in ipairs({1,10,11,20,21,30,31,40}) do for n=1,12 do
   local G={seed=seed,persona={cls=cls,lv=lv},roster={'hildegard','teiris'},lvl={hildegard=1,teiris=1}}
   out.process[#out.process+1]={seed=seed,cls=cls,level=lv,n=n,roster=G.roster,code=B.process_roll(G,n),price=B.process_band(G).price}
  end end
 end
 for n=1,20 do
  local G={seed=seed,persona={cls='',lv=1},roster={},lvl={}}
  out.process[#out.process+1]={seed=seed,cls='',level=1,n=n,roster={},code=B.process_roll(G,n),price=B.process_band(G).price}
 end
 for _,lv in ipairs({1,17,40}) do
  local G=B.G_new();G.seed=seed;G.n=0;G.persona.lv=lv;G.roster={};G.guild={quests={},active='',qn=0};B.tw_T(G)
  for i=1,32 do
   local q=B.gd_new(G);out.quests[#out.quests+1]={seed=seed,level=lv,index=G.n,qn=G.guild.qn,board=json.decode(json.encode(G.guild.quests)),q=q,gold=B.gd_gold(G,q),fight=B.gd_fight(q)}
   G.guild.quests[#G.guild.quests+1]=q
   if #G.guild.quests==4 then G.guild.quests={} end
  end
 end
end
local representatives={};for _,gid in ipairs(g.order) do local it=g.items[gid];if not representatives[it.rarity] then representatives[it.rarity]=gid end end
local bag={};B.bag_load=function()return bag end;B.bag_add=function(_,code)if #bag>=B.BAG_MAX then return false end;bag[#bag+1]=code;return true end
B.pend_hard=function(G,note)G.pending=note end
for _,rar in ipairs(B.RARITY_ORDER) do
 local gid=representatives[rar];local code=B.gear_code(gid,998877665544)
 for _,seed in ipairs({1,20261027,2147483646}) do for f=0,10 do for _,tries in ipairs({0,3,17}) do
  bag={code};local G={seed=seed,gold=1000000,forge={[code]={lv=f,tries=tries}}}
  local ok,cost=B.forge_try(G,'fixture',code)
  out.forge[#out.forge+1]={seed=seed,id=gid,gear_seed=998877665544,forge=f,tries=tries,success=ok,cost=cost,gold=G.gold,after=G.forge[code]}
 end end end
end
for _,who in ipairs({'persona','hildegard','missing'}) do for _,lv in ipairs({1,17,39,40}) do for _,count in ipairs({0,1,2}) do
 local G=B.G_new();G.scene='shop';G.persona.lv=lv;G.persona.exp=5;G.lv=lv;G.roster={'hildegard'};G.lvl={hildegard=lv};G.exp={hildegard=5};G.items={level_scroll=count};G.ui.sel='level_scroll'
 B.H.sh(G,'target_'..who,'fixture')
 out.scroll[#out.scroll+1]={who=who,level=lv,count=count,persona_lv=G.persona.lv,persona_xp=G.persona.exp,member_lv=G.lvl.hildegard,member_xp=G.exp.hildegard,remaining=G.items.level_scroll}
end end end
for _,seed in ipairs({1,20261027}) do
 local G=B.G_new();G.scene='guild';G.seed=seed;G.n=0;G.roster={};G.gold=10000;G.persona.lv=17;G.guild={quests={},active='',done=0,recruits=0,qn=0};B.tw_T(G);B.gd_fill(G)
 local first=G.guild.quests[1].id;local second=G.guild.quests[2].id
 for _,arg in ipairs({'acc_'..first,'acc_'..second,'rej_'..first,'rej_'..second,'refresh','refresh','drop','acc_q999'}) do
  B.H.gd(G,arg,'fixture');out.guild_flow[#out.guild_flow+1]={seed=seed,arg=arg,gold=G.gold,active=G.guild.active,rr=G.town.rr,qn=G.guild.qn,index=G.n,board=json.decode(json.encode(G.guild.quests))}
 end
end
for _,seed in ipairs({1,20261027}) do for _,over in ipairs({'win','lose'}) do for _,gold in ipairs({0,60,400}) do for _,difficulty in ipairs({'낮음','중간','높음','엘리트'}) do
 local G=B.G_new();G.seed=seed;G.n=0;G.scene='battle';G.gold=gold;G.roster={'hildegard','teiris'};G.party={'hildegard','teiris'};G.persona.cls='warrior';G.persona.lv=17;G.persona.exp=0;G.persona.fight=1;G.lvl={hildegard=17,teiris=17};G.exp={hildegard=0,teiris=0};G.aff={hildegard=99.5,teiris=150}
 local q={id='q7',title='남서 설산 균열, 고립된 탐사대 구조',rift='남서 설산 균열',kind='구조',stars=2,difficulty=difficulty,gold=100,reward_v=2,lv=17,cmp=1}
 G.guild={quests={q},active='q7',done=0,recruits=0,qn=7};G.town={day=3,rr=4,acts={},bn=1};bag={}
 local st={over=over,rg=123,exp=75,sid=1,pm={{id='persona',cls='warrior'},{id='hildegard',cls='warrior'},{id='teiris',cls='mage'}}}
 B.load=function()return st end;B.tw_settle(G,'fixture')
 out.settlement[#out.settlement+1]={seed=seed,over=over,gold_before=gold,difficulty=difficulty,gold=G.gold,day=G.town.day,rr=G.town.rr,done=G.guild.done,active=G.guild.active,gear=bag,persona_xp=G.persona.exp,member_xp=G.exp.hildegard,aff=G.aff}
end end end end
local G=B.G_new();G.scene='smithy';G.seed=20261027;G.persona.cls='warrior';G.gold=5000;bag={}
B.H.sm(G,'done','fixture');out.smithy_flow.empty=G.sm_work==nil
B.H.sm(G,'proc','fixture');out.smithy_flow.work=#G.sm_work.proc
B.H.sm(G,'back','fixture');out.smithy_flow.blocked=G.scene=='smithy'
B.H.sm(G,'done','fixture');out.smithy_flow.cleared=G.sm_work==nil and G.proc_fx==nil;out.smithy_flow.note=G.pending
B.H.sm(G,'back','fixture');out.smithy_flow.left=G.scene=='town'
return out`);
const folder=path.join(root,'verification/facilities-r22');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(folder,'oracle.json'),JSON.stringify(result,null,2)+'\n','utf8');
fs.writeFileSync(path.join(folder,'provenance.json'),JSON.stringify({method:'Original Lua reloaded into Wasmoon. Bag/chat/pending and completed battle snapshot are host fixtures. No adult handlers invoked.',sources:files.map(f=>({path:path.join(source,f.name),sha256:crypto.createHash('sha256').update(f.text).digest('hex')})),harnesses:['harness_town.mjs','harness_economy.mjs','harness_smithy.mjs'].map(name=>({path:'C:/Clauede Code/dungeon-bot/bot/'+name,sha256:crypto.createHash('sha256').update(fs.readFileSync('C:/Clauede Code/dungeon-bot/bot/'+name)).digest('hex')}))},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(result).map(([k,v])=>[k,Array.isArray(v)?v.length:v])));
sim.close();
