extends RefCounted
## P4's original-state ABI, synchronized at each call and each engine re-entry.
## The combat owner retains HP/effects/clock; this adapter never resolves a hit.
const Hooks=preload("res://game/gear_hooks_r22.gd")
static var shared_rules=preload("res://game/gear_rules_r22.gd").new()
var owner_ref: WeakRef
var b:
	get: return owner_ref.get_ref()
var hooks
var st={"u":[],"ev":{"T":0.0}}
const GLOBALS=["gw","gk","gb","gt"]

func _init(owner):
	owner_ref=weakref(owner); hooks=Hooks.new(self,shared_rules,true)

func slot(w: Dictionary) -> int:
	if w.is_empty(): return 0
	var index=b.data.allies.find(w)
	return index+1 if index>=0 else b.data.enemies.find(w)+5
func unit_at(i: int) -> Dictionary:
	if i<=0: return {}
	if i<=4: return b.data.allies[i-1] if i<=b.data.allies.size() else {}
	return b.data.enemies[i-5]
func skill_id(id: String) -> String:
	if id=="personal" and b.current_id=="persona": return "persona_skill"
	return {"attack":"atk","defend":"df","ptaunt":"taunt","pshield":"shield","hshield":"pshield","acid":"defdn","chaoswave":"wave"}.get(id,id)

func pack():
	var all=b.data.allies.duplicate()
	while all.size()<4: all.append({})
	all.append_array(b.data.enemies)
	st.n=b.turn_count+1; st.cur=slot(b.unit(b.current_id)); st.rs=1; st.ev.T=b.combat_events.T
	for key in GLOBALS:
		if b.x(all[0]).has("gear_"+key): st[key]=b.x(all[0])["gear_"+key]
		else: st.erase(key)
	if not st.has("gw"):
		for a in b.data.allies:
			if a.effects.has("wall_party"):
				var effect=a.effects.wall_party
				st.gw={"n":effect.turns,"p":effect.amount*100,"who":slot(a)}
	hooks.defs=[]
	while st.u.size()<all.size(): st.u.append({})
	for i in range(all.size()):
		var a=all[i]
		if a.is_empty():
			st.u[i]={"hp":0,"mhp":1,"mp":0,"mmp":0,"sh":0,"shT":0,"g":1000000000,"al":0,"dr":0,"chg":0,"tau":0,"cs":0,"de":0,"sp":100,"cr":0,"x":{},"gq":{},"gu":[],"dot":[],"bf":{}}
			hooks.defs.append({"name":"","full":"","row":"전열","kind":"mob","elite":false}); continue
		var ally=a.has("base")
		if not b.x(a).has("lsn") and a.effects.has("gear_guard"): b.x(a).lsn=a.effects.gear_guard.turns
		for pair in [["scar","scr"],["charge_damage","sws"],["stood","lsd"],["wall_saved","wlu"]]:
			if b.x(a).has(pair[0]) and not b.x(a).has(pair[1]): b.x(a)[pair[1]]=1 if b.x(a)[pair[0]] is bool else b.x(a)[pair[0]]
		var w={"hp":a.hp,"mhp":a.mhp,"mp":a.get("mp",0),"mmp":a.get("mmp",0),"sh":a.get("shield",0) if ally else b.fx(a,"shield"),"shT":a.effects.get("shield",{}).get("turns",0),"g":a.remaining,"al":1 if a.hp>0 else 0,"dr":1 if a.get("broken",false) else 0,"chg":1 if a.get("charging",false) else 0,"tau":a.effects.get("taunt",{}).get("turns",0),"cs":a.base[a.line] if ally else 0,"de":a.base.def if ally else a.defense,"sp":a.base.spd if ally else a.speed,"cr":a.base.crit if ally else 0,"x":b.x(a),"gq":a.get("gear_fx",{}),"gu":a.get("gear_special",[]),"dot":[],"bf":{}}
		if a.effects.has("dot"):
			var d=b._dot_metadata(a)
			for j in range(d.stacks.size()): w.dot.append({"d":d.stacks[j],"n":d.lifetimes[j],"k":1,"by":slot(b.ally(d.owners[j])) if not d.owners[j].is_empty() else 0,"bu":d.bursts[j],"n0":d.initial_turns[j],"order":d.orders[j]})
		for key in ["corrosion","bleed"]:
			if a.effects.has(key):
				var d=a.effects[key]; w.dot.append({"d":d.amount,"n":d.turns,"k":2 if key=="corrosion" else 3,"by":slot(b.ally(d.get("by",""))),"order":d.get("order",0)})
		st.u[i].merge(w,true)
		for e in w.gu:
			if e.key in ["pa_echo","gl_king"]:
				if not st.has("gk"): st.gk={}
				st.gk[e.key]=true
		hooks.defs.append({"name":a.name,"full":a.name,"row":a.row,"kind":"boss" if a.get("grade","") in ["boss","chief","core"] else a.get("grade","mob"),"elite":a.get("grade","")=="elite"})

