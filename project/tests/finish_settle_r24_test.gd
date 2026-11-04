extends "res://tests/finish_r24_test.gd"
func _initialize():create_timer(120).timeout.connect(func():quit(98));call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round4/settle-oracle.json"));var diffs=[];var adapter=Save.new()
	for f in oracle.rows:
		var w=ready_world();w.s.settings={"lang":f.lang};w.s.gear=[];w.s.serial=0;w.s.equipment.persona={};w.s.items.hp_s=2;w.s.items.mp_s=0;w.s.dungeon_r21.best=2
		w.s.owned=["haldric","urda"] if f.kern else ["teiris"];w.s.party=w.s.owned.duplicate();w.s.persona.name=""
		if f.kern:w.s.persona.nation="케른 연방"
		for i in int(f.n):w.s.serial+=1;w.s.gear.append(adapter.entry("wa01.1.1",w.s.serial))
		check(w.depart_dungeon(1,7),"settlement fixture departure")
		w.s.run.step=5;w.s.run.wins=3;w.s.run.gold=21;w.s.run.xp=55;w.s.run.loot_items={"hp_s":4,"mp_s":3};w.s.run.loot_gear=["wa01.2.1","wa01.3.1","wa01.4.1"]
		if f.result=="retreat":w.s.run.phase="rest"
		else:
			w.s.run.phase="battle";w.s.run.final=true
			var b=w.ModernBattle.new(w.battle_data());b.result="victory" if f.result=="clear" else "defeat"
			for unit in (b.data.enemies if f.result=="clear" else b.data.allies):unit.hp=0
			w.record_battle(b.snapshot())
		check(w.settle(f.result),"source settlement accepted")
		# Canonical lv_name leaves its default Korean persona name untranslated.
		# The requested language repair resolves that host name in emitted copy.
		var msg=Locale24.display(f.msg.replace("당신 Lv ","You Lv ") if f.lang=="en" else f.msg,w.s)
		if w.s.ui.msg!=msg:diffs.append({"lang":f.lang,"result":f.result,"actual":w.s.ui.msg,"expected":msg})
		eqcheck("settle/message",w.s.ui.msg,msg)
		eqcheck("settle/account",[w.s.gold,w.s.day,w.s.dungeon_r21.best,w.s.dungeon_r21.runs,not w.s.run.is_empty()],[f.gold,f.day,f.best,f.runs,f.run_exists])
		eqcheck("settle/bag",[source_bag(w).size(),";".join(source_bag(w)).sha256_text()],[f.count,f.bag_sha256])
		for id in ["hp_s","mp_s"]:eqcheck("settle/items",w.s.items[id],f.items.get(id,0))
		eqcheck("settle/lost",[w.s.summary.lost_gear,w.s.summary.lost],[f.summary.get("lost_gear",0),f.summary.lost_gold])
		if f.result!="defeat":eqcheck("settle/bag_full_loss",w.s.summary.gear_lost,f.summary.gear_lost)
		eqcheck("settle/received_gear",w.s.summary.gear,f.summary.get("kept_gear",[]) if f.result=="defeat" else f.summary.gear)
		var before=w.s.duplicate(true);check(not w.settle(f.result),"settlement cannot pay twice");eqcheck("settle/replay",w.s,before)
	FileAccess.open("res://../verification/finish-r24/round4/settle-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts,"differences":diffs}))
	print("FINISH SETTLE CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
