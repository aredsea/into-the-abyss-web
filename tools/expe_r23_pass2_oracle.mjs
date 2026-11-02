// Second pass: execute untouched canonical Lua; expose local references in memory.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..');
const source='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','72-guild.lua','74-level.lua','74-affection.lua','75-sortie.lua','76-dungeon.lua','77-explore.lua','78-battle-item.lua'];
const files=names.map(n=>({name:n,text:fs.readFileSync(path.join(source,'src',n),'utf8')}));
const extra=files.map(({name,text})=>'do\n'+(name==='75-sortie.lua'?text.replace('  local function cards(G)','  B.SO.r23_ordered=ordered\n  local function cards(G)'):text)+(name==='74-level.lua'?'\nB.R23_who=who\n':'')+(name==='76-dungeon.lua'?'\nB.R23_zone_title=zone_title\n':'')+(name==='77-explore.lua'?'\nB.R23P2={pname=pname,member_name=member_name,members=members,equip_key=equip_key,itname=itname,rar_of=rar_of,do_use=do_use,retreat=do_retreat}\n':'')+'\nend').join('\n');
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {sim,L}=await mkSim({lua:path.join(source,'dist/bot.lua'),policy:false,extra});
const persona=JSON.parse(fs.readFileSync(path.join(root,'verification/expedition-r22/save-specimens.json'),'utf8')).entry.persona;
const classes=JSON.parse(fs.readFileSync(path.join(root,'project/data/persona-r22.json'),'utf8')).classes.map(c=>c.name);
try {
 const out=await L(`
local P=json.decode([=[${JSON.stringify(persona)}]=])
local out={names={},formation={},ordered={},summary={},slots={},use={},rest={},retreat={},labels={},discovery={},zone_titles={}}
local function cp(x)return json.decode(json.encode(x))end
local function base()
 local G=B.G_new();G.persona=cp(P);G.persona.cls='전사';G.persona.lv=10;G.persona.fight=1;G.persona.name=''
 G.scene='dungeon';G.roster={'lynette','marceline','urda','haldric'};G.party={'lynette'};G.lvl={lynette=15,marceline=9,urda=10,haldric=40};G.exp={};G.items={};G.dungeon={best=2,sel=1,mode=1,pg=1,runs=0,cleared_bosses={}}
 return G
end
for _,name in ipairs({'','{{user}}','가온','A&B <tag>','  '})do
 local G=base();G.persona.name=name
 local values={};for _,id in ipairs({'persona','lynette','unknown',''})do values[id]=B.R23P2.member_name(G,{id=id})end
 for _,id in ipairs(B.CAST_ORDER)do values[id]=B.R23P2.member_name(G,{id=id})end
 local who={};for id,_ in pairs(values)do who[id]=B.R23_who(G,id)end
 out.names[#out.names+1]={name=name,value=B.SO.pname(G),explore=B.R23P2.pname(G),members=values,who=who}
end
for _,cls in ipairs(json.decode([=[${JSON.stringify([...classes,'unknown',''])}]=]))do for fight=0,1 do
 for _,party in ipairs({{}, {'lynette'}, {'urda','lynette','marceline','haldric'}, {'unknown','lynette','lynette','marceline','urda','haldric'}})do
  local G=base();G.persona.cls=cls;G.persona.fight=fight;G.party=cp(party)
  local row,label=B.SO.prow(G);local members=B.SO.members(G)
  out.formation[#out.formation+1]={cls=cls,fight=fight,party=party,clean=cp(G.party),row=row,label=label,members=members}
 end
end end
for _,filter in ipairs({'','front','back','all','invalid'})do for _,party in ipairs({{}, {'lynette'}, {'urda','marceline'}})do
 local G=base();G.ui.tab=filter;G.party=cp(party)
 out.ordered[#out.ordered+1]={filter=filter,party=party,value=B.SO.r23_ordered(G)}
end end
for _,lang in ipairs({'ko','en'})do for _,fight in ipairs({0,1})do for _,party in ipairs({{}, {'lynette'}, {'marceline','urda'}})do
 for _,q in ipairs({false,{}, {lv=0},{lv=1},{lv=14.9},{lv='20.9'},{lv='bad'},{lv=100},{difficulty='낮음'},{difficulty='중간'},{difficulty='높음'},{difficulty='엘리트'},{difficulty='bad',stars='3'},{stars=2}})do
  local G=base();G.persona.fight=fight;G.party=cp(party);local m=B.SO.members(G);B.LANG=lang
  out.summary[#out.summary+1]={lang=lang,fight=fight,party=party,q=q,value=B.SO.summary(G,q or nil,m)}
 end
end end end
B.LANG='ko'
for mask=0,15 do
 local pm={};for i=1,4 do pm[i]={id=(mask & (1 << (i-1)))~=0 and ({'persona','lynette','urda','marceline'})[i] or '',cls='warrior',L=15,extra={keep=i}}end
 local R={pm=pm};local keys={};for i=0,5 do keys[#keys+1]=B.R23P2.equip_key(R,i) or false end
 out.slots[#out.slots+1]={pm=pm,value=B.R23P2.members(R),keys=keys}
end
for _,phase in ipairs({'explore','rest','battle','done'})do for _,ask in ipairs({false,true})do for _,arg in ipairs({'retreat','retreat_no','retreat_yes'})do
 local G=base();local pm,n,avg=B.dn_party(G);G.dungeon.run=B.ex_new(G,1,pm,n,avg,7);local R=G.dungeon.run;R.phase=phase;R.ask=ask;R.loot.gold=21
 B.R23P2.retreat(G,'r23-pass2',arg)
 out.retreat[#out.retreat+1]={phase=phase,ask=ask,arg=arg,value={ask=R.ask,phase=R.phase,gold=G.gold}}
end end end
for _,iid in ipairs({'hp_s','mp_s','bandage','sh_s','antidote','unknown'})do for _,phase in ipairs({'explore','rest','battle','done'})do for _,hp in ipairs({0,1,101})do
 local G=base();G.persona.name='{{user}}';local pm,n,avg=B.dn_party(G);G.dungeon.run=B.ex_new(G,1,pm,n,avg,7);local R=G.dungeon.run;R.phase=phase;R.hp={hp,1,0,0};R.mp={1,1,0,0};R.mhp={101,101,0,0};R.mmp={71,71,0,0};R.last='before';R.log={'old'};G.items[iid]=1
 B.R23P2.do_use(G,'r23-pass2',iid,1)
 out.use[#out.use+1]={id=iid,phase=phase,hp=hp,value={hp=R.hp[1],mp=R.mp[1],last=R.last,log=R.log,stock=G.items[iid] or 0}}
end end end
for _,hp in ipairs({0,1,100,101})do for _,mp in ipairs({0,1,70,71})do
 local G=base();G.persona.name='가온';G.party={};local pm,n,avg=B.dn_party(G);G.dungeon.run=B.ex_new(G,1,pm,n,avg,7);local R=G.dungeon.run;R.hp={hp,0,0,0};R.mp={mp,0,0,0};R.mhp={101,0,0,0};R.mmp={71,0,0,0}
 B.ex_enter_rest(G,'r23-pass2',R)
 out.rest[#out.rest+1]={hp=hp,mp=mp,value={hp=R.hp[1],mp=R.mp[1],last=R.last,log=R.log,phase=R.phase,ask=R.ask}}
end end
for _,floor in ipairs({1,3,18,28})do for seed=1,50 do
 local G=base();G.persona.name='가온';G.party={};local pm,n,avg=B.dn_party(G);G.dungeon.run=B.ex_new(G,floor,pm,n,avg,7);local R=G.dungeon.run
 R.seed=seed;R.step=seed%5;R.hp={1,0,0,0};R.mp={1,0,0,0};R.mhp={101,0,0,0};R.mmp={71,0,0,0};R.last='before'
 local run=B.run;B.run=function()end;B.H.ex(G,'go','r23-pass2');B.run=run
 out.discovery[#out.discovery+1]={floor=floor,seed=seed,step=seed%5,value={phase=R.phase,step=R.step,elites=R.elites,last=R.last,log=R.log,gold=R.loot.gold,items=R.loot.items,gear=R.loot.gear,hp=R.hp[1],mp=R.mp[1]}}
end end
local function label(iid)
 local value={id=iid,name=B.R23P2.itname(iid),rarity=B.R23P2.rar_of(iid) or false,gear=B.C1_gear_label(iid),english=B.C1_en_gear_label(iid)}
 B.LANG='en';value.ui_english=B.C1_gear_label(iid);B.LANG='ko'
 out.labels[#out.labels+1]=value
end
for _,iid in ipairs({'hp_s','sh_s','bandage','unknown','wa01.1.1','wa01.bad.1','wa01','','wa01.1.99','wa01.0.1','wa01.zzzzzzzzzzzz.1','wa01.1234567890123.1','wa01.1.01','UPPER.1.1'})do
 label(iid)
end
local source_item_ids={};for iid in pairs(B.ITEMS)do source_item_ids[#source_item_ids+1]=iid end;table.sort(source_item_ids)
for _,iid in ipairs(source_item_ids)do label(iid)end
for _,iid in ipairs(B.gear().order)do for _,seed in ipairs({1,31,2147483646})do
 local code=B.gear_code(iid,seed)
 label(code)
end end
for _,lang in ipairs({'ko','en'})do
 B.LANG=lang
 for floor=1,420 do out.zone_titles[#out.zone_titles+1]={lang=lang,floor=floor,value=B.R23_zone_title(B.floor_info(floor))}end
end
B.LANG='ko'
return out
`);
 const dir=path.join(root,'verification/parity-r23');
 fs.writeFileSync(path.join(dir,'expe-pass2-oracle.json'),JSON.stringify(out,null,2)+'\n');
 const base_files=['dist/bot.lua','lua_sim.mjs','first_mes.html','src/01-game.lua','src/81-gear.lua'].map(file=>({file:'bot/'+file,sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(source,file))).digest('hex')}));
 fs.writeFileSync(path.join(dir,'expe-pass2-provenance.json'),JSON.stringify({source,base_files,files:files.map(f=>({file:'bot/src/'+f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')})),counts:Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])),method:'Canonical mkSim/Wasmoon; fixed canonical dist/bot.lua base (no LUA environment override), reloaded listed source chunks, only expose local references in loaded chunks. Full guild gd_qlv, no replacement.'},null,2)+'\n');
 console.log(JSON.stringify(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length]))));
} finally {if(sim.close)await sim.close();}