func unpack():
	for key in GLOBALS:
		if st.has(key): b.x(b.data.allies[0])["gear_"+key]=st[key]
		else: b.x(b.data.allies[0]).erase("gear_"+key)
	for i in range(st.u.size()):
		var a=unit_at(i+1); var w=st.u[i]
		if a.is_empty(): continue
		a.effects.erase("wall_party")
		if w.x.get("lsn",0)>0: a.effects.gear_guard={"amount":.3,"turns":w.x.lsn}
		elif w.x.has("lsn"): a.effects.erase("gear_guard")
		for pair in [["scar","scr"],["charge_damage","sws"],["stood","lsd"],["wall_saved","wlu"]]:
			if w.x.has(pair[1]): w.x[pair[0]]=w.x[pair[1]]>0 if pair[0] in ["stood","wall_saved"] else w.x[pair[1]]
			else: w.x.erase(pair[0])
		a.hp=int(w.hp); a.remaining=w.g
		if a.has("base"):
			a.mp=int(w.mp); a.mhp=int(w.mhp); a.mmp=int(w.mmp); a.shield=int(w.sh)
			a.base[a.line]=w.cs; a.base.def=w.de; a.base.spd=w.sp; a.base.crit=w.cr
			if w.sh>0: a.effects.shield={"amount":0,"turns":maxi(1,int(w.shT))}
			else: a.effects.erase("shield")
			a.gear_fx=w.get("gq",{}); a.gear_special=w.get("gu",[])
		var d={"stacks":[],"lifetimes":[],"owners":[],"bursts":[],"initial_turns":[],"orders":[]}
		for line in w.dot:
			if line.k!=1: continue
			d.stacks.append(line.d); d.lifetimes.append(line.n); d.owners.append(unit_at(int(line.by)).id if line.by>0 else ""); d.bursts.append(line.get("bu",0)); d.initial_turns.append(line.get("n0",line.n)); d.orders.append(line.get("order",0))
		b._store_class_dot(a,d)
		for key in ["corrosion","bleed"]:
			var found=false
			for line in w.dot:
				if line.k==(2 if key=="corrosion" else 3): found=true
			if not found: a.effects.erase(key)
	if st.has("gw"):
		unit_at(int(st.gw.who)).effects.wall_party={"turns":st.gw.n,"amount":st.gw.p/100.0}

func invoke(method: String,args: Array=[]):
	pack(); var result=hooks.callv(method,[st]+args); unpack(); return result

func initialize():
	pack()
	for i in range(mini(4,b.data.allies.size())):
		var a=unit_at(i+1)
		a.combat_ag=a.base.agi
		st.u[i].sp=floor(st.u[i].sp+.5)
		if a.has("gear_member"):
			var m=a.gear_member
			if m.has("native_eq"): hooks.gear_init_native(st,st.u[i],m)
			else: hooks.gear_init(st,st.u[i],m)
		if a.has("gear_vitals"):
			st.u[i].hp=mini(int(st.u[i].mhp),int(a.gear_vitals.hp)); st.u[i].mp=mini(int(st.u[i].mmp),int(a.gear_vitals.mp))
		for e in st.u[i].get("gu",[]):
			if e.key in ["pa_echo","gl_king"]:
				if not st.has("gk"): st.gk={}
				st.gk[e.key]=true
	unpack()

func rnd(_s): return b.dungeon_enemy_r21.random()
func actor(i): return st.u[i-1]
func setf(_s,i,key,value,_at): st.u[i-1][key]=value
func trait_line(_s,i,txt,at):
	b.combat_events.push("trait",b.combat_events.slot(b,unit_at(i)),at); b._event(hooks.defs[i-1].name+" · "+txt)
func say(_s,txt,_at):
	# The source emits HTML; the native combat journal stores plain text.
	var tags=RegEx.new(); tags.compile("<[^>]*>")
	b._event(tags.sub(txt,"",true).replace("&nbsp;"," ").replace("&amp;","&"))
func push(_s,event):
	var targets=[]
	for r in event.get("tg",[]): targets.append(b.combat_events.slot(b,unit_at(int(r.i))))
	var actor_id=int(event.get("a",0))
	b.combat_events.push(event.k,b.combat_events.slot(b,unit_at(actor_id)) if actor_id>0 else 0,event.t,targets)
func heal(_s,i,amount,_at):
	unpack(); var result=b._receive_heal(unit_at(i),amount); pack(); return result
func strike(_s,i,damage,_at,mul,src):
	unpack(); var a=unit_at(i); var shield=a.get("shield",0) if a.has("base") else b.fx(a,"shield")
	b._incoming_strike(a,floor(damage*mul) if mul!=null else damage,unit_at(int(src)) if (src is int or src is float) else {},{"name":"장비"},false,src=="fixed")
	var absorbed=mini(int(shield),int(damage)); pack()
	return {"i":i,"d":damage,"sh":absorbed,"kill":1 if a.hp<=0 else 0,"c":0}
func kill_credit(_s,i,_at):
	unpack(); b.TraitRules.kill_credit(b,unit_at(i)); pack()
func badd(_s,i,key,value,turns):
	unpack(); b._effect(unit_at(i),{"ddn":"defense_down","atk":"attack_up","def":"defense_up","spd":"haste"}.get(key,key),turns,value); pack()
