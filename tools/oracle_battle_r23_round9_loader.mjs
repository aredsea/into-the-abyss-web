import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','26-start.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua','51-raid.lua','71-shop.lua','78-battle-item.lua','40-fx.lua','50-render.lua','80-press.lua'];
const raw=files.map(f=>fs.readFileSync(path.join(root,'bot/src',f),'utf8'));
const patches={'78-battle-item.lua':[['function B.it_apply','B.__nine.cur_i=cur_i\nfunction B.it_apply'],['-- 평소 행동 칸','B.__nine.itname=itname\n-- 평소 행동 칸']],'20-state.lua':[['      s.hp, s.mp =','      B.__nine.r=r;B.__nine.rbase=s1\n      s.hp, s.mp =']]};
const extra='B.__nine={}\n'+raw.map((s,i)=>{s=s.replaceAll('\r\n','\n');for(const [a,b] of patches[files[i]]||[]){if(!s.includes(a))throw Error(a);s=s.replace(a,b);}return (files[i]==='34-traits.lua'?'B.GH={}':'')+'\ndo\n'+s+'\nend';}).join('\n');
const {L,sim}=await mkSim({policy:false,extra});
const pack=process.env.R23_ROUND9_PACK||'core';if(!['core','items','state','control','handlers','start','enemyturn','damaged'].includes(pack))throw Error('invalid pack');
const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
let result;try{result=await L(fresh+'\n'+fs.readFileSync('tools/oracle_battle_r23_round9_'+pack+'.lua','utf8'));}catch(e){console.log(sim.errors,sim.logs);throw e;}
const provenance=Object.fromEntries(files.map((f,i)=>[f,crypto.createHash('sha256').update(raw[i]).digest('hex')]));
const map=v=>Array.isArray(v)&&!v.length?{}:v;
function normalize(v){if(!v||typeof v!=='object')return;for(const [key,x]of Object.entries(v)){if(['bf','x','bag','gq','saved','draft','prefix_lv','suffix_lv','eq','forge'].includes(key))v[key]=map(x);normalize(v[key]);}}
function plain(s){return String(s??'').replace(/<[^>]*>/g,'').replaceAll('&amp;','&').replaceAll('&lt;','<').replaceAll('&gt;','>').replaceAll('&quot;','"').replaceAll('&#39;',"'");}
function view(html){
 const buttons=[];for(const m of html.matchAll(/<(button|div)\b([^>]*\bclass="btn(?:\s[^"]*)?"[^>]*)>([\s\S]*?)<\/\1>/g)){
  const content=m[3].match(/<span class="t">([\s\S]*?)<span class="d">([\s\S]*?)<\/span><\/span>/);
  buttons.push({action:m[2].match(/risu-btn="([^"]*)"/)?.[1]||'',enabled:m[1]==='button',label:plain(content?.[1]),description:plain(content?.[2])});
 }
 const header=html.match(/<span class="hd">([\s\S]*?)<\/span><span>([\s\S]*?)<\/span>/);
 return {heading:plain(header?.[1]),hint:plain(header?.[2]),buttons};
}
for(const row of result.rows){row.input=map(row.input);normalize(row);if(row.expected?.html!==undefined)row.expected.view=view(row.expected.html);}
const stem='battle-round9-'+pack,parts=[];let rows=[],size=0;
function flush(){if(!rows.length)return;const file=`${stem}-oracle-${parts.length+1}.json`,data=JSON.stringify({rows,provenance});if(Buffer.byteLength(data)>40*1024*1024)throw Error('40 MiB limit');fs.writeFileSync('verification/parity-r23/'+file,data);parts.push({file,rows:rows.length,bytes:Buffer.byteLength(data),sha256:crypto.createHash('sha256').update(data).digest('hex')});rows=[];size=0;}
for(const row of result.rows){const n=Buffer.byteLength(JSON.stringify(row));if(n+size>28*1024*1024)flush();rows.push(row);size+=n;}flush();
let source_only_file;
if(result.source_only){source_only_file=stem+'-source-observations.json';fs.writeFileSync('verification/parity-r23/'+source_only_file,JSON.stringify({source_only:result.source_only,provenance}));}
fs.writeFileSync('verification/parity-r23/'+stem+'-oracle.json',JSON.stringify({counts:result.counts,parts,constants:result.constants,source_only_file,provenance},null,2));console.log(JSON.stringify({pack,counts:result.counts,parts}));process.exit(0);
