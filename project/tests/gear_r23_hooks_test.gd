extends "res://tests/gear_hooks_r22_test.gd"
func run():
	var fixtures=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/hooks.json"))
	hooks=Hooks.new(self);var counts={}
	for f in fixtures:
		current=f.before.duplicate(true)
		for w in current.u:
			for k in ["x","bf","gq"]:
				if w.get(k) is Array and w[k].is_empty():w[k]={}
		hooks.act=int(f.act);hooks.skill=null if f.skill is bool and f.skill==false else f.skill;hooks.defs=f.defs
		var args=f.args.duplicate(true);var actual=null;var method=f.method
		if method=="gear_init":hooks.gear_init(current,current.u[0],args[0])
		else:actual=hooks.callv(method,[current]+args)
		if method=="gear_dot" and actual[1]==null:actual[1]=false
		if actual==null:actual="nil"
		check(equivalent(actual,f.result),"return "+method+" "+f.meta)
		check(equivalent(current,f.value),"state/calls/RNG "+method+" "+f.meta)
		counts[method]=counts.get(method,0)+1
	FileAccess.open("res://../verification/parity-r23/hooks-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"fixtures":fixtures.size(),"methods":counts},"  "))
	print("GEAR R23 HOOK CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
