import {L,dir} from './ui_r23_phase4_oracle.mjs';import fs from 'node:fs';
const out=await L(`
local o={settings={},bags={},details={},codex={},status={},codex_detail={}}
local function cp(v)return json.decode(json.encode(v))end
local oldbag=B.bag_load;local bag={};B.bag_load=function()return bag end
for _,lang in ipairs({'ko','en'})do B.LANG=lang
 for _,id in ipairs(B.CAST_ORDER)do
  local G=B.G_new();G.settings.nsfw=0;G.roster={id};G.favs={id};G.aff={[id]=99.9};G.lvl={[id]=40};bag={};B.VID='ui-phase4'
  o.codex_detail[#o.codex_detail+1]={id=id,lang=lang,g=cp(G),html=B.PX.cx_detail(G,id)}
 end
 for _,cls in ipairs({'','전사','암살자','궁수','공인 마법사','비공인 마법사','성기사','사제','연금술사','검투사','심연 마도사','unknown'})do for _,full in ipairs({false,true})do
  local G=B.G_new();G.persona.cls=cls;G.persona.race='인간';G.persona.nation='경계도시';G.persona.name='A & B';G.persona.fight=full and 0 or 1
  if full then G.roster={'levia','naran'};G.favs={'levia','naran','unknown'};G.aff={levia=100,naran=-20};G.party={'naran'}end
  o.status[#o.status+1]={lang=lang,g=cp(G),html=B.PX.st_me(G)}
 end end
 for _,owned in ipairs({{}, {'levia','naran','marceline'},B.CAST_ORDER})do for _,tab in ipairs({'','rec','el','el_fire','cls','cls_warrior','bad'})do for _,pg in ipairs({1,999})do
  local G=B.G_new();G.roster=cp(owned);G.favs={'naran'};G.aff={naran=99.9};G.ui.tab=tab;G.ui.page=pg
  o.codex[#o.codex+1]={lang=lang,g=cp(G),html=B.PX.cx_listview(G)}
 end end end
 for _,diff in ipairs({-1,0,1,2,3,4,'bad','2.9'})do for _,chron in ipairs({0,1})do
  local G=B.G_new();G.settings={lang=lang,diff=diff,chron=chron,form=0};G.ui.panel='settings'
  o.settings[#o.settings+1]={lang=lang,diff=diff,chron=chron,notes={lang=B.U('화면과 AI 답변의 언어입니다. 바꾸면 다음 화면과 다음 답변부터 적용됩니다.'),chron=B.U('층 돌파, 동료 합류, 호감 단계 변화, 레벨업 같은 확정된 일을 한 줄씩 적어 두고, 최근 15줄을 AI에게 알려 줍니다. 끄면 기록도 멈춥니다.')},html=B.PANELS.settings(G,'ui-phase4')}
 end end
 for _,count in ipairs({0,1,20,21,41})do
  bag={};for i=1,count do bag[i]=B.gear_code(B.gear().order[i],100+i)end
  for _,pg in ipairs({1,2,999})do for _,filter in ipairs({'','warrior','bad'})do
   local G=B.G_new();G.ui.bg={pg=pg,cls=filter,slot='',rar='',sel='',cmp='',conf=''}
   local h=B.PX.bg_view(G,'ui-phase4');o.bags[#o.bags+1]={lang=lang,bag=cp(bag),state=cp(G.ui.bg),input_page=pg,html=h}
  end end
 end
 for _,cls in ipairs(B.CLASSES)do for _,rarity in ipairs({'common','fine','rare','epic','legend'})do for _,lv in ipairs({1,40})do
  local gid,old
  for _,id in ipairs(B.gear().order)do local it=B.gear().items[id];if it.cls==cls.id and it.slot=='weapon' and it.rarity==rarity then gid=gid or id end;if it.cls==cls.id and it.slot=='weapon' and it.rarity=='common' then old=old or id end end
  if gid then
   local code=B.gear_code(gid,1235);local oldcode=B.gear_code(old,4242);bag={code}
   local G=B.G_new();G.persona.cls=cls.name;G.persona.lv=lv;G.persona.name='A & B';G.equip.persona={weapon=oldcode};G.ui.bg={pg=1,cls='',slot='',rar='',sel=code,cmp='',conf=''}
   o.details[#o.details+1]={lang=lang,cls=cls.name,level=lv,bag=cp(bag),old=oldcode,selected=code,html=B.PX.bg_view(G,'ui-phase4')}
  end
 end end end
 for _,mode in ipairs({'no_target','other_class','multi','empty_old','confirmed','forged'})do
  local gid,old;for _,id in ipairs(B.gear().order)do local it=B.gear().items[id];if it.cls=='warrior' and it.slot=='armor' and it.rarity=='legend'then gid=gid or id end;if it.cls=='warrior' and it.slot=='armor' and it.rarity=='rare'then old=old or id end end
  local code=B.gear_code(gid,1235);local oldcode=B.gear_code(old,4242);bag={code};local G=B.G_new();G.persona.cls='전사';G.persona.lv=40;G.persona.name='A & B';G.equip.persona={armor=oldcode};G.ui.bg={pg=1,cls='',slot='',rar='',sel=code,cmp='',conf=''}
  if mode=='no_target'then G.persona.cls=''end
  if mode=='other_class'then G.persona.cls='궁수'end
  if mode=='multi'then for _,id in ipairs(B.CAST_ORDER)do if B.CAST[id].cls=='전사'then G.roster[#G.roster+1]=id;G.lvl[id]=40 end end;G.party={G.roster[1]};G.ui.bg.cmp=G.roster[#G.roster]end
  if mode=='empty_old'then G.equip.persona={}end
  if mode=='confirmed'then G.ui.bg.conf=code end
  if mode=='forged'then G.forge[code]={lv=2,tries=0};G.forge[oldcode]={lv=1,tries=0}end
  o.details[#o.details+1]={lang=lang,mode=mode,g=cp(G),cls=G.persona.cls,level=40,bag=cp(bag),old=oldcode,selected=code,html=B.PX.bg_view(G,'ui-phase4')}
 end
end
B.bag_load=oldbag;return o
`);
const plain=s=>s.replace(/<[^>]*>/g,' ').replace(/\{\{asset::[^}]+\}\}/g,'').replace(/&quot;/g,'"').replace(/&#39;/g,"'").replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&').replace(/\s+/g,' ').trim();
for(const c of [...out.bags,...out.details,...out.codex,...out.status,...out.codex_detail]){c.expected={text:plain(c.html),bars:[...c.html.matchAll(/scaleX\(([^)]+)\)/g)].map(m=>+m[1]),buttons:[...c.html.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/g)].map(m=>({action:m[1].match(/risu-btn="([^"]*)"/)?.[1]??'',text:plain(m[2]),selected:/\bon\b/.test(m[1]),disabled:/\boff\b/.test(m[1])}))};delete c.html}
for(const c of out.settings){c.buttons=[...c.html.matchAll(/<button\b([^>]*)>([\s\S]*?)<\/button>/g)].filter(m=>/risu-btn="op_(lang|diff|chron)_/.test(m[1])).map(m=>({action:m[1].match(/risu-btn="([^"]*)"/)[1],text:plain(m[2]),selected:/\bon\b/.test(m[1])}));for(const key of ['lang','chron'])c.notes[key]=c.notes[key].replaceAll('과 AI 답변','').replaceAll('과 다음 답변','').replaceAll('두고, 최근 15줄을 AI에게 알려 줍니다.','둡니다.').replaceAll(" and the AI's replies",'').replaceAll(' and the next reply','').replaceAll(' The latest 15 entries are shared with the AI.','');delete c.html}
fs.writeFileSync(dir+'/ui-screens-oracle.json',JSON.stringify(out,null,2)+'\n');console.log(JSON.stringify({settings:out.settings.length,bags:out.bags.length,details:out.details.length}));
