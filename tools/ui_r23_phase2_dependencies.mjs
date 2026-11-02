// Check the template dependency against current source, separately from the dist harness.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const file=src+'/src/34-traits.lua',raw=fs.readFileSync(file,'utf8');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const {sim,L}=await mkSim({policy:false,extra:`assert(load(${JSON.stringify(raw)},'@34-traits.lua','t',_ENV))()`});
const result=await L(`local out={VAR=B.VAR};for i=1,100 do local k,v=debug.getupvalue(B.ptx,i);if not k then break end;if k=='X' or k=='P' then out[k]=v end end;return {values=out,source=debug.getinfo(B.ptx,'S').source}`);
const canonical=v=>Array.isArray(v)?v.map(canonical):v&&typeof v==='object'?Object.fromEntries(Object.keys(v).sort().map(k=>[k,canonical(v[k])])):v;
const shipped=JSON.parse(fs.readFileSync(root+'/project/data/persona-text-r23.json','utf8'));
const proof={file:'bot/src/34-traits.lua',sha256:crypto.createHash('sha256').update(raw).digest('hex'),function_source:result.source,shipped_values_equal:JSON.stringify(canonical(shipped))===JSON.stringify(canonical(result.values)),no_source_writes:true};
fs.writeFileSync(root+'/verification/parity-r23/phase2/dependencies.json',JSON.stringify(proof,null,2)+'\n');
console.log(JSON.stringify(proof));sim.close?.();if(!proof.shipped_values_equal)process.exitCode=1;
