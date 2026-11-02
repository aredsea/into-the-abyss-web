// Execute canonical Lua; only chat/pending host boundaries are replaced.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'), src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','24-stats.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-level.lua','74-affection.lua','81-gear.lua','82-smithy.lua'];
const files=names.map(name=>({name,text:fs.readFileSync(src+'/src/'+name,'utf8')}));
const npc=fs.readFileSync(src+'/src/79-sex.lua','utf8').split('\n');
// Only the ordinary NPC affinity helpers. No adult scene/handler is loaded here.
const extra=files.map(f=>f.text).join('\n')+'\n'+npc.slice(379,407).join('\n')+'\n'+npc.slice(423,430).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra});
const data=await L(`
local out={catalog=B.gear(),icons={},labels={},parse={},roll={},cost={},bag={},transactions={},migrate={},refresh={},party={},context={},smithy={},shop={},shop_flow={},guild={},fill={},inn={},aff={},fmt={},aff_party={},classes={},drop={}}
local function cp(x)return json.decode(json.encode(x))end
local function val(x)if x==nil then return false else return x end end
local function game()local G=B.G_new();G.seed=4242;G.gold=10000;G.persona.cls='warrior';G.persona.lv=40;G.persona.fight=1;G.roster={'hildegard','teiris'};G.party={'hildegard','teiris'};G.lvl={hildegard=40,teiris=10};G.aff={hildegard=99.5,teiris=150};B.tw_T(G);return G end
for _,id in ipairs(B.gear().order)do
 out.icons[#out.icons+1]={id=id,value=B.gear_icon(B.gear().items[id])}
 local code=B.gear_code(id,7);out.labels[#out.labels+1]={code=code,value=B.gear_label(code)}
end
for _,code in ipairs({'bad','zz99.a.1','wa01.a.2'})do out.labels[#out.labels+1]={code=code,value=B.gear_label(code)}end
for _,item in ipairs({{}, {id='missing',shape='missing'}, {id='missing',shape=B.gear().items.wa01.shape}})do out.icons[#out.icons+1]={item=item,value=val(B.gear_icon(item))}end
for _,c in ipairs({false,23,'','wa01','wa01.0.1','zz99.a.1','wa01.a.2','wa01.a.01','wa01.A.1','wa01.000000000000.1','wa01.zzzzzzzzzzzz.1','wa01.zzzzzzzzzzzzz.1','wa01.a.1\\n'}) do
 local id,s,v=B.gear_parse(c);out.parse[#out.parse+1]={input=c,value=id and {id=id,seed=tostring(s),v=v} or false}
end
for _,c in ipairs({'bad','zz99.1.1','wa01.a.2','wa01.a.1','wal2.a.1'})do for _,lv in ipairs({false,0,1,1.9,40,41,'bad','17.9'})do
 local r=B.gear_roll(c,lv,3.5);if r then r.item=nil;r.seed=tostring(r.seed)end
 out.roll[#out.roll+1]={code=c,lv=lv,forge=3.5,value=val(r)}
end end
for _,c in ipairs({'bad','zz99.a.1','wa01.a.1','wal2.a.1'})do for _,lv in ipairs({-1,0,.5,1,1.5,10,10.5,11})do out.cost[#out.cost+1]={code=c,level=lv,value=val(B.forge_cost(c,lv))}end end
local raw='';local host_get,host_set=getChatVar,setChatVar
getChatVar=function(id,key)if key=='dk_bag' then return raw end;return host_get(id,key)end
setChatVar=function(id,key,v)if key=='dk_bag' then raw=v else host_set(id,key,v)end end
for _,input in ipairs({false,42,'','null',';wa01.1.1;;bad;zz99.1.1;wa01.1.1;wa01.a.2;'})do
 raw=input;local loaded=B.bag_load('r23');B.bag_save('r23',loaded);out.bag[#out.bag+1]={kind='load',raw=input,loaded=loaded,saved=raw}
end
for _,size in ipairs({0,1,1999,2000,2001})do for _,code in ipairs({'wa01.1.1','bad','zz99.1.1'})do for _,method in ipairs({'bag_add','bag_take'})do
 local list={};for i=1,size do list[i]='wa01.1.1'end;raw=table.concat(list,';');local before=raw
 local ok=B[method]('r23',code);out.bag[#out.bag+1]={kind=method,raw=before,code=code,ok=ok,saved=raw,loaded=B.bag_load('r23')}
end end end
local function action(G,method,args)
 local before=cp(G);local list=B.bag_load('r23');local a,b=B[method](G,'r23',table.unpack(args));local ret={val(a)};if b~=nil then ret[2]=b end
 out.transactions[#out.transactions+1]={game=before,bag=list,method=method,args=args,result=ret,value=cp(G),after=B.bag_load('r23')}
end
for _,size in ipairs({0,1,1999,2000})do
 local g=game();g.equip={persona={weapon='wa01.1.1',armor='pr01.1.1'},nobody=3};local list={};for i=1,size do list[i]='wa01.2.1'end;raw=table.concat(list,';')
 action(g,'gear_equip',{'persona','wa01.2.1'});action(g,'gear_unequip',{'persona','weapon'});action(g,'gear_restrict',{});action(g,'gear_sell',{'wa01.2.1'});action(g,'gear_sell_common',{})
end
for _,eq in ipairs({false,3,{}, {persona=false},{persona={weapon='wa01.a.1',armor='',acc=4}}})do
 local g=game();g.equip=eq;g.forge={['wa01.a.1']={lv=4,tries=8}}
 local pm={{id='persona',eq={weapon='stale'}},{id='hildegard',eq={weapon='stale'}},{id='',eq={weapon='keep'}}};local before=cp(pm)
 B.gear_pm_refresh(g,pm);out.refresh[#out.refresh+1]={game=g,pm=before,value=pm,eq=val(B.gear_eq_of(g,'persona'))}
end
for _,version in ipairs({false,0,1})do for _,old in ipairs({false,true})do
 local g=game();g.settings.gear_v=version;g.equip={persona={weapon=old and 'eq_old' or 'wa01.1.1'},bad=4};g.items={hp_s=3,eq_old=old and 2 or nil};local before=cp(g)
 out.migrate[#out.migrate+1]={game=before,result=B.gear_migrate(g),value=cp(g)}
end end
for _,pm in ipairs({{},{{id='',cls='warrior'}},{{id='persona',cls='warrior'},{id='hildegard',cls='warrior'},{id='teiris',cls='mage'},{id='bad',cls='bad'},{id='x',cls='전사'}}})do
 out.party[#out.party+1]={pm=pm,value=B.gear_party_cls(pm)}
end
for _,eq in ipairs({false,{}, {persona={weapon='wal2.1.1'},hildegard={acc='wal2.1.1'}}})do
 local g=game();g.equip=eq;out.context[#out.context+1]={game=g,value=B.CTX['23-gear'](g)}
end
for _,input in ipairs({'','bad;wa01.1.1;wa01.1.1;wal2.2.1','wa01.3.1;wa01.1.1'})do
 raw=input;local g=game();g.equip={persona={weapon='wa01.1.1'},bad=4};out.smithy[#out.smithy+1]={game=g,bag=B.bag_load('r23'),value=B.smithy_list(g,'r23')}
end
for _,seed in ipairs({1,4242,20261027})do for _,aff in ipairs({49,49.5,50,99,100,130})do for _,buys in ipairs({0,1,9})do for _,count in ipairs({0,98,99,100})do
 local g=game();g.seed=seed;g.npcs={pietro={aff=aff,buys=buys}};g.items.charm_potion=count;g.ui.msg='before';local before=cp(g)
 B.shop_after_buy(g);out.shop[#out.shop+1]={game=before,aff=g.npcs.pietro.aff,buys=g.npcs.pietro.buys,count=g.items.charm_potion,msg=g.ui.msg}
end end end end
for seed=1,30 do
 local g=game();g.seed=seed;g.npcs={pietro={aff=50,buys=0}};g.items=false;g.ui.msg='before';local before=cp(g)
 B.shop_after_buy(g)
 if type(g.items)=='table' then out.shop[#out.shop+1]={game=before,aff=g.npcs.pietro.aff,buys=g.npcs.pietro.buys,count=g.items.charm_potion,msg=g.ui.msg};break end
end
B.pend_hard=function(G,note)G.pending=note end
for _,arg in ipairs({'buy_hp_s','buy_missing','buy_charm_potion','target_missing','gear_0','gear_999'})do for _,gold in ipairs({0,100000})do
 local g=game();g.scene='shop';g.gold=gold;g.items.hp_s=0;g.npcs={pietro={aff=60,buys=0}};raw='';local before=cp(g);B.H.sh(g,arg,'r23')
 out.shop_flow[#out.shop_flow+1]={arg=arg,game=before,gold=g.gold,items=g.items,npcs=g.npcs}
end end
for _,size in ipairs({0,1,3,4,5})do
 local g=game();g.n=0;g.guild={quests={},active='',qn=0};for i=1,size do g.guild.quests[i]=B.gd_new(g)end
 local before=cp(g);B.gd_fill(g);out.fill[#out.fill+1]={game=before,board=g.guild.quests,index=g.n,qn=g.guild.qn}
end
for _,raw in ipairs({'','bad','warrior','전사'})do
 local g=game();g.persona.cls=raw;g.roster={};local before=cp(g)
 -- Native classes are observed through a full original processing result too.
 out.classes[#out.classes+1]={game=before,code=B.process_roll(g,1)}
end
local all={};local seen={};for _,id in ipairs(B.gear().order)do local cls=B.gear().items[id].cls;if not seen[cls]then seen[cls]=true;all[#all+1]=cls end end
for _,floor in ipairs({0,1,7,100})do for _,kind in ipairs({'bad','battle','boss'})do
 local code=B.gear_drop(4242,floor,kind,all);out.drop[#out.drop+1]={seed=4242,floor=floor,kind=kind,classes=all,value=val(code)}
end end
-- Malformed table boundary only: zero existing weights in a disposable source
-- instance. No product data, item, rarity, or rule is added to make this branch.
local saved=cp(B.gear().fx.drop)
for _,band in ipairs(B.gear().fx.drop.bands)do for r in pairs(band.w.battle)do band.w.battle[r]=0 end end
out.drop[#out.drop+1]={seed=4242,floor=1,kind='battle',classes=all,zero_weights=true,value=val(B.gear_drop(4242,1,'battle',all))}
B.gear().fx.drop=saved
for _,owned in ipairs({{}, {'hildegard'},B.CAST_ORDER})do for _,lv in ipairs({1,17,40})do
 local g=game();g.roster=owned;g.persona.lv=lv;g.lvl={hildegard=33};g.guild={quests={{id='q1',title='a'},{id='q2',title='b'},{id='q1',title='c'}},active=''}
 local before=cp(g.guild.quests);local found=B.gd_find(g,'q1');local removed=B.gd_remove(g,'q1')
 out.guild[#out.guild+1]={roster=owned,level=lv,base=B.gd_base_lv(g),candidates=B.gd_candidates(g),before=before,found=found,removed=removed,board=g.guild.quests,missing=val(B.gd_find(g,'missing')),remove_missing=B.gd_remove(g,'missing')}
end end
for _,a in ipairs({-100,-60.005,-20,0,.005,19.95,20,49.99,50,79.99,80,99.995,100,149.95,150,199.99,200})do
 out.aff[#out.aff+1]={input=a,r2=B.aff_r2(a),fmt=B.aff_fmt(a),tier=B.gd_tier(a)}
end
for _,x in ipairs({'bad',' 1.6 ','1e2','-0.4',false,true,'0xff'})do out.fmt[#out.fmt+1]={input=x,value=B.aff_fmt(x)}end
for _,ids in ipairs({{}, {'persona','hildegard','hildegard','missing',''}, {{id='hildegard'},{id='hildegard'},{id='teiris'},{id='persona'},{id='missing'}}})do
 local g=game();local before=cp(g);local result=B.aff_party(g,ids,2);out.aff_party[#out.aff_party+1]={game=before,pm=ids,delta=result,value=g.aff}
end
B.pend_busy=function()return false end
for _,arg in ipairs({'talk_hildegard','meal_hildegard','gift_hildegard','rest_hildegard','rest_hildegard','talk_missing','invalid_hildegard','pick_hildegard','back'})do
 local g=game();g.scene='inn';g.settings.nsfw=0;g.town.day=3;g.town.rr=4;g.town.acts={hildegard_talk=3};local before=cp(g);B.H['in'](g,arg,'r23')
 out.inn[#out.inn+1]={game=before,arg=arg,gold=g.gold,day=g.town.day,rr=g.town.rr,acts=g.town.acts,aff=g.aff,selection=g.ui.sel,scene=g.scene}
end
return out`);
const dir=root+'/verification/parity-r23';fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(dir+'/oracle.json',JSON.stringify(data)+'\n');
fs.writeFileSync(dir+'/provenance.json',JSON.stringify({method:'Canonical functions executed in Wasmoon; no formula reimplementation; host chat variables in memory.',sources:[...files,{name:'79-sex.lua (ordinary affinity helpers only)',text:npc.join('\n')}].map(f=>({file:f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')})),source_write:false,adult_handlers_invoked:false},null,2));
console.log(Object.fromEntries(Object.entries(data).map(([k,v])=>[k,Array.isArray(v)?v.length:'catalog'])));sim.close();
