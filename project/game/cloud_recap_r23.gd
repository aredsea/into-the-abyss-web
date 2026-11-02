extends RefCounted
## Exact 68-cloud recap generation. No model request or invented history.
const DATA=preload("res://data/cloud-recap-r23.json").data
const V=preload("res://game/ui_value_r23.gd")
static func field(table: Variant,key: Variant,fallback: Variant=null) -> Variant:
	if table is Dictionary:return table.get(key,fallback)
	# Lua JSON uses [] for an empty table; numeric table indices start at one.
	if table is Array and (key is int or key is float) and key==floor(key) and key>=1 and key<=table.size():return table[int(key)-1]
	return fallback
static func name(id: Variant) -> String:
	var n=DATA.names.get(id,"nil" if id==null else V.text(id) if id is int or id is float else str(id));return DATA.words.get(n,n)
static func score(g: Dictionary,id: Variant) -> float:
	return V.number(field(g.get("lvl"),id),1)*1e6+(5e5 if id in g.get("party",[]) else 0)+V.number(field(g.get("exp"),id))
static func speakers(g: Dictionary) -> Dictionary:
	var vet: Variant=null;var close: Variant=null;var aff=g.get("aff",{})
	for id in g.get("roster",[]):
		if not V.truth(vet) or score(g,id)>score(g,vet):vet=id
	for id in g.get("roster",[]):
		if id!=vet and V.number(field(aff,id))>0 and (not V.truth(close) or V.number(field(aff,id))>V.number(field(aff,close))):close=id
	if V.truth(vet) and V.truth(close) and V.number(field(aff,vet))>=V.number(field(aff,close)):close=null
	return {"veteran":vet,"closest":close}
static func recap(g: Dictionary) -> String:
	var selected=speakers(g);var vet=selected.veteran;var close=selected.closest
	var companions=[];var levels=g.get("lvl",{})
	for id in g.get("roster",[]):companions.append(name(id)+" Lv"+V.text(V.number(field(levels,id),1)))
	var d=g.get("dungeon",{});var bosses=[]
	for id in d.get("cleared_bosses",[]):
		var z=DATA.zones.get(V.text(id),{});var f=DATA.foes.get(z.get("boss",""),{})
		if not f.is_empty():bosses.append(DATA.words.get(f.name,f.name)+" ("+DATA.words.get(z.name,z.name)+")")
	var who=""
	if V.truth(vet) and V.truth(close):who=name(vet)+" (the companion who has fought the most battles beside {{user}}) and "+name(close)+" (the companion closest to {{user}})"
	elif V.truth(vet):who=name(vet)+" (the companion who has fought the most battles beside {{user}} and is also the closest)"
	var facts=["{{user}} is level "+V.text(V.number(field(g.get("persona"),"lv"),1)),"companions: "+(", ".join(companions) if not companions.is_empty() else "none"),"deepest Great Dungeon floor reached: "+V.text(V.number(d.get("best"))),"zone bosses defeated: "+(", ".join(bosses) if not bosses.is_empty() else "none yet"),"gold: "+V.text(V.number(g.get("gold")))]
	return "[Journey recap — save loaded] The adventure resumes from a saved record. Scene: a quiet evening at the inn in Torva's lower town. "+(who+" sit with {{user}} and look back on the journey so far in their own voices, as a natural conversation (not a list), each from their own point of view. " if who!="" else "{{user}} sits alone and looks back on the journey so far. ")+"Mention only these facts and do not invent other past events or numbers: "+"; ".join(facts)+". End by letting {{user}} decide what to do next."
static func from_native(s: Dictionary) -> Dictionary:
	var g={"persona":s.get("persona",{}),"roster":s.get("owned",[]),"party":s.get("party",[]),"gold":s.get("gold",0),"dungeon":s.get("dungeon_r21",{}),"lvl":{},"exp":{},"aff":{}}
	for id in g.roster:
		var m=s.get("members",{}).get(id,{})
		g.lvl[id]=m.get("level",1);g.exp[id]=m.get("xp",0);g.aff[id]=m.get("aff",0)
	return g
