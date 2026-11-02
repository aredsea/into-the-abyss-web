extends RefCounted
## 81-gear slot only. Unit IDs are Lua's 1-based IDs; st.u is a JSON array.
## The owner supplies bridge.callv(name,[st,...]) for engine primitives. No engine
## primitive is emulated here, and callbacks must re-enter the owner's full chain.
const Rules=preload("res://game/gear_rules_r22.gd")
const J=preload("res://game/josa_r22.gd")
const SIGQ={"pa_layer":"shield","as_vital":"critdmg","al_brew":"heal","un_seep":"dot","ch_rift":"abyss"}
var rules
var bridge_ref: WeakRef
var bridge_owner: Object
var bridge: Object:
	get: return bridge_owner if bridge_owner!=null else bridge_ref.get_ref() if bridge_ref!=null else null
	set(value): bridge_owner=value; bridge_ref=null
var act=0
var skill: Variant=null
var defs=[]

func _init(engine: Object=null,shared_rules=null,weak_bridge=false):
	if weak_bridge: bridge_ref=weakref(engine) if engine!=null else null
	else: bridge_owner=engine
	rules=shared_rules if shared_rules!=null else Rules.new()
func u(st: Dictionary,i: int) -> Dictionary:return st.u[i-1]
func uq(w: Dictionary,key: String) -> Dictionary:
	for e in w.get("gu",[]):
		if e.key==key:return e
	return {}
func q(w: Dictionary,key: String) -> float:return float(w.get("gq",{}).get(key,0))
func call_engine(st: Dictionary,name: String,args: Array=[]) -> Variant:
	assert(bridge!=null and bridge.has_method(name),"P4 bridge missing "+name)
	return bridge.callv(name,[st]+args)
func line(st: Dictionary,i: int,txt: String,at: float):call_engine(st,"trait_line",[i,txt,at])
func setf(st: Dictionary,i: int,key: String,value: float,at: float):call_engine(st,"setf",[i,key,value,at])
func rnd(st: Dictionary) -> float:return call_engine(st,"rnd")
func heal(st: Dictionary,i: int,value: float,at: float) -> float:return call_engine(st,"heal",[i,value,at])
func nm(i: int) -> String:return defs[i-1].name
func part(s: String,p: String) -> String:return J.p(s,p)
func r1(v: float) -> float:return floor(v*10+.5)/10
func num(v: float) -> String:return str(int(v)) if v==bf(v) else str(v)
func bf(v: float) -> float:return floor(v+1e-9)
func pct(v: float) -> float:return 1+v/100.0
func T(st: Dictionary) -> float:return st.ev.T
func idx_of(st: Dictionary,w: Dictionary) -> int:
	for i in range(1,5):
		if is_same(u(st,i),w):return i
	return st.cur

func gear_init(st: Dictionary,w: Dictionary,m: Dictionary):
	if not m.get("eq") is Dictionary:return
	var rolls=[];var cls=rules.class_id(m.get("cls",""))
	for s in Rules.SLOTS:
		var code=m.eq.get(s,"")
		if not code is String or code=="":continue
		var rr=rules.gear_roll(code,m.get("L"),m.get("forge",{}).get(code,{}).get("lv",0))
		if not rr.is_empty() and cls!="" and m.has("L") and (rr.item.cls!=cls or rr.lv>m.L):rr={}
		if not rr.is_empty():rolls.append(rr)
	_apply_rolls(st,w,rolls)

func gear_init_native(st: Dictionary,w: Dictionary,m: Dictionary):
	# Exactly one initializer per unit. native_eq includes BOTH legacy and source
	# records; do not also call gear_init or apply model.stats gear percentages.
	var rolls=[];var cls=rules.class_id(m.get("cls",""))
	for slot in Rules.SLOTS:
		var entry=m.get("native_eq",{}).get(slot,{})
		if entry.is_empty() or not rules.by_id.has(entry.get("id","")):continue
		var it=rules.source.items[entry.id]
		if cls!="" and m.has("L") and (it.cls!=cls or rules.source.fx.equip_lv[it.rarity]>m.L):continue
		var rr
		if entry.get("source_r21",false):rr=rules.gear_roll(rules.code(entry),m.get("L"),entry.get("forge",0))
		else:
			rr={"fx":rules.roll(entry,int(m.get("L",it.lv)))}
			if it.has("unique"):rr.unique=it.unique
		if not rr.is_empty():rolls.append(rr)
	_apply_rolls(st,w,rolls)

