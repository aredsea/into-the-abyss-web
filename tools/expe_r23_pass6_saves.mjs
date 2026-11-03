import fs from 'node:fs';
import crypto from 'node:crypto';
import {validate} from '../server/abyss-save/src/validate.js';
const rows=[];
const files=['ko','en'].map(lang=>'verification/parity-r23/expe-pass6-ui-save-'+lang+'.json');
const latest=new Map();
for(const p of fs.globSync('verification/ui-r17/runtime-final-0/**/expe-pass6-*.json')){
 const m=p.match(/expe-pass6-(ko|en)-(360|390)-\d+\.json$/);if(!m)continue;
 const key=m[1]+'-'+m[2];if(!latest.has(key)||fs.statSync(p).mtimeMs>fs.statSync(latest.get(key)).mtimeMs)latest.set(key,p);
}
for(const[key,p]of latest){
 const output='verification/parity-r23/expe-pass6-defeat-save-'+key+'.json';
 fs.copyFileSync(p,output);files.push(output);
}
for(const file of files){
 const bytes=fs.readFileSync(file);
 try{validate(JSON.parse(bytes));rows.push({file,sha256:crypto.createHash('sha256').update(bytes).digest('hex'),passed:true});}
 catch(e){rows.push({file,passed:false,path:e.path,message:e.message});}
}
fs.writeFileSync('verification/parity-r23/expe-pass6-save-validation.json',JSON.stringify(rows,null,2)+'\n');
console.log(JSON.stringify(rows));if(rows.some(r=>!r.passed))process.exitCode=1;
