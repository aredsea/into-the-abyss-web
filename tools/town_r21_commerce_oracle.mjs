// Execute source Lua, preserving original code and stubbing only the bag host.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const {mkSim}=await import(pathToFileURL('C:/Clauede Code/dungeon-bot/bot/lua_sim.mjs').href);
const source='C:/Clauede Code/dungeon-bot/bot/src';
const names=['01-game.lua','71-shop.lua','81-gear.lua','82-smithy.lua','74-level.lua'];
const sources=names.map(name=>({name,text:fs.readFileSync(path.join(source,name),'utf8')}));
const {sim,L}=await mkSim({policy:false,extra:sources.map(s=>s.text).join('\n')});
const result=await L(`
local out={stock={},process={},forge={},roll={}}
local g=B.gear()
local all_classes={};for cls in pairs(g.by) do all_classes[#all_classes+1]=cls end;table.sort(all_classes)
for _,seed in ipairs({1,7919,20261027,2147483646}) do
 for _,day in ipairs({1,2,17,100}) do
  for _,cls in ipairs(all_classes) do
   if g.by[cls] then
    for _,slot in ipairs({'weapon','armor','acc'}) do
     local rows={}
     for _,v in ipairs(B.shop_stock({seed=seed,town={day=day}},cls,slot)) do rows[#rows+1]={code=v.code,id=v.item.id,price=v.price} end
     out.stock[#out.stock+1]={seed=seed,day=day,cls=cls,slot=slot,rows=rows}
    end
   end
  end
 end
end
for _,seed in ipairs({1,20261027,2147483646}) do
 for lv=1,40 do
  local roster={'hildegard','bargut','teiris','berenga'}
  local G={seed=seed,persona={lv=1},roster=roster,lvl={hildegard=lv,bargut=lv,teiris=lv,berenga=lv}}
  local classes={}
  for _,id in ipairs(roster) do classes[#classes+1]=B.cls_of(B.CAST[id].cls).id end
  for n=1,10 do
   local code=B.process_roll(G,n)
   out.process[#out.process+1]={seed=seed,level=lv,n=n,classes=classes,code=code}
  end
 end
end
for i,id in ipairs(g.order) do
 for _,seed in ipairs({1,998877665544}) do
  local code=B.gear_code(id,seed)
  for _,lv in ipairs({1,17,40}) do
   local f=lv==17 and 4 or 0
   out.roll[#out.roll+1]={id=id,seed=seed,level=lv,forge=f,value=B.gear_roll(code,lv,f).fx}
  end
 end
 if i%19==1 then
  for _,seed in ipairs({1,20261027,2147483646}) do
   for _,f in ipairs({0,3,8,9}) do
    local code=B.gear_code(id,998877665544)
    local old=B.bag_load;B.bag_load=function()return {code}end
    local G={seed=seed,gold=100000,forge={[code]={lv=f,tries=17}}}
    local ok,cost=B.forge_try(G,'local-oracle',code);B.bag_load=old
    out.forge[#out.forge+1]={seed=seed,id=id,gear_seed=998877665544,forge=f,tries=17,success=ok,cost=cost,after=G.forge[code]}
   end
  end
 end
end
return out`);
const folder=path.join(root,'verification/town-r21/round3');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(folder,'commerce-oracle.json'),JSON.stringify(result,null,2)+'\n','utf8');
fs.writeFileSync(path.join(folder,'commerce-provenance.json'),JSON.stringify({method:'Untouched source Lua in existing Wasmoon harness; forge bag host returns one fixture code; no chat or adult handlers invoked',sources:sources.map(s=>({path:path.join(source,s.name),sha256:crypto.createHash('sha256').update(s.text).digest('hex')}))},null,2)+'\n','utf8');
console.log(Object.fromEntries(Object.entries(result).map(([k,v])=>[k,v.length])));
if(sim.close)await sim.close();
