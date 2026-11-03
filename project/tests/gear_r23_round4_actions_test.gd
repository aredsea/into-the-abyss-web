extends "res://tests/gear_r23_round2_test.gd"
func source_work(w) -> Dictionary:
	var out={"forge":[],"proc":[]}
	for row in w.smithy_work:
		if row.kind=="process":out.proc.append(row.code)
		else:out.forge.append({"code":row.code,"ok":row.success,"lv":row.level})
	return out
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-round3-oracle.json"))
	var sample=World.new();var full=[]
	for uid in range(1,2001):full.append(sample.combat_gear_adapter.entry("wa01.1.1",uid))
	for f in o.handlers:
		if f.scene!="smithy":continue
		var w=ready_world();w.s.owned=["hildegard"];w.s.party=[];w.s.settings={"lang":"en"};w.s.gold=f.game.gold;w.s.town_r21.seed=f.game.seed
		set_level(w,"persona",40);set_level(w,"hildegard",40);w.s.gear=[];w.s.serial=0;w.s.equipment.persona={};w.s.equipment.hildegard={}
		if f.mode==4:
			w.s.gear=full.duplicate(true);w.s.serial=2000
		elif f.mode==5:w.bank_expedition_gear(["wa01.1.1"])
		if f.game.get("sm_work") is Dictionary:
			for code in f.game.sm_work.proc:w.smithy_work.append({"kind":"process","code":code,"name":w.gear.note_rules.gear_label(code)})
		w.facility="town" if f.mode==0 else "smithy"
		for key in ["forge_fx","proc_fx"]:
			if f.game.has(key):w.smithy_source_fx[key]=f.game[key].duplicate(true)
		w.smithy_action(f.arg)
		eqcheck("smithy_gold",w.s.gold,f.value.gold)
		eqcheck("smithy_counter",w.s.commerce_r21.process_n,f.value.town.get("process_n",0))
		eqcheck("smithy_scene",w.facility,f.value.scene)
		if f.arg in ["proc","done","back"]:eqcheck("smithy_message",w.facility_message,f.value.ui.msg)
		var expected=f.value.get("sm_work",{"forge":[],"proc":[]})
		eqcheck("smithy_work",source_work(w),expected)
		for key in ["forge_fx","proc_fx"]:eqcheck("smithy_effect_presence",w.smithy_source_fx.has(key),f.value.has(key))
		if f.value.has("proc_fx") and f.value.proc_fx.has("code"):
			eqcheck("smithy_processed_code",w.smithy_source_fx.proc_fx.get("code"),f.value.proc_fx.code)
		if f.arg=="proc" and not f.writes.is_empty():eqcheck("smithy_bag",source_bag(w),w.gear.note_rules.bag_load(f.writes[-1].value))
		for code in f.value.get("forge",{}):
			var e=w.s.gear.filter(func(row):return w.gear.code(row)==code)
			if not e.is_empty():eqcheck("smithy_forge",[e[0].forge,e[0].tries],[f.value.forge[code].lv,f.value.forge[code].tries])
		var again=World.new();check(again.restore(JSON.parse_string(JSON.stringify(w.s))),"smithy save resume "+f.arg)
		eqcheck("smithy_persisted",[again.s.gold,again.s.commerce_r21,source_bag(again)],[w.s.gold,w.s.commerce_r21,source_bag(w)])
	FileAccess.open("res://../verification/parity-r23/gear-round4-actions-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts},"  "))
	print("GEAR R23 ROUND4 ACTION CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
