extends RefCounted
## Schema 3 is additive. The input object and the on-disk legacy save are never edited.
const Legacy=preload("res://game/town_world_r21.gd")
const Rules=preload("res://game/persona_rules.gd")
static func migrate(value: Variant) -> Dictionary:
	if not value is Dictionary:return {}
	var out=value.duplicate(true)
	if out.has("persona") and not out.persona is Dictionary:return {}
	# JSON decodes numbers as floats; Array.has uses typed Variant comparison.
	var legacy_schema=out.get("schema")==1 or out.get("schema")==2
	# r21-D wrote only progress; its optional persona was an untouched import.
	# P1 schema 3 wrote persona and the inherited progress was a second payment.
	# Choose by writer/schema, never by max(level) and never add duplicate XP.
	if out.has("persona_progress_r21"):
		var p=out.persona_progress_r21
		if not p is Dictionary or not numeric(p.get("level")) or not numeric(p.get("xp")):return {}
		if p.level<1 or p.level>40 or p.level!=floor(p.level) or p.xp<0 or p.xp!=floor(p.xp) or (p.level==40 and p.xp!=0):return {}
		var archive="persona_migration_r21"
		while out.has(archive):archive+="_"
		out[archive]={"schema":out.get("schema"),"progress":p.duplicate(true),"persona":out.get("persona",{}).duplicate(true),"authority":"r21-progress" if legacy_schema else "p1-persona"}
		if legacy_schema:
			if not out.get("persona") is Dictionary:out.persona={}
			out.persona.lv=p.level;out.persona.exp=p.xp
		out.erase("persona_progress_r21")
	settle_experience(out)
	if out.get("schema")==1 or out.get("schema")==2:
		var old=Legacy.new()
		if not old.restore(out):return {}
		out=old.s.duplicate(true)
		out.schema=3
		out.merge({"persona":{"name":"","race":"","lineage":"","nation":"","cls":"","stats":{},"bonus":{},"fight":0,"lv":1,"exp":0,"bonus_total":5,"bonus_custom":0,"skill":{"prefix":"","suffix":"","prefix_lv":{},"suffix_lv":{}}},"creation_r22":{"complete":true,"legacy":true},"scene":"town","ui":{"page":1,"sel":"","msg":""},"scenario":"","xp_r22":{}},false)
		out.persona.merge({"name":"","race":"","lineage":"","nation":"","cls":"","stats":{},"bonus":{},"fight":0,"lv":1,"exp":0,"bonus_total":5,"bonus_custom":0,"skill":{"prefix":"","suffix":"","prefix_lv":{},"suffix_lv":{}}},false)
		out.erase("persona_progress_r21")
	return out

static func settle_experience(out: Dictionary) -> void:
	# 74-level.exp_settle: older curves can leave enough XP for several levels.
	# Keep the exact old fields in an additive archive before normalizing them.
	var rules=Rules.new();var changed=[]
	if out.get("members") is Dictionary and out.get("owned",out.get("party",[])) is Array:
		for id in out.get("owned",out.get("party",[])):
			var m=out.members.get(id)
			if not m is Dictionary or not numeric(m.get("level")) or not numeric(m.get("xp")):continue
			if m.level>=1 and m.level<40 and m.level==floor(m.level) and m.xp>=rules.need(int(m.level)):
				changed.append({"id":id,"level":m.level,"xp":m.xp})
				var n=rules.give(int(m.level),int(m.xp),0);m.level=n.level;m.xp=n.xp
	if out.get("persona") is Dictionary:
		var p=out.persona
		if numeric(p.get("lv")) and numeric(p.get("exp")) and p.lv>=1 and p.lv<40 and p.lv==floor(p.lv) and p.exp>=rules.need(int(p.lv)):
			changed.append({"id":"persona","level":p.lv,"xp":p.exp})
			var n=rules.give(int(p.lv),int(p.exp),0);p.lv=n.level;p.exp=n.xp
			if out.get("members",{}).get("persona") is Dictionary:out.members.persona.level=n.level;out.members.persona.xp=n.xp
	if not changed.is_empty():
		var key="experience_before_r22"
		while out.has(key):key+="_"
		out[key]=changed

static func validate(value: Dictionary,valid: Array,rules) -> bool:
	if value.get("schema")!=3:return false
	if not value.get("persona") is Dictionary or not value.get("creation_r22") is Dictionary:return false
	if not value.get("party") is Array or not value.get("owned") is Array:return false
	if not value.get("ui") is Dictionary or not value.get("scenario") is String or not value.get("xp_r22") is Dictionary:return false
	for key in ["members","equipment","research","run","items","summary"]:
		if not value.get(key) is Dictionary:return false
	for key in ["day","gold","runs","rng"]:
		if not numeric(value.get(key)):return false
	var p=value.persona;var c=value.creation_r22
	if not c.get("complete") is bool or not c.get("legacy") is bool:return false
	for k in ["name","race","lineage","nation","cls"]:
		if not p.get(k) is String or p[k].length()>200:return false
	for k in ["fight","lv","exp","bonus_total","bonus_custom"]:
		if not numeric(p.get(k)) or p[k]!=floor(p[k]):return false
	if int(p.fight) not in [0,1] or p.lv<1 or p.lv>40 or p.exp<0 or p.bonus_total<0 or p.bonus_total>99 or int(p.bonus_custom) not in [0,1]:return false
	if not p.get("stats") is Dictionary or not p.get("bonus") is Dictionary or not p.get("skill") is Dictionary:return false
	for k in p.stats:
		if k not in ["hp","mp","str","agi","int","def","spd"] or not numeric(p.stats[k]) or p.stats[k]<0 or p.stats[k]>1000:return false
	for k in p.bonus:
		if k not in rules.KEYS or not numeric(p.bonus[k]) or p.bonus[k]<0 or p.bonus[k]>rules.cap(rules.total(p)) or p.bonus[k]!=floor(p.bonus[k]):return false
	if rules.spent(p)>rules.total(p):return false
	if c.complete and not c.legacy:
		if not rules.reach(p,5):return false
		var calculated=rules.calc(p)
		if calculated.size()!=p.stats.size():return false
		for k in calculated:
			if not p.stats.has(k) or calculated[k]!=p.stats[k]:return false
	if not c.legacy and (not rules.by(rules.data.races,"name",p.race).is_empty() or p.race==""):
		if p.race=="수인" and p.lineage!="" and rules.by(rules.data.lineages,"name",p.lineage).is_empty():return false
	elif not c.legacy:return false
	if value.get("scene") not in ["create","scenario","town"] or not numeric(value.ui.get("page")) or value.ui.page<1 or value.ui.page>5 or value.ui.page!=floor(value.ui.page):return false
	if not value.ui.get("sel") is String or not value.ui.get("msg") is String:return false
	if c.complete and value.scene!="town":return false
	if not c.complete and value.scene=="town":return false
	if value.scene=="scenario" and not rules.reach(p,5):return false
	var seen=[]
	for id in value.owned:
		if id not in valid or id in seen:return false
		seen.append(id)
	if rules.clean(value.party,value.owned,int(p.fight),valid)!=value.party:return false
	return true

static func numeric(v: Variant) -> bool:return (v is int or v is float) and is_finite(v)
