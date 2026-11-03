import fs from 'node:fs';
let loader=fs.readFileSync('tools/expe_r23_pass3_oracle.mjs','utf8').split('try {')[0];
loader=loader.replace("path.resolve(import.meta.dirname,'..')",'process.cwd()');
loader+=`
try {
 const code=fs.readFileSync('tools/expe_r23_pass5_extra_cases.lua','utf8').replace('__PERSONA__',JSON.stringify(persona));
 const result=await L(code);
 fs.writeFileSync('verification/parity-r23/expe-pass5-extra-oracle-raw.json',JSON.stringify(result,null,2)+'\\n');
 fs.writeFileSync('verification/parity-r23/expe-pass5-extra-provenance.json',JSON.stringify({cases_sha256:crypto.createHash('sha256').update(code).digest('hex'),files:raw.map(f=>({file:f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')})),cases:result.length},null,2)+'\\n');
 console.log(JSON.stringify({extra_source_cases:result.length}));
} finally {if(sim.close)await sim.close();}
`;
await import('data:text/javascript;base64,'+Buffer.from(loader).toString('base64'));
