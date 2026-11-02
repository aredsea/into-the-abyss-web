// Invariant scan: no path may accept an arbitrary nested object; no allowed-but-absent key may accept one.
import fs from 'node:fs';
const B="C:/Users/asone/Documents/Codex/2026-10-30/into-the-abyss-handoff/work/r21-d-town/";
const mode=process.argv[2];
const {validate}=await import(mode==='fixed'?'./validate.js':'file:///'+B+'server/abyss-save/src/validate.js');
const src=fs.readFileSync(B+'server/abyss-save/src/validate.js','utf8');
const cand=[...new Set([...src.matchAll(/'([a-z_][a-z0-9_]{1,40})'/g)].map(m=>m[1]))];
const files=['verification/town-r21/round11/save-specimens.json','verification/expedition-r22/save-specimens.json','verification/facilities-r22/save-specimens.json','verification/cloud-r22/p9b/legitimate-fixtures.json','verification/cloud-r22/fixtures.json'];
const samples=[];for(const f of files)for(const[k,s]of Object.entries(JSON.parse(fs.readFileSync(B+f,'utf8'))))samples.push([f.split('/').slice(-2).join('/')+':'+k,s]);
const BLOB={zz:{yy:[1,'q',{x:true}]}};
const ok=s=>{try{validate(s);return true;}catch{return false;}};
const sig=p=>p.map(x=>typeof x==='number'?'#':x).join('.');
const replaced=new Map(),added=new Map();const seenR=new Set(),seenA=new Set();
for(const[name,s0]of samples){
 if(!ok(s0))continue;
 const walk=(v,p)=>{
  if(p.length>6)return;
  if(p.length){const g=sig(p);if(!seenR.has(g)){seenR.add(g);const s=structuredClone(s0);let o=s;for(const k of p.slice(0,-1))o=o[k];o[p.at(-1)]=structuredClone(BLOB);if(ok(s))replaced.set(g,name);}}
  if(v&&typeof v==='object'&&!Array.isArray(v)){
   const g=(sig(p)||'<root>')+'|'+Object.keys(v).sort().join(',');if(!seenA.has(g)){seenA.add(g);for(const k of cand){if(k==='__proto__'||Object.hasOwn(v,k))continue;const s=structuredClone(s0);let o=s;for(const q of p)o=o[q];o[k]=structuredClone(BLOB);if(ok(s))added.set(g+' +'+k,name);}}
   for(const[k,x]of Object.entries(v))walk(x,[...p,k]);
  }else if(Array.isArray(v))v.slice(0,2).forEach((x,i)=>walk(x,[...p,i]));
 };
 walk(s0,[]);
}
console.log(JSON.stringify({samples:samples.length,candidates:cand.length,pathsTried:seenR.size,nodesTried:seenA.size,replaceAccepted:[...replaced],addAccepted:[...added]},null,1));