func _apply_rolls(st: Dictionary,w: Dictionary,rolls: Array):
	var qq={};var list=[]
	for rr in rolls:
		for k in rr.fx:qq[k]=qq.get(k,0)+rr.fx[k]
		var un=rr.get("unique",{})
		if un.is_empty():continue
		if un.get("sig",false):
			list.append({"key":un.key,"v":un.v.duplicate()})
			if not st.has("gk"):st.gk={}
			st.gk[un.key]=true
			if SIGQ.has(un.key):qq[SIGQ[un.key]]=qq.get(SIGQ[un.key],0)+un.v[0]
		else:list.append({"key":un.key,"p":un.p,"x":un.x,"n":un.n})
	if rolls.is_empty():return
	for k in qq:qq[k]=r1(qq[k])
	w.gq=qq
	if not list.is_empty():w.gu=list
	else:w.erase("gu")
	if qq.has("stat"):w.cs*=pct(qq.stat)
	if qq.has("def"):w.de*=pct(qq.def)
	if qq.has("hp"):w.mhp=bf(w.mhp*pct(qq.hp)+.5);w.hp=w.mhp
	if qq.has("mp") and w.mmp>0:w.mmp=bf(w.mmp*pct(qq.mp)+.5);w.mp=w.mmp
	if qq.has("spd"):w.sp=bf(w.sp*pct(qq.spd)+.5)
	if qq.has("crit"):w.cr+=qq.crit

func deal(st: Dictionary,a: int,t: int,m: float,tags: Array,opt: Dictionary={}) -> float:
	var w=u(st,a);var x=w.x;var sum=q(w,"dmg");var mm=1.0
	if defs[t-1].get("kind") in ["elite","boss"] or defs[t-1].get("elite",false):sum+=q(w,"elite")
	if w.hp<=w.mhp*.5:sum+=q(w,"lowhp")
	if w.sh>0:sum+=q(w,"shdmg")
	if x.get("f1")==st.n:sum+=q(w,"first")
	if w.has("gu"):
		var e=uq(w,"abyss_res")
		if not e.is_empty() and u(st,t).dr==1:sum+=e.x
		if x.has("ch") and x.get("chk")!=st.n:
			if not x.has("chu"):x.chu=st.n
			if x.chu==st.n:sum+=x.ch
			else:x.erase("ch");x.erase("chu");x.erase("chk")
		e=uq(w,"pa_wrath")
		if not e.is_empty() and w.sh>0:sum+=e.v[0]
		e=uq(w,"ar_high")
		if not e.is_empty() and defs[a-1].get("row")=="후열":sum+=e.v[0]
		e=uq(w,"sa_comp")
		if not e.is_empty() and opt.get("k")=="burst":sum+=e.v[0]
		if x.get("sws",0)>0 and opt.get("k")=="burst":
			tags.append("방벽 영창 +"+str(int(bf(x.sws))));m+=x.sws;x.sws=0
		e=uq(w,"un_blood")
		if not e.is_empty() and x.get("blc",0)>0 and x.get("blk")!=st.n:x.blk=st.n;x.blu=x.blc;x.blc=0
		if not e.is_empty() and x.get("blk")==st.n and x.get("blu",0)>0:sum+=e.v[1]*x.blu
		e=uq(w,"gl_hunger")
		if not e.is_empty() and w.hp<=w.mhp*e.v[0]/100.0:sum+=e.v[1]
		e=uq(w,"ch_rift")
		if not e.is_empty() and u(st,t).dr==1:sum+=e.v[1]
		e=uq(w,"as_hunt")
		if not e.is_empty() and x.has("hbk") and x.hbk!=st.n:
			if not x.has("hbu"):x.hbu=st.n
			if x.hbu==st.n:sum+=e.v[1]
			else:x.erase("hbk");x.erase("hbu")
		e=uq(w,"ch_full")
		if not e.is_empty() and u(st,t).dr==1:
			mm=e.v[0]/2.5
			if opt.get("name")=="혼돈 파동":mm*=e.v[1]
		if x.get("scr",0)>0:tags.append("되갚는 상처 +"+str(int(bf(x.scr))));m+=x.scr;x.scr=0
	var pd=0.0
	for i in range(1,5):
		var pw=u(st,i);var e=uq(pw,"party_dmg")
		if pw.al==1 and not e.is_empty():pd=maxf(pd,e.x)
	sum+=pd
	if mm!=1:tags.append("완전한 공명 ×"+str(r1(mm)));m*=mm
	if sum!=0:tags.append("장비 "+("+" if sum>0 else "")+str(r1(sum))+"%");m*=pct(sum)
	return m

