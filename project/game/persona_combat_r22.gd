extends RefCounted
## 29-persona-skill: the one persona signature skill. Legacy companion tactics
## keep their existing execution path and saved slots.
const Research=preload("res://game/persona_research_r21.gd")

static func action(raw: Dictionary) -> Dictionary:
	if not Research.ready(raw): return {}
	var p=Research.part("prefixes",raw.prefix)
	return {"name":Research.skill_name(raw),"mp":p.mp,"target":{"enemy":"적 1","ally":"아군 1","none":"적 전체" if p.kind=="volley" else "아군 전체"}[p.target],"power":0,"brk":0,"note":Research.description(raw),"persona_skill":Research.clean(raw)}

static func debuffed(e: Dictionary) -> bool:
	for key in ["attack_down","defense_down","dot","corrosion","bleed","foxflame"]:
		if e.effects.has(key): return true
	return false

static func run(b,a: Dictionary,e: Dictionary,t: Dictionary,sk: Dictionary) -> void:
	var raw=Research.clean(sk.get("persona_skill",{}))
	if not Research.ready(raw): return
	var p=Research.part("prefixes",raw.prefix); var q=Research.part("suffixes",raw.suffix)
	var power=p.power+p.step*Research.level(raw.prefix_lv,p.id)
	var value=q.value+q.step*Research.level(raw.suffix_lv,q.id)
	if p.kind in ["attack","volley"]:
		var element=Research.data.class_elements[a.class_id] if p.id=="element" else a.element
		var targets=b.living(false) if p.kind=="volley" else [e]
		var results=[]
		if p.kind=="volley": b.volley_active=true; b.pending_hit_hooks=[]
		for target in targets:
			# B.attack may redirect to a protector. Suffixes follow the actual hit.
			if p.kind!="volley": target=b.dungeon_enemy_r21.protector(target)
			var result={"redirected":true,"element":element,"capture_result":true}
			b._damage(a,target,power*(1+value if q.kind=="bane" and debuffed(target) else 1),p.brk,false,-1,result)
			results.append({"target":target,"kill":result.get("primary_kill",false)})
		if p.kind=="volley":
			var hooks=b.pending_hit_hooks; b.pending_hit_hooks=[]; b.volley_active=false
			for hook in hooks: b._personal_hit_after(hook)
		for r in results:
			var target=r.target
			if q.kind=="tempo" and r.kill: a.remaining-=floor(10000*value+.5)
			if target.hp<=0: continue
			match q.kind:
				"bleed": b._push_class_dot(target,floor(a.base[a.line]*2*value+.5),2,a.id)
				"weaken": b._effect(target,"attack_down",2,value)
				"abyss": b.PersonalRules.abyss(b,a,target,value,element)
	else:
		var targets=b.living(true) if p.kind.ends_with("_all") else ([t] if not t.is_empty() and t.hp>0 else [])
		var amount=floor(a.base[a.line]*2*power+.5)
		for target in targets:
			if p.kind.begins_with("heal"): b._receive_heal(target,amount,a)
			else: b._shield(target,amount,3,false) # source setf; no GH.shield
			match q.kind:
				"regen": b.set_persona_regen(target,floor(a.base[a.line]*2*value+.5),2)
				"guard": b._effect(target,"psguard",2,value)
				"crit": b._effect(target,"pscrit",2,value)
