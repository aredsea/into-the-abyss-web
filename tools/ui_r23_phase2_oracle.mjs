// Phase 2: only the 109 remaining rows. Read-only source; isolated host state.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const dir=root+'/verification/parity-r23/phase2';fs.mkdirSync(dir,{recursive:true});
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','24-stats.lua','29-persona-skill.lua','34-traits.lua','60-create.lua','65-codex.lua','66-status.lua','67-settings.lua','68-cloud.lua','69-rank.lua','70-town.lua','74-affection.lua','74-level.lua','77-explore.lua','81-gear.lua','85-portrait.lua','86-portrait-have.lua','88-lore.lua','89-memory.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const extra=names.map((n,i)=>(n==='68-cloud.lua'?`B.CLOUD={HOST='',KEY_X={},KEY_M={},BUILD='fixture'}\n`:'')+`assert(load(${JSON.stringify(raws[i])},${JSON.stringify('@'+n)},'t',_ENV))()`).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));const {sim,L}=await mkSim({policy:false,extra});
const result=await L(`
local out={u={},t={},pack={},create={},hd={},st={},cx={},syn={},mname={},recap={},escape={},places={},calls={}}
local function cp(v)return json.decode(json.encode(v))end
local function up(f,w)for i=1,100 do local k,v=debug.getupvalue(f,i);if not k then break end;if k==w then return v end end;error(w)end
debug.sethook(function()local i=debug.getinfo(2,'S');if i and i.source:sub(1,1)=='@' then local k=i.source:sub(2)..':'..i.linedefined;out.calls[k]=(out.calls[k] or 0)+1 end end,'c')
for _,v in ipairs({'','&<>"',"'",'&amp;','한글😀','{{user}}',false,true,0,1.5}) do out.escape[#out.escape+1]={input=v,value=B.esc(v)} end
out.escape[#out.escape+1]={no_value=true,value=B.esc(nil)}
local oldraw,oldwords=B.UI_RAW,B.EN_RAW
local inputs={'{}','[]','null','false','7','"text"','broken','{"x":false,"zero":0,"empty":"","yes":"OK"}'}
for _,raw in ipairs(inputs) do
 B.UI={};B.EN=nil;B.UI_RAW={en=raw};B.EN_RAW=raw
 local first=cp(B.ui_pack('en'));B.UI_RAW.en='{"replacement":"later"}';local second=cp(B.ui_pack('en'))
 local words=cp(B.en_dict());B.EN_RAW='{"replacement":"later"}';local words2=cp(B.en_dict())
 out.pack[#out.pack+1]={raw=raw,first=first,second=second,words=words,words2=words2,unknown=B.ui_pack('fr')}
end
B.UI_RAW,B.EN_RAW=oldraw,oldwords;B.UI={};B.EN=nil
for _,lang in ipairs({'ko','en','fr'}) do B.LANG=lang
 for _,v in ipairs({'설정','레비아','unknown','',false,true,7,1.5}) do out.t[#out.t+1]={lang=lang,input=v,value=B.T(v)} end
 for _,text in ipairs({'plain','{a}','{a:이가}','{a:으로}', '{{a}}','{a:invalid}','{a-b}','{한글}','{0}','{a}{a}{missing}','{_x:을를}','{a:}{b:이다}','금화 {n}'}) do
  for _,vars in ipairs({{}, {a='레비아',b='길',n=7,['_x']='{{user}}',['0']='zero'}, {a=false,b=true,n=0}, {a='',b='😀',n=1.5}}) do
   out.u[#out.u+1]={lang=lang,input=text,vars=vars,value=B.U(text,vars)}
  end
  out.u[#out.u+1]={lang=lang,input=text,no_vars=true,value=B.U(text)}
 end
end
-- False must fall back, whereas zero and the empty string are truthy in Lua.
B.UI_RAW={en='{"fallback":false,"empty":"","translated":"{a:이가}"}'};B.UI={};B.LANG='en'
for _,text in ipairs({'fallback','empty','translated'}) do out.u[#out.u+1]={lang='en',input=text,vars={a='레비아'},pack=B.UI_RAW.en,value=B.U(text,{a='레비아'})}end
B.UI_RAW=oldraw;B.UI={};B.LANG='ko'
for _,scene in ipairs({'town','battle','create','scenario'}) do for _,panel in ipairs({'','status','codex','settings','save','unknown'}) do
 for _,arg in ipairs({'close','status','codex','settings','save','unknown',''}) do
  local G={scene=scene,ui={panel=panel,tab='keep',sel='levia',page=9,msg='old',bg={pg=2}}};local before=cp(G);B.H.hd(G,arg,'p2');out.hd[#out.hd+1]={before=before,arg=arg,value=G}
 end
 for _,arg in ipairs({'t_battle','t_me','t_bag','t_unknown',''}) do
  local G={scene=scene,ui={panel=panel,tab='keep',sel='levia',page=9,msg='old'}};local before=cp(G);B.H.st(G,arg,'p2');out.st[#out.st+1]={before=before,arg=arg,value=G}
 end
end end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,sel in ipairs({'persona','levia','bad',''}) do for _,favs in ipairs({{}, {'levia','levia'}, {'naran','teiris','hilde'}}) do
  for _,arg in ipairs({'fav','me','sel_persona','sel_levia','sel_bad','open_levia','open_bad','bag','f_all','f_el_fire','pg_1e2','pg_bad','back'}) do
   local G={scene='town',ui={panel='status',tab='keep',sel=sel,page=5,msg='old'},roster={'levia','naran','teiris'},favs=cp(favs)};local before=cp(G);B.H.cx(G,arg,'p2');out.cx[#out.cx+1]={lang=lang,before=before,arg=arg,value=G}
  end
 end end
end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,race in ipairs({'','인간','수인','엘프'}) do for _,total in ipairs({0,5,20,99}) do
  for _,scene in ipairs({'create','town'}) do
   local base=B.G_new();base.scene=scene;base.persona.race=race;base.persona.cls='전사';base.persona.nation='경계도시';base.persona.lineage='개과';base.persona.bonus_total=total;B.CR.P(base)
   for _,arg in ipairs({'tot_1e1','tot_5.0','tot_99','tot_p5','tot_m5','tot_free','tot_bad','go_bad','go_1e0','go_2.5','go_9','next','back','done','clear','auto','up_str','up_bad','dn_str','racehuman','race_elf','lin_cat','nat_bad','cls_priest'}) do
    local G=cp(base);G.ui.page=2;G.ui.msg='old';local before=cp(G);B.H.cr(G,arg,'p2');out.create[#out.create+1]={lang=lang,before=before,arg=arg,value=G}
   end
  end
 end end
end
local mname=up(B.PX.bg_detail,'mname')
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 local ids={'persona','bad<&>'};for _,id in ipairs(B.CAST_ORDER) do ids[#ids+1]=id end
 for _,n in ipairs({'','레비아','{{user}}','<A&B>"','unknown'}) do for _,id in ipairs(ids) do
  local G={persona={name=n}};out.mname[#out.mname+1]={lang=lang,input=G,id=id,value=mname(G,id)}
 end end
 for _,list in ipairs({B.CR.RACES,B.CR.LINEAGES,B.CR.NATIONS,{{syn='fallback'},{syn='fallback',syn2_raw=false},{syn='fallback',syn2_raw='',syn3_raw='{unknown.value}'}}}) do
  for _,e in ipairs(list) do local value=B.CR.syn_text(e);out.syn[#out.syn+1]={lang=lang,entry=e,value=value,display=B.U('시너지 2명이면 {effect}',{effect=value})} end
 end
end
local saved_label=B.ex_label
for _,enabled in ipairs({false,true}) do B.ex_label=enabled and saved_label or nil
 for _,lang in ipairs({'ko','en'}) do B.LANG=lang
  for _,scene in ipairs({'dungeon','town','smithy','shop','battle','sortie','bad'}) do
   for _,d in ipairs({{}, {run='bad'}, {run={}}, {run={floor=false}}, {run={floor=0}}, {run={floor=1}}, {run={floor='10'}}, {run={floor=''}}, {run={floor=-1}}}) do
    local G={scene=scene,dungeon=d,place='archive'};out.places[#out.places+1]={input=G,lang=lang,enabled=enabled,value=B.place_label(G) or ''}
   end
  end
 end
end
B.ex_label=saved_label
local dictionary={names={},words={},zones={},foes={}}
B.EN=nil
for id,c in pairs(B.CAST) do dictionary.names[id]=c.name;dictionary.words[c.name]=B.ai(c.name) end
for id,z in pairs(B.ZONES or {}) do dictionary.zones[tostring(id)]={name=z.name,boss=z.boss};dictionary.words[z.name]=B.ai(z.name) end
for id,f in pairs(B.FOES or {}) do dictionary.foes[id]={name=f.name};dictionary.words[f.name]=B.ai(f.name) end
out.recap_dictionary=dictionary
for _,roster in ipairs({{}, {'levia'}, {'levia','naran'}, {'naran','levia'}, {'levia','naran','teiris'}, {'bad','levia'}}) do
 for _,levels in ipairs({{}, {levia=4,naran=4,teiris=3}, {levia='5',naran='bad',teiris=6}}) do
  for _,party in ipairs({{}, {'levia'}, {'naran'}}) do for _,aff in ipairs({{}, {levia=20,naran=20,teiris=100}, {levia=100,naran=20}, {levia=-3,naran='40'}}) do
   local G={roster=roster,lvl=levels,party=party,aff=aff,exp={levia=0,naran=100},persona={lv=7},dungeon={best=3,cleared_bosses={1,999,'bad'}},gold=987}
   out.recap[#out.recap+1]={input=G,value=B.cloud_recap(G)}
  end end
 end
end
for _,roster in ipairs({{''},{7},{false},B.CAST_ORDER}) do
 local G={roster=roster,lvl={},party={},aff={},exp={},persona={},dungeon={cleared_bosses={}},gold=0}
 for id in pairs(B.ZONES or {}) do G.dungeon.cleared_bosses[#G.dungeon.cleared_bosses+1]=id end
 out.recap[#out.recap+1]={input=G,value=B.cloud_recap(G)}
end
for _,xp in ipairs({499999,500000,500001,1000000,1000001}) do
 local G={roster={'levia','naran'},lvl={levia=1,naran=2},party={'levia'},aff={levia=0,naran=1},exp={levia=xp},persona={lv=40},dungeon={best=100},gold=0}
 out.recap[#out.recap+1]={input=G,value=B.cloud_recap(G)}
end
debug.sethook();return out
`);
result.public_dictionary=await L(`
local ui,words={},{}
for _,key in ipairs({'즐겨찾기는 {max}명까지입니다. 다른 동료를 먼저 빼 주세요.','즐겨찾기에서 뺐습니다.','즐겨찾기에 넣었습니다.','전투 중에는 가방을 열 수 없습니다.','먼저 만남을 골라 주세요.','남은 점수가 없습니다.','한 능력치에는 최대 {cap}점까지만 줄 수 있습니다.','총량이 {n}점으로 바뀌어 나눠 둔 점수 {cut}점을 줄였습니다. 남은 점수를 다시 나눠 주세요.','이 단계부터 채워 주세요.','아직 비어 있는 단계가 있습니다.','{two}, 3명이면 {three}','시너지 2명이면 {effect}','대던전{floor}',' {n}층'}) do ui[key]=B.ui_pack('en')[key] or key end
for _,list in ipairs({B.CR.RACES,B.CR.NATIONS,B.CR.LINEAGES}) do for _,e in ipairs(list) do for _,k in ipairs({'syn2_raw','syn3_raw','te_raw','te','syn','tr','d'}) do if e[k] then words[e[k]]=B.T(e[k]) end end end end
local fn=B.ptx;local X,P
for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k=='X' then X=v elseif k=='P' then P=v end end
return {ui=ui,words=words,values={X=X,P=P,VAR=B.VAR}}
`);
result.public_dictionary.ui['{name}에게 장착']=await L(`return B.ui_pack('en')['{name}에게 장착'] or '{name}에게 장착'`);
const native=JSON.parse(fs.readFileSync(root+'/verification/cloud-r22/fixtures.json','utf8')).town;
const projected={persona:native.persona,roster:native.owned,party:native.party,gold:native.gold,dungeon:native.dungeon_r21,lvl:{},aff:{},exp:{}};
for(const id of native.owned){const m=native.members[id];projected.lvl[id]=m.level;projected.aff[id]=m.aff;projected.exp[id]=m.xp;}
result.native_recap={input:projected,value:await L(`return B.cloud_recap(json.decode(${JSON.stringify(JSON.stringify(projected))}))`)};
fs.writeFileSync(dir+'/oracle.json',JSON.stringify(result,null,2)+'\n');
fs.writeFileSync(dir+'/provenance.json',JSON.stringify({sources:names.map((n,i)=>({file:'bot/src/'+n,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')})),counts:Object.fromEntries(Object.entries(result).filter(([,v])=>Array.isArray(v)).map(([k,v])=>[k,v.length]))},null,2)+'\n');
console.log(JSON.stringify(JSON.parse(fs.readFileSync(dir+'/provenance.json')).counts));sim.close?.();