func gear_adv(st: Dictionary,i: int,amt: float):
	var w=u(st,i)
	if i==st.cur:w.x.adv=w.x.get("adv",0)+amt
	else:w.g=maxf(0,w.g-amt)

func gear_kill(st: Dictionary,a: int,at: float):
	var w=u(st,a);var x=w.x
	if q(w,"killmp")!=0:
		var n=bf(q(w,"killmp")+.5)
		if n>0 and w.mp<w.mmp:setf(st,a,"mp",minf(w.mmp,w.mp+n),at+.3);line(st,a,"처치의 기운: MP +"+str(int(n)),at+.3)
	var e=uq(w,"chain")
	if not e.is_empty():x.ch=e.x;x.chk=st.n;x.erase("chu");line(st,a,"연쇄: 다음 공격의 피해 +"+num(e.x)+"%",at+.3)
	e=uq(w,"as_hunt")
	if not e.is_empty() and act==a and x.get("huc",0)<e.v[0]:
		x.huc=x.get("huc",0)+1;x.hbk=st.n;x.erase("hbu");gear_adv(st,a,10000);line(st,a,"사냥꾼의 흐름: 바로 한 번 더 행동한다",at+.3)
	e=uq(w,"ar_chain")
	if not e.is_empty() and skill is String and skill=="snipe" and act==a:
		var back=bf(x.get("lmc",0)*e.v[1]/100.0+.5)
		if back>0 and w.mp<w.mmp:setf(st,a,"mp",minf(w.mmp,w.mp+back),at+.3)
		gear_adv(st,a,e.v[0]*100);line(st,a,"연쇄 사격: MP "+part(str(int(back)),"을를")+" 돌려받고 다음 차례가 "+num(e.v[0])+"% 빨라진다",at+.3)
	e=uq(w,"gl_king")
	if not e.is_empty():
		var sk=skill;skill=null
		var h=heal(st,a,w.mhp*e.v[0]/100.0,at+.3);skill=sk
		if h>0:line(st,a,"투기장의 왕: 처치로 HP +"+str(int(h)),at+.3)

func gear_skill(st: Dictionary,i: int,id: String):
	var w=u(st,i);var x=w.x
	if id=="taunt":
		var e=uq(w,"wa_wall")
		if not e.is_empty():x.wwn=e.v[1]+1;line(st,i,"철벽 함성: "+num(e.v[1])+"턴 동안 받는 피해 −"+num(e.v[0])+"%",T(st))
	elif id=="pshield":
		var e=uq(w,"pr_swift")
		if not e.is_empty():
			for a in range(1,5):
				if u(st,a).al==1:gear_adv(st,a,e.v[0]*100)
			line(st,i,"신속의 기도: 파티의 다음 차례가 "+num(e.v[0])+"% 빨라진다",T(st))
	elif id=="heal" and x.get("sgs",0)>0:line(st,i,"넘치는 생기: 넘친 회복이 보호막 "+part(str(int(x.sgs)),"이가")+" 되었다",T(st));x.erase("sgs")

func gear_mpc(w: Dictionary,sk: Dictionary) -> float:
	var mp=sk.get("mp",0);var e=uq(w,"ar_wind") if sk.id=="snipe" else {}
	return bf(mp*(1-e.v[0]/100.0)+.5) if not e.is_empty() and mp>0 else mp

