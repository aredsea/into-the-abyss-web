// Current canonical Lua, read only. Isolated GH lets fixtures observe gear's slot.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','24-stats.lua','81-gear.lua','82-smithy.lua'];
const raws=names.map(n=>fs.readFileSync(path.join(src,'src',n),'utf8'));
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:raws.slice(0,3).join('\n')+'\nB.GH={}\n'+raws.slice(3).join('\n')});
const dir=root+'/verification/gear-r22';fs.mkdirSync(dir,{recursive:true});
const data=await L('local g=B.gear();g.classes=B.CLASSES;g.cast=B.CAST;return g');
fs.writeFileSync(root+'/project/data/gear-r22.json',JSON.stringify(data,null,2)+'\n');
const rules=await L(`
local out={rolls={},codes={},parse={},process={},forge={},bags={},equip={},refresh={}}
local function cp(x)return json.decode(json.encode(x))end
for _,id in ipairs(B.gear().order) do
 for s=1,50 do local code=B.gear_code(id,s*7919+#id);local r=B.gear_roll(code);r.item=nil;out.rolls[#out.rolls+1]={code=code,value=r} end
 for _,lv in ipairs({0,1,10,20,40,41}) do for _,f in ipairs({-1,0,5,10,11}) do
  local code=B.gear_code(id,8734567);local r=B.gear_roll(code,lv,f);r.item=nil;out.rolls[#out.rolls+1]={code=code,lv=lv,forge=f,value=r}
 end end
end
for _,seed in ipairs({0,1,-12345,12345,1099511627776,9007199254740991,4738381338321616895,4738381338321616896}) do
 out.codes[#out.codes+1]={seed=tostring(seed),value=B.gear_code('wa01',seed)}
end
for _,c in ipairs({'wa01.9ix.1','wa01.k3j9x.1','zz99.a.1','WA01.a.1','wa01.a.2','wa01.zzzzzzzzzzzz.1','wa01.zzzzzzzzzzzzz.1','wa01.0.01','wa01','x..','wa01.a.1.2','wa01..1','wa01.A.1'}) do
 local id,s,v=B.gear_parse(c);out.parse[#out.parse+1]={code=c,value=id and {id=id,seed=tostring(s),v=v} or false,price=B.gear_price(c) or false,btn=B.gear_btn(c),unbtn=B.gear_unbtn(B.gear_btn(c)) or false}
end
for _,lv in ipairs({1,10,11,20,21,30,31,40}) do for s=1,200 do
 local G=B.G_new();G.seed=s*7919+13;G.persona.cls='warrior';G.persona.lv=lv
 if s%3==0 then G.roster={'levia','teiris'};G.lvl={levia=33,teiris=12} end
 if s%7==0 then G.persona.cls='';G.roster={} end
 local c=B.process_roll(G,s%11+1);out.process[#out.process+1]={game=G,n=s%11+1,value=c,lv=B.process_lv(G),band=B.process_band(G)}
end end
local bag={};B.bag_load=function()return cp(bag)end;B.bag_save=function(id,x)bag=cp(x)end
for _,id in ipairs(B.gear().order) do
 local code=B.gear_code(id,77)
 for lv=0,10 do for _,seed in ipairs({13,4242}) do
  local G={seed=seed,gold=999999,forge={[code]={lv=lv,tries=lv*7}}};bag={code}
  local before=cp(G);local a,b=B.forge_try(G,'p4',code)
  out.forge[#out.forge+1]={game=before,bag=bag,code=code,result={a==nil and 'nil' or a,b},value=G}
 end end
end
for _,sp in ipairs({{gold=0,bag=true},{gold=5000,bag=false},{gold=5000,bag=false,equip=true}}) do
 local code=B.gear_code('wa01',5);local G={gold=sp.gold,seed=99,equip=sp.equip and {persona={weapon=code}} or {}}
 bag=sp.bag and {code} or {};local before=cp(G);local a,b=B.forge_try(G,'p4',code)
 out.forge[#out.forge+1]={game=before,bag=bag,code=code,result={a==nil and 'nil' or a,b},value=G}
end
for _,cls in ipairs(B.CLASSES) do for _,lv in ipairs({1,10,20,40}) do
 local G={persona={cls=cls.name,lv=lv},roster={},lvl={}}
 for _,id in ipairs(B.gear().order) do if B.gear().items[id].cls==cls.id then
  local code=B.gear_code(id,1);local a,b=B.gear_can_equip(G,'persona',code)
  out.equip[#out.equip+1]={game=G,code=code,cid='persona',value=b and {a,b} or {a}}
 end end
end end
return out`);
fs.writeFileSync(dir+'/oracle.json',JSON.stringify(rules)+'\n');
console.log(Object.fromEntries(Object.entries(rules).map(([k,v])=>[k,v.length])));
// Dependency functions record engine calls. They deliberately do not run combat.
await L(fs.readFileSync(root+'/tools/gear_r22_hook_oracle.lua','utf8'));
const hooks=await L('return P4_FIXTURES');
fs.writeFileSync(dir+'/hooks.json',JSON.stringify(hooks)+'\n');
fs.writeFileSync(dir+'/provenance.json',JSON.stringify({files:names.map((name,i)=>({name,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')})),contracts:['harness_gear.mjs','harness_smithy.mjs','gear_battle_test.lua','gear_det.lua'],counts:Object.fromEntries(Object.entries(rules).map(([k,v])=>[k,v.length])),hooks:hooks.length,source_write:false},null,2)+'\n');
console.log('hook fixtures',hooks.length);sim.close();
