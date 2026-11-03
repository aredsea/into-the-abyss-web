import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/compose.json',JSON.stringify(pack.coverage));return pack.result;}};};
import {isDeepStrictEqual as __r23_equal} from 'node:util';
const __r23_write=fs.writeFileSync.bind(fs);
fs.writeFileSync=(file,data,...args)=>{const name=String(file).replaceAll('\\','/');
 if((name.startsWith('verification/parity-r23/')||name.startsWith('verification/data-r21/'))&&!name.includes('/coverage/')&&name.endsWith('.json')){
  const expected=JSON.parse(fs.readFileSync(file,'utf8')),got=JSON.parse(String(data));
  if(expected&&typeof expected==='object')delete expected.provenance;
  if(got&&typeof got==='object')delete got.provenance;
  for(const value of [expected,got])if(value?.parts)for(const part of value.parts){delete part.bytes;delete part.sha256;}
  if(!__r23_equal(expected,got))throw Error('Instrumentation changed oracle: '+name);
  return;
 }return __r23_write(file,data,...args);
};
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua'];
const raw=files.map(f=>fs.readFileSync(path.join('C:/Users/asone/Documents/Codex/2026-10-30/into-the-abyss-handoff/work/r21-a-data/verification/parity-r23/coverage/instrumented',f),'utf8'));
const extra=raw.map((s,i)=>`do\n${s}\n${files[i]==='27-compose.lua'?'B.r23_compose_helpers={pools=pools,has_summon=has_summon,has_charge=has_charge,fits=fits,pickl=pickl}':''}\nend`).join('\n');
const {L}=await mkSim({policy:false,extra});
const result=await L(`
local H=B.r23_compose_helpers
local out={pools=H.pools(),flags={},flag_boundaries={},fits={},random={},compositions={}}
for _,id in ipairs(B.FOE_ORDER) do
 local f=B.FOES[id]
 out.flags[#out.flags+1]={id=id,summon=H.has_summon(f),charge=H.has_charge(f)}
 local specs={{},{grade={'boss'}},{grade={}},{role={'돌격'}},{role={}},{row='front'},{row='back'}}
 local currents={{},{id},{id,id,id},{id,id,id,id},{'raging_lecturer'},{'apprentice_doll','rusted_shieldman'}}
 for _,spec in ipairs(specs) do for _,cur in ipairs(currents) do out.fits[#out.fits+1]={id=id,spec=spec,cur=cur,expected=H.fits(f,cur,spec)} end end
end
-- Test-only action-list shapes, using canonical summon/charge kinds. No
-- additional enemy or action is added to the game catalog.
for variant=0,5 do
 local f={acts={}}
 if variant==1 then f.acts={{kind='summon'}} end
 if variant==2 then f.ph2={acts={{kind='summon'}}} end
 if variant==3 then f.ph2={acts={},entry={kind='summon'}} end
 if variant==4 then f.ph2={acts={},entry={kind='guard'}} end
 if variant==5 then f.acts={{kind='charge'}} end
 out.flag_boundaries[#out.flag_boundaries+1]={variant=variant,summon=H.has_summon(f),charge=H.has_charge(f)}
end
for _,seed in ipairs({-2147483647,-2147483646,-1,0,1,2147483645,2147483646,2147483647,9007199254740991}) do
 local rng=B.mkrng(seed);local values,states={},{};for i=1,8 do values[i]=rng();states[i]=math.floor(values[i]*2147483647+.5) end
 local picks={};rng=B.mkrng(seed);for i=1,8 do picks[i]=H.pickl(rng,{'a','b','c'}) end
 out.random[#out.random+1]={seed=string.format('%.0f',seed),expected=values,states=states,picks=picks}
end
for _,floor in ipairs({1,2,3,26,27,28,29,54,55,420}) do for n=1,4 do for _,seed in ipairs({0,1,2147483646}) do for _,kind in ipairs({'battle','elite','chief','boss'}) do
 local ctx={floor=floor,party_n=n,kind=kind};out.compositions[#out.compositions+1]={seed=seed,ctx=ctx,expected=B.compose(seed,ctx)}
end end end end
out.cached_pools=H.pools()
return out`);
for(const row of result.fits)if(Array.isArray(row.spec)&&row.spec.length===0)row.spec={};
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
fs.writeFileSync('verification/parity-r23/compose-oracle.json',JSON.stringify({...result,provenance})+'\n');console.log(JSON.stringify(Object.fromEntries(Object.entries(result).map(([k,v])=>[k,Array.isArray(v)?v.length:'map']))));process.exit(0);
