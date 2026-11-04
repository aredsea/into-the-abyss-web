// Feed the native screen's saved observable inputs back through the real Lua.
import fs from 'node:fs';
let loader=fs.readFileSync('tools/expe_r23_pass3_oracle.mjs','utf8').split('try {')[0];
loader=loader.replace("path.resolve(import.meta.dirname,'..')",'process.cwd()');
loader+=`
try {
 const input=fs.readFileSync('verification/parity-r23/expe-pass5-ui-observations.json','utf8');
 const result=await L('local rows=json.decode([=['+input+']=]);local out={};for _,r in ipairs(rows)do B.LANG=r.lang;r.G.dungeon.run=r.R;local h;if r.kind=="sortie"then local m=B.SO.members(r.G);local _,_,avg=B.dn_party(r.G);h=B.R23_sortie.cards(r.G)..B.R23_sortie.summary(r.G,{lv=B.dn_floor_view(r.G.dungeon.sel,avg).el},m) elseif r.kind=="explore"then local sub=r.R.phase=="rest"and B.U("휴식")or(r.R.step==0 and B.U("입장")or B.U("탐색 {step}/{total}",{step=r.R.step,total=5}));h=B.R23P3.head(r.G,r.R,sub)..B.R23P3.last(r.R)..B.R23P3.party(r.G,r.R,true)..(r.R.phase=="rest" and B.R23P3.gear(r.G,r.R) or "") elseif r.kind=="retreat"then h=B.R23P3.retreat(r.R)else h=B.R23P3.done(r.G,r.R)end;out[#out+1]={kind=r.kind,lang=r.lang,html=h}end;return out');
 fs.writeFileSync('verification/parity-r23/expe-pass5-ui-lua.json',JSON.stringify(result,null,2)+'\\n');
 console.log(JSON.stringify({source_screen_comparisons:result.length}));
} finally {if(sim.close)await sim.close();}
`;
await import('data:text/javascript;base64,'+Buffer.from(loader).toString('base64'));
