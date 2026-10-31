extends RefCounted
## Literal port of 24-stats.lua / 27-compose.lua / 77-explore.lua.
## Array order is significant: no Godot RNG or Dictionary iteration in composition.
var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies-r21.json"))
var config=JSON.parse_string(FileAccess.get_file_as_string("res://data/dungeons-r21.json"))
var foes={}
var zones={}
var rifts={}
var pools={"mobs":{},"elites":{},"common_mobs":[],"common_elites":[],"all_elites":[]}
var final_cache={}

class PM:
	var s: int
	func _init(seed: int):
		s=posmod(seed,2147483646)+1
		for i in range(4): s=(s*16807)%2147483647
	func next() -> float:
		s=(s*16807)%2147483647
		return float(s)/2147483647.0
	func pick(list: Array): return list[mini(list.size()-1,int(floor(next()*list.size())))]
	func shuffle(list: Array):
		for k in range(list.size(),1,-1):
			var j=mini(k-1,int(floor(next()*k)))
			var v=list[k-1]; list[k-1]=list[j]; list[j]=v

func _init():
	for z in config.zones: zones[z.id]=z
	for r in config.rifts: rifts[r.id]=r
	for f in catalog.enemies:
		foes[f.id]=f
		var common=f.zone=="common"
		if f.grade in ["mob","swarm"]:
			if common: pools.common_mobs.append(f.id)
			else:
				if not pools.mobs.has(f.zone): pools.mobs[f.zone]=[]
				pools.mobs[f.zone].append(f.id)
		elif f.grade=="elite":
			if common: pools.common_elites.append(f.id)
			else:
				if not pools.elites.has(f.zone): pools.elites[f.zone]=[]
				pools.elites[f.zone].append(f.id)
			if not f.zone.begins_with("rift_"): pools.all_elites.append(f.id)

func floor_info(value: int) -> Dictionary:
	var f=maxi(1,value); var zi: int; var order: int; var dk=0; var dc=0
	if f<=27: zi=int((f-1)/3); order=(f-1)%3+1
	else: zi=int((f-28)/3)%9; order=(f-28)%3+1; dk=int((f-25)/3); dc=int((f-28)/27)+1
	return {"floor":f,"zi":zi+1,"zone":config.zone_order[zi],"ord":order,"dk":dk,"dc":dc}

func floor_star(info: Dictionary) -> int: return 9 if info.dk>0 else int(zones[info.zone].star)
func floor_boss_kind(info: Dictionary) -> String: return "boss" if info.ord>=3 else "chief"
func floor_level(avg: float,info: Dictionary) -> int:
	return maxi(40 if info.dk>0 else int(zones[info.zone].lv_lo),mini(40,int(floor(avg+.5))+int(info.ord)-1))

func star_mult(st: Dictionary) -> Dictionary:
	var k=st.get("dk",0); var t=catalog.tune
	if k>0:
		return {"hp":t.deep.hp0*pow(t.deep.hpk,k)*t.star["9"].hp,"atk":t.deep.atk0*pow(t.deep.atk1,k)*t.star["9"].atk,"reward":t.deep.reward0*pow(t.deep.reward1,k)}
	var star=clampi(int(st.get("star",1)),1,9); var s=config.stats.stars[star-1]; var tu=t.star[str(star)]
	return {"hp":s.hp*tu.hp,"atk":s.atk*tu.atk,"reward":s.reward}

func floor_mult(f: int) -> Dictionary:
	var info=floor_info(f); var m=star_mult({"star":floor_star(info),"dk":info.dk})
	if info.dk==0:
		var following=config.stats.stars[info.zi].reward if info.zi<9 else catalog.tune.deep.reward0*catalog.tune.deep.reward1
		m.reward*=pow(following/m.reward,(info.ord-1)/3.0)
	return m

func curve_hp(c: Dictionary,f: int) -> float:
	var p=c.pts
	if f<=p[0][0]: return p[0][1]
	for i in range(1,p.size()):
		if f<=p[i][0]:
			var t=float(f-p[i-1][0])/(p[i][0]-p[i-1][0])
			return exp(log(p[i-1][1])+t*(log(p[i][1])-log(p[i-1][1])))
	var n=p.size()-1
	return p[n][1]*exp((log(p[n][1])-log(p[n-1][1]))/(p[n][0]-p[n-1][0])*(f-p[n][0]))

