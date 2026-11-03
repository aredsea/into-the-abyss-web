import fs from 'node:fs';
let loader=fs.readFileSync('tools/expe_r23_pass3_oracle.mjs','utf8').split('try {')[0].replace("path.resolve(import.meta.dirname,'..')",'process.cwd()');
loader+=`
try {
 const rows=JSON.parse(fs.readFileSync('verification/parity-r23/expe-pass6-ui-observations.json','utf8'));
 const output=[];
 for(const row of rows){
  const data=JSON.stringify(row);
  const html=await L('local r=json.decode([=['+data+']=]);local G=r.G;B.LANG=r.lang;local m=B.SO.members(G);if r.kind=="slots"then return B.R23_sortie.slots(G,m)elseif r.kind=="fight"then return B.R23_sortie.fight(G)elseif r.kind=="quest"then return B.R23_sortie.quest(G,r.extra.q)elseif r.kind=="dungeon_card"then return B.dn_card(G)elseif r.kind=="heading"then return B.tw_hd(r.extra.icon,B.esc(r.extra.text))elseif r.kind=="hint"then return B.tw_hint(B.esc(r.extra.text))elseif r.kind=="place"then local p=r.extra.place;return B.tw_pbtn("tw_"..p.scene,p.ic,B.U(p.name),B.U(p.d))end');
  output.push({...row,html});
 }
 fs.writeFileSync('verification/parity-r23/expe-pass6-ui-source.json',JSON.stringify(output,null,2)+'\\n');
 console.log('Actual painted inputs rerun in canonical Lua: '+output.length);
} finally {if(sim.close)await sim.close();}
`;
await import('data:text/javascript;base64,'+Buffer.from(loader).toString('base64'));