func gear_save(st: Dictionary,t: int,at: float) -> int:
	var w=u(st,t);var e=uq(w,"wa_last")
	if e.is_empty() or w.x.has("wlu"):return 0
	w.x.wlu=1;setf(st,t,"hp",maxf(1,bf(w.mhp*e.v[0]/100.0+.5)),at)
	st.gw={"n":e.v[1]+(1 if st.cur==t else 0),"p":e.v[2],"who":t}
	line(st,t,"마지막 성벽: HP "+num(e.v[0])+"%로 버티고 자신의 "+num(e.v[1])+"턴 동안 파티가 받는 피해 −"+num(e.v[2])+"%",at)
	call_engine(st,"say",["<b>"+nm(t)+"</b>의 <b>마지막 성벽</b> 덕에 쓰러질 일격을 버텨 냈다",at+.2]);return 1

func gear_splash(st: Dictionary,i: int,tgt: int,val: float):
	if uq(u(st,i),"al_splash").is_empty():return
	for j in [tgt-1,tgt+1]:
		if j>=5 and j<=st.u.size() and u(st,j).al==1:call_engine(st,"badd",[j,"ddn",val,3])

func gear_dottick(st: Dictionary,wb: Array,at: float):
	var seen=[]
	for i in wb:
		if i in seen:continue
		seen.append(i);var w=u(st,int(i));var e=uq(w,"un_blood")
		if not e.is_empty() and w.al==1:
			w.x.blc=minf(e.v[2],w.x.get("blc",0)+1)
			if w.mp<w.mmp:setf(st,int(i),"mp",minf(w.mmp,w.mp+e.v[0]),at)
			line(st,int(i),"피의 대가: MP +"+num(e.v[0])+", 다음 공격 피해 +"+num(w.x.blc*e.v[1])+"%",at)

func gear_dotchain(st: Dictionary,t: int,by: int):
	var w=u(st,t);var e=uq(u(st,by),"un_chain")
	if e.is_empty() or w.al!=1:return
	var c=0;var sum=0.0
	for x in w.dot:
		if x.k==1:c+=1
		sum+=x.d*x.n
	if c<e.v[0] or t<5:return
	sum=bf(sum*pct(e.v[1]));w.dot=[]
	var res=call_engine(st,"strike",[t,sum,T(st)+.3,null,null])
	call_engine(st,"push",[{"k":"dot","a":t,"t":T(st),"tg":[res]}])
	call_engine(st,"say",["<b>"+nm(by)+"</b>의 <b>연쇄 폭발</b>. "+part(nm(t),"에게")+" 남은 지속 피해가 한꺼번에 들어가 <em>"+str(int(res.d))+"</em> 피해를 입혔다"+(". 쓰러졌다" if res.kill==1 else ""),T(st)+.5])
	if res.kill==1:st.kill=defs[by-1].full+"의 연쇄 폭발";call_engine(st,"kill_credit",[by,T(st)+.3])

func gear_begin(st: Dictionary,i: int):
	var w=u(st,i);var n=bf(q(w,"mpreg")+.5)
	if n>0 and w.mp<w.mmp:setf(st,i,"mp",minf(w.mmp,w.mp+n),T(st))
	var e=uq(w,"taunt_heal")
	if not e.is_empty() and w.tau>0:
		var h=heal(st,i,w.mhp*e.x/100.0,T(st)+.2)
		if h>0:line(st,i,"버티는 자: HP +"+str(int(h)),T(st)+.2)

func gear_echo(st: Dictionary,i: int,cost: float):
	var w=u(st,i);w.x.lmc=cost;var e=uq(w,"echo")
	if e.is_empty() or rnd(st)*100>=e.p:return
	var back=bf(cost*e.x/100.0+.5)
	if back<=0 or w.mp>=w.mmp:return
	setf(st,i,"mp",minf(w.mmp,w.mp+back),T(st));line(st,i,"메아리: MP "+str(int(back))+" 되돌려 받는다",T(st))

func gear_dot(st: Dictionary,by: int,d: float) -> Array:
	if by<1 or by>4 or by>st.u.size():return [d,null]
	var w=u(st,by);var e=uq(w,"dot_burst")
	if w.get("gq",{}).has("dot"):d=bf(d*pct(q(w,"dot"))+.5)
	return [d,e.get("x")]

