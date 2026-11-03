import fs from 'node:fs';
import crypto from 'node:crypto';
import {mkSim} from 'file:///C:/Clauede%20Code/dungeon-bot/bot/lua_sim.mjs';
const source='C:/Clauede Code/dungeon-bot/bot/';
const files=['src/74-affection.lua','src/77-explore.lua'];
const extra=files.map(f=>'do\n'+fs.readFileSync(source+f,'utf8')+'\nend').join('\n');
const {sim,L}=await mkSim({lua:source+'dist/bot.lua',policy:false,extra});
try {
 const out=await L(`local out={format={},note={}}
 for i=-30000,30000 do local n=i/100;out.format[#out.format+1]={value=n,text=B.aff_fmt(n)}end
 for _,lang in ipairs({'ko','en'})do
  B.LANG=lang;local G={persona={name='가온'},roster={'lynette'},aff={lynette=199.75}};local R={pm={{id='lynette'}},wins=1};local S={}
  B.ex_aff_note(G,R,'retreat',S);out.note[#out.note+1]={lang=lang,value=S.aff,after=G.aff.lynette}
 end
 return out`);
 fs.writeFileSync('verification/parity-r23/expe-format-oracle.json',JSON.stringify(out,null,2)+'\n');
 fs.writeFileSync('verification/parity-r23/expe-format-provenance.json',JSON.stringify({files:[...files,'dist/bot.lua','lua_sim.mjs'].map(f=>({file:'bot/'+f,sha256:crypto.createHash('sha256').update(fs.readFileSync(source+f)).digest('hex')})),format:out.format.length,notes:out.note.length},null,2)+'\n');
 console.log(JSON.stringify({format:out.format.length,notes:out.note.length}));
} finally {if(sim.close)await sim.close();}
