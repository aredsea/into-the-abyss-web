// Execute source functions. Observer exports expose existing locals verbatim.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','24-stats.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-affection.lua','77-explore.lua','81-gear.lua','82-smithy.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const observed=raws.map((s,i)=>names[i]==='82-smithy.lua'?s.replace('  B.SCREENS.smithy = function','  B.R23_WORK_OF=work_of;B.R23_PCT=pct\n  B.SCREENS.smithy = function').replace('    local parts = {}','    B.R23_CUT=cut\n    local parts = {}').replace('  B.H.sm = function','  B.R23_WORK_NOTE=work_note\n  B.H.sm = function'):s);
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:observed.join('\n')});
const out=await L(`
local out={work={},notes={},cut={},labels={},transactions={},bag_host={},aff={},screens={},pct={}}
local function cp(x)return json.decode(json.encode(x))end
local function val(x)if x==nil then return false end;return x end
local function game()local g=B.G_new();g.settings.nsfw=0;g.scene='smithy';g.seed=4242;g.gold=10000;g.persona.cls='warrior';g.persona.lv=40;g.roster={'hildegard'};g.party={};g.lvl={hildegard=40};g.aff={hildegard=99.5};B.tw_T(g);return g end
for _,w in ipairs({false,3,{}, {forge={},proc={}}, {forge={{code='wa01.1.1',ok=true,lv=1}}}, {proc={'wa01.1.1'}}, {forge={},proc={'wa01.1.1'}}})do
 local g=game();g.sm_work=w;out.work[#out.work+1]={input=w,value=val(B.R23_WORK_OF(g))}
end
for _,id in ipairs(B.gear().order)do
 local code=B.gear_code(id,7);out.labels[#out.labels+1]={code=code,value=B.C1_en_gear_label(code)}
 for _,ok in ipairs({false,true})do for _,lv in ipairs({0,1,10})do
  local w={forge={{code=code,ok=ok,lv=lv}},proc={code}}
  out.notes[#out.notes+1]={work=w,value=B.R23_WORK_NOTE(w)}
 end end
end
for _,code in ipairs({'bad','zz99.1.1','wa01.1.2'})do out.labels[#out.labels+1]={code=code,value=B.C1_en_gear_label(code)}end
for _,n in ipairs({0,1,7,8,9,20})do for _,kind in ipairs({'forge','proc','both'})do
 local w={forge={},proc={}}
 for i=1,n do
  if kind~='proc' then w.forge[#w.forge+1]={code=i%2==1 and 'wa01.1.1' or 'bad',ok=i%2==1,lv=i%11}end
  if kind~='forge' then w.proc[#w.proc+1]=i%2==1 and 'wal2.1.1' or 'bad'end
 end
 out.notes[#out.notes+1]={work=w,value=B.R23_WORK_NOTE(w)}
 local list={};for i=1,n do list[i]='v'..i end
 out.cut[#out.cut+1]={input=list,value=B.R23_CUT(list,function(x)return x end)}
end end
for _,v in ipairs({false,0,1,0.00001,0.0001,99.99999,999999,1000000,1.23456789,-0.000001})do out.pct[#out.pct+1]={input=v,value=B.R23_PCT(v)}end
local raw='';local host_get,host_set=getChatVar,setChatVar
getChatVar=function(_,key)if key=='dk_bag' then return raw end end
setChatVar=function(_,key,v)if key=='dk_bag' then raw=v end end
local function action(g,method,args)
 local before=cp(g);local bag=B.bag_load('r23');local a,b=B[method](g,'r23',table.unpack(args));local result={val(a)};if b~=nil then result[2]=b end
 out.transactions[#out.transactions+1]={method=method,args=args,game=before,bag=bag,result=result,value=cp(g),after=B.bag_load('r23')}
end
for _,cid in ipairs({'persona','hildegard'})do for _,mode in ipairs({'bag','self','other','duplicate'})do
 local g=game();g.equip={persona={},hildegard={}};raw='';local code='wa01.1.1'
 if mode=='bag' or mode=='duplicate' then raw=code end
 if mode=='self' then g.equip[cid].weapon=code elseif mode=='other' or mode=='duplicate' then g.equip[cid=='persona' and 'hildegard' or 'persona'].weapon=code end
 action(g,'gear_equip',{cid,code})
 action(g,'gear_unequip',{cid,'weapon'})
 action(g,'gear_sell',{code});action(g,'gear_sell',{code})
end end
for _,size in ipairs({0,1999,2000})do
 local g=game();g.equip={persona={weapon='wa01.1.1'}};local bag={};for i=1,size do bag[i]='wa01.2.1'end;raw=table.concat(bag,';')
 action(g,'gear_unequip',{'persona','weapon'});action(g,'gear_sell_common',{})
end
for _,mode in ipairs({'throw_get','false_get','throw_set'})do
 getChatVar=function()if mode=='throw_get' then error('fixture get failure')end;return mode=='false_get' and false or 'wa01.1.1'end
 setChatVar=function()error('fixture set failure')end
 local ok,v=pcall(B.bag_load,'r23');local saved,err=pcall(B.bag_save,'r23',{'wa01.1.1'})
 out.bag_host[#out.bag_host+1]={mode=mode,load_ok=ok,loaded=ok and v or false,save_ok=saved}
end
getChatVar,setChatVar=host_get,host_set
for _,cid in ipairs({'','persona','missing','hildegard'})do for _,amt in ipairs({-1000,-1,0,1,1000})do
 local g=game();local calls={};B.chron_aff=function(_,id,a,b)calls[#calls+1]={id=id,before=a,after=b}end
 local delta=B.aff_add(g,cid,amt);out.aff[#out.aff+1]={cid=cid,amount=amt,delta=delta,aff=g.aff,calls=calls}
end end
-- Additional source presentation branches, with no sexual helper loaded.
B.sx_inn_card=nil;B.pend_busy=function()return false end
for _,scene in ipairs({'shop','guild','inn','smithy'})do for _,lang in ipairs({'ko','en'})do
 for _,size in ipairs({0,1,30})do
  local g=game();g.scene=scene;g.roster={};for i=1,size do g.roster[i]=B.CAST_ORDER[i]end;g.ui.sel=size>0 and g.roster[1] or '';g.ui.tab=scene=='guild' and 'recruit' or scene=='smithy' and 'process' or '';B.LANG=lang
  local html=B.SCREENS[scene](g,'r23');out.screens[#out.screens+1]={scene=scene,lang=lang,size=size,html=html}
 end
end end
return out`);
fs.writeFileSync(root+'/verification/parity-r23/gear-round2-oracle.json',JSON.stringify(out)+'\n');
fs.writeFileSync(root+'/verification/parity-r23/round2-provenance.json',JSON.stringify({sources:names.map((name,i)=>({name,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')})),observer_exports:['work_of','pct','work_note','cut'],counts:Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length]))},null,2));
console.log(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])));sim.close();
