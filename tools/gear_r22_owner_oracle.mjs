// Execute the real owner functions for effects read outside 81-gear's GH slot.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const names=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','30-engine.lua','34-traits.lua','81-gear.lua'];
const raw=names.map(n=>fs.readFileSync(src+'/src/'+n,'utf8'));
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:raw.join('\n')});
const out=await L(`
local out={evade={},blood={},snipe={},shadow={},warp={},crit={},dot={}}
local function uniq(key)for _,id in ipairs(B.gear().order)do local e=B.gear().items[id].unique;if e and e.key==key then return e end end end
local rnd=B.rnd
for _,na in ipairs({'','naerin'}) do for _,q in ipairs({0,1,15,100}) do for s=1,40 do for _,prior in ipairs({false,true})do
 local st={u={{na=na,gq={evade=q}}},rs=s*7919+13};local before=st.rs;local value=B.GH.evade(st,prior,1,5)
 out.evade[#out.evade+1]={unit=st.u[1],seed=before,value=value or false,rs=st.rs,base=na=='naerin' and .01 or 0,prior=prior}
end end end end
B.hpc=nil
for _,equipped in ipairs({false,true})do for hp=1,200 do
 local u={mhp=hp,gu=equipped and {uniq('gl_boil')} or nil}
 out.blood[#out.blood+1]={unit=u,base=B.floor(hp*.15),value=B.blood_cost({u={u}},1)}
end end
local attack
B.attack=function(st,a,t,o)attack=o end;B.trait_line=function()end
for _,equipped in ipairs({false,true})do
 local u={gu=equipped and {uniq('ar_wind')} or nil}
 B.RUN.snipe({u={u}},1,5)
 out.snipe[#out.snipe+1]={unit=u,crit=attack.cc,mp=B.mpb({u={u}},1,{id='snipe',mp=17})}
end
B.DEF={{name='시험',clsid='assassin'},{name='상대'}}
for _,equipped in ipairs({false,true})do for n=0,100 do
 local u={al=1,gu=equipped and {uniq('as_shadow')} or nil};attack=nil;B.rnd=function()return n/100 end
 B.GH.extra_hit({u={u,{al=1}}},1,2,{name='일반 공격'},{kill=0},0)
 out.shadow[#out.shadow+1]={unit=u,draw=n/100,value=attack~=nil}
end end
B.push=function()end;B.say=function()end
for _,equipped in ipairs({false,true})do for _,boss in ipairs({0,1})do
 local u={gu=equipped and {uniq('sa_warp')} or nil,x={},g=0};local v={g=10000,rd=boss}
 local st={u={u,v},ev={T=0},cur=1};local mult=B.rdm(v);B.RUN.burst(st,1,2)
 out.warp[#out.warp+1]={unit=u,mult=mult,delay=v.g-10000,adv=u.x.adv or false}
end end
B.rnd=function()return 0 end;B.chain_at=function(st,ev,pos,args)return args[pos]end;B.GH.crit=nil;B.bget=function()return 0 end
for _,base_cm in ipairs({1.5,2,3.5})do for _,extra in ipairs({0,5,48,100})do
 B.bhas=function()return false end
 local u={cs=50,cr=5,ag=0,gq={critdmg=extra}};local v={de=0,dr=0};local st={u={u,v},K=1}
 local d=B.hit(st,1,2,{m=1,cc=100,cm=base_cm})
 out.crit[#out.crit+1]={unit=u,base=base_cm,value=d}
end end
B.GH.dotmul=nil;B.rnd=rnd
local sum
B.strike=function(st,i,d)sum=d;return {d=d,kill=0}end
for _,bu in ipairs({0,25,50,100})do for _,n0 in ipairs({1,3,5})do
 local st={u={{dot={{d=101,n=1,n0=n0,bu=bu}}}},ev={T=0}}
 B.dot_tick(st,1)
 out.dot[#out.dot+1]={line={d=101,n=0,n0=n0,bu=bu},value=sum-101}
end end
return out`);
fs.writeFileSync(root+'/verification/gear-r22/owner-oracle.json',JSON.stringify(out)+'\n');
fs.writeFileSync(root+'/verification/gear-r22/owner-provenance.json',JSON.stringify({files:names.map((name,i)=>({name,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')})),functions:['GH.evade','blood_cost','RUN.snipe','mpb','GH.extra_hit','RUN.burst','hit','dot_tick'],counts:Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length]))},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(out).map(([k,v])=>[k,v.length])));sim.close();
