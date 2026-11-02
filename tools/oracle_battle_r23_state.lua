local out={}
local ids={'felice','naran','levia','marceline'}
local function dump(st,n)
 local us={}
 for i=1,n do
  local u,d=st.u[i],B.DEF[i]
  us[i]={hp=u.hp,mhp=u.mhp,mp=u.mp,mmp=u.mmp,g=u.g,sp=u.sp,cs=u.cs,de=u.de,ag=u.ag,cr=u.cr,row=d.row,element=d.el,cls=d.clsid}
 end
 return us
end
for n=1,4 do for _,level in ipairs({1,10,40}) do for variant=0,3 do
 local pm,carry={},{hp={},mp={}}
 for i=1,4 do
  pm[i]={id=i<=n and ids[i] or '',cls=i<=n and B.cls_of(B.CAST[ids[i]].cls).id or 'warrior',L=level}
  if i<=n then
   if variant==1 then carry.hp[i]=1;carry.mp[i]=0 end
   if variant==2 and i==n then carry.hp[i]=0;carry.mp[i]=0 end
   if variant==3 then carry.hp[i]=0;carry.mp[i]=0 end
  end
 end
 local run=B.run;B.run=function()end
 local st=B.fresh(1,nil,{pm=pm,carry=carry,enc={fl={'apprentice_doll'},fg={''},ne=1,star=1,raid=false},el=1})
 B.run=run
 local initial=dump(st,n)
 st.tk=0;B.fire(st,'turn_end',1);st.tk=200;B.fire(st,'turn_end',1)
 out[#out+1]={n=n,level=level,variant=variant,ids=ids,initial=initial,later=dump(st,n)}
end end end
return out