func floor_final(f: int,kind: String) -> Array:
	if not final_cache.has(kind): final_cache[kind]=[[0.0,0.0,false]]
	var cache=final_cache[kind]; var c=catalog.tune.curve.get(kind,catalog.tune.curve.normal)
	while cache.size()<=f:
		var i=cache.size(); var previous=cache[-1]
		if kind=="normal" or kind==floor_boss_kind(floor_info(i)):
			var h=curve_hp(c,i); var a=pow(h,c.get("pow",.55))
			cache.append([maxf(previous[0],h),maxf(previous[1],a),h<previous[0]-1e-12 or a<previous[1]-1e-12])
		else: cache.append([previous[0],previous[1],false])
	return cache[f]

func foe_def(enc: Dictionary,index: int,level: int) -> Dictionary:
	var f=foes[enc.fl[index]].duplicate(true); var gr=enc.fg[index]; var deep=enc.dk>0
	if gr in ["chiefb","eliteb"]: gr="chief" if gr=="chiefb" else "elite"; deep=true
	if not gr.is_empty(): f.grade=gr
	f.srole="하수인" if f.grade=="minion" else f.get("stat_role",f.role)
	f.name=("깊은 " if deep else "")+f.name; f.lvn=mini(40,level)
	return f

func fc(key: String,level: float) -> float:
	var c=config.stats.curves[key]; var v=level-1
	return 1+c.a*v+c.b*v*v

func foe_stats(enc: Dictionary,d: Dictionary,level: int) -> Dictionary:
	var L=d.get("lvn",level); var fa=fc("atk",L); var fd=fc("def",L)
	var r=catalog.roles.get(d.get("srole",d.role),catalog.roles["돌격"])
	var g=catalog.grades.get(d.grade,catalog.grades.mob); var sm=star_mult(enc)
	var z=zones.get(enc.zk,rifts.get(str(enc.zk).trim_prefix("rift_"),{})); var zt=z.get("tune",{})
	var bh=1.0; var ba=1.0; var dk=enc.dk
	if d.grade in ["chief","boss","core"]:
		bh=zt.get("chief_hp" if d.grade=="chief" else "boss_hp",1); ba=zt.get("chief_atk" if d.grade=="chief" else "boss_atk",1)
		if dk>0: bh*=catalog.tune.deep.get("boss_hp",1); ba*=catalog.tune.deep.get("boss_atk",1)
	var mh=sm.hp*zt.get("hp",1)*bh; var ma=sm.atk*zt.get("atk",1)*ba
	if enc.has("floor"):
		var f=int(enc.floor); var kind="chief" if d.grade=="chief" else "boss" if d.grade=="boss" else "normal"
		var m=floor_final(f,kind); mh=m[0]; ma=m[1]
		if kind=="chief":
			mh*=zt.get("chief_hp",1); ma*=zt.get("chief_atk",1)
			if dk>0: mh*=zt.get("chief_deep_hp",1); ma*=zt.get("chief_deep_atk",1)
		elif kind=="boss" and dk==0: mh*=zt.get("boss_hp",1); ma*=zt.get("boss_atk",1)
		if kind=="boss" and dk>0 and d.has("deep"): mh*=d.deep.get("hp",1); ma*=d.deep.get("atk",1)
		var dn=enc.get("dn",{}); var X=config.explore
		if dn.get("kind")=="explore":
			var F=X.FOE; var el=F.get("elite",1) if d.grade=="elite" else 1; var pw=F.get("pow",.55); var h=curve_hp(F,f)
			var o3=(F.get("ord3",1) if enc.order>=3 else 1)*F.get("zone",{}).get(enc.zk,1)
			mh=h*el*o3; ma=pow(h,pw)*pow(el*o3,pw)
		var ea=X.EARLY; var pn=int(dn.get("party_n",0)); var newbie=X.NEWBIE[pn-1] if pn>=1 and pn<=3 else {}; var scale=newbie.get(dn.get("kind",""),[])
		if not scale.is_empty() and (f<=3 or f<ea.to):
			var k=1.0 if f<=3 else 1-float(f-3)/(ea.to-3)
			mh*=pow(scale[0],k); ma*=pow(scale[1],k)
		if not dn.is_empty() and f<ea.to:
			var t=pow(float(f-1)/(ea.to-1),ea.get("curve",1)); mh*=pow(ea.hp,1-t); ma*=pow(ea.atk,1-t)
	var E=config.stats.enemy_std
	var gauge=d.get("gauge",g.get("gauge"))
	if gauge==null: gauge=r.gauge
	return {"hp":E.hp*fa*r.hp*g.hp*mh,"atk":E.str*2*fa*r.atk*g.atk*ma,"de":E.def*fd*r.de,"ay":gauge,"sp":E.spd*r.spd}

