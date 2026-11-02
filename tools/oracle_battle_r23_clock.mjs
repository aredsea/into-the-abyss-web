import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const root='C:/Clauede Code/dungeon-bot';const {mkSim}=await import(pathToFileURL(path.join(root,'bot/lua_sim.mjs')).href);
const files=['05-gen.lua','10-data.lua','20-state.lua','24-stats.lua','27-compose.lua','30-engine.lua','29-persona-skill.lua','31-foes.lua','32-personal-a.lua','32-personal-b.lua','34-traits.lua','81-gear.lua'];
const extra=files.map(f=>`${f==='34-traits.lua'?'B.GH={}':''}\ndo\n${fs.readFileSync(path.join(root,'bot/src',f),'utf8')}\nend`).join('\n');const {L}=await mkSim({policy:false,extra});
const fresh=fs.readFileSync('tools/oracle_combat_a6_r22.lua','utf8').split('local out=')[0];
const rows=await L(fresh+`
local out={}
for _,count in ipairs({0,1,8,60,61,100}) do for _,cur in ipairs({0,1,5}) do for alive=0,2 do
 local st=fresh();st.cur=cur;local units={}
 for i,u in ipairs(st.u) do
  u.al=(alive==0 or (alive==1 and i%2==1)) and 1 or 0;u.hp=u.al==1 and 1000 or 0
  u.g=(i-2)*.25;u.sp=100+i*17.137;units[i]={id='u'..i,hp=u.hp,remaining=u.g,speed=u.sp}
 end
 local before=json.encode(st);local got=B.preview(st,count)
 out[#out+1]={count=count,cur=cur,alive=alive,units=units,expected=got,unchanged=before==json.encode(st)}
end end end
return out`);
const provenance=Object.fromEntries(files.map(f=>[f,crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'bot/src',f))).digest('hex')]));
fs.writeFileSync('verification/parity-r23/clock-oracle.json',JSON.stringify({rows,provenance},null,2)+'\n');console.log(JSON.stringify({cases:rows.length}));process.exit(0);
