// Observe the source wrapper's real predecessor call; native replay starts at
// the captured gear boundary. This does NOT claim native custom callback APIs.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'..'),src='C:/Clauede Code/dungeon-bot/bot';
const read=n=>fs.readFileSync(src+'/src/'+n,'utf8');
const {mkSim}=await import(pathToFileURL(src+'/lua_sim.mjs'));
const pre=`
B.GH={};local function cp(x)return json.decode(json.encode(x))end
local mode=0;local checkpoint
for _,method in ipairs({'damaged','attacked','turn_end','abyss_after'})do
 B.GH[method]=function(st,...)
  local args={...};st.calls[#st.calls+1]={k='predecessor',args={method,mode}}
  if mode==1 then
   if method=='damaged' then st.u[args[1]].hp=1
   elseif method=='attacked' then args[3].d=80
   elseif method=='turn_end' then st.u[args[1]].x.adv=1000
   else st.u[args[2]].dr=1;st.u[args[1]].mp=0 end
  elseif mode==2 then
   if method=='damaged' then st.u[args[1]].al=0
   elseif method=='attacked' then st.u[args[2]].al=0
   elseif method=='turn_end' then st.u[args[1]].al=0
   else st.u[args[2]].dr=0 end
  end
  checkpoint={state=cp(st),args=cp(args)}
  return 'ignored_predecessor_return'
 end
end
B.R23_MODE=function(n)mode=n end
B.R23_CHECKPOINT=function()return checkpoint end
`;
const {sim,L}=await mkSim({policy:false,extra:[read('05-gen.lua'),read('10-data.lua'),read('24-stats.lua'),pre,read('81-gear.lua')].join('\n')});
const primitives=fs.readFileSync(root+'/tools/gear_r22_hook_oracle.lua','utf8').split('local specs=')[0];
const out=await L(primitives+`
local out={}
for _,method in ipairs({'damaged','attacked','turn_end','abyss_after'})do for mode=0,2 do for _,side in ipairs({1,5})do
 local st=state(1);st.u[1].gu={{key='wa_scar',v={30,50}},{key='last_stand',x=30,n=2},{key='ch_void',v={20,10}}};st.u[1].gq={reflect=50};st.u[1].x={fzn=1,lsn=1,wwn=1};st.gt={t=1,e=5,d=40,x=50,n=7}
 local args=method=='damaged' and {1,30,5,3} or method=='attacked' and {1,side,{d=20},3} or method=='turn_end' and {side} or {1,5,20,3,{}}
 B.R23_MODE(mode);local result=B.GH[method](st,table.unpack(args));local cp=B.R23_CHECKPOINT()
 out[#out+1]={method=method,args=cp.args,before=cp.state,value=json.decode(json.encode(st)),result=result==nil and 'nil' or result,act=0,skill=false,defs=B.DEF,meta='predecessor:'..mode..':side:'..side}
end end end
return out`);
fs.writeFileSync(root+'/verification/parity-r23/predecessors.json',JSON.stringify(out)+'\n');
console.log('Predecessor checkpoints',out.length);sim.close();
