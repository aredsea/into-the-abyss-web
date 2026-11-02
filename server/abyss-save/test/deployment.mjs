// Read local configuration only; never contacts Cloudflare or uses credentials.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
const here=path.dirname(fileURLToPath(import.meta.url)),root=path.resolve(here,'../../..');
const out=path.join(root,'verification/cloud-r22/round12');fs.mkdirSync(out,{recursive:true});
const config=fs.readFileSync(path.join(here,'../wrangler.toml'),'utf8');
const section=name=>config.match(new RegExp('^\\['+name.replaceAll('.','\\.')+'\\]\\s*\\n([\\s\\S]*?)(?=^\\[|$(?![\\s\\S]))','m'))?.[1]??'';
const value=(body,key)=>body.match(new RegExp('^'+key+'\\s*=\\s*"?([^"\\r\\n]+)"?','m'))?.[1];
const prod=section('vars'),dev=section('env.development.vars');
assert.equal(value(prod,'TURNSTILE_ENABLED'),'true','Deployment refused: production Turnstile must be true');
assert.equal(value(dev,'TURNSTILE_ENABLED'),'false');
assert.equal(value(prod,'ALLOW_LOCALHOST'),'false');
assert.equal(value(dev,'ALLOW_LOCALHOST'),'true');
for(const [key,expected] of [['GLOBAL_NEW_PER_DAY',10000],['GLOBAL_NEW_BYTES_PER_DAY',268435456]])assert.equal(Number(value(prod,key)),expected);
assert.match(config.split('[build]')[0],/^workers_dev = true$/m);
assert.match(section('env.development'),/^workers_dev = false$/m);
const pkg=JSON.parse(fs.readFileSync(path.join(here,'../package.json')));
const lock=JSON.parse(fs.readFileSync(path.join(here,'../package-lock.json')));
assert.equal(pkg.devDependencies.miniflare,'5.20261012.0-beta');
assert.equal(lock.packages['node_modules/miniflare'].version,pkg.devDependencies.miniflare);
assert.equal(lock.packages[''].devDependencies.miniflare,pkg.devDependencies.miniflare);
// These fields are filled by the deployment owner after review.
const client=JSON.parse(fs.readFileSync(path.join(root,'project/data/cloud-r22.json')));
assert.equal(client.server_url,'');assert.equal(client.turnstile_site_key,'');
process.env.WRANGLER_LOG_PATH=path.join(out,'wrangler.log');process.env.WRANGLER_SEND_METRICS='false';
const {unstable_readConfig}=await import('wrangler');
const configPath=path.join(here,'../wrangler.toml');
const normalized=unstable_readConfig({config:configPath}),development=unstable_readConfig({config:configPath,env:'development'});
assert.equal(normalized.vars.TURNSTILE_ENABLED,'true');assert.equal(development.vars.TURNSTILE_ENABLED,'false');
assert.equal(development.workers_dev,false);assert.equal(development.d1_databases[0].database_name,'abyss-web-save-development');
assert.deepEqual(Object.keys(normalized.vars).sort(),Object.keys(development.vars).sort());
const falseConfig=path.join(out,'wrangler-false.toml');
fs.writeFileSync(falseConfig,config.replace('TURNSTILE_ENABLED = "true"','TURNSTILE_ENABLED = "false"'));
const run=args=>spawnSync(process.execPath,[path.join(here,'../check-deployment.mjs'),...args],{encoding:'utf8',windowsHide:true,env:{...process.env,WRANGLER_SEND_METRICS:'false',WRANGLER_LOG_PATH:path.join(out,'wrangler.log')}});
try{
 const yes=run([]),no=run([falseConfig]);
 assert.equal(yes.status,0,yes.stderr);assert.match(yes.stdout,/Production Turnstile enabled/);
 assert.equal(no.status,1,no.stderr);assert.match(no.stderr,/Deployment refused/);
 fs.writeFileSync(path.join(out,'deployment-gate.log'),yes.stdout+yes.stderr+no.stdout+no.stderr);
}finally{fs.unlinkSync(falseConfig);}
fs.writeFileSync(path.join(out,'deployment-results.json'),JSON.stringify({checks:22,failures:0,production_turnstile:true,development_turnstile:false,disabled_production_refused:true,wrangler_environment_parsing:true,remote_actions:0},null,2));
console.log('DEPLOYMENT CHECKS 22 FAILURES 0');
