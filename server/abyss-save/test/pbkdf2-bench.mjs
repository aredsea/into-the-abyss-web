// Run the shipped hash function in actual workerd, isolated from D1 and rate limits.
import {runtime} from './runtime.mjs';
import fs from 'node:fs';
import readline from 'node:readline';
const source=fs.readFileSync(new URL('../src/index.js',import.meta.url),'utf8');
const hash=source.slice(source.indexOf('async function hash('),source.indexOf('async function authenticate('));
const hex=source.slice(source.indexOf('const hex='),source.indexOf('async function hash('));
const script=hex+hash+`export default {async fetch(request){const n=Number(new URL(request.url).searchParams.get('n'));if(n)await hash('23456789AB','local-performance-fixture',n);return new Response('ok');}};`;
const {mf}=await runtime(undefined,{}, {script});
try{
 for(let i=0;i<5;i++)await (await mf.dispatchFetch('http://localhost/?n=5000')).text();
 console.log(JSON.stringify({ready:true,pid:process.pid}));
 for await(const line of readline.createInterface({input:process.stdin})){
  if(line==='quit')break;
  const iterations=Number(line),times=[];
  for(let i=0;i<100;i++){const start=performance.now();await (await mf.dispatchFetch('http://localhost/?n='+iterations)).text();times.push(performance.now()-start);}
  const sorted=times.toSorted((a,b)=>a-b);console.log(JSON.stringify({iterations,n:times.length,wall_mean_ms:times.reduce((a,b)=>a+b,0)/times.length,wall_p95_ms:sorted[94]}));
 }
}finally{await mf.dispose();process.stdin.destroy();}
