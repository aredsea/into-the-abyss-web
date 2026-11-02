import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';
const {mkSim}=await import(pathToFileURL(root+'/bot/lua_sim.mjs'));
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua'];
const {L}=await mkSim({policy:false,extra:files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(root+'/bot/src/'+f,'utf8')}\nend`).join('\n')});
const result=await L(`
local out={initial={},skills={}}
local races={"인간","엘프","악마","하프엘프","녹스","수인"}
local nations={"신성 세레디아 제국","대카라쉰","솔렌 성왕국","마렌토 공화국","나에린","모르가스 신관국","케른 연방","경계도시"}
local function view(st)
 local out={}
 for i,u in ipairs(st.u) do
  local bf={} for k,v in pairs(u.bf or {}) do bf[k]={v=v.v,n=v.n,f=v.f or false} end
  local dot={} for _,v in ipairs(u.dot or {}) do dot[#dot+1]={d=v.d,n=v.n} end
  out[i]={hp=u.hp,mp=u.mp,sh=u.sh,g=u.g,ay=u.ay,cs=u.cs,de=u.de,ag=u.ag,cr=u.cr,sp=u.sp,mhp=u.mhp,mmp=u.mmp,bf=bf,dot=dot,regen=u.x and u.x.psrg or false}
 end return out
end
local run0=B.run;B.run=function()end
for _,entry in ipairs(B.CLASSES) do local c=B.cls_of(entry.id)
 for _,race in ipairs(races) do for _,nat in ipairs(nations) do for _,lv in ipairs({1,10,40}) do
  local ps=json.decode(json.encode(c.base));ps.str=ps.str+2;ps.agi=ps.agi+1;ps.spd=ps.spd+4
  local pm={{id="persona",cls=c.id,L=lv,ps=ps,race=race,lin="고양이과",nat=nat},{id="hildegard",cls="warrior",L=lv},{id="felice",cls="priest",L=lv},{id="sorel",cls="priest",L=lv}}
  -- Companion classes must come from their source catalog, not from this harness.
  for i=2,4 do pm[i].cls=B.cls_of(B.CAST[pm[i].id].cls).id end
  local st=B.fresh(1,nil,{pm=pm,enc={fl={"apprentice_doll","apprentice_doll"},fg={},ne=2,star=1,raid=false},el=10})
  out.initial[#out.initial+1]={pm=pm,cls=c.name,units=view(st)}
 end end end
 for _,p in ipairs(B.PERSONA.prefixes) do for _,q in ipairs(B.PERSONA.suffixes) do if B.ps_compatible(p,q) then for lv=0,10 do
  local raw={prefix=p.id,suffix=q.id,prefix_lv={[p.id]=lv},suffix_lv={[q.id]=lv}}
  local pm={{id="persona",cls=c.id,L=10,skill=raw},{id="felice",cls=B.cls_of(B.CAST.felice.cls).id,L=10},{id="naran",cls="archer",L=10},{id="sorel",cls=B.cls_of(B.CAST.sorel.cls).id,L=10}}
  local st=B.fresh(1,nil,{pm=pm,enc={fl={"apprentice_doll","apprentice_doll"},fg={},ne=2,star=1,raid=false},el=10})
  st.cur=1;st.n=0;st.tk=0;st.rd=0
  for i,u in ipairs(st.u) do u.hp=(i<=4) and 50 or 1000;u.mhp=1000;u.sh=0;u.mp=100;u.mmp=100;u.g=10000;u.bf={};u.dot={};u.x={};u.ay=100;u.ym=100;u.dr=0;u.mk=0;u.fx=0;u.rc="";u.na="";u.ln="";u.tau=0 end
  B.begin_ev(st);B.rbegin(st);B.ACT=st.u[1];B.SKON=true
  B.PRUN.persona(st,1,p.target=="ally" and 2 or 5,B.ps_skill(raw));B.ACT=nil;B.SKON=nil
  out.skills[#out.skills+1]={pm=pm,cls=c.name,raw=raw,units=view(st),rng=st.rs,seed=st.seed}
 end end end end
end
B.run=run0
return out`);
result.provenance=Object.fromEntries(files.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(root+'/bot/src/'+f)).digest('hex')]));
fs.writeFileSync('verification/data-r21/a8-persona-oracle.json',JSON.stringify(result)+'\n');
console.log(JSON.stringify({initial:result.initial.length,skills:result.skills.length}));process.exit(0);
