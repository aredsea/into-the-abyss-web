-- The loader prefixes the common scenario/observation helpers from round7.lua.
local cycle
for _,id in ipairs(B.FOE_ORDER) do if B.FOES[id].ph2 and B.FOES[id].ph2.cycle then cycle=id;break end end
assert(cycle)
for _,roll in ipairs({0,1}) do
 local s=base();s.fl={cycle,cycle};s.fg={'boss','boss'};s.raid=1;B.bind_foes(s)
 for j=5,6 do s.u[j].ph=1;s.u[j].rd=1;s.u[j].cq=1;s.u[j].ay=1;s.u[j].ym=150;s.u[j].dr=1;s.u[j].hp=500 end
 local old=B.rnd;B.rnd=function()return roll end
 invoke('phase',s,{foe=cycle,forced_roll=roll},function()return B.phase_check(s)end);B.rnd=old
end
for _,kind in ipairs({'missing','atk','guard','charge','buff','debuff','dot','heal','summon','protect','special'}) do
 local s=base();local a={kind=kind,name='test',ic='attack',stat='atk',amount=.2,m=1,enemy='apprentice_doll',count=1}
 invoke('dispatch',s,{action=a},function()return B.e_act(s,5,a)end)
end
return out
