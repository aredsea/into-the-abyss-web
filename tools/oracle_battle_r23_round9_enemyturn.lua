local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local fields={'hp','mhp','mp','sh','shT','g','al','df','am','bt','ay','ym','dr','ia','it','tau','oath','oT','mk','chg','bf','x','sp','sil','dot','edot','lf'}
local ids={};for id in pairs(B.FOES)do ids[#ids+1]=id end;table.sort(ids)
for _,id in ipairs(ids)do
 local specimen=fresh();specimen.fl[1]=id;B.bind(specimen);local acts=#B.DEF[5].acts
 for ai=1,acts do for _,damaged in ipairs({false,true})do
  local s=fresh();s.fl[1]=id;B.bind(s);s.rs=12345;s.u[5].ia=ai;s.u[5].ph=B.DEF[5].ph2 and 1 or 0;s.u[5].rd=B.DEF[5].grade=='boss'and 1 or 0;s.u[5].add=B.DEF[5].grade=='minion'and 1 or 0
  for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;B.DEF[i].wk={};s.u[i].x={};s.u[i].edot={};s.u[i].hp=damaged and 500 or 1000 end
  local input={state=cp(s),defs=cp(B.DEF),skills=cp(B.SK),id=id,action=ai}
  B.enemy_turn(s,5)
  local units={};for i,u in ipairs(s.u)do local w={};for _,k in ipairs(fields)do if u[k]~=nil then w[k]=cp(u[k])end end;units[i]=w end
  local value={n=s.n,tn=s.u[5].tn,pt=s.u[5].pt,hid=s.u[5].hid,cq=s.u[5].cq or 0}
  out.rows[#out.rows+1]={op='enemy_turn',input=input,expected={units=units,events=s.ev.list,h=s.ev.h,log=s.log,T=s.ev.T,rng=s.rs,value=value,nd=s.nd,kill=s.kill}}
  out.counts.enemy_turn=(out.counts.enemy_turn or 0)+1
 end end
end
return out
