// Read-only source Lua; observations are text, controls, bars and fallback identity.
import fs from 'node:fs';import path from 'node:path';import {pathToFileURL} from 'node:url';import crypto from 'node:crypto';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot',dir=root+'/verification/parity-r23/ui-phase4';fs.mkdirSync(dir,{recursive:true});
const names=['01-game.lua','05-gen.lua','10-data.lua','15-josa.lua','24-stats.lua','29-persona-skill.lua','34-traits.lua','60-create.lua','65-codex.lua','66-status.lua','67-settings.lua','68-cloud.lua','69-rank.lua','70-town.lua','74-affection.lua','74-level.lua','81-gear.lua','85-portrait.lua','86-portrait-have.lua','88-lore.lua','89-memory.lua'];
const raws=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const extra=names.map((n,i)=>(n==='68-cloud.lua'?`B.CLOUD={HOST='fixture.invalid',KEY_X={},KEY_M={},BUILD='fixture'}\n`:'')+`assert(load(${JSON.stringify(raws[i])},${JSON.stringify('@'+n)},'t',_ENV))()`).join('\n');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));const {L}=await mkSim({policy:false,extra});
const out=await L(`
local o={cases={},portraits={},packs={ui=B.ui_pack('en'),words=B.en_dict()},items=B.ITEMS}
local function add(id,fn,args,value)o.cases[#o.cases+1]={id=id,fn=fn,args=args,lang=B.LANG,value=value}end
local function cp(v)return json.decode(json.encode(v))end
for _,id in ipairs(B.CAST_ORDER)do for _,variant in ipairs({'default','smile','missing','bad variant',''})do
 o.portraits[#o.portraits+1]={id=id,variant=variant,asset=B.portrait_pick(id,variant) or '',html=B.portrait(id,variant) or ''}
end end
for _,lang in ipairs({'ko','en'}) do B.LANG=lang
 for _,v in ipairs({false,0,1,'','전사','없는 값'})do add('P2370','c1_en',{v},B.C1_en(v))end
 add('P2370','c1_en',{},B.C1_en(nil))
 for _,msg in ipairs({'','A &amp; B','<b>장비</b> &lt;검&gt;','<i>Levia</i><br>완료','&#39; &quot; &#x1F600;','A & B','<b>사용자 &lt;이름&gt;</b>'})do add('P2500','notice',{msg},B.PX.notice({ui={msg=msg}}))end
 for _,id in ipairs({'unknown','persona','levia','marceline','A_B',''})do
  for _,name in ipairs({'','이름','Alex','😀모험가','{{user}}','A & B'})do add('P2496','face',{id,name},B.PX.face(id,name,''))end
 end
 for _,id in ipairs(B.CAST_ORDER)do
  local G=B.G_new();G.roster={id};G.party={id};G.favs={id};G.lvl={[id]=40};G.aff={[id]=100.8}
  add('P2521','tile',{cp(G),id},B.PX.cx_tile(G,id));add('P2563','fav',{cp(G),id},B.PX.st_fav(G,id))
  G.roster={};add('P2521','tile',{cp(G),id},B.PX.cx_tile(G,id))
 end
 for _,a in ipairs({-100,-.5,0,99.9,100,199.9,200,999})do for _,party in ipairs({false,true})do
  local G=B.G_new();G.roster={'levia'};G.party=party and {'levia'} or {};G.favs={'levia'};G.aff={levia=a};G.lvl={levia=1};add('P2563','fav',{G,'levia'},B.PX.st_fav(G,'levia'))
 end end
 for id in pairs(B.ITEMS)do add('P2501','item_name',{id},B.PX.item_name(id))end
 for _,id in ipairs({'','missing','g1:bad:0','<name>'})do add('P2501','item_name',{id},B.PX.item_name(id))end
 for _,id in ipairs({false,0,7})do add('P2501','item_name',{id},B.PX.item_name(id))end
 add('P2501','item_name',{},B.PX.item_name(nil))
 for i,id in ipairs(B.gear().order)do local code=B.gear_code(id,100+i);add('P2501','item_name',{code},B.PX.item_name(code))end
 -- All public source U/T lookup keys. Non-public keys remain in the oracle only.
 for k in pairs(B.ui_pack('en'))do add('P0089 P0090 P0091','u',{k,{n=2,name='전사',gold=300,max=3,level='보통',old='없음',new='전사',cls='전사',el='불',lv=40,a=100}},B.U(k,{n=2,name='전사',gold=300,max=3,level='보통',old='없음',new='전사',cls='전사',el='불',lv=40,a=100}))end
 for k in pairs(B.en_dict())do add('P0092 P0095','t',{k},B.T(k))end
 for _,k in ipairs({'전사','뒤로','이름 없는 키','A & B','{unknown}'})do add('P0089 P0090','u',{k,{}},B.U(k,{}))end
end
local saved,savedraw=B.EN,B.EN_RAW
for _,raw in ipairs({'["one",false,3]','{}','null','broken'})do for _,v in ipairs({false,0,1,2,3,'1','missing'})do
 B.EN=nil;B.EN_RAW=raw;add('P2370','c1_custom',{raw,v},B.C1_en(v))
end end
B.EN,B.EN_RAW=saved,savedraw
return o
`);
const decode=s=>s.replace(/&quot;/g,'"').replace(/&#39;|&apos;/g,"'").replace(/&#x([0-9a-f]+);/gi,(_,n)=>String.fromCodePoint(parseInt(n,16))).replace(/&#([0-9]+);/g,(_,n)=>String.fromCodePoint(+n)).replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
const plain=s=>decode(s.replace(/<[^>]*>/g,' ').replace(/\{\{asset::[^}]+\}\}/g,'')).replace(/\s+/g,' ').trim();
for(const c of out.cases)if(['tile','fav','notice','face'].includes(c.fn)){
 c.expected={text:plain(c.value),bars:[...c.value.matchAll(/scaleX\(([^)]+)\)/g)].map(m=>+m[1]),buttons:[...c.value.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/g)].map(m=>({action:m[1].match(/risu-btn="([^"]*)"/)?.[1]??'',text:plain(m[2])})),favorite:/px-mark/.test(c.value)};
 if(c.fn==='face')c.expected={asset:c.value.match(/asset::([^}]+)/)?.[1]??'',initial:c.value.includes('px-ini')?plain(c.value):'',persona:c.value.includes('im-ph-persona')};
 delete c.value;
}
out.sources=names.map((n,i)=>({file:n,sha256:crypto.createHash('sha256').update(raws[i]).digest('hex')}));
const adult=/NSFW|섹스|성관계|성교|접대부|애무|자위|절정|삽입|발정|음란|정액|질내|유두|유방|(?<![가-힣])음부(?![가-힣])|음경|보지|자지|sx_|sex_/i;
const translations=path.resolve(src,'../design/i18n/en'),intimacy=JSON.parse(fs.readFileSync(translations+'/intimacy.json','utf8')),publicKeys=new Set();
for(const n of fs.readdirSync(translations).filter(n=>n.endsWith('.json')&&n!=='intimacy.json'))for(const k of Object.keys(JSON.parse(fs.readFileSync(translations+'/'+n,'utf8'))))publicKeys.add(k);
const adultOnly=new Set(Object.keys(intimacy).filter(k=>!publicKeys.has(k)));
out.excluded={};for(const section of ['ui','words']){out.excluded[section]=Object.keys(out.packs[section]).filter(k=>adult.test(k)||(section==='words'&&adultOnly.has(k)));for(const k of out.excluded[section])delete out.packs[section][k]}
out.cases=out.cases.filter(c=>!(c.fn==='u'&&out.excluded.ui.includes(c.args[0]))&&!(c.fn==='t'&&out.excluded.words.includes(c.args[0])));
fs.writeFileSync(dir+'/ui-oracle.json',JSON.stringify(out,null,2)+'\n');console.log(JSON.stringify({cases:out.cases.length,ui:Object.keys(out.packs.ui).length,words:Object.keys(out.packs.words).length}));
export {L,dir};
