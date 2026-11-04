extends "res://tests/finish_r24_test.gd"
func _initialize():create_timer(120).timeout.connect(func():quit(98));call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round4/inn-oracle.json"));var differences=[]
	for f in oracle.rows:
		var w=ready_world();w.s.settings={"lang":f.lang};w.s.gold=f.before.gold;w.s.day=f.before.town.day;w.s.members.teiris.aff=f.before.aff.teiris;w.s.ui.sel=f.before.ui.sel;w.s.ui.msg=f.before.ui.msg;w.facility=f.before.scene
		w.s.acts=f.before.town.acts.duplicate(true) if f.before.town.acts is Dictionary else {}
		w.inn_action(f.arg,f.before.scene)
		var daily={}
		for key in w.s.acts:
			if not key.ends_with("_story") and not key.ends_with("_transition"):daily[key]=w.s.acts[key]
		var actual={"scene":w.facility,"sel":w.s.ui.sel,"msg":w.s.ui.msg,"gold":w.s.gold,"day":w.s.day,"acts":daily,"aff":w.s.members.teiris.aff,"npc":w.s.npc_aff_r21.get("dorothea",0)}
		var expected=f.after.duplicate(true)
		if expected.acts is Array:expected.acts={}
		if not same(actual,expected):differences.append({"arg":f.arg,"lang":f.lang,"actual":actual,"expected":expected})
		eqcheck("inn/route",actual,expected)
		if f.arg=="talk_teiris" and f.before.scene=="inn" and f.before.gold==300 and not f.before.town.acts is Dictionary:
			check(not w.s.dialogue_r21.pending.is_empty(),"source handler retains authored narrative")
	FileAccess.open("res://../verification/finish-r24/round4/inn-routes-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts,"differences":differences}))
	print("FINISH INN ROUTES CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