func gear_shbreak(st: Dictionary,t: int,ab: float,src: Variant):
	if st.get("gk",{}).get("pa_echo",false):st.gb={"t":t,"d":ab}
	if not (src is int or src is float) or src<5:return
	var e=uq(u(st,t),"thorns_shd")
	if not e.is_empty():st.gt={"t":t,"e":src,"d":ab,"x":e.x,"n":st.n}

func gear_pecho(st: Dictionary,t: int,at: float):
	var gb=st.get("gb",{});st.erase("gb")
	if gb.is_empty() or gb.t!=t or u(st,t).al!=1:return
	var bw=0;var be={}
	for i in range(1,5):
		var w=u(st,i);var e=uq(w,"pa_echo")
		if w.al==1 and not e.is_empty() and (be.is_empty() or e.v[0]>be.v[0]):bw=i;be=e
	if not be.is_empty():
		var h=heal(st,t,gb.d*be.v[0]/100.0,at+.3)
		if h>0:line(st,bw,"은총의 반향: "+nm(t)+" HP +"+str(int(h)),at+.3)

func gear_buff(v: float) -> float:
	if act<1:return v
	# Owner supplies actor via current_state for this original state-free boundary.
	var w=bridge.call("actor",act)
	if w.get("gq",{}).has("buff") and v>0 and skill!=null:v*=pct(q(w,"buff"))
	var e=uq(w,"pr_bless")
	if not e.is_empty() and skill is String and skill=="bless" and v>0:v*=pct(e.v[0])
	return v

func crit(st: Dictionary,a: int,_t: int,_opt: Dictionary={},previous: float=0) -> float:
	var w=u(st,a);var x=w.x;var r=previous
	if x.get("fzn",0)>0:r+=x.fzx
	var e=uq(w,"gl_king")
	if x.has("kg") and not e.is_empty():r+=x.kg*e.v[1]
	return r

func take(st: Dictionary,t: int,dmg: float,_src: Variant=null,previous: Variant=null) -> Variant:
	var w=u(st,t);var f=1.0
	if w.get("gq",{}).has("dr"):f*=1-q(w,"dr")/100.0
	if w.x.get("lsn",0)>0:f*=.7
	var e=uq(w,"wa_wall")
	if not e.is_empty() and w.x.get("wwn",0)>0:f*=1-e.v[0]/100.0
	e=uq(w,"pa_wrath")
	if not e.is_empty() and w.sh>0:f*=1-e.v[1]/100.0
	e=uq(w,"sa_ward")
	if not e.is_empty() and w.chg==1:
		f*=1-e.v[0]/100.0
		var kept=(previous if previous!=null else dmg)*e.v[0]/100.0*e.v[1]/100.0
		w.x.sws=minf(w.mhp,w.x.get("sws",0)+kept)
	if st.has("gw"):f*=1-st.gw.p/100.0
	return (previous if previous!=null else dmg)*f if f<1 else previous

func heal_amount(st: Dictionary,t: int,amt: float,previous: Variant=null) -> Variant:
	var changed=previous
	if previous!=null:amt=previous
	var c=u(st,act) if act>0 else {};var hh={}
	if not c.is_empty() and skill!=null:
		if c.get("gq",{}).has("heal"):amt*=pct(q(c,"heal"));changed=amt
		hh=uq(c,"heal_haste")
		if not hh.is_empty() and amt>0 and c.x.get("hh")!=st.n:
			c.x.hh=st.n
			if rnd(st)*100<hh.p:
				for i in range(1,5):
					var pw=u(st,i)
					if pw.al==1:pw.g=maxf(0,pw.g-10000*hh.x/100.0)
				line(st,idx_of(st,c),"축복의 바람: 파티의 다음 차례가 "+num(hh.x)+"% 빨라진다",T(st))
	var w=u(st,t)
	if w.get("gq",{}).has("healrecv"):amt*=pct(q(w,"healrecv"));changed=amt
	var e=uq(c,"al_surge") if not c.is_empty() and skill!=null else {}
	if not e.is_empty():
		var over=w.hp+bf(amt+.5)-w.mhp
		var s=bf(over*e.v[0]/100.0) if over>0 else 0.0
		s=minf(s,maxf(0,bf(w.mhp*.5)-w.sh))
		if s>0 and w.al==1:setf(st,t,"sh",w.sh+s,T(st)+.3);w.shT=maxf(w.shT,e.v[1]);c.x.sgs=c.x.get("sgs",0)+s
	return changed

