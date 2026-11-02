// Execute the original affection functions in the source bot's Lua harness.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source='C:/Clauede Code/dungeon-bot/bot/src/74-affection.lua';
const raw=fs.readFileSync(source,'utf8');
const {mkSim}=await import(pathToFileURL('C:/Clauede Code/dungeon-bot/bot/lua_sim.mjs').href);
const {sim,L}=await mkSim({policy:false,extra:raw});
const rows=await L(`
local out={}
for _,a in ipairs({-100,-60.01,-60,-59.99,-20.01,-20,-19.99,0,19.99,20,49.99,50,79.99,80,99.99,100,149.99,150,199.99,200}) do
 for _,n in ipairs({-300,-2,-0.005,0,0.005,1,2,3,100,500}) do
  out[#out+1]={a=a,amount=n,stage=B.aff_stage(a),next=B.aff_next(a,n)}
 end
end
return out`);
const dir=path.join(root,'verification/town-r21/round6');fs.mkdirSync(dir,{recursive:true});
fs.writeFileSync(path.join(dir,'affection-oracle.json'),JSON.stringify(rows)+'\n');
fs.writeFileSync(path.join(dir,'affection-provenance.json'),JSON.stringify({source,sha256:crypto.createHash('sha256').update(raw).digest('hex'),method:'Unmodified 74-affection.lua functions in source Wasmoon harness'},null,2)+'\n');
console.log('affection samples',rows.length);
if(sim.close) await sim.close();
