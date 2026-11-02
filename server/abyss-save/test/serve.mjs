import {runtime,root} from './runtime.mjs';
import fs from 'node:fs';
import path from 'node:path';
const {mf}=await runtime(8787);const url=await mf.ready;
console.log('Local D1 worker',String(url));
fs.writeFileSync(path.join(root,'verification/cloud-r22/local-server-ready.json'),JSON.stringify({url:String(url)}));
process.on('SIGINT',async()=>{await mf.dispose();process.exit(0);});
