// Actual source Lua, unchanged rules; export lexical presentation helpers only.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','24-stats.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-affection.lua','81-gear.lua','82-smithy.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const extra=raws.map((s,i)=>names[i]==='72-guild.lua'?s.replace('  function B.gd_recruit_tab(G, id)','  B.GEAR_R4_CELL=recruit_cell;B.GEAR_R4_ROSTER=recruit_roster;B.GEAR_R4_RESULT=recruit_result\n  function B.gd_recruit_tab(G, id)').replace('-- (최상위 local 개수 한계 때문에 do 블록 안에 둔다 — 밖으로는 B.gd_recruit_tab 하나만 나간다)','B.GEAR_R4_BOARD=tab_board\n-- (최상위 local 개수 한계 때문에 do 블록 안에 둔다 — 밖으로는 B.gd_recruit_tab 하나만 나간다)'):names[i]==='82-smithy.lua'?s.replace('  B.SCREENS.smithy = function','  B.GEAR_R4_FORGE=tab_forge;B.GEAR_R4_PROCESS=tab_process\n  B.SCREENS.smithy = function'):s).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra});
const out=await L(`
local out={storage={},restrictions={},migrations={},tabs={},cells={},rosters={},quests={},boards={},recruit_results={},forges={},processes={},cards={},screens={},host={},locale={ui=B.ui_pack('en'),words=B.en_dict()}}
local function cp(x)return json.decode(json.encode(x))end
local function game(scene)
 local g=B.G_new();g.scene=scene or 'town';g.seed=4242;g.gold=10000;g.settings.nsfw=0
 g.persona.cls='warrior';g.persona.lv=40;g.roster={'hildegard'};g.party={};g.lvl={hildegard=40};g.aff={hildegard=99.5};B.tw_T(g);return g
end
local host_get,host_set=getChatVar,setChatVar
local raw='';getChatVar=function(id,key)if key=='dk_bag'then return raw end;return host_get(id,key)end;setChatVar=function(id,key,v)if key=='dk_bag'then raw=v else host_set(id,key,v)end end
local function observe(g)return {bag=B.bag_load('r4'),equip=cp(g.equip or {}),gold=g.gold,forge=cp(g.forge or {})}end
for _,n in ipairs({0,1,1999,2000})do
 for _,method in ipairs({'add','take','equip','unequip','sell','sellc'})do
  local g=game();local bag={};for i=1,n do bag[i]='wa01.1.1'end
  if method=='unequip' then g.equip={persona={weapon='wa01.2.1'}}end
  raw=table.concat(bag,';');local before=observe(g);local result
  if method=='add' then result=B.bag_add('r4','wa01.2.1')
  elseif method=='take' then result=B.bag_take('r4','wa01.1.1')
  elseif method=='equip' then result=B.gear_equip(g,'r4','persona','wa01.1.1')
  elseif method=='unequip' then result=B.gear_unequip(g,'r4','persona','weapon')
  elseif method=='sell' then result=B.gear_sell(g,'r4','wa01.1.1')
  else result=B.gear_sell_common(g,'r4') end
  local after=observe(g);g=cp(g);raw=tostring(raw);local resumed=observe(g)
  out.storage[#out.storage+1]={n=n,method=method,before=before,result=result,after=after,resumed=resumed}
 end
end
for _,value in ipairs({false,7,'','bad;;wa01.1.1;zz99.1.1;wa01.1.1;wa01.2.1;'})do
 raw=value;local loaded=B.bag_load('r4');B.bag_save('r4',loaded);out.storage[#out.storage+1]={method='raw',raw=value,after={bag=B.bag_load('r4')},saved=raw}
end
for _,n in ipairs({0,1999,2000})do for _,code in ipairs({'wa80.1.1','pa01.1.1'})do
 local g=game();g.persona.lv=1;g.lvl.hildegard=1;g.equip={persona={weapon=code}}
 local bag={};for i=1,n do bag[i]='wa01.1.1'end;raw=table.concat(bag,';');local before=cp(g)
 B.gear_restrict(g,'r4');out.restrictions[#out.restrictions+1]={n=n,code=code,before=before,bag=bag,after=cp(g),after_bag=B.bag_load('r4')}
end end
for _,version in ipairs({false,0,1,'1'})do
 local g=game();g.settings.gear_v=version;g.items={eq_old=3,hp_s=2};g.equip={persona={weapon='eq_old',armor='wa01.2.1'}}
 local before=cp(g);local result=B.gear_migrate(g);local after=cp(g);g=cp(g);local again=B.gear_migrate(g)
 out.migrations[#out.migrations+1]={before=before,result=result,after=after,again=again,resumed=cp(g)}
end
-- Capture exact visible button labels/selection independently of HTML markup.
local original_btn=B.btn;local buttons={}
B.btn=function(id,label,cls,sub)buttons[#buttons+1]={id=id,label=label,selected=type(cls)=='string' and cls:find(' on',1,true)~=nil,sub=sub};return original_btn(id,label,cls,sub)end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for mode=0,3 do
  local g=game('guild');B.gd_fill(g)
  if mode==0 then g.guild.quests={}elseif mode==1 then g.guild.active=g.guild.quests[1].id elseif mode==2 then g.gold=0 else g.town.rr=7 end
  out.boards[#out.boards+1]={game=cp(g),lang=lang,mode=mode,html=B.GEAR_R4_BOARD(g)}
 end
 for _,cid in ipairs({'','missing',table.unpack(B.CAST_ORDER)})do
  for _,busy in ipairs({false,true})do
   local g=game('guild');g.town.meet=cid;g.roster=cp(B.CAST_ORDER);g.aff[cid]=99.5
   B.pend_busy=function()return busy end
   out.recruit_results[#out.recruit_results+1]={cid=cid,busy=busy,lang=lang,html=B.GEAR_R4_RESULT(g,'r4')}
  end
 end
 B.pend_busy=function()return false end
 for _,lv in ipairs({1,10,11,20,21,30,31,40})do for _,gold in ipairs({0,1000})do for _,code in ipairs({'','bad','wa01.1.1'})do
  local g=game('smithy');g.persona.lv=lv;g.lvl.hildegard=lv;g.gold=gold;g.town.process_n=7
  if code~=''then g.proc_fx={code=code}end
  out.processes[#out.processes+1]={level=lv,gold=gold,code=code,lang=lang,html=B.GEAR_R4_PROCESS(g,'r4')}
 end end end
 for _,id in ipairs(B.gear().order)do
  local code=B.gear_code(id,42);out.cards[#out.cards+1]={code=code,lang=lang,html=B.PX.gear_card(B.gear_roll(code,40))}
 end
 for mode=0,5 do
  local g=game('smithy');raw=mode==0 and '' or 'wa01.1.1;wa01.1.1;wa01.2.1';g.forge={['wa01.1.1']={lv=mode==2 and 10 or 0,tries=0}}
  if mode==1 then g.gold=0 elseif mode==3 then g.forge_fx={ok=true} elseif mode==4 then g.forge_fx={ok=false} elseif mode==5 then g.equip={persona={weapon='wa01.3.1'}}end
  out.forges[#out.forges+1]={game=cp(g),bag=B.bag_load('r4'),lang=lang,mode=mode,html=B.GEAR_R4_FORGE(g,'r4')}
 end
 for _,scene in ipairs({'smithy','guild'})do for _,tab in ipairs({'','forge','process','board','recruit','loredana','invalid'})do
  local g=game(scene);g.ui.tab=tab;buttons={};raw='';local html=B.SCREENS[scene](g,'r4');local tabs={}
  for _,b in ipairs(buttons)do if b.id:find('_tab_',1,true)then tabs[#tabs+1]=b end end
  out.tabs[#out.tabs+1]={scene=scene,tab=tab,lang=lang,buttons=tabs,html=html}
 end end
 for _,label in ipairs({'소개비','가진 금화','동료'})do for _,sub in ipairs({false,'한 명 늘 때마다 +20','금화 20 모자라다'})do
  out.cells[#out.cells+1]={label=label,value='100',sub=sub,lang=lang,html=B.GEAR_R4_CELL(label,'100',sub or nil,sub and 'short' or nil)}
 end end
 for _,ids in ipairs({{}, {'hildegard'}, {'hildegard','teiris'},B.CAST_ORDER})do
  local g=game('guild');g.roster=cp(ids);g.town.meet=ids[#ids];buttons={}
  out.rosters[#out.rosters+1]={ids=cp(ids),last=g.town.meet,lang=lang,html=B.GEAR_R4_ROSTER(g),buttons=cp(buttons)}
 end
 for _,seed in ipairs({1,42,4242})do for _,active in ipairs({false,true})do
  local g=game('guild');g.seed=seed;B.gd_fill(g)
  for _,q in ipairs(g.guild.quests)do
   out.quests[#out.quests+1]={game=cp(g),quest=cp(q),active=active,lang=lang,html=B.gd_quest_card(g,q,active)}
  end
 end end
end
B.btn=original_btn
-- Every remaining presentation row gets fresh source output for an explicit gap audit.
for _,scene in ipairs({'shop','guild','smithy','inn'})do for mode=0,5 do
 local g=game(scene);raw='';g.ui.sel='hildegard'
 if mode==0 then g.roster={};g.ui.sel=''elseif mode==1 then g.gold=0 elseif mode==2 then g.roster=cp(B.CAST_ORDER)elseif mode==3 then g.ui.sel='missing'elseif mode==4 then g.town.meet='hildegard';g.ui.tab='recruit'else raw='wa01.1.1';g.ui.tab='process'end
 local before=cp(g);out.screens[#out.screens+1]={scene=scene,mode=mode,game=before,bag=B.bag_load('r4'),html=B.SCREENS[scene](g,'r4')}
end end
-- Host-only callbacks are explicitly observed, not implemented as native networking.
for _,scene in ipairs({'guild','inn'})do for _,mode in ipairs({'ok','false','error'})do
 local g=game(scene);g.roster=scene=='guild' and {} or {'hildegard'};local calls={}
 addChat=function(id,role,line)calls[#calls+1]={id=id,role=role,line=line};if mode=='error'then error('host fixture failure')end;return mode~='false'end
 local before=cp(g);B.H[scene=='guild' and 'gd' or 'in'](g,scene=='guild' and 'meet' or 'talk_hildegard','r4')
 out.host[#out.host+1]={scene=scene,mode=mode,calls=calls,before=before,game=cp(g)}
end end
return out`);
const file=root+'/verification/parity-r23/gear-round4-oracle.json';fs.writeFileSync(file,JSON.stringify(out)+'\n');
fs.writeFileSync(root+'/verification/parity-r23/gear-round4-provenance.json',JSON.stringify({sources:names.map((name,i)=>({name,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')})),counts:Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])),observer_exports:['recruit_cell','recruit_roster','recruit_result','tab_board','tab_forge','tab_process'],host_scope:'RisuAI-only callbacks, AI/lorebook instructions excluded; no adult scenes'},null,2));
console.log(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])));sim.close();
