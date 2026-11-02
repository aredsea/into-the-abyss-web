// Read-only oracle: current source handlers, not a translation of their rules.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'), source='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','24-stats.lua','29-persona-skill.lua','34-traits.lua','65-codex.lua','66-status.lua','74-affection.lua','74-level.lua','81-gear.lua','85-portrait.lua','86-portrait-have.lua'];
const raw=names.map(n=>fs.readFileSync(path.join(source,'src',n),'utf8'));
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:raw.join('\n')});
const data=await L(`
local function walk(t)
 if type(t)~='table' then return t end
 local o={};for k,v in pairs(t) do o[k]=type(v)=='table' and walk(v) or (type(v)=='string' and B.ptx(v) or v) end;return o
end
return {cast=B.CAST,order=B.CAST_ORDER,classes=B.CLASSES,cls=B.CLS,curves=B.CURVES,passives=walk(B.PASSIVES),have=B.PORTRAIT_HAVE,expr=B.PORTRAIT_EXPR,fx_order=B.PX.FX_ORDER,els=B.PX.EL,el_order=B.PX.EL_ORDER,slots=B.PX.SLOTS}
`);
const fixtures=await L(`
local out={lists={},actions={},stats={},persona={},aff={},portraits={},bags={},gear_actions={},compare={}}
local function cp(v)return json.decode(json.encode(v))end
local roster={'levia','marceline','naran','teiris','haldric'}
local function game()local G=B.G_new();G.scene='town';G.roster=cp(roster);G.party={'levia','teiris'};G.favs={};G.ui={tab='',sel='',page=1,msg=''};return G end
for _,rr in ipairs({{},roster,B.CAST_ORDER}) do
 local tabs={'','rec','el','cls','invalid'}
 for _,e in ipairs(B.PX.EL_ORDER) do tabs[#tabs+1]='el_'..e end
 for _,c in ipairs(B.CLASSES) do tabs[#tabs+1]='cls_'..c.id end
 for _,tab in ipairs(tabs) do local G=game();G.roster=rr;G.ui.tab=tab;out.lists[#out.lists+1]={owned=rr,tab=tab,value=B.PX.cx_list(G)} end
end
local G=game()
for _,arg in ipairs({'sel_bad','sel_levia','fav','sel_marceline','fav','sel_naran','fav','sel_teiris','fav','sel_levia','fav','sel_teiris','fav','back','pg_999','f_el_fire','me','open_bad','open_naran','bag','f_all'}) do
 local before=cp(G);B.H.cx(G,arg,'p7');out.actions[#out.actions+1]={before=before,arg=arg,value=cp(G)}
end
for _,cid in ipairs(B.CAST_ORDER) do for lv=1,40 do
 local G=game();G.roster=B.CAST_ORDER;G.lvl={[cid]=lv};local value=B.PX.cstats(G,cid)
 out.stats[#out.stats+1]={id=cid,level=lv,value=value}
end end
for _,c in ipairs(B.CLASSES) do for _,lv in ipairs({1,2,10,40}) do for _,bonus in ipairs({0,5,99}) do
 local G=game();G.persona={cls=c.name,lv=lv,stats={hp=c.hp,mp=c.mp,str=c.str+bonus,agi=c.agi+bonus,int=c.int+bonus,def=c.def+bonus,spd=c.spd+2*bonus}}
 local html=B.PX.st_persona(G);local values={};for k,v in html:gmatch('<small>([^<]+)</small><b>(%-?[%d%.]+)</b>') do values[k]=tonumber(v) end
 out.persona[#out.persona+1]={persona=G.persona,value=values}
end end end
for a=-110,210 do
 for _,f in ipairs({0,.25,.9}) do local v=a+f;out.aff[#out.aff+1]={a=v,stage=B.aff_stage(v),shown=B.PX.aff({aff={levia=v}},'levia')} end
end
for name in pairs(B.PORTRAIT_HAVE) do
 local id,v=name:match('^([a-z0-9]+)_portrait_([a-z_]+)$');out.portraits[#out.portraits+1]={id=id,variant=v,value=B.portrait_pick(id,v) or ''}
end
for _,id in ipairs({'marceline','nobody','','MARCELINE','../x','persona','dorothea'}) do for _,v in ipairs({'default','smile','Smile','../x','','not_here'}) do out.portraits[#out.portraits+1]={id=id,variant=v,value=B.portrait_pick(id,v) or ''} end end
local codes={};for i,gid in ipairs(B.gear().order) do codes[#codes+1]=B.gear_code(gid,1234+i) end
local saved_load=B.bag_load;B.bag_load=function(id)return cp(codes)end
local filters={{cls='',slot='',rar=''}}
for _,c in ipairs(B.CLASSES) do filters[#filters+1]={cls=c.id,slot='',rar=''} end
for _,s in ipairs(B.PX.SLOTS) do filters[#filters+1]={cls='',slot=s[1],rar=''} end
for _,r in ipairs(B.RARITY_ORDER) do filters[#filters+1]={cls='',slot='',rar=r} end
for _,S in ipairs(filters) do local list,total,n,g=B.PX.bg_list('p7',S);local order={};for _,e in ipairs(list) do order[#order+1]=e.c end;out.bags[#out.bags+1]={filter=S,codes=codes,value=order,total=total,common=n,gold=g} end
B.bag_load=saved_load
local bag={};B.bag_load=function()return cp(bag)end;B.bag_save=function(id,v)bag=cp(v)end
for _,rar in ipairs(B.RARITY_ORDER) do
 for _,gid in ipairs(B.gear().order) do if B.gear().items[gid].rarity==rar then bag[#bag+1]=B.gear_code(gid,77);break end end
end
local G=game();G.persona.cls='전사';G.persona.lv=40;G.lvl={levia=40,teiris=40};G.equip={};G.gold=100
for _,arg in ipairs({'f_rar_epic','sel_1','sell','back','sel_1','sell','sell','f_rar_all','sellc','f_cls_warrior','sel_1','cmp_persona','eq_persona','back','f_cls_all','pg_999','f_slot_bad','f_cls_bad'}) do
 local before=cp(G);local before_bag=cp(bag);B.H.bg(G,arg,'p7')
 out.gear_actions[#out.gear_actions+1]={before=before,bag=before_bag,arg=arg,value=cp(G),after_bag=cp(bag)}
end
for _,cls in ipairs(B.CLASSES) do
 local chosen={};for _,gid in ipairs(B.gear().order) do local it=B.gear().items[gid];if it.cls==cls.id and not chosen[it.rarity] then chosen[it.rarity]=gid end end
 for _,rar in ipairs(B.RARITY_ORDER) do for _,level in ipairs({1,10,20,40}) do for _,forge in ipairs({0,5}) do
  local code=B.gear_code(chosen[rar],8734567);local old=B.gear_code(chosen.common,33)
  local it=B.gear().items[chosen[rar]];local G=game();G.roster={};G.party={};G.persona.cls=cls.name;G.persona.lv=level;G.equip={persona={[it.slot]=old}};G.forge={[code]={lv=forge}};bag={code}
  local S={sel=code,cmp='persona',conf=''};local r=B.gear_roll(code,level,forge)
  out.compare[#out.compare+1]={code=code,old=old,level=level,forge=forge,fx=r.fx,affix=r.affix,html=B.PX.bg_detail(G,'p7',S)}
 end end end
end
return out`);
for(const f of fixtures.compare){f.table=[...f.html.matchAll(/<div class="bg-cr"><span>(.*?)<\/span><span>(.*?)<\/span><span>(.*?)<\/span><b class="[^"]*">(.*?)<\/b><\/div>/g)].map(m=>m.slice(1));delete f.html;}
const folder=path.join(root,'verification/panels-r22');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(root,'project/data/panels-r22.json'),JSON.stringify(data,null,2)+'\n');
fs.writeFileSync(path.join(folder,'oracle.json'),JSON.stringify(fixtures)+'\n');
fs.writeFileSync(path.join(folder,'provenance.json'),JSON.stringify({files:names.map((name,i)=>({name,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')})),contracts:['harness_panels.mjs','harness_portrait.mjs','harness_affection.mjs'],counts:Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])),source_write:false},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])));
sim.close?.();
