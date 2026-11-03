import fs from 'node:fs';
import crypto from 'node:crypto';
import {validate} from '../server/abyss-save/src/validate.js';
const file='verification/parity-r23/expe-pass4-cloud-save-specimens.json';
const bytes=fs.readFileSync(file);
const results=Object.entries(JSON.parse(bytes)).map(([name,save])=>{
 try{validate(save);return {name,passed:true};}catch(e){return {name,passed:false,path:e.path};}
});
fs.writeFileSync('verification/parity-r23/expe-pass4-save-validation.json',JSON.stringify({file,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),validator:'server/abyss-save/src/validate.js',validator_sha256:crypto.createHash('sha256').update(fs.readFileSync('server/abyss-save/src/validate.js')).digest('hex'),results},null,2)+'\n');
console.log(JSON.stringify(results));
if(results.some(r=>!r.passed))process.exitCode=1;
