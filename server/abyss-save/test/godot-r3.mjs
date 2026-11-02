// Same real Worker/D1 service as serve.mjs, with isolated per-suite quotas.
import fs from 'node:fs';
import path from 'node:path';
import {spawn} from 'node:child_process';
import {runtime,root} from './runtime.mjs';
const out=path.join(root,'verification/cloud-r22/round12');fs.mkdirSync(out,{recursive:true});
const names=fs.readdirSync(path.join(root,'project/tests')).filter(n=>n.endsWith('_test.gd')||['export_licenses.gd','motion_r9_integration.gd','motion_r18_integration.gd','balance_probe.gd'].includes(n)).map(n=>n.slice(0,-3)).sort();
const selected=process.argv.slice(2);
const {mf,db}=await runtime();
const reportFile=path.join(out,'regression.json');
let results=selected.length&&fs.existsSync(reportFile)?JSON.parse(fs.readFileSync(reportFile,'utf8')):[];
try{
 for(const name of ['import',...names]){
  if(selected.length&&!selected.includes(name))continue;
  await db.prepare('DELETE FROM counters').run();
  if(name==='cloud_archive_r22_test'){
   const save=JSON.parse(fs.readFileSync(path.join(root,'verification/cloud-r22/fixtures.json'))).town;
   const r=await mf.dispatchFetch('http://localhost/v1/account',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({save})});
   if(r.status!==201)throw Error('archive fixture failed');const a=await r.json();
   await db.prepare('UPDATE accounts SET updated=0 WHERE code=?').bind(a.code).run();await (await mf.getWorker()).scheduled({cron:'17 * * * *'});
   fs.writeFileSync(path.join(root,'verification/cloud-r22/p9c/archived-fixture.json'),JSON.stringify({code:a.code,pin:a.pin}));
  }
  const native=name.startsWith('ui_')||['motion_r9_integration','motion_r18_integration'].includes(name);
  const args=name==='import'?['--headless','--editor','--import','--quit']:[...(native?['--position','-10000,-10000']:['--headless']),'--script',`res://tests/${name}.gd`];
  const filename=path.join(out,name+'.log'),fd=fs.openSync(filename,'w'),start=Date.now();
  const child=spawn('python',['tools/godot_r17.py',...args],{cwd:root,stdio:['ignore',fd,fd],windowsHide:true,env:{...process.env,ABYSS_TEST_SERVER:String(await mf.ready).replace(/\/$/,'')}});
  const timer=setTimeout(()=>spawn('taskkill',['/PID',String(child.pid),'/T','/F'],{windowsHide:true}),240000);
  const exit_code=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('exit',resolve);});clearTimeout(timer);fs.closeSync(fd);
  const log=fs.readFileSync(filename,'utf8'),lines=log.split(/\r?\n/);
  const errors=lines.filter(s=>(s.includes('SCRIPT ERROR:')||s.startsWith('ERROR:')||s.startsWith('FAIL:'))&&!s.includes('root certificate store'));
  const summary=lines.filter(s=>/CHECKS|checks|FAILURES|failures|PASS|TESTS:|Exported/.test(s)).slice(-3);
  const row={name,exit_code,errors,summary,seconds:(Date.now()-start)/1000};results=results.filter(r=>r.name!==name);results.push(row);
  fs.writeFileSync(path.join(out,'regression.json'),JSON.stringify(results,null,2));
  console.log(name,exit_code===0&&!errors.length?'PASS':'FAIL',JSON.stringify(summary));
 }
 console.log('GROUPS',results.length,'FAILED',results.filter(r=>r.exit_code!==0||r.errors.length).length);
 process.exitCode=results.some(r=>r.exit_code!==0||r.errors.length)?1:0;
}finally{await mf.dispose();}
