local out={}
local kinds={'atk','snipe','wave','burst','eatk','shield','taunt','def','oath','mark','rev','chg','cut','trait','deplete','recover','edef','ebuff','eall','edeb','eheal','item','esum','echg','ecut','phase','adot','end'}
for _,kind in ipairs(kinds) do for variant=0,9 do
 local st=fresh();local target=(kind=='eatk' or kind=='eall' or kind=='adot') and 1 or 5
 local tg={}
 for i=0,1 do tg[#tg+1]={i=target+i,d=600,sh=({0,60,600})[variant%3+1],c=(variant%3==1) and 1 or 0,kill=0,ab=0,tags=(variant%3==2) and {'약점 화염'} or {},f='hp'} end
 local e={k=kind,a=(target==1) and 5 or 1,t=.15,ht=.6,nm=(variant==1) and '일반 공격' or 'test',d=10,win=variant%2,el='fire',tg=tg,last=variant>=6,shoot=variant%2,big=(variant%3==0) and 1 or 0,pc=(variant==9) and true or nil}
 local observed,saved={},{}
 for name,tag in pairs({fx_result='hit',fx_dn='number',fx_cn='critical',fx_cutin='cut',fx_pcutin='pcut',fx_plaque='plaque'}) do
  local old=B[name];saved[name]=old;local label=tag
  B[name]=function(...)
   local args={...};local at=(label=='hit') and args[3] or ((label=='cut') and args[5] or ((label=='pcut') and args[4] or args[2]))
   observed[#observed+1]={kind=(label=='pcut') and 'cut' or label,t=at};return old(...)
  end
 end
 local L={u={},panel='',party='',field='',cls={},vars={},bz={},icwf={},hit={},hk={},lun={},trg={},drn={},cuts={},muzzle={}}
 B.fx_event(st,e,L)
 for name,fn in pairs(saved) do B[name]=fn end
 out[#out+1]={event=e,variant=variant,expected=observed}
end end
return out
