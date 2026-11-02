local out={drain={},heal={}}
do
 local st=fresh(); local keys={"atk","def","bs","bl","g2","red","red20","red25","spd"}
 for _,key in ipairs(keys) do B.badd(st.u[1],key,.1,99) end
 out.strip={}
 for step=1,9 do
  B.e_after_hit(st,5,{strip=true},1,{d=100},0)
  local remaining={}; for _,key in ipairs(keys) do remaining[#remaining+1]=B.bhas(st.u[1],key) end
  out.strip[step]=remaining
 end
end
for _,hp in ipairs({1000,5,500}) do
 local st=fresh(); st.cur=5; st.seed=12345; st.n=0; B.rbegin(st)
 st.u[5].hp=hp; st.u[1].gq={reflect=10}; st.fl={"apprentice_doll","apprentice_doll"}
 if hp==500 then st.u[1].sh=60; st.u[1].gq={} end
 for i=1,3 do st.u[i].rc="demon" end
 st.u[5].it=1; B.e_attack(st,5,{name="test",kind="atk",m=1,drain=.5},1)
 out.drain[#out.drain+1]={start=hp,hp=st.u[5].hp,ally=st.u[1].hp,mp=st.u[1].mp,alive=st.u[5].al==1}
end
for _,kind in ipairs({"heal","haste"}) do
 local st=fresh(); st.u[1].hp=500; st.u[1].g=10000
 for i=1,3 do st.u[i].rc="demon" end
 if kind=="heal" then st.u[1].gq={heal=100} else st.u[1].gu={{key="heal_haste",p=100,x=50,n=1}} end
 B.ACT=st.u[1]; B.SKON=true; st.seed=12345; st.n=0; B.rbegin(st)
 local count=0; local rnd=B.rnd; B.rnd=function(s) count=count+1; return rnd(s) end
 B.attack(st,1,5,{name="test",id="atk",m=100,ab=0})
 B.rnd=rnd
 out.heal[#out.heal+1]={kind=kind,hp=st.u[1].hp,g=st.u[1].g,rng=st.rs,draws=count,skill_restored=B.SKON==true}
end
for seed=1,1000 do
 local st=fresh(); st.cur=5; st.seed=seed; st.n=1; B.rbegin(st)
 for i=1,3 do st.u[i].na="kern" end
 st.u[1].gq={reflect=10}; st.fl={"apprentice_doll","apprentice_doll"}
 local reflected=0; local strike=B.strike
 B.strike=function(s,t,d,at,mul,src)
  local res=strike(s,t,d,at,mul,src)
  if src=="fixed" and t==5 then reflected=reflected+(res.d or 0) end
  return res
 end
 st.u[5].it=1; B.e_attack(st,5,{name="test",kind="atk",m=1},1)
 B.strike=strike
 if st.u[5].hp<990 then
  out.counter={seed=seed,hp=st.u[5].hp,rng=st.rs,ally=st.u[1].hp,reflected=reflected}; break
 end
end
do
 local st=fresh(); st.cur=5; st.seed=1; st.n=1; B.rbegin(st)
 for i=1,3 do st.u[i].na="kern" end
 st.u[5].hp=500; st.u[5].it=1; st.u[1].gq={reflect=10}; B.badd(st.u[1],"atk",.5,3)
 B.e_attack(st,5,{name="test",kind="atk",m=1,drain=.5,push=.2,dot={m=.3,turns=3},strip=true})
 out.ordering={hp=st.u[5].hp,g=st.u[1].g,attack=B.bget(st.u[1],"atk"),dot=st.u[1].edot[1].d,life=st.u[1].edot[1].n}
end
return out