func shield(st: Dictionary,i: int,amt: float,previous: Variant=null) -> Variant:
	var changed=previous
	if previous!=null:amt=previous
	var w=u(st,i);var e=uq(w,"guardian")
	if w.get("gq",{}).has("shield"):amt*=pct(q(w,"shield"));changed=amt
	if not e.is_empty() and rnd(st)*100<e.p:amt*=pct(e.x);changed=amt;line(st,i,"수호: 보호막 +"+num(e.x)+"%",T(st))
	return changed

func abyss_mul(st: Dictionary,a: int,_t: int,amt: float) -> Variant:
	return amt*pct(q(u(st,a),"abyss")) if u(st,a).get("gq",{}).has("abyss") else null

func hit_after(st: Dictionary,a: int,_t: int,res: Dictionary,_opt: Dictionary,at: float):
	var w=u(st,a);var e=uq(w,"frenzy")
	if not e.is_empty() and w.x.get("fzr")!=st.n:
		w.x.fzr=st.n
		if rnd(st)*100<e.p:w.x.fzx=e.x;w.x.fzn=e.get("n",1)+1;line(st,a,"광기: "+num(e.get("n",1))+"턴 동안 치명타 확률 +"+num(e.x)+"%p",at+.3)
	e=uq(w,"gl_hunger")
	if not e.is_empty() and w.al==1 and res.get("d",0)>0:
		var h=heal(st,a,res.d*e.v[2]/100.0,at+.3)
		if h>0:line(st,a,"굶주린 칼: HP +"+str(int(h)),at+.3)

func damaged(st: Dictionary,t: int,dmg: float,_src: Variant,at: float):
	var w=u(st,t);var e=uq(w,"wa_scar")
	if not e.is_empty():w.x.scr=minf(w.mhp*e.v[1]/100.0,w.x.get("scr",0)+dmg*e.v[0]/100.0)
	if w.al==1 and not w.x.has("lsd"):
		e=uq(w,"last_stand")
		if not e.is_empty() and w.hp<w.mhp*e.x/100.0:w.x.lsd=1;w.x.lsn=e.get("n",1);line(st,t,"최후의 저항: "+num(e.get("n",1))+"턴 동안 받는 피해 −30%",at+.2)

func attacked(st: Dictionary,t: int,enemy: int,res: Dictionary,at: float):
	if enemy<5:return
	var w=u(st,t)
	if w.get("gq",{}).has("reflect") and u(st,enemy).al==1:
		var d=bf(res.get("d",0)*q(w,"reflect")/100.0)
		if d>=1:
			var rr=call_engine(st,"strike",[enemy,d,at+.2,null,"fixed"])
			call_engine(st,"say",["<b>"+nm(t)+"</b>의 장비가 충격을 되돌렸다. "+part(nm(enemy),"에게")+" <em>"+str(int(rr.d))+"</em> 반사 피해를 입혔다"+(". 쓰러졌다" if rr.kill==1 else ""),at+.4])
			if rr.kill==1:call_engine(st,"kill_credit",[t,at+.2])
	var gt=st.get("gt",{});st.erase("gt")
	if not gt.is_empty() and gt.t==t and gt.n==st.n and u(st,int(gt.e)).al==1:
		var d=bf(gt.d*gt.x/100.0)
		if d>=1:
			var rr=call_engine(st,"strike",[gt.e,d,at+.3,null,"fixed"])
			call_engine(st,"say",["<b>"+nm(t)+"</b>의 보호막이 깨지며 가시가 튀었다. "+part(nm(int(gt.e)),"에게")+" <em>"+str(int(rr.d))+"</em> 피해를 입혔다"+(". 쓰러졌다" if rr.kill==1 else ""),at+.5])
			if rr.kill==1:call_engine(st,"kill_credit",[t,at+.3])

