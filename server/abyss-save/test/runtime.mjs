import {createRequire} from 'node:module';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {bundle} from '../build.mjs';
export const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../..');
let require=createRequire(import.meta.url);
if(process.env.ABYSS_NODE_MODULES)require=createRequire(path.join(process.env.ABYSS_NODE_MODULES,'package.json'));
export const {Miniflare}=require('miniflare');
export async function runtime(port){
 // The runtime receives the actual two source modules; no mock DB or alternate handler.
 const script=bundle();
 const worker={name:'abyss-web-save',modules:true,script,compatibilityDate:'2025-07-18',d1Databases:['DB'],bindings:{TURNSTILE_ENABLED:'false'}};
 const v5=Number(require('miniflare/package.json').version.split('.')[0])>=5;
 const options={...worker,host:'127.0.0.1',...(port?{port}:{}),cf:false};
 const mf=new Miniflare(v5?require('miniflare').convertV4MiniflareOptions(options):options);
 const db=await mf.getD1Database('DB');
 const sql=fs.readFileSync(path.join(here,'../migrations/0001.sql'),'utf8');
 // exec() requires one statement per line, so prepare the trigger separately.
 const trigger=sql.slice(sql.indexOf('CREATE TRIGGER'));
 const base=sql.slice(0,sql.indexOf('-- The CAS'));
 for(const s of base.split(';').map(x=>x.trim()).filter(Boolean))await db.prepare(s).run();
 await db.prepare(trigger).run();
 return {mf,db};
}
