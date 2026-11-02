import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const names=['05-gen.lua','10-data.lua','24-stats.lua','81-gear.lua','82-smithy.lua'];
const {sim,L}=await mkSim({policy:false,extra:names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8')).join('\n')});
const out=await L(`
local out={drop={},transactions={},refresh={},caps={},process_try={},context={},seed_inputs={}}
local function cp(x)return json.decode(json.encode(x))end
for f=1,420 do for _,kind in ipairs({'battle','elite','chief','boss'}) do for s=1,5 do
 local seed=s*7919+f;local classes=s%2==0 and {'warrior','priest','bad','warrior'} or {}
 local code,it,lv=B.gear_drop(seed,f,kind,classes)
 out.drop[#out.drop+1]={seed=seed,floor=f,kind=kind,classes=classes,value=code or false,lv=lv or false}
end end end
local bag={};B.bag_load=function()return cp(bag)end;B.bag_save=function(id,x)bag=cp(x)end
local function game()return {seed=4242,gold=10000,persona={cls='warrior',lv=40},roster={'levia','teiris'},lvl={levia=40,teiris=10},equip={},settings={},ui={}}end
local function action(g,method,args)
 local before=cp(g);local before_bag=cp(bag);local a,b=B[method](g,'p4',table.unpack(args));local ret={a};if b~=nil then ret[2]=b end
 if a==nil then ret={'nil'}end
 out.transactions[#out.transactions+1]={method=method,args=args,game=before,bag=before_bag,result=ret,value=cp(g),after_bag=cp(bag)}
end
local g=game();bag={B.gear_code('wa01',5),B.gear_code('wa11',6),B.gear_code('wa27',7),B.gear_code('pr01',8)}
action(g,'gear_equip',{'persona',bag[1]});action(g,'gear_equip',{'persona',bag[1]});action(g,'gear_equip',{'levia','wa27.7.1'})
action(g,'gear_equip',{'persona','pr01.8.1'});action(g,'gear_equip',{'nobody','wa01.5.1'});action(g,'gear_equip',{'persona','bad'})
action(g,'gear_unequip',{'persona','weapon'});action(g,'gear_unequip',{'persona','weapon'})
action(g,'gear_sell',{'wa27.7.1'});action(g,'gear_sell',{'wa27.7.1'});action(g,'gear_sell_common',{})
g=game();g.equip={persona={weapon=B.gear_code('pr01',8)}};bag={}
action(g,'gear_restrict',{})
g=game();g.equip={persona={weapon=B.gear_code('wa01',5)}};bag={};for i=1,2000 do bag[i]=B.gear_code('wa01',i)end
action(g,'gear_unequip',{'persona','weapon'})
g=game();g.equip={persona={weapon=B.gear_code('pr01',8)}};action(g,'gear_restrict',{})
for _,raw in ipairs({'','null','null;wa01.1.1;bad;zz99.1.1;wa01.1.1'}) do
 setChatVar('p4','dk_bag',raw)
 local saved=B.bag_load;B.bag_load=nil
 -- bag_load source filtering has separate fixture coverage in Godot.
 B.bag_load=saved
end
for _,cls in ipairs(B.CLASSES) do
 local g=game();g.persona.cls=cls.name
 g.equip={persona={weapon=B.gear_code(B.gear().by[cls.id].weapon[1],5)},levia={acc=''}}
 local pm={{id='persona',cls=cls.id,L=40,eq={weapon='stale'}},{id='levia',cls='chthon',L=40,eq={weapon='stale'}},{id='',eq={weapon='leave'}}}
 local before=cp(pm);B.gear_pm_refresh(g,pm);out.refresh[#out.refresh+1]={game=g,pm=before,value=pm}
end
local old=B.gear().fx.cap
for _,id in ipairs({'wa27','wa33','wa34','pr31','as10','al15','wa35','ar36'}) do for s=1,40 do
 B.gear().fx.cap=9;local c=B.gear_code(id,s);local r=B.gear_roll(c);r.item=nil;out.caps[#out.caps+1]={code=c,value=r}
end end
B.gear().fx.cap=old
for _,sp in ipairs({{gold=1000,n=0,size=0},{gold=89,n=0,size=0},{gold=500,n=0,size=2000},{gold=1000,n=1,size=0}}) do
 local g=game();g.scene='smithy';g.persona.lv=5;g.roster={};g.gold=sp.gold;g.town={process_n=sp.n}
 bag={};for i=1,sp.size do bag[i]='wa01.1.1'end
 local before=cp(g);local before_bag=cp(bag);B.H.sm(g,'proc','p4')
 out.process_try[#out.process_try+1]={game=before,bag=before_bag,value=g,after_bag=bag}
end

for _,fight in ipairs({0,1})do
 local g=game();g.persona.fight=fight;g.party={'levia','teiris'}
 g.equip={persona={weapon=B.gear_code('wa47',7),acc=B.gear_code('wal2',8)},levia={acc=B.gear_code('chl2',8)},teiris={weapon='bad'},nobody={acc=B.gear_code('pal2',8)}}
 out.context[#out.context+1]={game=g,value=B.CTX['23-gear'](g)}
end
for _,value in ipairs({'  12345  ','-123.9','1e3','0xff','bad','-9223372036854775808'})do
 out.seed_inputs[#out.seed_inputs+1]={seed=value,value=B.gear_code('wa01',value)}
end
return out`);
fs.writeFileSync(root+'/verification/gear-r22/extra-oracle.json',JSON.stringify(out)+'\n');
console.log(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])));sim.close();
