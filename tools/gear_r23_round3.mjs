// Execute original rules, including the remaining function-local boundaries.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','24-stats.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-affection.lua','81-gear.lua','82-smithy.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const extra=raws.map((s,i)=>names[i]==='82-smithy.lua'?s.replace('  B.SCREENS.smithy = function','  B.R23_PCT=pct;B.R23_FX_CLEAR=fx_clear\n  B.SCREENS.smithy = function'):names[i]==='73-inn.lua'?s.replace('B.SCREENS.inn = function','B.R23_ACT_VISIBLE=act_visible\nB.SCREENS.inn = function'):s).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra});
const out=await L(`
local out={pct={},fx={},visible={},aff={},restrict={},transactions={},presentations={},handlers={},edges={}}
local host_get,host_set=getChatVar,setChatVar
local function cp(x)return json.decode(json.encode(x))end
local function val(x)if x==nil then return {kind='nil'}end;return {kind=type(x),value=x}end
local function game(scene)
 local g=B.G_new();g.scene=scene or 'smithy';g.seed=4242;g.gold=10000;g.settings.nsfw=0
 g.persona.cls='warrior';g.persona.lv=40;g.roster={'hildegard'};g.lvl={hildegard=40};g.aff={hildegard=99.5};B.tw_T(g);return g
end
local values={0,-0.0,1,-1,0.00001,0.0001,999999,999999.5,999998.5,1.234565,1.234575,123456.5,123457.5,0.00009999995,0.00009999985,2^-1074,-2^-1074,0x1.fffffffffffffp1023,math.huge,-math.huge,0/0}
for e=-300,300,12 do for _,m in ipairs({1,1.23456789,9.999995,9.999985,-1.23456789})do values[#values+1]=m*10^e end end
for i=1,512 do values[#values+1]=((i*48271)%2147483647)/2147483647*10^((i%41)-20) end
for _,v in ipairs(values)do out.pct[#out.pct+1]={input=string.format('%.17g',v),bytes={string.byte(string.pack('<d',v),1,8)},value=B.R23_PCT(v)}end
out.pct[#out.pct+1]={input=false,value=B.R23_PCT(false)}
for _,f in ipairs({false,0,{}, {ok=true}})do for _,p in ipairs({false,0,{}, {code='wa01.1.1'}})do
 local g={forge_fx=f,proc_fx=p,keep={7}};local before=cp(g);local result=B.R23_FX_CLEAR(g)
 out.fx[#out.fx+1]={input=before,value=g,result=val(result)}
end end
for _,g in ipairs({{}, {settings={nsfw=0}}, {settings={nsfw=1}}, {roster={},gold=0}})do
 for _,act in ipairs({'talk','meal','gift','rest','missing',false})do for _,cid in ipairs({'hildegard','missing','',false})do
  out.visible[#out.visible+1]={game=g,act=act,cid=cid,value=B.R23_ACT_VISIBLE(g,act,cid)}
 end end
end
for _,a in ipairs({false,'12.5',-100,-60,0,99.5,100,150,200})do for _,amt in ipairs({-1000,-1,0,1,1000})do
 for _,cid in ipairs({'','persona','missing','hildegard'})do for _,callback in ipairs({false,true})do
  local g={aff={hildegard=a,missing=a}};local calls={};local before=cp(g)
  B.chron_aff=callback and function(state,id,old,new)calls[#calls+1]={same=state==g,cid=id,before=old,after=new}end or nil
  local result=B.aff_add(g,cid,amt);out.aff[#out.aff+1]={input=before,cid=cid,amount=amt,callback=callback,result=result,value=cp(g),calls=cp(calls)}
 end end
end end
for _,shape in ipairs({false,0,{}, {hildegard='0x1.8p+6'}})do for _,cid in ipairs({'','persona','hildegard'})do for _,amt in ipairs({false,'bad',' 1.5 ','0x1p1'})do
 local g={aff=cp(shape)};local before=cp(g);local calls={};B.chron_aff=function(state,id,a,b)calls[#calls+1]={same=state==g,cid=id,before=a,after=b}end
 local result=B.aff_add(g,cid,amt);out.aff[#out.aff+1]={input=before,cid=cid,amount=amt,callback=true,result=result,value=cp(g),calls=cp(calls)}
end end end
B.chron_aff=nil
local raw='';local writes={};getChatVar=function()return raw end;setChatVar=function(_,key,value)writes[#writes+1]={key=key,value=value};raw=value end
for _,equip in ipairs({false,0,{}, {persona=false}, {persona={weapon='wa01.1.1',armor='bad',acc=7}}, {persona={weapon='mal1.1.1'}}})do
 for _,n in ipairs({0,1999,2000})do
  local g=game();g.persona.lv=1;g.equip=cp(equip);local bag={};for i=1,n do bag[i]='wa01.2.1'end;raw=table.concat(bag,';');writes={}
  local before=cp(g);local result=B.gear_restrict(g,'r23')
  out.restrict[#out.restrict+1]={game=before,bag=bag,result=val(result),value=cp(g),after=B.bag_load('r23'),writes=cp(writes)}
 end
end
for _,cid in ipairs({'persona','hildegard','missing'})do for _,code in ipairs({'bad','zz99.1.1','wa01.1.1','mal1.1.1'})do
 for _,method in ipairs({'gear_equip','gear_sell'})do
  local g=game();g.persona.lv=1;g.lvl.hildegard=1;raw='wa01.1.1;wa01.1.1';writes={};local before=cp(g);local bag=B.bag_load('r23')
  local args=method=='gear_equip' and {cid,code} or {code};local a,b=B[method](g,'r23',table.unpack(args));local result={val(a)};if b~=nil then result[2]=val(b)end
  out.transactions[#out.transactions+1]={method=method,args=args,game=before,bag=bag,result=result,value=cp(g),after=B.bag_load('r23'),writes=writes}
 end
end end
do
 local g=game();g.equip=false;raw='wa01.1.1';local before=cp(g);local a,b=B.gear_equip(g,'r23','persona','wa01.1.1');out.transactions[#out.transactions+1]={method='gear_equip',args={'persona','wa01.1.1'},game=before,bag={'wa01.1.1'},result={val(a)},value=cp(g),after=B.bag_load('r23'),writes={}}
 g=game();raw='wal2.1.1;wa01.1.1';before=cp(g);a,b=B.gear_sell_common(g,'r23');out.transactions[#out.transactions+1]={method='gear_sell_common',args={},game=before,bag={'wal2.1.1','wa01.1.1'},result={val(a),val(b)},value=cp(g),after=B.bag_load('r23'),writes={}}
end
-- Every presentation row is executed in both languages. These are observations,
-- not a claim that native Controls return source HTML.
B.sx_inn_card=nil;local busy=false;B.pend_busy=function()return busy end;B.pend_hard=function(g,note)g.pending=note end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,scene in ipairs({'shop','guild','inn','smithy'})do for mode=0,7 do
  local g=game(scene);raw='';busy=mode==7
  if mode==0 then g.roster={}elseif mode==1 then g.roster=cp(B.CAST_ORDER)end
  g.ui.sel=(mode==2 or mode==3 or mode==7) and 'hildegard' or '';g.gold=mode==3 and 0 or 10000
  if scene=='guild' then B.gd_fill(g);g.ui.tab=mode%3==0 and 'board' or mode%3==1 and 'recruit' or 'loredana';g.town.meet=mode>=4 and 'hildegard' or nil end
  if scene=='inn' then if mode==3 then g.town.acts.hildegard_talk=g.town.day end end
  if scene=='shop' then g.ui.tab=mode%2==0 and 'gear' or '';g.ui.sel=mode==2 and 'level_scroll' or '';g.items.charm_potion=mode>=4 and 1 or 0 end
  if scene=='smithy' then
   g.ui.tab=mode%2==0 and 'forge' or 'process';raw=mode>=2 and 'wa01.1.1' or '';g.forge={['wa01.1.1']={lv=mode==2 and 10 or 0,tries=0}}
   if mode>=4 then g.sm_work={forge={},proc={'wa01.1.1'}};g.proc_fx={code=mode==4 and 'bad' or 'wa01.1.1'};g.forge_fx={ok=mode%2==0}end
  end
  out.presentations[#out.presentations+1]={scene=scene,mode=mode,lang=lang,game=cp(g),html=B.SCREENS[scene](g,'r23')}
 end end
end
-- Scene guards, invalid arguments, pending, full bags, prices, daily limits,
-- host false/error and successful actions. All are real source parent calls.
for _,scene in ipairs({'smithy','guild','inn','shop'})do
 local method=({smithy='sm',guild='gd',inn='in',shop='sh'})[scene]
 local args=({smithy={'tab_forge','tab_process','tab_invalid','try_0','try_1','try_2','back','done','proc','unknown'},guild={'back','tab_board','tab_recruit','tab_loredana','tab_bad','fill','acc_missing','rej_missing','drop','refresh','meet','unknown'},inn={'back','list','pick_hildegard','pick_missing','talk_hildegard','meal_hildegard','gift_hildegard','rest_hildegard','unknown_hildegard','unknown'},shop={'back','buy_hp_s','buy_missing','unknown'}})[scene]
 for mode=0,8 do for _,arg in ipairs(args)do
  local g=game(mode==0 and 'town' or scene);raw=mode==4 and string.rep('wa01.1.1;',2000) or mode==5 and 'wa01.1.1' or '';busy=mode==2;g.gold=mode==3 and 0 or 10000
  if mode==6 then g.sm_work={forge={},proc={'wa01.1.1'}};g.town.acts.hildegard_talk=g.town.day end
  if scene=='guild' then B.gd_fill(g);if mode==4 then g.roster=cp(B.CAST_ORDER)end end
  g.forge_fx={ok=true};g.proc_fx={code='wa01.1.1'};g.pending_at=77;g.pend_soft=true
  addChat=function()if mode==8 then error('fixture host failure')end;return mode~=7 end
  local before=cp(g);writes={};local result=B.H[method](g,arg,'r23')
  out.handlers[#out.handlers+1]={scene=scene,arg=arg,mode=mode,game=before,value=cp(g),result=val(result),writes=cp(writes)}
 end end
end
-- Native-unmatched source contracts, explicitly retained as observations.
local function edge(g,method,arg,tag)
 local before=cp(g);local result=B.H[method](g,arg,'r23');out.edges[#out.edges+1]={tag=tag,game=before,arg=arg,value=cp(g),result=val(result)}
end
do
 local g=game('smithy');raw='wa01.1.1';g.forge={['wa01.1.1']={lv=10,tries=0}};edge(g,'sm','try_1','forge max failure')
 local process_roll=B.process_roll;B.process_roll=function()return nil end;edge(game('smithy'),'sm','proc','process dependency returns nil');B.process_roll=process_roll
 g=game('guild');g.guild.quests={};out.presentations[#out.presentations+1]={scene='guild',mode='empty-board',game=cp(g),html=B.SCREENS.guild(g,'r23')}
 B.gd_fill(g);g.guild.active=g.guild.quests[1].id;out.presentations[#out.presentations+1]={scene='guild',mode='active-board',game=cp(g),html=B.SCREENS.guild(g,'r23')}
 edge(g,'gd','acc_'..g.guild.quests[2].id,'already active');edge(g,'gd','rej_'..g.guild.active,'reject active');edge(g,'gd','drop','abandon active');g.gold=0;edge(g,'gd','refresh','refresh funds')
 g=game('guild');B.gd_fill(g);g.guild.active=g.guild.quests[1].id;edge(g,'gd','refresh','refresh preserves active')
 local dirty=B.ps_dirty;B.ps_dirty=function()return true end;edge(g,'gd','back','dirty editor callback');B.ps_dirty=dirty
 edge(game('guild'),'gd','ps_pre_missing','research delegation')
 local rnd=B.gd_rnd;B.gd_rnd=function()return 1.1 end;edge(game('guild'),'gd','meet','candidate upper bound callback');B.gd_rnd=rnd
 g=game('guild');g.roster={};g.gold=0;g.ui.tab='recruit';out.presentations[#out.presentations+1]={scene='guild',mode='unfunded-recruit',game=cp(g),html=B.SCREENS.guild(g,'r23')}
 local visible=B.R23_ACT_VISIBLE -- local act_visible is constant true; its false parent gate is unreachable without replacing the lexical source function.
 for _,arg in ipairs({'cls_warrior','slot_acc','scroll','target_persona','gear_0','gear_1'})do edge(game('shop'),'sh',arg,'shop selection')end
 for _,cid in ipairs({'persona','hildegard'})do
  g=game('shop');g.persona.lv=1;g.lvl.hildegard=1;g.items.level_scroll=1;g.ui.sel='level_scroll';edge(g,'sh','target_'..cid,'scroll target')
 end
 g=game('shop');g.items.level_scroll=0;g.ui.sel='level_scroll';edge(g,'sh','target_persona','missing scroll')
 g=game('shop');g.shop_got={hp_s=1,['wa01.1.1']=2};edge(g,'sh','back','shop departure ledger')
 g=game('shop');g.items=false;edge(g,'sh','buy_hp_s','missing inventory table')
 g=game('shop');g.shop_slot='weapon';g.ui.tab='warrior';g.gold=0;edge(g,'sh','gear_1','unfunded stock')
 g=game('shop');g.shop_slot='weapon';g.ui.tab='warrior';g.shop_stock={day=g.town.day,bought={}};raw='';edge(g,'sh','gear_1','stock existing day')
 local stock=B.shop_stock(g,'warrior','weapon')[1];if stock then g.shop_stock.bought[stock.code]=true end;edge(g,'sh','gear_1','stock sold')
end
getChatVar,setChatVar=host_get,host_set
return out`);
for(const f of out.aff){if(Array.isArray(f.value.aff))f.value.aff={};}
fs.writeFileSync(root+'/verification/parity-r23/gear-round3-oracle.json',JSON.stringify(out)+'\n');
fs.writeFileSync(root+'/verification/parity-r23/round3-provenance.json',JSON.stringify({sources:names.map((name,i)=>({name,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')})),counts:Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])),observer_exports:['pct','fx_clear','act_visible'],scope:'No adult scene/handler; source files are read-only.'},null,2));
console.log(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])));sim.close();