func has_summon(f: Dictionary) -> bool:
	for a in f.acts+f.get("phase2",{}).get("acts",[])+[f.get("phase2",{}).get("entry",{})]:
		if a.get("kind")=="summon": return true
	return false
func has_charge(f: Dictionary) -> bool:
	return f.acts.any(func(a):return a.kind=="charge")
func threat_limit(order: int,elite: bool) -> float:
	var t=catalog.threat
	return t.base+t.per_order*(order-1)+(t.elite_bonus if elite else 0)+t.get("zone_bonus",0)

func check_comp(fl: Array,fg: Array,o: Dictionary={}) -> Dictionary:
	var front=0; var sup=0; var summ=0; var charge=0; var common=0; var count={}; var union={}; var threat=0.0; var bad=[]
	for k in range(fl.size()):
		var f=foes[fl[k]]; var g=fg[k] if not fg[k].is_empty() else f.grade
		if f.row=="front": front+=1
		if f.role=="지원": sup+=1
		if f.role=="소환" or has_summon(f): summ+=1
		if has_charge(f): charge+=1
		if f.zone=="common": common+=1
		count[f.id]=count.get(f.id,0)+1
		if count[f.id]>3 and f.grade!="swarm": bad.append("duplicate")
		for w in f.weak: union[w]=true
		if g in ["elite","eliteb"]: threat+=catalog.threat.elite
		elif g not in ["chief","chiefb","boss","core"]: threat+=catalog.roles[f.role].threat
	if front<1: bad.append("front")
	if sup>1: bad.append("support")
	if summ>1: bad.append("summon")
	if charge>1: bad.append("charge")
	if common>1: bad.append("common")
	if o.get("union",false) and union.size()<o.get("umin",4): bad.append("union")
	if o.has("limit") and threat>o.limit+1e-9: bad.append("threat")
	return {"bad":bad,"threat":threat,"union":union.size(),"front":front}

func fits(f: Dictionary,cur: Array,spec: Dictionary) -> bool:
	if spec.has("grade") and f.grade not in spec.grade: return false
	if spec.has("role") and f.role not in spec.role: return false
	if spec.has("row") and (spec.row=="front")!=(f.row=="front"): return false
	var sup=0; var summ=0; var common=0; var same=0; var charge=0
	for id in cur:
		var g=foes[id]
		if g.role=="지원": sup+=1
		if g.role=="소환" or has_summon(g): summ+=1
		if g.zone=="common": common+=1
		if id==f.id: same+=1
		if has_charge(g): charge+=1
	return not ((f.role=="지원" and sup>=1) or ((f.role=="소환" or has_summon(f)) and summ>=1) or (f.zone=="common" and common>=1) or (f.grade!="swarm" and same>=3) or (has_charge(f) and charge>=1))

const FILL=[{"role":["돌격"]},{"role":["사격","주술"]},{"role":["방어","돌격"]},{"role":["무리","돌격"]}]
func build_slots(t: Dictionary,tc: int,elite: bool) -> Array:
	var slots=t.slots.duplicate(); var ext=0
	while slots.size()>tc and slots.size()>1: slots.pop_back()
	while slots.size()<tc:
		ext+=1; slots.append({"grade":["mob","swarm"]} if elite else FILL[ext%FILL.size()])
	return slots

func dfs(slots: Array,k: int,fl: Array,fg: Array,budget: Array,args: Dictionary) -> bool:
	if k>=slots.size(): return check_comp(fl,fg,{"union":true,"limit":args.limit,"umin":args.umin}).bad.is_empty()
	var sp=slots[k]; var is_el=sp.get("grade",[]).slice(0,1)==["elite"]; var cand=[]
	for id in (args.elites if is_el else args.mobs):
		if fits(foes[id],fl,sp): cand.append(id)
	args.rng.shuffle(cand)
	for id in cand:
		budget[0]-=1
		if budget[0]<=0: return false
		fl.append(id); fg.append("eliteb" if is_el and args.borrowed else "")
		if check_comp(fl,fg).threat<=args.limit+1e-9 and dfs(slots,k+1,fl,fg,budget,args): return true
		fl.pop_back(); fg.pop_back()
	return false

