// Access probes expose original local closures, without replacing their bodies.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua','40-fx.lua','50-render.lua'];
const raw=files.map(f=>fs.readFileSync(path.join(root,'bot/src',f),'utf8'));
const patches={
 '24-stats.lua':[['  local s = { str =','  B.__batch.stat=st\n  local s = { str =']],
 '27-compose.lua':[
  ['local FILL =','B.__batch.party_target=party_target; B.__batch.pickl=pickl\nlocal FILL ='],
  ['  -- ---------- 레이드:', '  B.__batch.result=result\n  -- ---------- 레이드:'],
  ['  for try = 1, 40 do','  B.__batch.build_slots=build_slots\n  for try = 1, 40 do'],
  ['    local found\n','    B.__batch.dfs=function(seed,sl,k,fl,fg,budget,opts)\n      rng=mkrng(seed); mobs=opts.mobs; elites=opts.elites; borrowed=opts.borrowed; limit=opts.limit; umin=opts.umin\n      local ok=dfs(sl,k,fl,fg,budget); return {ok=ok,fl=fl,fg=fg,budget=budget.n,next=math.floor(rng()*2147483647+.5)}\n    end\n    B.__batch.shuffle_run=function(seed,l) rng=mkrng(seed); shuffle(l); return {list=l,next=math.floor(rng()*2147483647+.5)} end\n    local found\n']],
 '32-personal-a.lua':[['-- ============ 할드리크:', 'B.__batch.xs=xs; B.__batch.foes=foes; B.__batch.behind=behind\n-- ============ 할드리크:'],['local function unslow(st)','B.__batch.cor_live=cor_live; B.__batch.corrode=corrode\nlocal function unslow(st)']],
 '32-personal-b.lua':[['  local function magic_now(st, e)','  B.__batch.has_magic=has_magic\n  local function magic_now(st, e)'],['  B.PSK.lavinia =','  B.__batch.casting=casting\n  B.PSK.lavinia =']],
 '34-traits.lua':[['-- 전투 유닛 만들기','B.__batch.lv=lv; B.__batch.tr_xs=xs\n-- 전투 유닛 만들기']]
};
patches['27-compose.lua'][3][1]=patches['27-compose.lua'][3][1].replace('    local found\n','    B.__batch.shuffle_roll=function(roll,l) local calls=0; rng=function() calls=calls+1;return roll end; shuffle(l); return {list=l,calls=calls} end\n    local found\n');
patches['27-compose.lua'].push(['  table.sort(idx, function(a, b)','  local function front_before(a, b)'],['  end)\n  local f2','  end\n  B.__batch.front_before=front_before;B.__batch.front_list=fl\n  table.sort(idx,front_before)\n  local f2']);
patches['32-personal-b.lua'].push(['  local trs = {}','  B.__batch.drop_caster_buffs=drop_caster_buffs;B.__batch.Kc=Kc\n  local trs = {}']);
patches['32-personal-b.lua'].push(['  -- ---------- 베렌가','  B.__batch.nm_b=nm;B.__batch.sub=sub;B.__batch.bp=bp;B.__batch.short=short;B.__batch.pct_b=pct\n  -- ---------- 베렌가']);
patches['32-personal-a.lua'].push(['-- ============ 할드리크:','B.__batch.pct_a=pct;B.__batch.sn=sn\n-- ============ 할드리크:']);
patches['30-engine.lua']=[['local function isweak','B.__batch.nm_engine=nm\nlocal function isweak']];
patches['31-foes.lua']=[['-- 조합 전투의 적 공격 한 줄:','B.__batch.nm_foes=nm;B.__batch.pct_foes=pct\n-- 조합 전투의 적 공격 한 줄:']];
patches['29-persona-skill.lua']=[['  function B.ps_clean(raw)','  B.__batch.ps_lvl=lvl;B.__batch.ps_part=part\n  function B.ps_clean(raw)'],['  -- 편집 중인 조합','  B.__batch.ps_label=label\n  -- 편집 중인 조합']];
patches['34-traits.lua'].push(['local POS =','B.__batch.pnode=pnode\nlocal POS ='],['local G = B.GH','B.__batch.refresh=refresh;B.__batch.trait=trait\nlocal G = B.GH']);
patches['50-render.lua']=[['-- 사건 기록에서','B.__batch.hud_pct=pct;B.__batch.hud_f2=f2\n-- 사건 기록에서']];
patches['51-raid.lua']=[['-- 다음 큰 기술','B.__batch.raid_f2=f2\n-- 다음 큰 기술']];
patches['40-fx.lua']=[['local function put','B.__batch.fx_f2=f2;B.__batch.fx_sv=sv\nlocal function put'],['-- 판 흔들림','B.__batch.kx=kx\n-- 판 흔들림'],['-- 심연 깎기 숫자','B.__batch.tagcls=tagcls\n-- 심연 깎기 숫자']];
const extra='B.__batch={}\n'+raw.map((s,i)=>{s=s.replaceAll('\r\n','\n');for(const [a,b] of patches[files[i]]||[]){if(!s.includes(a))throw Error('missing access marker '+a);s=s.replace(a,b);}return (files[i]==='34-traits.lua'?'B.GH={}':'')+'\ndo\n'+s+'\nend';}).join('\n');
const {L}=await mkSim({policy:false,extra});
const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
const result=await L(fresh+'\n'+fs.readFileSync('tools/oracle_battle_r23_round4.lua','utf8'));


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
fs.writeFileSync('verification/parity-r23/round4-oracle.json',JSON.stringify({...result,provenance},null,2)+'\n');
console.log(JSON.stringify({cases:result.rows.length,counts:result.counts}));process.exit(0);
