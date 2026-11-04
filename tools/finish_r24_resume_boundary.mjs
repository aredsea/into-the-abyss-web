// Read-only proof of the server allowlist boundary. No server sources are edited.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {validate} from '../server/abyss-save/src/validate.js';
const path='verification/finish-r24/round2/resume-probe.json';
const probe=JSON.parse(fs.readFileSync(path,'utf8'));
const inspect=s=>{try{validate(s);return {accepted:true}}catch(e){return {accepted:false,error:String(e.message),path:e.path}}};
const results=[{case:'existing snapshot',...inspect(probe.state)}];
for(const field of ['depletions','last_kill']){
 const state=structuredClone(probe.state);
 state.run.battle[field]=probe.before[field];
 results.push({case:`persist battle.${field}`,...inspect(state)});
}
assert.equal(results[0].accepted,true,'baseline must be accepted before claiming an allowlist blocker');
assert.equal(results[1].accepted,false);assert.equal(results[2].accepted,false);
assert.equal(probe.restored,true);assert.equal(probe.equal,false);
const result={native_resume:{before:probe.before,after:probe.after,equal:probe.equal},server:results,blocked:true,required_change:'Add bounded battle outcome metadata to both native snapshots and the server battle allowlist; preserve missing fields in old saves with explicit defaults.',server_modified:false};
fs.writeFileSync('verification/finish-r24/round2/server-boundary.json',JSON.stringify(result,null,2));
console.log(JSON.stringify(result));
