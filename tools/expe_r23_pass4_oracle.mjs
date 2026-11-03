// Reuse only the proven canonical loader; do not replay completed-row fixtures.
import fs from 'node:fs';
const original=fs.readFileSync('tools/expe_r23_pass3_oracle.mjs','utf8');
let loader=original.slice(0,original.indexOf('try {'));
loader=loader.replace("path.resolve(import.meta.dirname,'..')",'process.cwd()');
loader=loader.replace('zero=zero4,snapshot=', 'name=itname,step=do_explore,zero=zero4,snapshot=');
loader=loader.replace('B.R23supply_name=itname', 'B.R23supply_name=itname;B.R23cur=cur_i');
loader+=`
try {
 const code=fs.readFileSync(path.join(root,'tools/expe_r23_pass4_cases.lua'),'utf8').replace('__PERSONA__',JSON.stringify(persona));
 const pack=await L(code);
 const folder=path.join(root,'verification/parity-r23');
 const stem=instrument?'expe-pass4-instrumented':'expe-pass4';
 fs.writeFileSync(path.join(folder,stem+'-oracle.json'),JSON.stringify(pack.result,null,2)+'\\n');
 if(instrument)fs.writeFileSync(path.join(folder,'expe-pass4-coverage-raw.json'),JSON.stringify(pack.coverage,null,2)+'\\n');
 else fs.writeFileSync(path.join(folder,'expe-pass4-provenance.json'),JSON.stringify({loader_sha256:crypto.createHash('sha256').update(fs.readFileSync('tools/expe_r23_pass3_oracle.mjs')).digest('hex'),cases_sha256:crypto.createHash('sha256').update(code).digest('hex'),files:raw.map(f=>({file:f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')})),counts:Object.fromEntries(Object.entries(pack.result).map(([k,v])=>[k,v.length]))},null,2)+'\\n');
 console.log(JSON.stringify(Object.fromEntries(Object.entries(pack.result).map(([k,v])=>[k,v.length]))));
} finally {if(sim.close)await sim.close();}
`;
await import('data:text/javascript;base64,'+Buffer.from(loader).toString('base64'));
