import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const here=path.dirname(fileURLToPath(import.meta.url));
export function bundle(){
 const known=fs.readFileSync(path.join(here,'src/known.json'),'utf8');
 const validator=fs.readFileSync(path.join(here,'src/validate.js'),'utf8').replace(/^import .*;\r?\n/,'').replace(/export /g,'');
 const handler=fs.readFileSync(path.join(here,'src/index.js'),'utf8').replace(/^import .*;\r?\n/,'');
 return 'const K='+known+';\n'+validator+'\n'+handler;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
 fs.mkdirSync(path.join(here,'dist'),{recursive:true});fs.writeFileSync(path.join(here,'dist/worker.mjs'),bundle());console.log('Built dependency-free Worker');
}