func turn_end(st: Dictionary,i: int):
	if i>4:return
	var w=u(st,i);var x=w.x
	for k in ["fzn","lsn","wwn"]:
		if x.get(k,0)>0:x[k]-=1
	if st.has("gw") and st.gw.who==i:
		st.gw.n-=1
		if st.gw.n<=0:st.erase("gw")
	if x.get("adv",0)>0:
		if w.al==1:w.g=maxf(0,w.g-x.adv)
		x.erase("adv")

func enemy_dead(st: Dictionary,_t: int):
	if not st.get("gk",{}).get("gl_king",false):return
	for i in range(1,5):
		var w=u(st,i);var e=uq(w,"gl_king")
		if w.al==1 and not e.is_empty() and w.x.get("kg",0)<e.v[2]:w.x.kg=w.x.get("kg",0)+1;line(st,i,"투기장의 왕: 치명 확률 +"+num(w.x.kg*e.v[1])+"%p",T(st))

func round_end(st: Dictionary):
	if st.has("gw") and u(st,int(st.gw.who)).al!=1:
		st.gw.n-=1
		if st.gw.n<=0:st.erase("gw")

func abyss_after(st: Dictionary,a: int,t: int,_amt: float,at: float,_list: Array):
	var w=u(st,a);var e=uq(w,"ch_void")
	if not e.is_empty() and u(st,t).dr==1:
		var n=bf(w.mmp*e.v[0]/100.0+.5)
		if w.mp<w.mmp:setf(st,a,"mp",minf(w.mmp,w.mp+n),at+.4)
		gear_adv(st,a,e.v[1]*100);line(st,a,"공허 흡수: MP +"+str(int(n))+", 다음 차례가 "+num(e.v[1])+"% 빨라진다",at+.4)

## These eight boundaries live in 30-engine / 34-traits, not in 81's GH slot.
func first_action(st: Dictionary,i: int):
	var w=u(st,i)
	if w.get("gq",{}).has("first") and not w.x.has("f1"):w.x.f1=st.n
func crit_damage(w: Dictionary,base: float) -> float:return base+q(w,"critdmg")/100.0
func evade_chance(w: Dictionary,base: float) -> float:return base+q(w,"evade")/100.0
func evade_roll(st: Dictionary,t: int,base: float=0,already: bool=false) -> Variant:
	if already:return null
	var p=evade_chance(u(st,t),base)
	if p<=0:return null
	return true if rnd(st)<p else null
func dot_expiry(dot: Dictionary) -> float:
	return bf(dot.d*dot.n0*dot.bu/100.0) if dot.has("bu") and dot.n<=0 else 0.0
func snipe_crit(w: Dictionary) -> float:
	var e=uq(w,"ar_wind");return e.v[1] if not e.is_empty() else 70.0
func assassin_extra(w: Dictionary,base: float) -> float:
	var e=uq(w,"as_shadow");return e.v[0]/100.0 if not e.is_empty() else base
func hp_cost(w: Dictionary,base: float) -> float:
	var e=uq(w,"gl_boil");return bf(base*(1-e.v[0]/100.0)+.5) if not e.is_empty() else base
func splash_value(w: Dictionary,item_mult: float=1) -> float:
	var e=uq(w,"al_splash");return (e.v[0]/100.0 if not e.is_empty() else .20)*item_mult
func miracle(w: Dictionary,base_heal: float) -> Dictionary:
	var e=uq(w,"pr_miracle");return {"hp":e.v[0]/100.0,"shield":e.v[1]/100.0} if not e.is_empty() else {"hp":base_heal,"shield":0}
func warp(st: Dictionary,i: int,t: int,charging: bool,raid_mult: float,base_delay: float) -> float:
	var e=uq(u(st,i),"sa_warp");var d=(e.v[1]*100 if charging else e.v[0]*100) if not e.is_empty() else base_delay
	d*=raid_mult;u(st,t).g+=d
	if not e.is_empty():gear_adv(st,i,d*e.v[2]/100.0)
	return d
