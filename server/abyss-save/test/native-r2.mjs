import fs from 'node:fs';
import path from 'node:path';
import {spawn} from 'node:child_process';
import {runtime,root} from './runtime.mjs';
const out=path.join(root,'verification/cloud-r22/p9c');
const {mf,db}=await runtime();
async function godot(name,args){
 await db.prepare('DELETE FROM counters').run(); // Independent engine test groups.
 const log=fs.openSync(path.join(out,name+'.log'),'w');
 const child=spawn('python',['tools/godot_r17.py',...args],{cwd:root,stdio:['ignore',log,log],env:{...process.env,ABYSS_TEST_SERVER:String(await mf.ready).replace(/\/$/,'')}});
 console.log(name,'PID',child.pid);
 const timeout=setTimeout(()=>spawn('taskkill',['/PID',String(child.pid),'/T','/F']),240000);
 const exit=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('exit',resolve);});clearTimeout(timeout);fs.closeSync(log);
 console.log(name,'EXIT',exit);return {name,exit};
}
try{
 const save=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json'))).town;
 const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json','CF-Connecting-IP':'192.0.2.201'},body:JSON.stringify({save})});
 if(r.status!==201)throw Error('archive fixture create failed');const a=await r.json();
 await db.prepare('UPDATE accounts SET updated=0 WHERE code=?').bind(a.code).run();await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
 fs.writeFileSync(path.join(out,'archived-fixture.json'),JSON.stringify({code:a.code,pin:a.pin}));
 const results=[];
 results.push(await godot('native-service',['--headless','--script','res://tests/cloud_r22_test.gd']));
 results.push(await godot('native-archive',['--headless','--script','res://tests/cloud_archive_r22_test.gd']));
 results.push(await godot('native-ui',['--position','-10000,-10000','--script','res://tests/ui_cloud_r22_test.gd']));
 fs.writeFileSync(path.join(out,'native-run-results.json'),JSON.stringify(results,null,2));process.exitCode=results.some(r=>r.exit!==0)?1:0;
}finally{await mf.dispose();}
