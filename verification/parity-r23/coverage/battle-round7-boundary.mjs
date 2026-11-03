import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim:mkSimBase}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const mkSim=async(o)=>{const sim=await mkSimBase({...o,extra:'B.__r23_cov={calls={},branches={}}\n'+o.extra});const original=sim.L;return {...sim,L:async(code)=>{const pack=await original('B.__r23_cov={calls={},branches={}};local __result=(function()\n'+code+'\nend)();return {result=__result,coverage=B.__r23_cov}');fs.writeFileSync('verification/parity-r23/coverage/battle-round7-boundary.json',JSON.stringify(pack.coverage));return pack.result;}};};
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
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua','40-fx.lua','50-render.lua','80-press.lua'];
const raw=files.map(f=>fs.readFileSync(path.join('C:/Users/asone/Documents/Codex/2026-10-30/into-the-abyss-handoff/work/r21-a-data/verification/parity-r23/coverage/instrumented',f),'utf8'));
const extra='B.__batch={}\n'+raw.map((s,i)=> {if(files[i]==='29-persona-skill.lua')s=s.replace('function B.ps_dirty','B.__batch.work=work;B.__batch.same=same\nfunction B.ps_dirty').replace('local function save(G, id)','B.__batch.changes=changes\nlocal function save(G, id)');return (files[i]==='34-traits.lua'?'B.GH={}':'')+'\ndo\n'+s+'\nend';}).join('\n');
const {L,sim}=await mkSim({policy:false,extra});
const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
const pack=process.env.R23_ROUND7_PACK||'';if(!['','persona','boundary'].includes(pack))throw Error('invalid pack');
const stem='battle-round7'+(pack?'-'+pack:'');
let body=fs.readFileSync('tools/oracle_battle_r23_round7'+(pack?'_'+pack:'')+'.lua','utf8');
if(pack==='boundary')body=fs.readFileSync('tools/oracle_battle_r23_round7.lua','utf8').split("for _,lang in ipairs({'ko','en'})")[0]+body;
let result;try{result=await L(fresh+'\n'+body);}catch(e){console.log(sim.errors,sim.logs);throw e;}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
// Preserve Lua's empty-table ambiguity only for actual map fields.
const map=v=>Array.isArray(v)&&!v.length?{}:v;
for(const row of result.rows){for(const s of [row.input.state,row.expected]){
 if(!s)continue;for(const u of s.units||s.u||[]){if(u&&typeof u==='object'){if('bf'in u)u.bf=map(u.bf);if('x'in u)u.x=map(u.x);}}
}if('rules'in row.input)row.input.rules=map(row.input.rules);
function normalizeSkill(v){if(v&&typeof v==='object'){for(const k of ['prefix_lv','suffix_lv'])if(k in v)v[k]=map(v[k]);}}
for(const v of [row.input.saved,row.input.a,row.input.b,row.input.draft,row.expected])normalizeSkill(v);
}
const parts=[];let rows=[],size=0;
function flush(){if(!rows.length)return;const file=`${stem}-oracle-${parts.length+1}.json`;const data=JSON.stringify({rows,provenance});if(Buffer.byteLength(data)>40*1024*1024)throw Error('40 MiB limit');fs.writeFileSync('verification/parity-r23/'+file,data);parts.push({file,rows:rows.length,bytes:Buffer.byteLength(data),sha256:crypto.createHash('sha256').update(data).digest('hex')});rows=[];size=0;}
for(const row of result.rows){const n=Buffer.byteLength(JSON.stringify(row));if(size+n>35*1024*1024)flush();rows.push(row);size+=n;}flush();
fs.writeFileSync('verification/parity-r23/'+stem+'-oracle.json',JSON.stringify({counts:result.counts,parts,provenance},null,2));
console.log(JSON.stringify({counts:result.counts,parts}));process.exit(0);
