extends "res://tests/town_r21_round11_test.gd"
const B=preload("res://game/battle_v3.gd")
const GW=preload("res://game/persona_world.gd")
func fresh(companion="teiris"):
	var w=W.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc");w.s.gold=10000
	# Roster fixtures use canonical owned companions beyond the first-meeting set.
	w.s.owned=[companion];w.s.party=[companion]
	w.research_action("persona","ps_pre_strike");w.research_action("persona","ps_suf_bleed");w.research_action("persona","ps_save")
	return w
func run():
	var w=fresh();w.s.persona.lv=10;w.s.members.persona.level=10;w.s.members.teiris.level=10
	var plain=GW.new();plain.s=w.s.duplicate(true)
	var item={}
	for it in w.gear.by_id.values():
		if it.cls=="warrior" and it.slot=="armor" and it.rarity=="fine":item=it;break
	check(not item.is_empty(),"canonical fine warrior armor")
	var entry={}
	for seed in range(1,200):
		entry=w.combat_gear_adapter.source_drop({"id":item.id,"seed":seed},1)
		if w.combat_gear_adapter.rules.gear_roll(entry.code,10,0).fx.get("hp",0)>0:break
	w.s.gear=[entry];w.s.serial=1;check(w.equip("persona",1),"P7 persona equip")
	plain.s=w.s.duplicate(true)
	check(same(w.stats("persona",10),plain.stats("persona",10)),"P5 persona equipment stats applied once")
	w.s.settings.diff=3;check(w.depart_dungeon(1,117),"P5 actual departure");w.dismiss_dialogue_queue()
	while w.s.run.phase!="battle" and w.s.run.step<5:w.advance();w.dismiss_dialogue_queue()
	check(w.s.run.phase=="battle","real exploration encounter")
	var facility_gear=w.gear
	var d=w.battle_data();var b=B.new(d)
	check(w.gear==facility_gear and w.gear.has_method("classes"),"battle input preserves P6 smithy rules object")
	check(d.allies.map(func(a):return a.id).count("persona")==1,"persona appears once")
	check(d.allies[0].gear_member.native_eq.size()==1,"native equipment transmitted once")
	check(b.ally("persona").mhp==plain.stats("persona",10).hp,"engine equipment equals source world stats")
	var plan=d.encounter_r21
	for i in b.data.enemies.size():
		var raw=w.dungeon_rules.foe_stats(plan.enc,w.dungeon_rules.foe_def(plan.enc,i,plan.el),plan.el)
		check(b.data.enemies[i].mhp==int(floor(raw.hp*1.25+.5)),"P8 enemy HP scaled once")
	var frozen=w.battle_data();w.s.settings.diff=1
	check(same(frozen,w.battle_data()),"active battle difficulty frozen")
	for turn in range(400):
		if not b.result.is_empty():break
		if not b.player_turn():check(b.automatic_turn(),"actual CTB enemy action");continue
		b.selected_enemy=b.living(false)[0].id
		var action="personal" if b.current_id=="persona" and b.actions().has("personal") and b.unavailable("personal")=="" else "attack"
		check(b.act(action),"actual CTB action")
		if turn<3:
			w.record_battle(b.snapshot());save_sample(w,"midfight_%d"%turn)
	check(b.result=="victory","actual integrated CTB victory")
	w.record_battle(b.snapshot());save_sample(w,"terminal")
	var before=w.s.persona.duplicate(true)
	check(w.finish_battle(),"finish battle")
	check(w.s.persona==before and w.s.run.xp>0,"P5 XP deferred until settlement")
	var resolved=JSON.stringify(w.s)
	check(not w.finish_battle() and JSON.stringify(w.s)==resolved,"repeat finish changes nothing including bark")
	w.dismiss_dialogue_queue();var aff=w.s.members.teiris.aff
	check(w.settle("retreat"),"P5 settle")
	check(w.s.members.teiris.aff>aff,"affection settlement hook")
	check(w.s.persona!=before,"P1 XP award")
	check(C.entries(w.s).filter(func(x):return x.contains("Retreated from Great Dungeon")).size()==1,"P10 one return fact")
	var settled=JSON.stringify(w.s)
	check(not w.settle("retreat") and not w.finish_battle() and JSON.stringify(w.s)==settled,"repeat result does not pay or emit")
	save_sample(w,"settled")
	# P5 source codes and full-bag overflow must survive the merged facade.
	var code=w.combat_gear_adapter.rules.code(entry);var bank=w.bank_expedition_gear([code])
	check(w.s.gear[-1].get("code","")==code and w.s.gear[-1].source_r21,"P5 preserves canonical source code")
	var full=fresh();full.s.gear=[]
	for i in range(2000):var e=entry.duplicate(true);e.uid=i+1;full.s.gear.append(e)
	full.s.serial=2000;bank=full.bank_expedition_gear([code])
	check(full.s.get("gear_r22",{}).get("overflow",[]).size()==1,"P5 full bag preserves drop in overflow")
	# Reconstruct the public P5 double-equipment cap without changing the source rules.
	var old_save=samples.midfight_2.duplicate(true);var old_reader=W.new();old_reader.restore(old_save)
	var correct=old_reader.stats("persona",10);var bonus=old_reader.gear_bonus("persona",10)
	var old_hp=int(floor(correct.hp*(1+bonus.get("hp",0)/100.0)+.5))
	check(old_hp>correct.hp,"old equipped persona fixture reproduces excess HP")
	old_save.members.persona.hp=old_hp;old_save.run.maxima.persona.hp=old_hp;old_save.run.battle.units.persona.hp=old_hp
	var old_bytes=JSON.stringify(old_save);var migrated=W.new()
	check(migrated.restore(old_save),"public P5 double-equipment save migrates")
	check(JSON.stringify(old_save)==old_bytes,"old equipment save input unchanged")
	check(migrated.s.equipment_vitals_before_r14.hp==old_hp and migrated.s.equipment_vitals_before_r14.battle_hp==old_hp,"exact old world and battle HP archived")
	check(migrated.s.members.persona.hp==correct.hp and migrated.s.run.battle.units.persona.hp==correct.hp,"old excess HP normalized once")
	save_sample(migrated,"public_p5_equipment_migration")
	var again=W.new();check(again.restore(migrated.s) and same(again.s,migrated.s),"equipment migration repeated restore is idempotent")
	var invalid=migrated.s.duplicate(true);invalid.equipment_vitals_before_r14.opaque={}
	check(not again.restore(invalid),"equipment archive rejects opaque fields")
	var large=fresh();large.s.items.hp_s=10001;large.depart_dungeon(1,117);large.dismiss_dialogue_queue()
	while large.s.run.phase!="battle" and large.s.run.step<5:large.advance();large.dismiss_dialogue_queue()
	var large_battle=B.new(large.battle_data());large.record_battle(large_battle.snapshot())
	check(not large.s.run.battle.is_empty(),"P6 large item stock persists in an active P5 battle")
	save_sample(large,"large_item_stock_battle")
	for quantity in [-1,.5,9007199254740992]:
		var broken=large_battle.snapshot();broken.inventory.hp_s=quantity
		check(not B.new(large.battle_data()).restore(broken),"battle inventory rejects invalid or inexact JSON count")
	# All companions enter the real merged P5 model with source native equipment.
	for c in w.config.companions:
		var roster=fresh(c.id);roster.s.persona.lv=40;roster.s.members.persona.level=40;roster.s.members[c.id].level=40
		for who in ["persona",c.id]:
			for it in roster.gear.by_id.values():
				if it.cls==roster.class_def(who).id and it.slot=="acc" and it.rarity=="legend":
					roster.s.serial+=1;roster.s.gear.append(roster.combat_gear_adapter.source_drop({"id":it.id,"seed":456},roster.s.serial));check(roster.equip(who,roster.s.serial),"roster canonical equip "+who);break
		check(roster.depart_dungeon(1,117),"roster P5 departure "+c.id);roster.dismiss_dialogue_queue()
		while roster.s.run.phase!="battle" and roster.s.run.step<5:roster.advance();roster.dismiss_dialogue_queue()
		var combat=B.new(roster.battle_data())
		roster.record_battle(combat.snapshot());save_sample(roster,c.id+"_entry")
		for turn in range(20):
			if not combat.result.is_empty():break
			if combat.automatic_turn():continue
			combat.selected_enemy=combat.living(false)[0].id
			var action="personal" if combat.unavailable("personal")=="" else "attack"
			combat.selected_ally=combat.living(true).filter(func(a):return a.id!=combat.current_id)[0].id
			check(combat.act(action),"roster CTB action "+c.id)
			roster.record_battle(combat.snapshot());save_sample(roster,c.id+"_action_"+str(turn))
	# Production client upload/download replaces the complete model mid-fight.
	await process_frame
	await process_frame
	await create_timer(.05).timeout
	var cloud_world=W.new();check(cloud_world.restore(samples.midfight_2),"midfight cloud input")
	var store=Store.new("user://round14/cloud.json");DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://round14"))
	var cloud=Cloud.new();cloud.model=cloud_world;cloud.storage=store;root.add_child(cloud)
	cloud.config.server_url=OS.get_environment("ABYSS_TEST_SERVER");cloud.account={"code":"","pin":"","rev":0,"auto":false,"synced":false}
	check(store.write(cloud_world.s)==OK,"production local save flushes chronicle before cloud")
	var original=cloud_world.s.duplicate(true)
	FileAccess.open("res://../verification/town-r21/round14/cloud-input.json",FileAccess.WRITE).store_string(JSON.stringify(original))
	await cloud.create_account();check(cloud.account.rev==1,"midfight real D1 account")
	await cloud.upload();check(cloud.account.rev==2,"midfight real D1 PUT")
	cloud_world.s.gold=1;await cloud.download();check(same(cloud_world.s,original),"midfight real D1 download all fields")
	FileAccess.open("res://../verification/town-r21/round14/cloud-downloaded.json",FileAccess.WRITE).store_string(JSON.stringify(cloud_world.s))
	var resumed=B.new(cloud_world.battle_data());check(resumed.restore(cloud_world.s.run.battle),"downloaded battle resumes")
	var local=B.new(cloud_world.battle_data());local.restore(original.run.battle)
	for model in [local,resumed]:
		if model.player_turn():model.selected_enemy=model.living(false)[0].id;model.act("attack")
		else:model.automatic_turn()
	check(same(local.snapshot(),resumed.snapshot()),"D1 resumed next action deterministic")
	cloud.queue_free()
	var out="res://../verification/town-r21/round14/"
	FileAccess.open(out+"save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"  "))
	FileAccess.open(out+"integration-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":samples.size()},"  "))
	print("TOWN COMBAT ROUND14 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
