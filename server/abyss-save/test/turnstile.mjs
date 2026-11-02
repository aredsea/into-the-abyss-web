import {runtime,root} from './runtime.mjs';
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
let outgoing=0;
const {mf}=await runtime(undefined,{TURNSTILE_ENABLED:'true',TURNSTILE_SECRET:'local-test-secret',ALLOW_LOCALHOST:'false',TURNSTILE_HOSTNAMES:'aredsea.github.io,localhost'},{outboundService:async request=>{
 assert.equal(request.url,'https://challenges.cloudflare.com/turnstile/v0/siteverify');
 const form=await request.formData();assert.equal(form.get('secret'),'local-test-secret');outgoing++;
 const token=form.get('response');
 return new Response(JSON.stringify({success:token!=='failed',action:token==='bad-action'?'other':'account',hostname:token==='local-host'?'localhost':token==='bad-host'?'evil.example':'aredsea.github.io'}),{headers:{'content-type':'application/json'}});
}});
const save=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json'))).town;
const cases=[['',403],['failed',403],['bad-action',403],['local-host',403],['bad-host',403],['synthetic-valid',201]];
try{
 for(const[token,status]of cases){const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json','CF-Connecting-IP':'192.0.2.1'},body:JSON.stringify({save,turnstile:token})});assert.equal(r.status,status,await r.text());}
 assert.equal(outgoing,5);
 fs.writeFileSync(path.join(root,'verification/cloud-r22/p9b/siteverify-results.json'),JSON.stringify({checks:7,failures:0,provider:'local outbound test double, no live service or tokens'}));console.log('SITEVERIFY CHECKS 7 FAILURES 0');
}finally{await mf.dispose();}
