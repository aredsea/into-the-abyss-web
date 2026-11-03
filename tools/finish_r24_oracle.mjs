// Execute canonical Lua. Only export lexical helpers in the simulator's copies.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const src='C:/Clauede Code/dungeon-bot/bot',out='verification/finish-r24';
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','24-stats.lua','34-traits.lua','60-create.lua','74-level.lua','77-explore.lua','81-gear.lua','89-memory.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const extra=raws.map((s,i)=>`assert(load(${JSON.stringify(s)},${JSON.stringify('@'+names[i])},'t',_ENV))()`).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));const {sim,L}=await mkSim({policy:false,extra});
try {
const data=await L(`
local out={traits={},heads={},nav={},steps={},confirm={},options={},seeds={},chronicle={},bank={}}
local function cp(v)return json.decode(json.encode(v))end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,kind in ipairs({'race','nation','lineage','line'})do
  local list=kind=='race' and B.CR.RACES or kind=='nation' and B.CR.NATIONS or kind=='lineage' and B.CR.LINEAGES or B.CR.LINE
  for key,e in pairs(list)do
   out.traits[#out.traits+1]={lang=lang,kind=kind,entry=cp(e),value=B.CR.trait_row('종족',e.tr,e.te,e.syn or '',e)}
  end
 end
 for _,race in ipairs({'','인간','엘프','수인'})do for _,nation in ipairs({'','경계도시','신성 세레디아 제국'})do for _,cls in ipairs({'','전사','마법사'})do for _,spent in ipairs({0,1})do
  local g=B.G_new();local p=B.CR.P(g);p.race=race;p.nation=nation;p.cls=cls;p.lineage=race=='수인' and '여우' or '';if spent==1 then B.H.cr(g,'auto','f')end
  for page=1,5 do
   out.nav[#out.nav+1]={lang=lang,p=cp(p),page=page,value=B.CR.nav(p,page)}
   out.steps[#out.steps+1]={lang=lang,p=cp(p),page=page,value=B.CR.steps(p,page)}
  end
  if B.CR.reach(p,5) then out.confirm[#out.confirm+1]={lang=lang,p=cp(p),value=B.CR.pg_confirm(p)}end
 end end end end
 for page=1,5 do for _,n in ipairs(page==4 and {0,5,10,20,99} or {5})do local p=B.CR.view(B.G_new());p.bonus_total=n;out.heads[#out.heads+1]={lang=lang,page=page,total=B.CR.total(p),value=B.CR.head(page,type(B.CR.SUB[page])=='function' and B.CR.SUB[page](p) or B.CR.SUB[page])}end end
 for _,on in ipairs({false,true})do for _,off in ipairs({false,true})do out.options[#out.options+1]={lang=lang,on=on,off=off,value=B.CR.opt('choice',on,nil,'전사','전열',off)}end end
end
local oldt,oldc,oldr=os.time,os.clock,math.random
for _,t in ipairs({0,1,1793664000})do for _,c in ipairs({0,.000001,1.5})do for _,r in ipairs({1,77,2147483646})do
 os.time=function()return t end;os.clock=function()return c end;local calls=0;math.random=function(a,b)assert(a==1 and b==2147483646);calls=calls+1;return r end
 out.seeds[#out.seeds+1]={seconds=t,micros=math.floor(c*1000000),random=r,value=B.new_seed(),calls=calls}
end end end
os.time,os.clock,math.random=oldt,oldc,oldr
local facts={'테이리스와 첫 만남, 동료로 함께하게 되었다','테이리스가 길드 소개로 동료가 되었다','의뢰 「균열 조사」를 완료했다','의뢰 「균열 조사」에 실패했다','레벨이 올랐다: {{user}} Lv 1 → 2, 테이리스 Lv 1 → 2','대던전 1층 돌파, 보스 수습 인형','대던전 3층에서 퇴각','철의 묘지 구역 보스 수습 인형을 처음 쓰러뜨렸다','대던전 4층 도전 실패','대던전 4층 도전 실패, 보스 수습 인형 앞에서 무너졌다','대던전 3층 돌파 뒤 곧장 4층으로 내려갔다','대던전 3층 돌파 뒤 토르바로 돌아갔다'}
for _,text in ipairs(facts)do out.chronicle[#out.chronicle+1]={ko=text,en=B.chron_english(text)}end
local oldadd=B.bag_add
for _,size in ipairs({0,1999,2000,2001})do local bag={};for i=1,size do bag[i]='wa01.1.1'end
 B.bag_add=function(id,code)if #bag>=2000 then return false end;bag[#bag+1]=code;return true end
 local g=B.G_new();local got,lost=B.ex_gear_bank(g,'finish',{'wa01.2.1','wa01.3.1'})
 out.bank[#out.bank+1]={size=size,got=got,lost=lost,after=#bag}
end
B.bag_add=oldadd
local oldget,oldset=getChatVar,setChatVar;local raw=''
getChatVar=function(id,key)if key=='dk_bag'then return raw end;return oldget(id,key)end
setChatVar=function(id,key,value)if key=='dk_bag'then raw=value else oldset(id,key,value)end end
out.unknown_codes={}
for _,code in ipairs({'zz99.1.1','invalid'})do
 raw='';local g=B.G_new();g.persona.cls='warrior';g.equip={persona={weapon=code}}
 local got,lost=B.ex_gear_bank(g,'finish',{code});local bank=B.bag_load('finish');raw='';B.gear_restrict(g,'finish')
 out.unknown_codes[#out.unknown_codes+1]={code=code,bank={gear=got,lost=lost,bag=bank},restricted={equip=g.equip,bag=B.bag_load('finish')}}
end
getChatVar,setChatVar=oldget,oldset
return out
`);
const plain=s=>s.replace(/<[^>]*>/g,' ').replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/\s+/g,' ').trim();
for(const k of ['traits','heads','confirm','options','steps','nav'])for(const c of data[k]){
 c.text=plain(c.value);c.buttons=[...c.value.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/g)].map(m=>({id:m[1].match(/risu-btn="([^"]*)"/)?.[1]??'',text:plain(m[2]),disabled:/\boff\b/.test(m[1]),selected:/\bon\b|\bpick\b/.test(m[1])}));delete c.value;
}
data.sources=names.map((n,i)=>({file:'bot/src/'+n,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')}));
fs.writeFileSync(out+'/oracle.json',JSON.stringify(data)+'\n');console.log(JSON.stringify(Object.fromEntries(Object.entries(data).map(([k,v])=>[k,v.length]))));
}finally{if(sim.close)await sim.close()}