func compose(seed: int,ctx: Dictionary) -> Dictionary:
	var rng=PM.new(seed); var info=floor_info(int(ctx.floor)) if ctx.has("floor") else {}
	var zone=ctx.get("zone",""); var order=int(ctx.get("order",1)); var rift=rifts.get(ctx.get("rift_id",""),{})
	var dk=0; var dc=0
	if not info.is_empty(): zone=info.zone; order=info.ord; dk=info.dk; dc=info.dc
	if not rift.is_empty(): order=clampi(int(ctx.get("stars",1)),1,3)
	var kind=ctx.get("kind","battle"); var n=clampi(int(ctx.get("party_n",4)),1,4); var Z=zones.get(zone,{})
	var star=floor_star(info) if not info.is_empty() else int(Z.get("star",clampi(int(ctx.get("stars",1)),1,4)))
	if not rift.is_empty(): star=clampi(int(ctx.get("stars",1)),1,3)
	var zkey="rift_"+rift.id if not rift.is_empty() else zone
	var mobs=[]; var elites=[]
	if not rift.is_empty(): mobs=rift.mobs.duplicate()+pools.common_mobs; elites=[rift.elite]
	else:
		mobs=pools.mobs.get(zkey,[]).duplicate()+pools.common_mobs
		var own=pools.elites.get(zkey,[])
		if own.is_empty(): own=pools.all_elites
		elites=own.duplicate()+pools.common_elites
	var borrowed=rift.is_empty() and pools.elites.get(zkey,[]).is_empty()
	var result={"kind":kind,"zone":zkey,"order":order,"star":star,"zk":zkey,"dk":dk,"dc":dc}
	if ctx.has("floor"): result.floor=ctx.floor
	if not rift.is_empty(): result.rift=rift.id
	if kind in ["chief","boss","rift_core"]:
		var lead=""; var lg=""
		if kind=="boss": lead=Z.boss
		elif kind=="rift_core": lead=rift.core
		else:
			var pool=Z.get("chiefs",[])
			if pool.is_empty(): pool=pools.all_elites; lg="chiefb"
			else: lg="chief"
			lead=rng.pick(pool)
			if lg=="chief" and Z.get("chief_borrow",false): lg="chiefb"
		var fl=[lead]; var fg=[lg]
		if kind!="boss" and not has_summon(foes[lead]):
			var pool=mobs.filter(func(id):return foes[id].grade=="mob")
			for k in range(1 if n<=2 else 2):
				var cand=[]
				for id in pool:
					if fits(foes[id],fl,{}) and (k!=0 or foes[lead].row=="front" or foes[id].row=="front"): cand.append(id)
				if cand.is_empty(): cand=pool
				fl.append(rng.pick(cand)); fg.append("")
		return _composition(result,fl,fg,kind,true)
	var elite=kind=="elite"; var limit=threat_limit(order,elite); var best=[]; var bestscore=INF
	var tc0=[2,2,3,4][n-1]
	if n>=2 and order>=2 and rng.next()<.35: tc0+=1
	tc0=mini(5,tc0)
	var tmpls=[]; var totw=0.0
	for tp in catalog.templates:
		if kind in tp.kinds and tp.get("min_order",1)<=order: tmpls.append(tp); totw+=tp.get("weight",1)
	for attempt in range(40):
		var r=rng.next()*totw; var t=tmpls[-1]
		for tp in tmpls:
			r-=tp.get("weight",1)
			if r<=0: t=tp; break
		var tc=maxi(2,tc0-int(attempt/10)); var fl=[]; var fg=[]; var okfill=true
		for sp in build_slots(t,tc,elite):
			var is_el=sp.get("grade",[]).slice(0,1)==["elite"]; var cand=[]
			for id in (elites if is_el else mobs):
				if fits(foes[id],fl,sp): cand.append(id)
			if cand.is_empty(): okfill=false; break
			fl.append(rng.pick(cand)); fg.append("eliteb" if is_el and borrowed else "")
		if okfill:
			var inf=check_comp(fl,fg,{"union":true,"limit":limit}); var score=inf.bad.size()*10+absf(inf.threat-limit)*.01-inf.union*.001
			if inf.bad.is_empty(): best=[fl,fg,t.id,false]; bestscore=-1; break
			if score<bestscore: best=[fl,fg,t.id,false]; bestscore=score
	if bestscore>=0:
		var found=[]
		for um in [4,3]:
			for tc in range(maxi(2,tc0),1,-1):
				var order_t=tmpls.duplicate(); rng.shuffle(order_t)
				for t in order_t:
					var fl=[]; var fg=[]
					if dfs(build_slots(t,tc,elite),0,fl,fg,[4000],{"rng":rng,"mobs":mobs,"elites":elites,"borrowed":borrowed,"limit":limit,"umin":um}): found=[fl,fg,t.id,um<4]; break
				if not found.is_empty(): break
			if not found.is_empty(): break
		if not found.is_empty(): best=found
	assert(not best.is_empty(),"compose: "+zkey)
	var idx=range(best[0].size())
	idx.sort_custom(func(a,b):return (a<b if (foes[best[0][a]].row=="front")== (foes[best[0][b]].row=="front") else foes[best[0][a]].row=="front"))
	var fl=[]; var fg=[]
	for i in idx: fl.append(best[0][i]); fg.append(best[1][i])
	var res=_composition(result,fl,fg,best[2],false)
	if best[3]: res.relaxed=true
	return res

