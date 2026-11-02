extends "res://tests/facilities_r22_test.gd"
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/facility-contracts.json"))
	for word in o.title_words:check(Rules.title_word(word)==o.title_words[word],"source quest vocabulary")
	for f in o.titles:
		var q={} if f.q is Array and f.q.is_empty() else f.q
		check(Rules.title(q)==f.ko,"source Korean quest title")
		check(Rules.title(q,"en")==f.ui_en,"source English UI quest title")
		check(Rules.title_en(q)==f.en,"source English context quest title")
	for f in o.smithy:
		var w=ready_world();w.s.owned=[];w.s.party=[];w.s.gold=f.game.gold;w.s.town_r21.seed=f.game.seed;w.facility="smithy"
		w.smithy_fx={"kind":"forge","success":true,"name":"fixture","level":1} if f.game.has("forge_fx") or f.game.has("proc_fx") else {}
		if f.kind=="done":
			for e in f.game.sm_work.forge:w.smithy_work.append({"kind":"forge","code":e.code,"success":e.ok,"level":e.lv})
			for code in f.game.sm_work.proc:w.smithy_work.append({"kind":"process","code":code})
			w.complete_smithy()
		elif f.arg.begins_with("tab_"):w.smithy_select(f.arg.trim_prefix("tab_"))
		elif f.arg=="back":w.facility_route("town")
		elif f.arg=="done":w.complete_smithy()
		elif f.arg=="proc":w.process_gear()
		var source_fx=f.value.has("forge_fx") or f.value.has("proc_fx")
		check(w.s.gold==f.value.gold,"smithy money "+str(f))
		check((not w.smithy_fx.is_empty())==source_fx,"smithy effect clear "+str(f.get("arg","done")))
		var pending=f.value.get("sm_work",{})
		check((not w.smithy_work.is_empty())==(pending.get("forge",[]).size()+pending.get("proc",[]).size()>0),"smithy work ledger")
		if f.kind=="done":check((not w.receipt.is_empty())==(f.value.get("pending","")!=""),"native receipt observes original confirmed work")
		if f.get("arg")=="back":check(w.facility==f.value.scene,"smithy route")
	for f in o.guild:
		if f.arg not in ["meet","host_chat"]:continue
		var w=ready_world();w.s.owned=f.game.roster.duplicate();w.s.party=[];w.s.gold=f.game.gold
		w.s.town_r21.seed=f.game.seed;w.s.town_r21.counter=f.game.n;w.s.recruits=f.game.guild.recruits
		var ok=w.recruit()
		check(ok and w.s.gold==f.value.gold and w.s.owned==f.value.roster,"guild meet actual economic result")
		check(w.s.town_r21.counter==f.value.n,"guild meet RNG count")
		var cid=f.value.roster[-1]
		check(w.s.members[cid].aff==f.value.aff[cid] and w.s.members[cid].level==f.value.lvl[cid] and w.s.members[cid].xp==f.value.exp[cid],"guild join values")
	for f in o.inn:
		if f.arg!="host_chat":continue
		var w=ready_world();w.s.owned=f.game.roster.duplicate();w.s.party=[];w.s.gold=f.game.gold;w.s.members.hildegard.aff=0
		check(w.inn("hildegard","talk") and w.s.gold==f.value.gold and w.s.members.hildegard.aff==f.value.aff.hildegard,"inn commit survives host chat result")
	FileAccess.open("res://../verification/parity-r23/facility-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("GEAR R23 FACILITY CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
