extends "res://tests/panels_r22_test.gd"
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/panels-r22/oracle.json"))
	for f in oracle.gear_actions:
		var w=source_world(f.before,f.bag);var st=State.new(w);st.ui.msg=f.before.ui.msg
		if f.before.ui.get("bg") is Dictionary:st.bg=f.before.ui.bg.duplicate(true)
		st.bg_action(f.arg);check(st.ui.msg==f.value.ui.msg,"P2593 original handler message "+f.arg+": "+st.ui.msg+" / "+f.value.ui.msg)
	var extra=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-oracle.json"))
	for f in extra.message_actions:
		var w=source_world(f.before,f.bag);w.s.settings={"lang":f.lang};var st=State.new(w);st.ui.msg=f.before.ui.msg
		if f.before.ui.get("bg") is Dictionary:st.bg=f.before.ui.bg.duplicate(true)
		st.bg_action(f.arg);check(st.ui.msg==f.value.ui.msg,"P2593 "+f.lang+" message "+f.arg+": "+st.ui.msg+" / "+f.value.ui.msg)
		check(same(st.bg,f.value.ui.bg,["pg","cls","slot","rar","sel","cmp","conf"]),"P2593 "+f.lang+" selector "+f.arg)
	var suffix="baseline" if "baseline" in OS.get_cmdline_user_args() else "results"
	FileAccess.open("res://../verification/parity-r23/messages-"+suffix+".json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("PANEL MESSAGES R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
