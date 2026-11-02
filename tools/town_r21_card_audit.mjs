// Report absence rather than invent rules for the legacy web prototype's cards.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source='C:/Clauede Code/dungeon-bot';
const terms=['봉인된 보관함','봉인 해제','안전한 야영','탐색 카드','find_card','G.hand','R.hand'];
const manifest=[],hits=[];
function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const f=path.join(dir,e.name);if(e.isDirectory())walk(f);else if(/\.(lua|json|md)$/.test(f)){const raw=fs.readFileSync(f,'utf8');manifest.push({file:f,sha256:crypto.createHash('sha256').update(raw).digest('hex')});raw.split('\n').forEach((line,i)=>{const found=terms.filter(t=>line.includes(t));if(found.length)hits.push({file:f,line:i+1,terms:found,text:line.slice(Math.max(0,line.indexOf(found[0])-100),line.indexOf(found[0])+300)});});}}}
walk(source+'/bot/src');walk(source+'/design');
const raw=fs.readFileSync(source+'/bot/src/77-explore.lua','utf8');
const {mkSim}=await import(pathToFileURL(source+'/bot/lua_sim.mjs').href);
const {sim,L}=await mkSim({policy:false,extra:raw});
const runtime=await L(`
local kinds={};local count=0
for seed=1,64 do for floor=1,25 do for step=1,5 do
 local o=B.ex_roll(seed,floor,step,0,{"warrior","assassin","mage","priest"})
 kinds[o.kind]=(kinds[o.kind] or 0)+1;count=count+1
end end end
return {samples=count,kinds=kinds,steps=B.EX.STEPS}`);
const result={status:'source_rules_absent',scope:'Current canonical bot/src and design, no git history or external archives inspected.',terms,files:manifest.length,hits,manifest,runtime,interpretation:'77 head_card/last_card/party_card/gear_card are HTML panels. The matching seal name is an enemy skill. Existing web key/camp behavior and saved hands are preserved, not claimed as canonical parity.'};
const dir=path.join(root,'verification/town-r21/round7');fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'card-audit.json'),JSON.stringify(result,null,2)+'\n');
const allowed=new Set(['battle','elite','coin','item','equip']);
if(Object.keys(runtime.kinds).some(k=>!allowed.has(k)))throw Error('Unexpected exploration outcome; inspect source again');
console.log('CARD SOURCE AUDIT',manifest.length,'FILES /',runtime.samples,'LUA ROLLS /',JSON.stringify(runtime.kinds),'/ canonical card rules absent');
if(sim.close)await sim.close();
