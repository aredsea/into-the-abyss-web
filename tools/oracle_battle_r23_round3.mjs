// Round 3 shares the real source loader and exports only original closures.
import fs from 'node:fs';
let loader=fs.readFileSync('tools/oracle_battle_r23_batch.mjs','utf8');
loader=loader.replace("const extra='B.__batch={}\\n'",`patches['27-compose.lua'].push(['  table.sort(idx, function(a, b)','  local function front_before(a, b)'],['  end)\\n  local f2','  end\\n  B.__batch.front_before=front_before;B.__batch.front_list=fl\\n  table.sort(idx,front_before)\\n  local f2']);
patches['32-personal-b.lua'].push(['  local trs = {}','  B.__batch.drop_caster_buffs=drop_caster_buffs;B.__batch.Kc=Kc\\n  local trs = {}']);
patches['32-personal-b.lua'].push(['  -- ---------- 베렌가','  B.__batch.nm_b=nm;B.__batch.sub=sub;B.__batch.bp=bp;B.__batch.short=short;B.__batch.pct_b=pct\\n  -- ---------- 베렌가']);
patches['32-personal-a.lua'].push(['-- ============ 할드리크:','B.__batch.pct_a=pct;B.__batch.sn=sn\\n-- ============ 할드리크:']);
patches['30-engine.lua']=[['local function isweak','B.__batch.nm_engine=nm\\nlocal function isweak']];
patches['31-foes.lua']=[['-- 조합 전투의 적 공격 한 줄:','B.__batch.nm_foes=nm;B.__batch.pct_foes=pct\\n-- 조합 전투의 적 공격 한 줄:']];
const extra='B.__batch={}\\n'`);
// 26-start is definitions only. Its host dependencies are never stubbed here.
loader=loader.replace("'24-stats.lua','27-compose.lua'","'24-stats.lua','26-start.lua','27-compose.lua'");
loader=loader.replaceAll('tools/oracle_battle_r23_batch.lua','tools/oracle_battle_r23_round3.lua');
loader=loader.slice(0,loader.indexOf('for(const r of result.rows)'))+`
for(const r of result.rows){
 if(Array.isArray(r.input))r.input={};
 if(['felice_save','corrode'].includes(r.op)&&Array.isArray(r.input.value)&&r.input.value.length===0)r.input.value={};
 for(const key of ['x','bf','state']){
  if(Array.isArray(r.expected?.[key])&&r.expected[key].length===0)r.expected[key]={};
 }
 if(r.op==='drop')for(const u of r.expected)if(Array.isArray(u.bf))u.bf={};
}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
fs.writeFileSync('verification/parity-r23/round3-oracle.json',JSON.stringify({...result,provenance},null,2)+'\\n');
console.log(JSON.stringify({cases:result.rows.length,counts:result.counts}));process.exit(0);
`;
// Keep generated loader beside the ordinary oracle for coverage replay.
fs.writeFileSync('tools/oracle_battle_r23_round3_loader.mjs',loader);
await import('./oracle_battle_r23_round3_loader.mjs?'+Date.now());
