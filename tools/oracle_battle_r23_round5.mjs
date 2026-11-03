// Run canonical source bodies with access-only exports for private closures.
import fs from 'node:fs';
let code=fs.readFileSync('tools/oracle_battle_r23_round4_loader.mjs','utf8');
code=code.replace("const extra='B.__batch={}\\n'", `
patches['40-fx.lua'].push(['function B.fx_dn','B.__batch.fx_put=put\\nfunction B.fx_dn']);
patches['50-render.lua'].push(['-- (최상위 local','B.__batch.numspan=numspan;B.__batch.chip=chip\\n-- (최상위 local']);
patches['50-render.lua'].push(['function B.r_rail','B.__batch.tile=tile\\nfunction B.r_rail']);
patches['50-render.lua'].push(['  local p = {}','  B.__batch.bzo=bzo\\n  local p = {}']);
patches['51-raid.lua'].push(['function B.r_boss','B.__batch.pips=pips\\nfunction B.r_boss']);
const extra='B.__batch={}\\n'`);
code=code.replaceAll('tools/oracle_battle_r23_round4.lua','tools/oracle_battle_r23_round5.lua');
code=code.replace('const {L}=await mkSim','const {L,sim}=await mkSim');
code=code.replace("const result=await L(fresh+'\\n'+fs.readFileSync('tools/oracle_battle_r23_round5.lua','utf8'));", "let result;try{result=await L(fresh+'\\n'+fs.readFileSync('tools/oracle_battle_r23_round5.lua','utf8'));}catch(e){console.log(sim.errors,sim.logs);throw e;}");
code=code.slice(0,code.indexOf('// Lua empty tables'))+`
// Schema conversion is limited to known maps. Arrays and primitive types remain exact.
function map(v){return Array.isArray(v)&&v.length===0?{}:v;}
function layer(v){for(const k of ['u','icwf','hit','hk','cls','vars','lun','trg','drn','spawn'])if(k in v)v[k]=map(v[k]);return v;}
for(const r of result.rows){
 r.input=map(r.input);
 if(r.expected&&typeof r.expected==='object'){
  if(r.expected.L)layer(r.expected.L);
  if(r.op==='frame'){layer(r.expected.layers);r.expected.dynamic.K=r.expected.dynamic.K.map(map);}
  if(['fx_event','fx_sequence','fx_cutin','fx_pcutin','fx_abyss','fx_put','bz_add','fx_result'].includes(r.op)||r.op==='fx_optional'&&!r.expected.L)layer(r.expected);
  if(r.op==='dyn')r.expected.K=r.expected.K.map(map);
 }
 if(r.input.L)layer(r.input.L);
 if(r.op==='chip_dotn')r.input.v=r.input.v.map(map);
 if(r.op==='chips')r.input.state.u=r.input.state.u.map(v=>{if(v.bf)v.bf=map(v.bf);return v;});
 if(r.op==='urda_round_full')r.expected.units.forEach(v=>v.bf=map(v.bf));
}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
fs.writeFileSync('verification/parity-r23/round5-oracle.json',JSON.stringify({...result,provenance},null,2)+'\\n');
console.log(JSON.stringify({cases:result.rows.length,counts:result.counts}));process.exit(0);
`;
fs.writeFileSync('tools/oracle_battle_r23_round5_loader.mjs',code);
await import('./oracle_battle_r23_round5_loader.mjs?'+Date.now());
