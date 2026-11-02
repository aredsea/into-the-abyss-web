// Read-only validation against the protected P9 server; never edits its allowlists.
import fs from 'node:fs';
import path from 'node:path';
import {validate} from '../server/abyss-save/src/validate.js';
const root=path.resolve(import.meta.dirname,'..');
const folder=path.join(root,'verification/expedition-r22');
const samples=JSON.parse(fs.readFileSync(path.join(folder,'save-specimens.json'),'utf8'));
const rows=Object.entries(samples).map(([name,save])=>{try{validate(save);return {name,accepted:true}}catch(e){return {name,accepted:false,reason:e.message}}});
fs.writeFileSync(path.join(folder,'p9-boundary.json'),JSON.stringify({protectedServerUnmodified:true,rows,requiresP9SchemaUpdate:rows.some(r=>!r.accepted)},null,2)+'\n');
console.log(rows);