func _composition(res: Dictionary,fl: Array,fg: Array,tmpl: String,raid: bool) -> Dictionary:
	res.merge({"fl":fl,"fg":fg,"tmpl":tmpl,"raid":raid,"n":fl.size(),"ne":fl.size()+(2 if fl.any(func(id):return has_summon(foes[id])) else 0)})
	return res

func floor_enc(f: int,avg: float,n: int,kind: String,seed: int) -> Dictionary:
	var info=floor_info(f); var enc=compose(seed,{"floor":f,"kind":floor_boss_kind(info) if kind=="boss" else kind,"party_n":n})
	enc.dn={"floor":f,"kind":"boss" if kind=="boss" else "explore","party_n":n}
	return {"enc":enc,"el":floor_level(avg,info),"star":enc.star,"info":info}

func gold(f: int,kind: String) -> int:
	var R=catalog.tune.reward
	return int(floor(R.gold_ref*floor_mult(f).reward*(R.chief if kind=="chief" else R.boss if kind=="boss" else 1)+.5))

func exp_reward(enc: Dictionary,level: int,mult: float=1) -> int:
	var R=catalog.tune.reward; var total=0.0
	if enc.raid:
		var gr=foe_def(enc,0,level).grade
		total=level*12*R.exp_ref_enemies*R.get(gr,R.chief)
	else:
		for i in range(enc.fl.size()): total+=level*catalog.grades[foe_def(enc,i,level).grade].exp
	return int(floor(total*(floor_mult(int(enc.floor)).reward if enc.has("floor") else star_mult(enc).reward)*mult))

static func ushr(x: int,n: int) -> int: return (x>>n)&((1<<(64-n))-1)
static func mix(seed: int,a: int,b: int,c: int) -> float:
	# Lua 5.4 unsigned shifts and wrapping int64 products (SplitMix-style).
	var x=seed*-7046029254386353131+a*-4658895280553007687+b*-7723592293110705685+c*0x2545F4914F6CDD1D
	x=(x^ushr(x,30))*-4658895280553007687
	x=(x^ushr(x,27))*-7723592293110705685
	x=x^ushr(x,31)
	return float(ushr(x,11))/9007199254740992.0

func battle_seed(seed: int,f: int,step: int,boss=false) -> int:
	return int(floor(mix(seed,f,99 if boss else step,config.explore.BOSS_SALT if boss else 9)*2147483646))+1

