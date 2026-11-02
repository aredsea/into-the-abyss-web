// Test host only: unchanged P9 Worker and original migration/runtime.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
// Long Miniflare temp + 64-character SQLite filenames exceed Windows MAX_PATH.
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const temp=path.join(root,'.p6tmp');fs.mkdirSync(temp,{recursive:true});
process.env.TEMP=temp;process.env.TMP=temp;process.env.TMPDIR=temp;
const {runtime}=await import('../server/abyss-save/test/runtime.mjs');
const {mf}=await runtime(8787);await mf.ready;
console.log('P9 original local test runtime ready on 127.0.0.1:8787');
const stop=async()=>{await mf.dispose();process.exit(0)};
process.on('SIGINT',stop);process.on('SIGTERM',stop);
await new Promise(()=>{});
