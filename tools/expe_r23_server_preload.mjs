// Test launcher only. Execute serve.mjs with its real runtime/Worker/D1, but
// request an ephemeral port because an existing service owns 127.0.0.1:8787.
// No server files are written. The exact in-memory launcher diff is recorded.
import {registerHooks} from 'node:module';
import {pathToFileURL} from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const serve=pathToFileURL(path.join(root,'server/abyss-save/test/serve.mjs')).href;
registerHooks({load(url,context,next){
 const result=next(url,context);
 if(url!==serve)return result;
 const before=String(result.source);
 if(!before.includes('runtime(8787)')||!before.includes("console.log('Local D1 worker'"))throw Error('Unexpected serve launcher; refusing to adapt');
 const seed=`
const db=await mf.getD1Database('DB');
const save=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json'),'utf8')).town;
const fixtureResponse=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({save})});
if(fixtureResponse.status!==201)throw Error('Archive account fixture creation failed');
const account=await fixtureResponse.json();
await db.prepare('UPDATE accounts SET updated=0 WHERE code=?').bind(account.code).run();
await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
fs.writeFileSync(path.join(root,'verification/cloud-r22/p9c/archived-fixture.json'),JSON.stringify({code:account.code,pin:account.pin}));
`;
 const after=before.replace('runtime(8787)','runtime()').replace("console.log('Local D1 worker'",seed+"\nconsole.log('Local D1 worker'");
 fs.writeFileSync(path.join(root,'verification/parity-r23/expe-pass2-server-adapter.json'),JSON.stringify({entry:'server/abyss-save/test/serve.mjs',disk_unchanged:true,changes:['runtime(8787) -> runtime() (ephemeral loopback port)', 'seed an archived account in the very same D1 runtime before ready marker'],existing_port:8787},null,2));
 return {...result,source:after};
}});
