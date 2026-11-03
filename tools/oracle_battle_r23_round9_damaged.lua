local out={rows={},counts={}}
local function cp(v)return json.decode(json.encode(v))end
local kinds={};for id in pairs(B.TR)do kinds[#kinds+1]=id end;table.sort(kinds)
local fields={'hp','mhp','mp','sh','shT','g','al','df','am','bt','ay','ym','dr','ia','it','tau','oath','oT','mk','chg','bf','x','sp','sil','dot','edot','lf'}
for _,kind in ipairs(kinds)do for bits=0,31 do
 local s=fresh();s.rs=12345
 for i=1,6 do B.DEF[i].name='unit'..i;B.DEF[i].full='unit'..i;s.u[i].x={};s.u[i].edot={}end
 B.DEF[1].cid=kind;s.u[1].x.emg=bits//2%3
 if bits>=16 then s.u[1].al=0;s.u[1].hp=0 end
 s.u[2].hp=bits%2==1 and 250 or 251
 if bits//4%2==1 then s.u[2].hp=0;s.u[2].al=0 end
 B.DEF[2].cid=bits//8%2==1 and 'adeline' or 'neutral'
 for i=1,4 do s.u[i].bf.red={v=.1,n=2,src=2};s.u[i].bf.red20={v=.2,n=2,src=1};s.u[i].x.areg={d=10,n=2,src=2}end
 local input={state=cp(s),defs=cp(B.DEF),kind=kind,at=bits%2==1 and .125 or 1.5}
 B.fire(s,'damaged',2,10,5,input.at)
 local units={};for i,u in ipairs(s.u)do local v={};for _,k in ipairs(fields)do if u[k]~=nil then v[k]=cp(u[k])end end;units[i]=v end
 out.rows[#out.rows+1]={op='damaged',input=input,expected={units=units,events=s.ev.list,h=s.ev.h,log=s.log,T=s.ev.T,rng=s.rs,value=false,nd=s.nd,kill=s.kill}}
 out.counts.damaged=(out.counts.damaged or 0)+1
end end
return out
