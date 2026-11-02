local first=#P4_FIXTURES
for _,eq in ipairs({false,{}, {weapon='bad'},{weapon='zz99.1.1'}})do
 fixture(state(1),'gear_init',{{cls='warrior',L=40,eq=eq}},nil,nil,'r23:empty-or-invalid-equipment')
end
for _,cost in ipairs({0,1,20})do for _,mp in ipairs({0,99,100})do for _,p in ipairs({0,100})do
 local st=state(1);st.u[1].gu={{key='echo',p=p,x=30,n=1}};st.u[1].mp=mp
 fixture(st,'gear_echo',{1,cost},nil,nil,'r23:echo-boundary')
end end end
for _,by in ipairs({0,1,4,5,7,8})do
 fixture(state(1),'gear_dot',{by,100},nil,nil,'r23:dot-invalid-owner')
end
for _,target in ipairs({1,5})do for _,alive in ipairs({0,1})do for _,lines in ipairs({0,1,3})do
 local st=equipped('un_chain');st.u[target].al=alive;st.u[target].dot={}
 for i=1,lines do st.u[target].dot[i]={d=10,n=3,k=1}end
 fixture(st,'gear_dotchain',{target,1},nil,nil,'r23:chain-count-target-alive')
end end end
for _,enemy in ipairs({1,4,5})do
 local st=state(1);st.u[1].gq={reflect=50};st.gt={t=1,e=5,d=40,x=50,n=7}
 fixture(st,'attacked',{1,enemy,{d=50},3},nil,nil,'r23:attacker-side')
end
for _,i in ipairs({1,4,5,7})do
 local st=state(1);st.u[i].x={fzn=1,lsn=0,wwn=-1,adv=1000}
 fixture(st,'turn_end',{i},nil,nil,'r23:turn-side-and-expiry')
end
for _,dr in ipairs({0,1})do for _,mp in ipairs({0,100})do
 local st=equipped('ch_void');st.u[5].dr=dr;st.u[1].mp=mp
 fixture(st,'abyss_after',{1,5,20,3,{}},nil,nil,'r23:drain-mana-boundary')
end end
local out={};for i=first+1,#P4_FIXTURES do out[#out+1]=P4_FIXTURES[i]end
return out
