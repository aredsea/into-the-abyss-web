extends RefCounted
## 29-persona-skill: the one persona signature skill. Legacy companion tactics
## keep their existing execution path and saved slots.
const Research=preload("res://game/persona_research_r21.gd")
static func part_label(node: Dictionary,lang: String="ko") -> String:return node.en if lang=="en" else node.name

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
	sk=sk.duplicate();sk.name=sk.get('name',Research.skill_name(raw))
	var p=Research.part("prefixes",raw.prefix); var q=Research.part("suffixes",raw.suffix)
	var power=p.power+p.step*Research.level(raw.prefix_lv,p.id)
	var value=q.value+q.step*Research.level(raw.suffix_lv,q.id)
	var clock=b.combat_events
	clock.ensure_record(b)
	# This skill owns both cut-in records, including direct lower-level callers.
	clock.Record.push(clock.record,{"k":"cut","a":clock.slot(b,a),"t":clock.T,"nm":sk.name,"pc":1})
	clock.push('cut',clock.slot(b,a),clock.T);clock.T+=1.9
	if p.kind in ["attack","volley"]:
		var element=Research.data.class_elements[a.class_id] if p.id=="element" else a.element
		var options={"m":power,"brk":p.brk,"name":sk.name,"sk":sk.name,"vb":"내리쳤다","hit":.45,"dur":1.5,"el":element,"volley":p.kind=='volley',"k":'wave' if p.kind=='volley' else 'atk'}
		if q.kind=='bane':options.ps_bane=value
		var result=b.SourceAttack.attack(b,a,e,options)
		var results=clock.record.ev.list.filter(func(event):return event.k=='wave' and event.a==clock.slot(b,a))[-1].tg if p.kind=='volley' else [result]
		for r in results:
			var target=(b.data.allies+b.data.enemies)[int(r.i)-1]
			if q.kind=="tempo" and r.kill==1: a.remaining-=floor(10000*value+.5)
			if target.hp<=0: continue
			match q.kind:
				"bleed": b._push_class_dot(target,floor(a.base[a.line]*2*value+.5),2,a.id)
				"weaken": b._effect(target,"attack_down",2,value)
				"abyss":
					var ab=b.PersonalRules.abyss_result(b,a,target,value,element,clock.T);r.ab+=ab.n
					if ab.list is Array:
						if not r.has('list'):r.list=[]
						r.list.append_array(ab.list)
	else:
		var targets=b.living(true) if p.kind.ends_with("_all") else ([t] if not t.is_empty() and t.hp>0 else [])
		var amount=floor(a.base[a.line]*2*power+.5)
		var T=clock.T;var hits=[]
		for target in targets:
			if p.kind.begins_with("heal"): b.PersonalRules.heal_record(b,target,amount,T+.7,a)
			else:
				b._shield(target,amount,3,false);clock.field(b,target,'sh',target.shield,T+.7)
			match q.kind:
				"regen": b.set_persona_regen(target,floor(a.base[a.line]*2*value+.5),2)
				"guard": b._effect(target,"psguard",2,value)
				"crit": b._effect(target,"pscrit",2,value)
			hits.append({"i":clock.slot(b,target),"d":amount})
		clock.Record.push(clock.record,{"k":"shield","a":clock.slot(b,a),"t":T,"tg":hits,"nm":sk.name})
		clock.say(b.CombatDisplay.Locale.u('<b>{who}</b>{particle} {skill:을를} 펼쳤다. {effect}',{"who":a.name,"particle":b.CombatDisplay.Josa.tail(a.name,'이가'),"skill":sk.name,"effect":Research.description(raw)}),T+.8)
		b.PersonalRules.finish_payload(b,1.8)
