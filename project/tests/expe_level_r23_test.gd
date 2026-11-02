extends SceneTree
const Base=preload("res://tests/expedition_r22_test.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:
		failures.append(label)
		if failures.size()<12:push_error(label)
func _initialize():call_deferred("run")
func run():
	var helper=Base.new();var w=helper.ready_world();var initial=w.s.duplicate(true)
	var api=w.has_method("expedition_level") and w.has_method("expedition_experience")
	check(api,"source level/experience read API")
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-oracle.json"))
	if api:
		for row in oracle.levels:
			w.s=initial.duplicate(true);var input=row.input
			w.s.persona=input.get("persona");w.s.lv=input.get("lv");w.s.owned=input.get("roster",[]);w.s.members={}
			var levels=input.get("lvl",{});var xp=input.get("exp",{})
			if levels is Dictionary:
				for id in levels:w.s.members[id]={"level":levels[id]}
			if xp is Dictionary:
				for id in xp:
					if not w.s.members.has(id):w.s.members[id]={}
					w.s.members[id].xp=xp[id]
			var before=JSON.stringify(w.s)
			for id in row.value:
				check(w.expedition_level(id)==row.value[id].level,"source lv_of "+str([input,id]))
				check(w.expedition_experience(id)==row.value[id].xp,"source exp_of "+str([input,id]))
			check(JSON.stringify(w.s)==before,"level access does not rewrite old fields")
	FileAccess.open("res://../verification/parity-r23/expe-level-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"oracle_rows":oracle.levels.size()},"  "))
	print("EXPE LEVEL R23 CHECKS ",checks," FAILURES ",failures.size());helper.free();quit(0 if failures.is_empty() else 1)
