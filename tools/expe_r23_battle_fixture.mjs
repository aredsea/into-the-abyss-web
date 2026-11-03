// Replay the existing source oracle with a dedicated output path. The gear
// oracle owns oracle.json in this combined workspace; do not overwrite it.
import fs from 'node:fs';
import crypto from 'node:crypto';
const file='tools/oracle_battle_r23.mjs';
const before=fs.readFileSync(file,'utf8');
const needle="'verification/parity-r23/oracle.json'";
if(before.split(needle).length!==2)throw Error('Unexpected oracle output path');
const after=before.replace(needle,"'verification/parity-r23/battle-oracle-r23.json'");
fs.writeFileSync('verification/parity-r23/expe-pass3-battle-fixture-adapter.json',JSON.stringify({file,source_sha256:crypto.createHash('sha256').update(before).digest('hex'),method:'Only in-memory output filename replacement; original source oracle and comparisons unchanged',old_path:'verification/parity-r23/oracle.json',new_path:'verification/parity-r23/battle-oracle-r23.json'},null,2)+'\n');
await import('data:text/javascript;base64,'+Buffer.from(after).toString('base64'));
