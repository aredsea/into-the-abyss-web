// Unmodified Lua execution. No production HTTP, AI, source writes or user saves.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const dir=root+'/verification/parity-r23/ui-phase3';fs.mkdirSync(dir,{recursive:true});
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','24-stats.lua','29-persona-skill.lua','34-traits.lua','60-create.lua','65-codex.lua','66-status.lua','67-settings.lua','68-cloud.lua','69-rank.lua','70-town.lua','74-affection.lua','74-level.lua','81-gear.lua','85-portrait.lua','86-portrait-have.lua','88-lore.lua','89-memory.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const extra=names.map((n,i)=>(n==='68-cloud.lua'?`B.CLOUD={HOST='fixture.invalid',KEY_X={},KEY_M={},BUILD='fixture'}\n`:'')+`assert(load(${JSON.stringify(raws[i])},${JSON.stringify('@'+n)},'t',_ENV))()`).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));const {L}=await mkSim({policy:false,extra});
const out=await L(`
local o={cases={},calls={},dictionary={ui={},words={}},host={},cloud={}}
local U,T=B.U,B.T
B.U=function(k,v)o.dictionary.ui[k]=B.ui_pack('en')[k] or k;return U(k,v)end
B.T=function(k)if type(k)=='string' then o.dictionary.words[k]=B.en_dict()[k] or k end;return T(k)end
local function up(f,w)for i=1,100 do local k,v=debug.getupvalue(f,i);if not k then break end;if k==w then return v end end;error(w)end
local function cp(v)return json.decode(json.encode(v))end
local function add(id,fn,args,h)o.cases[#o.cases+1]={id=id,fn=fn,args=args,lang=B.LANG,html=h}end
o.passives=B.PASSIVES;o.gear_icons={}
for _,gid in ipairs(B.gear().order) do o.gear_icons[gid]=B.gear_icon(B.gear().items[gid])end
debug.sethook(function()local i=debug.getinfo(2,'S');if i and i.source:sub(1,1)=='@' then local k=i.source:sub(2)..':'..i.linedefined;o.calls[k]=(o.calls[k] or 0)+1 end end,'c')
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,c in pairs(B.CAST) do for _,key in ipairs({'name','full','cls','race','lineage','nation','row','skill','skill_d','trait','trait_d'}) do if type(c[key])=='string' then B.T(c[key])end end end
 for _,key in ipairs({'뒤로','장비 가방','마을','원정','기록','즐겨찾기','상태창','장착하기'}) do B.U(key)end
 for _,el in ipairs({'fire','ice','bolt','wind','holy','dark','none','','invalid'}) do add('P2497','element',{el},B.PX.eltag(el))end
 for _,v in ipairs({false,true}) do add('P2480','kind',{v},B.C1_chip(v))end
 for _,title in ipairs({'종족 특성','출신 특성'}) do
  for _,group in ipairs({B.PASSIVES.races,B.PASSIVES.nations}) do for _,node in pairs(group) do for _,lin in ipairs({'dog','cat','','bad'}) do add('P2531 P2532','pass_block',{title,node,lin},B.PX.pass_block(title,node,lin))end end end
  add('P2531','pass_block',{title,false,''},B.PX.pass_block(title,nil,''))
 end
 for _,cls in ipairs(B.CLASSES) do for _,rid in ipairs({'human','beast','bad',''}) do for _,lin in ipairs({'dog','cat',''}) do
  add('P2533','passives',{cls.id,rid,lin,'border'},B.PX.passives(cls,rid,lin,'border'))
 end end end
 add('P2533','passives',{'bad','','',''},B.PX.passives(nil,'','',''))
 for _,st in ipairs({{}, {hp=0,mp=12,str=1.25,agi=-1,int=99999,def=7,spd=1.5}, {hp='?',mp='bad',str=8,agi=3,int=2,def=1,spd=0}}) do add('P2499','stats',{st},B.PX.stat_grid(st))end
 for _,msg in ipairs({'','plain','한글 😀','A & B'}) do add('P2500','notice',{msg},B.PX.notice({ui={msg=msg}}))end
 for _,level in ipairs({0,1,9,10,29,30,39,40,99}) do for _,xp in ipairs({-1,0,1,27,99999}) do
  local G={persona={lv=level,exp=xp},roster={'levia'},lvl={levia=level},exp={levia=xp}}
  for _,cid in ipairs({'persona','levia','unknown'}) do add('P2492','expbar',{G,cid},B.PX.expbar(G,cid))end
 end end
 for _,kind in ipairs({'hp','mp','exp','aff'}) do for _,cur in ipairs({-5,0,1,3.3333,100}) do for _,max in ipairs({-1,0,3,100}) do add('P2494','bar',{kind,cur,max},B.PX.bar(kind,cur,max))end end end
 for _,tab in ipairs({'','rec','el','el_fire','el_bad','cls','cls_warrior','cls_bad','invalid','elbad','el1','cls2','el9_ice','_el','123'}) do add('P2518 P2520','tabs',{tab},B.PX.cx_tabs({ui={tab=tab}}))end
 for _,cls in ipairs({'','sm','sm on','sm off'}) do for _,sub in ipairs({'','보조 설명'}) do
  local args={'cx_test','테스트',cls,sub};add('P0104 P2498','button',args,B.PX.btn(table.unpack(args)))
 end end
 local chip=up(B.PX.bg_listview,'chip')
 for _,kind in ipairs({'cls','slot','rar'}) do for _,v in ipairs({'','warrior','weapon','common'}) do for _,cur in ipairs({'',v,'bad'}) do add('P2576','chip',{kind,v,'전체',cur},chip(kind,v,'전체',cur))end end end
 local fxline=up(B.PX.gear_fx,'fxline')
 for _,key in ipairs({'stat','dmg','crit','mpreg','bad'}) do for _,v in ipairs({-1.25,0,1.25,2.35}) do for _,cls in ipairs({'warrior','priest','bad'}) do
  add('P2511','fxline',{key,v,cls},fxline(key,v,cls))
 end end end
 -- Every shipped item; actual source rolls, including zero/negative values and unique effects.
 for i,gid in ipairs(B.gear().order) do
  local code=B.gear_code(gid,100+i);local r=B.gear_roll(code)
  add('P2512','gear_fx',{cp(r)},B.PX.gear_fx(r));add('P2515','gear_card',{cp(r)},B.PX.gear_card(r))
  add('P2513','gear_icon',{cp(r.item)},B.PX.gear_icon(r.item))
  add('P2514','gear_tile',{cp(r.item),'bg_sel_1','장착'},B.PX.gear_tile(r.item,'bg_sel_1','장착'))
  add('P2514','gear_tile',{cp(r.item),false,false},B.PX.gear_tile(r.item))
 end
 for _,r in ipairs({{item={base={},cls='warrior'},fx={},affix={}}, {item={base={dmg=0,stat=-2},cls='warrior'},fx={dmg=0,stat=-2},affix={{'crit',0},{'mpreg',-1.25}},unique={name='A & B',text='<문자>'}}}) do add('P2512','gear_fx',{r},B.PX.gear_fx(r))end
end
-- Isolate host-only effects, observe calls and failure swallowing directly.
local get=getChatVar
for _,raw in ipairs({'{}','[]','null','false','7','"text"','broken','{"saved":{"x":1}}'}) do
 getChatVar=function()return raw end;local v=B.mem_jget('ui-phase3','key');o.host[#o.host+1]={id='P3816 P3817',raw=raw,value=v or false}
end
getChatVar=function()error('host unavailable')end;o.host[#o.host+1]={id='P3816 P3817',throws=true,value=B.mem_jget('ui-phase3','key') or false};getChatVar=get
o.battle_preview={}
local old_bag,old_vid=B.bag_load,B.VID;local bag={}
for i,gid in ipairs(B.gear().order) do bag[#bag+1]=B.gear_code(gid,100+i)end
B.bag_load=function()return bag end;B.VID='ui-phase3-preview'
for _,scene in ipairs({'town','battle'}) do
 local g=B.G_new();g.scene=scene;g.persona.cls='전사';g.persona.lv=40;local ids={}
 for _,code in ipairs(B.PX.items_for(g,'weapon','persona')) do ids[#ids+1]=B.gear_parse(code)end
 o.battle_preview[#o.battle_preview+1]={scene=scene,ids=ids}
end
B.bag_load,B.VID=old_bag,old_vid
async=function(f)return f end;B.refresh=function()end;B.nudge=function()end;addChat=function()end
local payload=B.G_new();payload.gold=777;payload.bag='';payload.persona.cls='전사';payload.persona.stats=B.CR.calc(payload.persona);payload.roster={'levia'}
for _,action in ipairs({'op_cpin','op_cload'}) do for _,mode in ipairs({'cancel','code','pin','pin_cancel','404','429','500','envelope','body','version','invalid','success','request_error'}) do
 local input,requests=0,0
 alertInput=function()input=input+1;return {await=function()if mode=='cancel' or (mode=='pin_cancel' and input==2) then return '' end;if mode=='code' then return 'bad' end;if input==2 then return mode=='pin' and 'bad' or '234567' end;return 'ABCD-EFGH-JKMP' end}end
 request=function()requests=requests+1;if mode=='request_error' then error('fixture offline')end
  return {await=function()
   if mode=='envelope' then return 'broken' end
   local p=cp(payload);if mode=='version' then p.v=99 elseif mode=='invalid' then p.persona=nil end
   return json.encode({status=tonumber(mode) or 200,data=mode=='body' and 'broken' or json.encode({rev=3,save=p})})
  end}
 end
 local g=B.G_new();g.scene='town';g.persona.name='Local';B.G_save('ui-phase3-cloud',g);B.cloud_button('ui-phase3-cloud',action)
 local after=B.G_load('ui-phase3-cloud');o.cloud[#o.cloud+1]={action=action,mode=mode,requests=requests,gold=after.gold,account=after.cloud and after.cloud.account or '',name=after.persona.name,msg=after.ui.msg,scene=after.scene}
end end
debug.sethook();return o
`);
// HTML is reduced only to user-observable text, actions, selection and bar fill.
const decode=s=>s.replace(/&quot;/g,'"').replace(/&#39;|&apos;/g,"'").replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
const text=s=>decode(s.replace(/<[^>]*>/g,' ')).replace(/\s+/g,' ').trim();
for(const f of out.cases){f.expected={text:text(f.html),buttons:[...f.html.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/g)].map(m=>({action:m[1].match(/risu-btn="([^"]*)"/)?.[1]??'',text:text(m[2]),selected:/\bon\b/.test(m[1]),disabled:/\boff\b/.test(m[1])})),bars:[...f.html.matchAll(/scaleX\(([^)]+)\)/g)].map(m=>Number(m[1]))};if(['gear_icon','gear_tile','gear_card'].includes(f.fn))f.expected.icons=[...f.html.matchAll(/\bim-([a-z0-9-]+)/g)].map(m=>m[1]);if(['gear_tile','gear_card'].includes(f.fn))f.expected.rarity=f.html.match(/bg-r-([a-z]+)/)?.[1];}
out.sources=names.map((n,i)=>({file:n,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')}));
fs.writeFileSync(dir+'/ui-oracle.json',JSON.stringify(out,null,2)+'\n');
console.log(JSON.stringify({cases:out.cases.length,host_cases:out.host.length,source_functions:Object.keys(out.calls).length}));
