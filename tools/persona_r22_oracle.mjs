// Reload the six P1 source files in the original Wasmoon harness. Source is read-only.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..');
const source='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','24-stats.lua','34-traits.lua','01-game.lua','20-state.lua','26-start.lua','60-create.lua','74-level.lua','75-sortie.lua'];
const raw=names.map(n=>fs.readFileSync(path.join(source,'src',n),'utf8'));
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:raw.join('\n')});
const data=await L(`return {races=B.CR.RACES,lineages=B.CR.LINEAGES,nations=B.CR.NATIONS,blocked=B.CR.BAR,notes=B.CR.NOTE,classes=B.CLASSES,descriptions=B.CR.CLS_D,class_notes=B.CR.CLS_NOTE,lines=B.CR.LINE,stats=B.CR.STATS,steps=B.CR.STEPS,scenarios=B.CR.scens()}`);
const fixtures=await L(`
local out={actions={},totals={},levels={},party={},awards={},bonus={},migration={}}
local function cp(v) return json.decode(json.encode(v)) end
local function view(G) return {persona=cp(G.persona),scene=G.scene,page=G.ui.page,sel=G.ui.sel or '',scenario=G.scenario,roster=cp(G.roster),party=cp(G.party),gold=G.gold} end
local function act(G,arg,kind)
 local before=view(G); B.H[kind or 'cr'](G,arg,'p1-oracle')
 out.actions[#out.actions+1]={before=before,arg=arg,kind=kind or 'cr',value=view(G)}
end
for _,race in ipairs(B.CR.RACES) do for _,nat in ipairs(B.CR.NATIONS) do
 local G=B.G_new();act(G,'next');act(G,'race_'..race.id);act(G,'lin_dog');act(G,'next');act(G,'nat_'..nat.id);act(G,'next');act(G,'race_human');act(G,'race_elf');act(G,'nat_naerin');act(G,'race_halfelf')
end end
for _,c in ipairs(B.CLASSES) do for _,t in ipairs({0,1,5,10,20,37,99}) do
 local G=B.G_new();act(G,'race_human');act(G,'nat_border');act(G,'cls_'..c.id)
 B.CR.set_total(B.CR.P(G),t,true)
 for _,arg in ipairs({'auto','up_spd','dn_def','up_int','clear','auto','tot_5','tot_free','tot_p5','tot_m1','tot_m5','tot_20','auto','next','go_5','done'}) do act(G,arg) end
 for _,s in ipairs(B.CR.scens()) do local H=cp(G);act(H,'pick_'..s.id,'sc');act(H,'go','sc');act(H,'go','sc') end
end end
for t=-5,105 do
 local p={cls='사제',bonus={str=23,agi=22,int=21,def=20,spd=19}}
 local cut=B.CR.set_total(p,t,true)
 out.totals[#out.totals+1]={input=t,value=cp(p),cut=cut,cap=B.CR.cap(B.CR.total(p))}
end
for L=-2,43 do for _,x in ipairs({0,27,28,500,1000000}) do
 local G=B.G_new();G.persona.lv=L;G.persona.exp=x;B.exp_give(G,'persona',0)
 out.levels[#out.levels+1]={lv=L,xp=x,value=cp(G.persona),need=B.exp_need(L)}
end end
for _,fight in ipairs({0,1}) do for _,party in ipairs({{}, {'levia'}, {'levia','teiris','naran','marceline'}, {'bad','levia','levia','teiris','naran','marceline'}}) do
 local G=B.G_new();G.scene='sortie';G.persona.cls='궁수';G.persona.fight=fight;G.roster={'levia','teiris','naran','marceline'};G.party=cp(party)
 local before=cp(G);local clean=cp(B.SO.clean(G));local pm=cp(B.battle_pm(G))
 out.party[#out.party+1]={fight=fight,party=party,roster=G.roster,clean=clean,pm=pm}
 for _,xp in ipairs({1,29,1000,1000000}) do
  local H=cp(G);local st={exp=xp,pm=pm,sid=7};local lines,gains=B.award_exp(H,st);local once=cp(H);local again,twice=B.award_exp(H,st)
  out.awards[#out.awards+1]={before=G,xp=xp,pm=pm,gains=gains,value=H,duplicate=#again==0 and next(twice)==nil}
 end
end end
for _,c in ipairs(B.CLASSES) do for _,lv in ipairs({1,10,40}) do for _,b in ipairs({0,3,99}) do
 local G=B.G_new();G.persona.cls=c.name;G.persona.lv=lv;G.persona.bonus={str=b,agi=b,int=b,def=b,spd=b};G.persona.stats=B.CR.calc(G.persona)
 local pm=B.battle_pm(G);local st=B.fresh(1,nil,{pm=pm,el=1,star=1});B.bind(st)
 out.bonus[#out.bonus+1]={cls=c.name,lv=lv,b=b,calc=G.persona.stats,unit={hp=st.u[1].mhp,mp=st.u[1].mmp,cs=st.u[1].cs,ag=st.u[1].ag,sp=st.u[1].sp}}
end end end
for _,scene in ipairs({'town','battle','shop','create'}) do local G={scene=scene,gold=555,party={'levia'},roster={'levia'},lv=7};local H=B.G_migrate(G);out.migration[#out.migration+1]={scene=scene,value=H} end
return out`);
const folder=path.join(root,'verification/persona-r22');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(root,'project/data/persona-r22.json'),JSON.stringify(data,null,2)+'\n');
fs.writeFileSync(path.join(folder,'oracle.json'),JSON.stringify(fixtures)+'\n');
fs.writeFileSync(path.join(folder,'provenance.json'),JSON.stringify({files:names.map((n,i)=>({name:n,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')})),contracts:['harness_create.mjs','harness_persona_bonus.mjs','harness_party.mjs','harness_sortie.mjs'],method:'Original source reloaded; direct Lua handlers and functions; no AI, sexual scene, host request, or original file write.'},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])));
if(sim.close)await sim.close();
