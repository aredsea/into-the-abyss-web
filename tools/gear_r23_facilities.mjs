// Preserve original UI/host returns for every remaining facility presentation row.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','70-town.lua','71-shop.lua','72-guild.lua','73-inn.lua','74-affection.lua','81-gear.lua','82-smithy.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:raws.join('\n')});
const out=await L(`
local out={screens={},titles={},title_words={},smithy={},npcs={},inn={},guild={}}
local function cp(x)return json.decode(json.encode(x))end
local bag={};B.bag_load=function()return cp(bag)end;B.bag_save=function(_,list)bag=cp(list)end
local busy=false;B.pend_hard=function(G,note)G.pending=note end;B.pend_busy=function()return busy end
B.sx_inn_card=nil
local function game(scene)local G=B.G_new();G.settings.nsfw=0;G.scene=scene;G.seed=4242;G.gold=10000;G.roster={};G.party={};G.persona.cls='warrior';G.persona.lv=1;G.ui.tab='';B.tw_T(G);return G end
for _,kind in ipairs(B.QUEST_KINDS)do out.title_words[kind.t]=B.C1_en(kind.t)end
for _,q in ipairs({{}, {title='plain'}, {rift='rift',title='rift, title'}, {rift='남서 설산 균열',title='남서 설산 균열, 고립된 탐사대 구조'}})do
 B.LANG='ko';local ko=B.gd_title(q);B.LANG='en';local ui_en=B.gd_title(q);B.LANG='ko'
 out.titles[#out.titles+1]={q=q,ko=ko,ui_en=ui_en,en=B.gd_title_en(q)}
end
for _,scene in ipairs({'shop','guild','inn','smithy'})do for _,mode in ipairs({0,1,2,3,4})do
 local g=game(scene);bag={}
 if mode>0 then g.roster={'hildegard'};g.party={'hildegard'};g.aff={hildegard=150};g.ui.sel='hildegard';g.lvl={hildegard=40} end
 if scene=='guild' then
  B.gd_fill(g);g.ui.tab=(mode==1 or mode>=3) and 'recruit' or mode==2 and 'loredana' or 'board';g.town.meet=mode==1 and 'hildegard' or nil
  if mode==3 then g.roster=cp(B.CAST_ORDER)end
  if mode==4 then g.roster={};g.gold=0;busy=true end
 end
 if scene=='shop' then g.ui.tab=mode==3 and 'invalid' or '';g.shop_slot=mode==2 and 'acc' or 'invalid';g.ui.sel=mode==1 and 'level_scroll' or '';g.items.charm_potion=mode==2 and 1 or 0 end
 if scene=='smithy' then
  g.ui.tab=mode==1 and 'process' or 'forge'
  if mode>1 then bag={'wa01.1.1'};g.forge={['wa01.1.1']={lv=mode==2 and 10 or 0,tries=0}};g.forge_fx={ok=mode==2,code='wa01.1.1'};g.sm_work={forge={{code='wa01.1.1',ok=true,lv=1}},proc={}} end
 end
 local before=cp(g);local html=B.SCREENS[scene](g,'r23');out.screens[#out.screens+1]={scene=scene,mode=mode,game=before,html=html};busy=false
end end
for _,has in ipairs({false,true})do for _,html in ipairs({'','path.png','<img src="fixture">'})do
 local old=B.portrait;B.portrait=has and function()return html end or nil
 out.npcs[#out.npcs+1]={has=has,portrait=html,value=B.tw_npcs({{'pietro','피에트로','토르바 지배인'}})};B.portrait=old
end end
for _,count in ipairs({0,1,8,9})do for _,kind in ipairs({'forge','proc','both'})do
 local g=game('smithy');g.sm_work={forge={},proc={}}
 for i=1,count do
  if kind~='proc' then g.sm_work.forge[#g.sm_work.forge+1]={code='wa01.1.1',ok=i%2==1,lv=i%11}end
  if kind~='forge' then g.sm_work.proc[#g.sm_work.proc+1]='wa01.1.1'end
 end
 local before=cp(g);B.H.sm(g,'done','r23');out.smithy[#out.smithy+1]={kind='done',count=count,work=kind,game=before,value=cp(g)}
end end
for _,arg in ipairs({'tab_forge','tab_process','tab_missing','try_0','try_999','back','done','invalid','proc'})do
 local g=game('smithy');g.forge_fx={ok=true};g.proc_fx={code='wa01.1.1'};bag={};local before=cp(g);B.H.sm(g,arg,'r23')
 out.smithy[#out.smithy+1]={kind='action',arg=arg,game=before,value=cp(g),bag=bag}
end
for _,scene in ipairs({'town','inn'})do for _,arg in ipairs({'list','back','pick_hildegard','meal_hildegard','talk_missing','invalid'})do
 local g=game(scene);g.roster={'hildegard'};g.aff={hildegard=0};local before=cp(g);B.H['in'](g,arg,'r23');out.inn[#out.inn+1]={arg=arg,game=before,value=cp(g)}
end end
for _,arg in ipairs({'tab_board','tab_recruit','tab_loredana','tab_invalid','fill','acc_missing','rej_missing','drop','back','invalid','meet'})do
 local g=game('guild');local before=cp(g);B.H.gd(g,arg,'r23');out.guild[#out.guild+1]={arg=arg,game=before,value=cp(g)}
end
for _,sent in ipairs({false,true})do
 addChat=function()return sent end
 for _,scene in ipairs({'guild','inn'})do
  local g=game(scene);g.roster={'hildegard'};g.aff={hildegard=0};local before=cp(g)
  if scene=='guild' then B.H.gd(g,'meet','r23')else B.H['in'](g,'talk_hildegard','r23')end
  out[scene=='guild' and 'guild' or 'inn'][#out[scene=='guild' and 'guild' or 'inn']+1]={arg='host_chat',sent=sent,game=before,value=cp(g)}
 end
end
return out`);
fs.writeFileSync(root+'/verification/parity-r23/facility-contracts.json',JSON.stringify(out)+'\n');
fs.writeFileSync(root+'/verification/parity-r23/facility-provenance.json',JSON.stringify({sources:names.map((name,i)=>({name,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')})),note:'Original HTML and AI pending text are retained as source observations, not claimed identical to native UI receipts. No adult handler invoked.'},null,2));
console.log(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])));sim.close();
