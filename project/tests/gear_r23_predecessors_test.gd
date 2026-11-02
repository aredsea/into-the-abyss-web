extends "res://tests/gear_hooks_r22_test.gd"
func run():
	var fixtures=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/predecessors.json"))
	hooks=Hooks.new(self)
	for f in fixtures:
		current=f.before.duplicate(true)
		for w in current.u:
			for k in ["x","bf","gq"]:
				if w.get(k) is Array and w[k].is_empty():w[k]={}
		hooks.act=0;hooks.skill=null;hooks.defs=f.defs
		var result=hooks.callv(f.method,[current]+f.args)
		check(equivalent("nil" if result==null else result,f.result),"wrapper ignores predecessor return "+f.method)
		check(equivalent(current,f.value),"post-predecessor state/call order "+f.method+" "+f.meta)
		check(current.calls[0].k=="predecessor","predecessor observed before gear "+f.method)
	FileAccess.open("res://../verification/parity-r23/predecessors-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"fixtures":fixtures.size(),"scope":"Native gear replay begins at source predecessor checkpoint; native custom callback ABI not claimed."},"  "))
	print("GEAR R23 PREDECESSORS CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
