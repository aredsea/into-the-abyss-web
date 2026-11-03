// Expose the actual source closures; their bodies remain untouched.
import fs from 'node:fs';
let code=fs.readFileSync('tools/oracle_battle_r23_round3_loader.mjs','utf8');
code=code.replace("const extra='B.__batch={}\\n'",`patches['29-persona-skill.lua']=[['  function B.ps_clean(raw)','  B.__batch.ps_lvl=lvl;B.__batch.ps_part=part\\n  function B.ps_clean(raw)'],['  -- 편집 중인 조합','  B.__batch.ps_label=label\\n  -- 편집 중인 조합']];
patches['34-traits.lua'].push(['local POS =','B.__batch.pnode=pnode\\nlocal POS ='],['local G = B.GH','B.__batch.refresh=refresh;B.__batch.trait=trait\\nlocal G = B.GH']);
patches['50-render.lua']=[['-- 사건 기록에서','B.__batch.hud_pct=pct;B.__batch.hud_f2=f2\\n-- 사건 기록에서']];
patches['51-raid.lua']=[['-- 다음 큰 기술','B.__batch.raid_f2=f2\\n-- 다음 큰 기술']];
patches['40-fx.lua']=[['local function put','B.__batch.fx_f2=f2;B.__batch.fx_sv=sv\\nlocal function put'],['-- 판 흔들림','B.__batch.kx=kx\\n-- 판 흔들림'],['-- 심연 깎기 숫자','B.__batch.tagcls=tagcls\\n-- 심연 깎기 숫자']];
const extra='B.__batch={}\\n'`);
code=code.replace("'78-battle-item.lua'];","'78-battle-item.lua','40-fx.lua','50-render.lua'];");
code=code.replaceAll('tools/oracle_battle_r23_round3.lua','tools/oracle_battle_r23_round4.lua');
code=code.slice(0,code.indexOf('for(const r of result.rows)'))+`
// Lua empty tables need schema-aware conversion, never numeric coercion.
for(const r of result.rows){
 if(Array.isArray(r.input)&&!r.input.length)r.input={};
 if(r.op==='ps_clean'||r.op==='ps_parts'||r.op==='ps_meta'){
  const v=r.op==='ps_clean'?r.expected:r.op==='ps_parts'?r.expected.v:null;
  if(v)for(const key of ['prefix_lv','suffix_lv'])if(Array.isArray(v[key]))v[key]={};
 }
 if(['tick','refresh','syn_full'].includes(r.op)&&Array.isArray(r.expected)&&!r.expected.length&&r.op==='refresh')r.expected={};
 if(r.op==='refresh'&&Array.isArray(r.expected.sy))r.expected.sy={};
 if(r.op==='tick'&&Array.isArray(r.expected))r.expected={};
 if(r.op==='miko_deal')for(const key of ['x','opt'])if(Array.isArray(r.expected[key]))r.expected[key]={};
 if(r.op==='haldric')r.expected.buffs=r.expected.buffs.map(v=>Array.isArray(v)?{}:v);
 if(r.op==='urda'&&Array.isArray(r.expected.buffs))r.expected.buffs={};
 if(r.op==='double_full'&&Array.isArray(r.expected.sy))r.expected.sy={};
}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
fs.writeFileSync('verification/parity-r23/round4-oracle.json',JSON.stringify({...result,provenance},null,2)+'\\n');
console.log(JSON.stringify({cases:result.rows.length,counts:result.counts}));process.exit(0);
`;
fs.writeFileSync('tools/oracle_battle_r23_round4_loader.mjs',code);
await import('./oracle_battle_r23_round4_loader.mjs?'+Date.now());
