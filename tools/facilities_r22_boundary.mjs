// Read the unchanged P9 validator; do not change the server's allowed schema.
import fs from 'node:fs';
import path from 'node:path';
import {validate} from '../server/abyss-save/src/validate.js';
const folder=path.resolve(import.meta.dirname,'../verification/facilities-r22');
const samples=JSON.parse(fs.readFileSync(path.join(folder,'save-specimens.json'),'utf8'));
const rows=Object.entries(samples).map(([name,save])=>{try{validate(save);return {name,accepted:true}}catch(e){return {name,accepted:false,reason:e.message}}});
fs.writeFileSync(path.join(folder,'p9-boundary.json'),JSON.stringify({protectedServerUnmodified:true,rows},null,2)+'\n');
console.log(rows);
