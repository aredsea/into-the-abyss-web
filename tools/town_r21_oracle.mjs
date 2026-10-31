// Execute the untouched original Lua through its own existing Wasmoon harness.
// Source is read-only; all observations are written in this worktree.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const {mkSim}=await import(pathToFileURL('C:/Clauede Code/dungeon-bot/bot/lua_sim.mjs').href);
const src='C:/Clauede Code/dungeon-bot/bot/src';
const sourceNames=['01-game.lua','27-compose.lua','70-town.lua','71-shop.lua','81-gear.lua','72-guild.lua','73-inn.lua','74-affection.lua','74-level.lua'];
const rawSources=sourceNames.map(name=>({name,text:fs.readFileSync(path.join(src,name),'utf8')}));
const {sim,L}=await mkSim({policy:false,extra:rawSources.map(s=>s.text).join('\n')});
const data=await L(`
local out={need={},aff={},price={},costs={},inn={},scroll={},guild={},source_rng={},guild_loot={},ledger={}}
for count=0,4 do
 local pm={}
 for i=1,4 do pm[#pm+1]={id='persona',cls='warrior',nat=i<=count and '마렌토 공화국' or ''} end
 for _,gold in ipairs({1,70,100,160,400,12345}) do out.ledger[#out.ledger+1]={count=count,base=gold,value=B.reward_gold({pm=pm},gold)} end
end
for _,seed in ipairs({1,20261027,2147483646,7919}) do
 for qn=1,24 do
  local G={seed=seed};local q={id='q'..qn}
  for _,classes in ipairs({{'warrior','assassin','sanctioned','priest'},{'warrior','assassin','mage','priest'},{'alchemist','alchemist','chaos','paladin'},{}}) do
   local pm={}
   for i,c in ipairs(classes) do pm[#pm+1]={id='fixture'..i,cls=c} end
   local codes={}
   for i=1,2 do codes[#codes+1]=B.gd_gear(G,q,pm,i) end
   out.guild_loot[#out.guild_loot+1]={seed=seed,qn=qn,classes=classes,codes=codes,count=1+math.floor(B.ex_mix(seed+qn,1,9,0)*2)}
  end
 end
end
for _,seed in ipairs({1,20261027,2147483646,7919}) do
 local g={seed=seed,n=0}
 for n=1,24 do out.source_rng[#out.source_rng+1]={seed=seed,n=n,value=B.G_rnd(g)} end
 for _,lv in ipairs({1,17,40}) do
  local G={seed=seed,n=0,town={day=1,acts={},rr=0},guild={qn=0,quests={}},roster={'hildegard'},lvl={hildegard=lv},persona={lv=lv},ui={}}
  for n=1,8 do
   local q=B.gd_new(G)
   out.guild[#out.guild+1]={seed=seed,n=n,level=lv,quest=q}
   G.guild.quests[#G.guild.quests+1]=q
  end
 end
end
for lv=-2,43 do out.need[#out.need+1]={lv=lv,value=B.exp_need(lv)} end
for _,a in ipairs({-100,-20,0,19.5,99,99.5,99.9,100,149.9,199.8,200}) do
 for _,n in ipairs({-300,-1,0,0.2,1,2,3,100,500}) do out.aff[#out.aff+1]={a=a,n=n,value=B.aff_next(a,n)} end
end
-- Same price function as live shop, with its only external input (synergy)
-- supplied explicitly; no translated implementation is used as the oracle.
local original=B.tx_shop
for count=0,4 do
 B.tx_shop=function() return count>=3 and .88 or (count>=2 and .94 or 1) end
 for _,p in ipairs({0,1,15,30,40,50,60,90,110,120,130,180,220,260,1200}) do
  out.price[#out.price+1]={amount=p,count=count,value=B.shop_price({}, {price=p})}
 end
end
B.tx_shop=original
for n=0,30 do
 local g={town={rr=n},guild={recruits=n,quests={}}}
 out.costs[#out.costs+1]={n=n,recruit=B.gd_recruit_cost(g),refresh=B.gd_refresh_cost(g)}
end
-- Real inn handler: suppress only host-only pending/chat and NPC scene hooks.
local old_busy,old_like,old_add=B.pend_busy,B.npc_like,addChat
B.pend_busy=function() return false end; B.npc_like=function() end; addChat=function() return true end
for _,a in ipairs({0,99.5,100,199.8}) do
 local g={scene='inn',gold=200,roster={'hildegard'},aff={hildegard=a},town={day=1,acts={},rr=3},guild={quests={}},ui={sel='hildegard',msg=''},settings={nsfw=0},persona={lv=1}}
 local history={}
 for _,verb in ipairs({'talk','talk','meal','gift','rest','talk'}) do
  B.H['in'](g,verb..'_hildegard','town-r21-oracle')
  history[#history+1]={action=verb,gold=g.gold,day=g.town.day,aff=g.aff.hildegard,refreshes=g.town.rr}
 end
 out.inn[#out.inn+1]={initial=a,history=history}
end
B.pend_busy=old_busy;B.npc_like=old_like;addChat=old_add
for _,lv in ipairs({1,14,39,40}) do
 local g={scene='shop',items={level_scroll=2},roster={'hildegard'},lvl={hildegard=lv},exp={hildegard=12},persona={lv=1},ui={sel='level_scroll',tab='',msg=''}}
 B.H.sh(g,'target_hildegard','town-r21-oracle')
 out.scroll[#out.scroll+1]={before=lv,level=g.lvl.hildegard,xp=g.exp.hildegard,count=g.items.level_scroll}
end
return out`);
const output=path.join(root,'verification/town-r21/oracle.json');
fs.writeFileSync(output,JSON.stringify(data,null,2)+'\n','utf8');
fs.writeFileSync(path.join(root,'verification/town-r21/oracle-provenance.json'),JSON.stringify({method:'Existing Wasmoon RisuSim bootstrap, followed by untouched current source files reloaded before every sample; only external host hooks stubbed',sources:rawSources.map(s=>({path:path.join(src,s.name),sha256:crypto.createHash('sha256').update(s.text).digest('hex')})),bootstrap:'C:/Clauede Code/dungeon-bot/bot/lua_sim.mjs',excluded:'79-sex.lua handlers and scenes are never invoked'},null,2)+'\n','utf8');
console.log('Original Lua oracle:',Object.fromEntries(Object.entries(data).map(([k,v])=>[k,v.length])));
// Each sim owns a Lua state; closing it avoids dangling WASM work.
if(sim.close) await sim.close();
