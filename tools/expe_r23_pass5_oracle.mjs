// Execute the read-only canonical bot; expose only local functions under review.
import fs from 'node:fs';
let loader=fs.readFileSync('tools/expe_r23_pass3_oracle.mjs','utf8').split('try {')[0];
loader=loader.replace("path.resolve(import.meta.dirname,'..')",'process.cwd()');
loader=loader.replace('zero=zero4,snapshot=', 'bar=bar,zero=zero4,snapshot=');
loader+=`
try {
 const code=fs.readFileSync('tools/expe_r23_pass5_cases.lua','utf8').replace('__PERSONA__',JSON.stringify(persona));
 const result=await L(code);
 const visibleCode=['project/game/expedition_ui_r23.gd','project/ui/expedition_screen_r22.gd','project/game/expedition_world_r22.gd'].map(p=>fs.readFileSync(p,'utf8')).join('\\n');
 if(result.locale) for(const key of ['ui','words']) result.locale[key]=Object.fromEntries(Object.entries(result.locale[key]).filter(([k])=>visibleCode.includes(k)));
 fs.writeFileSync('verification/parity-r23/expe-pass5-oracle-raw.json',JSON.stringify(result,null,2)+'\\n');
 fs.writeFileSync('verification/parity-r23/expe-pass5-provenance.json',JSON.stringify({files:raw.map(f=>({file:f.name,sha256:crypto.createHash('sha256').update(f.text).digest('hex')})),cases_sha256:crypto.createHash('sha256').update(code).digest('hex'),counts:Object.fromEntries(Object.entries(result).map(([k,v])=>[k,v.length]))},null,2)+'\\n');
 console.log(JSON.stringify(Object.fromEntries(Object.entries(result).map(([k,v])=>[k,v.length]))));
} finally {if(sim.close)await sim.close();}
`;
await import('data:text/javascript;base64,'+Buffer.from(loader).toString('base64'));
