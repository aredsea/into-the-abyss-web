// Read-only current Lua oracle. No host requests, model calls, or source writes.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),source='C:/Clauede Code/dungeon-bot/bot';
const names=['01-game.lua','05-gen.lua','10-data.lua','74-affection.lua','81-gear.lua','88-lore.lua','89-memory.lua'];
const raw=names.map(n=>fs.readFileSync(path.join(source,'src',n),'utf8'));
const {mkSim}=await import(pathToFileURL(source+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:raw.join('\n')});
const data=await L(`return {places=B.PLACE,order=B.PLACE_ORDER,npcs=B.NPC_AT,english=B.en_dict(),limits={max=B.MEM.CHRON_MAX,line=B.MEM.LINE,dedup=B.MEM.DEDUP,show=B.MEM.CHRON_SHOW},lore=B.LORE,lo=B.LORE_ORDER}`);
// The public Korean lore files are the source of the introduction UI. Never
// import world documents or private/hidden callouts into the shipping bundle.
const publicNpcs={},files=[];
for(const id of data.lo){
 if(data.lore[id].kind!=='npc')continue;
 const f=path.join(source,'lore/npcs',id+'.md'),rawText=fs.readFileSync(f,'utf8');
 const content=rawText.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/,'');
 const lines=content.split(/\r?\n/);const safe=[];let privateBlock=false;
 for(const line of lines){
  if(/숨은 진실|비공개|hidden truth|private/i.test(line)){privateBlock=true;continue;}
  if(privateBlock){if(/^#{1,3} /.test(line))privateBlock=false;else continue;}
  // Quoted boxes are never part of the public profile.
  if(/^\s*>/.test(line))continue;
  if(line.trim())safe.push(line);
 }
 publicNpcs[id]={name:data.lore[id].name,lines:safe};
 files.push({path:f,sha256:crypto.createHash('sha256').update(rawText).digest('hex')});
}
delete data.lore;delete data.lo;data.profiles=publicNpcs;
const fixtures=await L(`
local out={places={},chron={},aff={},gear={}}
local function cp(t)return json.decode(json.encode(t))end
for _,scene in ipairs({'town','guild','shop','inn','smithy','create','scenario','sortie','battle','dungeon'}) do
 for _,place in ipairs({'','archive','gate','smithy','invalid'}) do
  for _,dest in ipairs({'town','guild','shop','inn','smithy','archive','gate','alley','rose','lamp','invalid'}) do
   local G={scene=scene,place=place,gold=555,town={day=7,acts={x=1}},seed=42,n=3,ui={sel='old',tab='old'},forge_fx=1,proc_fx=1,sm_work=1}
   local before=cp(G);local p=B.place_id(G);local moved=B.place_set(G,dest)
   out.places[#out.places+1]={before=before,id=p or '',dest=dest,moved=moved,value=G}
  end
 end
end
local samples={'','hello','a  b\\n c',' 한글  공백 ','레벨이 올랐다: 나란 Lv 1 → 3','대던전 1층 돌파, 보스 기록 수호자','대던전 3층에서 퇴각','대던전 4층 도전 실패','대던전 5층 도전 실패, 보스 감시자 앞에서 무너졌다','대던전 1층 돌파 뒤 곧장 2층으로 내려갔다','대던전 1층 돌파 뒤 토르바로 돌아갔다','의뢰 「균열」를 완료했다','의뢰 「균열」에 실패했다','나란과 첫 만남, 동료로 함께하게 되었다','나란이 길드 소개로 동료가 되었다',string.rep('한😀a',60)}
for _,text in ipairs(samples) do for _,day in ipairs({1,3.9,-2}) do for _,off in ipairs({0,1}) do
 local G={town={day=day},settings={chron=off}};B.chron_add(G,text);B.chron_add(G,text)
 out.chron[#out.chron+1]={text=text,day=day,off=off,queue=G._chq or {}}
end end end
for a=-101,201 do for _,b in ipairs({a+.25,a+25,a-30,200,-100}) do
 local G={town={day=2}};B.chron_aff(G,'naran',a,b);out.aff[#out.aff+1]={a=a,b=b,queue=G._chq or {}}
end end
local legend,common
for _,gid in ipairs(B.gear().order) do local it=B.gear().items[gid];if it.rarity=='legend' and not legend then legend=gid end;if it.rarity=='common' and not common then common=gid end end
for _,ids in ipairs({{legend},{legend,legend},{common},{common,legend}}) do
 local G={town={day=1}};local codes={};for _,gid in ipairs(ids) do codes[#codes+1]=B.gear_code(gid,5) end;B.chron_gear(G,codes);out.gear[#out.gear+1]={ids=ids,queue=G._chq or {}}
end
return out`);
// Exercise actual host-variable flush with previous history/window boundaries.
fixtures.flush=[];
for(const n of [0,1,7,8,9,59,60,61,80]){
 const history=Array.from({length:n},(_,i)=>'Day 1: '+i);
 for(const index of [0,Math.max(0,n-8),Math.max(0,n-9),Math.max(0,n-1)]){
  sim.setVar('dk_chron',JSON.stringify(history));
  const queue=['Day 1: '+index,'Day 2: fresh','Day 2: fresh'];
  await L(`B.chron_flush('key',json.decode(${JSON.stringify(JSON.stringify(queue))}));return true`);
  fixtures.flush.push({history,queue,value:JSON.parse(sim.getVar('dk_chron'))});
 }
}
const folder=path.join(root,'verification/chronicle-r22');fs.mkdirSync(folder,{recursive:true});
fs.writeFileSync(path.join(root,'project/data/chronicle-r22.json'),JSON.stringify(data,null,2)+'\n');
fs.writeFileSync(path.join(folder,'oracle.json'),JSON.stringify(fixtures)+'\n');
fs.writeFileSync(path.join(folder,'provenance.json'),JSON.stringify({files:[...names.map((n,i)=>({path:source+'/src/'+n,sha256:crypto.createHash('sha256').update(raw[i]).digest('hex')})),...files],contracts:['harness_lore.mjs: place_id/place_set/NPC_AT (non-host)','harness_memory.mjs: chron_add/flush/aff/gear (non-AI)'],counts:Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])),world_imported:false,source_write:false},null,2)+'\n');
console.log(Object.fromEntries(Object.entries(fixtures).map(([k,v])=>[k,v.length])));sim.close?.();
