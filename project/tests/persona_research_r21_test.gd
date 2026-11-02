extends SceneTree
const Rules=preload("res://game/persona_research_r21.gd")
const World=preload("res://game/town_world_r21.gd")
var checks=0
var failures=[]
var matches=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<15:push_error(msg)
func canon(v: Variant) -> Variant:
	if v is Array and v.is_empty():return {}
	if v is Dictionary:
		var out={}
		for k in v:out[k]=canon(v[k])
		return out
	return v
func same(a: Variant,b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):return float(a)==float(b)
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for k in a:
			if not b.has(k) or not same(a[k],b[k]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not same(a[i],b[i]):return false
		return true
	return typeof(a)==typeof(b) and a==b
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/town-r21/round5/persona-oracle.json"))
	for row in oracle.clean:
		var ok=same(Rules.clean(row.raw),canon(row.value));matches+=int(ok);check(ok,"Lua clean "+str(row))
	for row in oracle.cost:
		var ok=Rules.cost(row.n)==row.value;matches+=int(ok);check(ok,"Lua next-step cost "+str(row.n))
	for row in oracle.skills:
		var expected_skill=canon(row.skill) if row.skill is Dictionary else {}
		var got=[Rules.clean(row.raw),Rules.ready(row.raw),Rules.skill_name(row.raw),Rules.description(row.raw),Rules.skill_name(row.raw,true),Rules.description(row.raw,true),Rules.skill(row.raw)]
		var expected=[canon(row.value),row.ready,row.name,row.description,row.name_en,row.description_en,expected_skill]
		var ok=same(got,expected);matches+=int(ok);check(ok,"Lua skill "+str(row.raw)+" got "+str(got)+" expected "+str(expected) if not ok else "Lua skill")
	for row in oracle.actions:
		var v=canon(row.input)
		var got=Rules.transition(v.saved,v.draft,v.spent,v.gold,row.arg,row.busy)
		var ok=same(got,canon(row.value));matches+=int(ok);check(ok,"Lua action "+row.arg+" input "+str(v)+" got "+str(got)+" expected "+str(canon(row.value)) if not ok else "Lua action")
	var w=World.new();w.s.gold=100000
	var legacy=w.s.duplicate(true);legacy.erase("research_editor_r21");var before=legacy.duplicate(true)
	var migrated=World.new();check(migrated.restore(legacy),"legacy save accepted")
	check(legacy==before and migrated.s.research_editor_r21=={},"migration does not mutate caller, new ledger defaults empty")
	for k in before:check(migrated.s[k]==before[k],"preserved old field "+k)
	check(w.research_action("hildegard","ps_pre_strike") and w.research_action("hildegard","ps_suf_bane"),"edit combination")
	check(w.tactic("hildegard").is_empty(),"draft is not active in battle")
	check(w.research_action("hildegard","ps_up_pre") and w.s.gold==99940,"first upgrade costs next step 60 immediately")
	var raw=JSON.parse_string(JSON.stringify(w.s));var copy=World.new();var untouched=raw.duplicate(true)
	check(copy.restore(raw) and copy.s==raw and raw==untouched,"draft and paid cost survive JSON save without caller mutation")
	check(copy.research_action("hildegard","ps_save") and not copy.research_dirty("hildegard"),"confirm saved draft")
	check(copy.s.research.hildegard.prefix_lv.strike==1 and copy.tactic("hildegard").power==1.26,"confirmed data feeds existing battle tactic adapter")
	check(copy.research_action("hildegard","ps_pre_mend") and copy.research_work("hildegard").suffix.is_empty(),"incompatible suffix cleared")
	check(copy.research_action("hildegard","ps_suf_guard") and copy.research_action("hildegard","ps_save"),"support confirmed")
	check(copy.research_action("hildegard","ps_pre_strike") and copy.research_work("hildegard").prefix_lv.strike==1,"piece levels survive changing combinations")
	var invalid=raw.duplicate(true);invalid.research_editor_r21.hildegard.spent=-1;var state=copy.s.duplicate(true)
	check(not copy.restore(invalid) and copy.s==state,"invalid spent rejected atomically")
	invalid=raw.duplicate(true);invalid.research_editor_r21.hildegard.draft.prefix_lv.strike=11
	check(not copy.restore(invalid) and copy.s==state,"invalid piece level rejected atomically")
	invalid=raw.duplicate(true);invalid.research_editor_r21.unknown={"draft":Rules.clean({}),"spent":0}
	check(not copy.restore(invalid) and copy.s==state,"unknown owner rejected atomically")
	var gold=copy.s.gold;copy.s.gold=0;state=copy.s.duplicate(true)
	check(not copy.research_action("hildegard","ps_up_pre") and copy.s==state,"no funds rejection atomic")
	copy.s.gold=gold;copy.depart_dungeon(1,117);state=copy.s.duplicate(true)
	check(not copy.research_action("hildegard","ps_pre_sweep") and copy.s==state,"active expedition cannot edit")
	var live=World.new();check(live.restore(copy.s) and live.s==copy.s,"in-progress expedition and draft roundtrip")
	var report={"checks":checks,"failures":failures,"lua_samples":oracle.clean.size()+oracle.cost.size()+oracle.skills.size()+oracle.actions.size(),"lua_matches":matches,"clean":oracle.clean.size(),"skills":oracle.skills.size(),"actions":oracle.actions.size(),"cost":oracle.cost.size()}
	FileAccess.open("res://../verification/town-r21/round5/persona-results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("PERSONA RESEARCH R21 CHECKS ",checks," FAILURES ",failures.size()," LUA ",matches," / ",report.lua_samples)
	quit(0 if failures.is_empty() else 1)