func ex_roll(seed: int,f: int,step: int,elites: int,party_cls: Array=[]) -> Dictionary:
	var X=config.explore
	if mix(seed,f,step,1)<X.P_BATTLE:
		return {"kind":"elite" if f>=3 and step>=X.ELITE_FROM and elites<X.ELITE_MAX and mix(seed,f,step,5)<X.ELITE_P else "battle"}
	var r=mix(seed,f,step,2)
	if r<X.LOOT_COIN: return {"kind":"coin","gold":maxi(1,int(floor(gold(f,"battle")*X.GOLD_COIN*(.75+.5*mix(seed,f,step,6))+.5)))}
	if r<X.LOOT_ITEM:
		var total=0.0
		for id in config.item_order:
			if f>=X.ITEM_FROM.get(id,0): total+=X.ITEM_W.get(id,0)
		var x=mix(seed,f,step,3)*total; var pick=config.item_order[0]
		for id in config.item_order:
			x-=X.ITEM_W.get(id,0) if f>=X.ITEM_FROM.get(id,0) else 0
			if x<0: pick=id; break
		return {"kind":"item","item":pick}
	var drop=gear_drop(int(floor(mix(seed,f,step,4)*2147483646))+1,f,"battle",party_cls)
	if drop.is_empty(): return {"kind":"coin","gold":maxi(1,gold(f,"battle"))}
	return {"kind":"equip","code":drop.code,"rarity":drop.rarity}

func gear_drop(seed: int,f: int,kind: String,party_cls: Array) -> Dictionary:
	var D=config.gear_drop; var w={}
	for band in D.bands:
		if f>=band.from: w=band.w.get(kind,{})
	if w.is_empty(): return {}
	var all=[]; var party=[]; var others=[]
	for item in config.gear_items:
		if item.cls not in all: all.append(item.cls)
	for cls in party_cls:
		if cls in all and cls not in party: party.append(cls)
	for cls in all:
		if cls not in party: others.append(cls)
	var pool=all
	if not party.is_empty() and not others.is_empty(): pool=party if mix(seed,1,0,0)*100<D.party_pct else others
	elif not party.is_empty(): pool=party
	var cls=pool[int(floor(mix(seed,2,0,0)*pool.size()))]; var slot=["weapon","armor","acc"][int(floor(mix(seed,3,0,0)*3))]
	var order=["common","fine","rare","epic","legend"]; var total=0.0
	for r in order: total+=w.get(r,0)
	if total<=0: return {}
	var x=mix(seed,6,0,0)*total; var ri=0
	for k in range(order.size()):
		var v=w.get(order[k],0)
		if v>0:
			ri=k; x-=v
			if x<0: break
	for k in range(ri,-1,-1):
		var best={}; var n=0
		for item in config.gear_items:
			if item.cls==cls and item.slot==slot and item.rarity==order[k]:
				n+=1
				if mix(seed,5,n,0)*n<1: best=item
		if not best.is_empty():
			var roll_seed=int(floor(mix(seed,7,0,0)*1099511627776))+1
			return {"id":best.id,"seed":roll_seed,"rarity":best.rarity,"code":best.id+"."+base36(roll_seed)+"."+str(int(config.gear_version))}
	return {}

static func base36(value: int) -> String:
	var out=""; var n=value
	while n>0:
		out="0123456789abcdefghijklmnopqrstuvwxyz"[n%36]+out; n=int(n/36)
	return out if not out.is_empty() else "0"

func level_reward(level: float) -> float:
	var lv=clampf(level,1,40); var pts=[[1,1],[5,2],[10,4],[17,5],[20,7],[30,13],[40,25]]; var target=25.0
	for i in range(1,pts.size()):
		if lv<=pts[i][0]: target=pts[i-1][1]+float(pts[i][1]-pts[i-1][1])*(lv-pts[i-1][0])/(pts[i][0]-pts[i-1][0]); break
	var lo=int(floor(target)); var a=floor_mult(lo).reward
	return a*pow(floor_mult(mini(25,lo+1)).reward/a,target-lo)

func quest_difficulty(q: Dictionary) -> String:
	return q.difficulty if config.quest_difficulty.has(q.get("difficulty","")) else "높음" if q.get("stars",1)>=3 else "중간" if q.get("stars",1)>=2 else "낮음"
func quest_fight(q: Dictionary) -> String:
	return "core" if q.get("kind")=="토벌" else "battle" if quest_difficulty(q)=="낮음" else "elite"
func quest_gold(q: Dictionary,level: int) -> int:
	var difficulty=quest_difficulty(q); var mult=config.quest_difficulty[difficulty].reward if q.get("reward_v",0)==2 else 1
	var lv=mini(40,level+3) if q.get("reward_v",0)==2 and difficulty=="엘리트" else level
	return int(floor(q.get("gold",0)*level_reward(lv)*mult+.5))
