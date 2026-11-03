extends "res://tests/gear_r23_round2_test.gd"
const Store=preload("res://game/world_store.gd")
const Save=preload("res://game/gear_save_r22.gd")
func normalized_eq(value) -> Dictionary:
	var out={"persona":{},"hildegard":{}}
	if value is Dictionary:
		for cid in value:
			if not value[cid] is Dictionary:continue
			if not out.has(cid):out[cid]={}
			for slot in value[cid]:
				if value[cid][slot]!="":out[cid][slot]=value[cid][slot]
	return out
func observe(w) -> Dictionary:
	return {"bag":source_bag(w),"equip":source_equipment(w),"gold":w.s.gold}
func resumed(w,index):
	var store=Store.new("user://gear-round4-%s.json"%index)
	check(store.write(w.s)==OK,"real file write "+str(index))
	var again=World.new();check(store.read_into(again),"real file resume "+str(index))
	return again
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-round4-oracle.json"))
	var adapter=Save.new();var r=GearRules.new();var i=0
	for f in o.storage:
		i+=1
		var w=ready_world();w.s.owned=["hildegard"];w.s.party=[];w.s.gear=[];w.s.serial=0;w.s.equipment.persona={};w.s.equipment.hildegard={}
		set_level(w,"persona",40);set_level(w,"hildegard",40)
		var payload={"bag":f.raw if f.method=="raw" else ";".join(f.before.bag),"equip":{} if f.method=="raw" else f.before.equip}
		# Source bag_load maps corrupt/non-string chat contents to an empty bag.
		# Native import is typed; its adapter accepts the observed, filtered bag.
		if not payload.bag is String:payload.bag=";".join(r.bag_load(payload.bag))
		var imported=adapter.import_codes(w.s,payload);check(imported.ok,"legacy import "+str(i));w.s=imported.state
		w.s.gold=10000 if f.method=="raw" else f.before.gold
		if f.method!="raw":
			var uid=0
			for e in w.s.gear:
				if w.gear.code(e)=="wa01.1.1" and w.wearer(int(e.uid)).is_empty():uid=e.uid;break
			var result=false
			match f.method:
				"add":result=not w.bank_expedition_gear(["wa01.2.1"]).gear.is_empty()
				"take":
					for j in range(w.s.gear.size()):
						if w.s.gear[j].uid==uid:w.s.gear.remove_at(j);result=true;break
				"equip":result=w.equip("persona",uid)
				"unequip":result=w.unequip("persona","weapon")
				"sell":result=w.sell_gear(uid)
				"sellc":var panel=PanelState.new(w);panel.bg_action("sellc");result=true
			if f.method!="sellc":eqcheck("native_result",result,f.result)
		var expected={"bag":f.after.bag,"equip":normalized_eq({} if f.method=="raw" else f.after.equip),"gold":w.s.gold if f.method=="raw" else f.after.gold}
		eqcheck("native_observable",observe(w),expected)
		var again=resumed(w,i);eqcheck("file_roundtrip",observe(again),expected)
		# Continue the next transaction after resume, rather than comparing JSON bytes.
		var a=w.buy("hp_s");var b=again.buy("hp_s");eqcheck("next_action",[a,w.s.gold,w.s.items,w.s.commerce_r21],[b,again.s.gold,again.s.items,again.s.commerce_r21])
	for f in o.migrations:
		var g=f.before.duplicate(true);var result=r.gear_migrate(g)
		eqcheck("migration_return",result,f.result)
		var archive=g.get("gear_r22_prototypes",{}).duplicate(true);g.erase("gear_r22_prototypes");eqcheck("migration_active",g,f.after)
		g=JSON.parse_string(JSON.stringify(g));eqcheck("migration_again",r.gear_migrate(g),f.again)
		eqcheck("migration_resumed",g,f.resumed)
		if result:eqcheck("migration_archive",archive,{"equip":{"persona":{"weapon":"eq_old"}},"items":{"eq_old":3}})
	# Broken JSON restores the last good bag/equipment; rejected saves are atomic.
	var w=ready_world();w.s.owned=["hildegard"];w.s.party=[];w.bank_expedition_gear(["wa01.1.1","wa01.1.1"])
	check(w.equip("persona",int(w.s.gear[0].uid)),"equip before backup")
	var store=Store.new("user://gear-round4-corrupt.json");check(store.write(w.s)==OK,"backup first write");check(store.write(w.s)==OK,"backup second write")
	FileAccess.open(store.path,FileAccess.WRITE).store_string("{broken")
	var fallback=World.new();check(store.read_into(fallback),"corrupt JSON uses valid backup");eqcheck("backup_observable",observe(fallback),observe(w))
	for field in ["gold","gear","equipment"]:
		var bad=w.s.duplicate(true);bad[field]="broken";var before=observe(fallback)
		check(not fallback.restore(bad),"reject corrupt "+field);eqcheck("rejected_atomic",observe(fallback),before)
	# Source aff_add has an exposed source-shaped API. Test that callback absence
	# and invalid cid are observable at this API, not the owned-companion facade.
	var aff=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-round3-oracle.json"))
	for f in aff.aff:
		var g=f.input.duplicate(true);var value=TownRules.aff_add_source(g,f.cid,f.amount)
		eqcheck("aff_function_result",value,f.result);eqcheck("aff_function_state",g,f.value)
	var gaps=[]
	for f in o.restrictions:
		var probe=ready_world();probe.s.owned=["hildegard"];probe.s.party=[];probe.s.gear=[];probe.s.serial=0;probe.s.equipment.persona={};probe.s.equipment.hildegard={}
		set_level(probe,"persona",1);set_level(probe,"hildegard",1)
		var imported=adapter.import_codes(probe.s,{"bag":";".join(f.bag),"equip":f.before.equip})
		check(imported.ok,"restriction probe imports without data loss");probe.s=imported.state
		var actual=observe(probe);var expected={"gold":probe.s.gold,"bag":f.after_bag,"equip":normalized_eq(f.after.equip)}
		gaps.append({"id":"P3540","code":f.code,"bag_size":f.n,"same":same(actual,expected),"native":actual,"source":expected,"overflow":imported.get("overflow",0),"conflicts":imported.get("conflicts",0)})
	FileAccess.open("res://../verification/parity-r23/gear-round4-restriction-gaps.json",FileAccess.WRITE).store_string(JSON.stringify(gaps))
	# Host-only send success/false/exception never rolls back a confirmed recruit.
	for f in o.host:
		if f.scene!="guild":continue
		var probe=ready_world();probe.s.owned=[];probe.s.party=[];probe.s.gold=f.before.gold;probe.s.town_r21.seed=f.before.seed;probe.s.town_r21.counter=f.before.n;probe.s.recruits=f.before.guild.recruits
		set_level(probe,"persona",f.before.persona.lv)
		check(probe.recruit(),"recruit source confirmation "+f.mode)
		eqcheck("recruit_observable",[probe.s.owned,probe.s.gold,probe.s.town_r21.counter,probe.s.town_r21.meet],[f.game.roster,f.game.gold,f.game.n,f.game.town.meet])
		var joined=f.game.town.meet
		eqcheck("recruit_values",[probe.s.members[joined].level,probe.s.members[joined].xp,probe.s.members[joined].aff],[f.game.lvl[joined],f.game.exp[joined],f.game.aff[joined]])
		var again=resumed(probe,"recruit-"+f.mode);eqcheck("recruit_file_resume",[again.s.owned,again.s.gold,again.s.town_r21],[probe.s.owned,probe.s.gold,probe.s.town_r21])
	FileAccess.open("res://../verification/parity-r23/gear-round4-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts},"  "))
	print("GEAR R23 ROUND4 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
