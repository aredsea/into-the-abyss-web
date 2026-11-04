extends "res://tests/cloud_finish_r24_test.gd"
func equal_json(a,b):
	if (a is int or a is float) and (b is int or b is float):return a==b
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not equal_json(a[key],b[key]):return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in a.size():
			if not equal_json(a[i],b[i]):return false
		return true
	return typeof(a)==typeof(b) and a==b
func run():
	var had_preferences=FileAccess.file_exists(Cloud.PREFS)
	var preferences=FileAccess.get_file_as_bytes(Cloud.PREFS) if had_preferences else PackedByteArray()
	var c=Cloud.new();root.add_child(c);c.model=World.new();c.storage=Store.new("user://finish-r24-r4-source.json")
	c.config.server_url=OS.get_environment("ABYSS_TEST_SERVER");c.account={"code":"","pin":"","rev":0,"auto":false,"synced":false}
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:c.model.create_action(arg)
	c.model.seed_source=func():return 4242
	c.model.create_action("pick_teiris","sc");c.model.create_action("go","sc");c.model.s.dialogue_r21.queue=[]
	check(c.model.depart_dungeon(1,7),"cloud rest departure");c.model.s.run.phase="rest"
	c.model.bank_expedition_gear(["wa01.1.1","sa01.1.1"])
	check(c.model.expedition_equipment_action("eq_weapon_wa01_1_1"),"cloud source equip")
	check(c.model.expedition_equipment_action("who_2"),"cloud selected second member")
	await c.create_account();check(c.account.rev==1,"D1 accepts existing UI selection field")
	var other=Cloud.new();root.add_child(other);other.model=World.new();other.storage=Store.new("user://finish-r24-r4-target.json");other.config.server_url=c.config.server_url
	other.account={"code":c.account.code,"pin":c.account.pin,"rev":1,"auto":false,"synced":false}
	await other.download();check(other.account.synced,"second device downloads rest")
	if not equal_json(other.model.s.equipment,c.model.s.equipment):print("CLOUD GEAR DIFF ",JSON.stringify(c.model.s.equipment)," RECEIVED ",JSON.stringify(other.model.s.equipment))
	check(other.model.expedition_equipment_slot()==2,"selected member resumes through cloud")
	check(equal_json(other.model.s.equipment.persona,c.model.s.equipment.persona),"equipped copy resumes through cloud")
	check(other.model.expedition_equipment_action("eq_weapon_sa01_1_1"),"second device continues with selected member")
	check(other.model.s.equipment.teiris.has("weapon"),"selected teammate receives the bag copy")
	await other.upload();check(other.account.rev==2,"rest edit uploads")
	await c.download();check(equal_json(c.model.s.equipment,other.model.s.equipment),"first device sees resumed gear transaction")
	var disk=World.new();check(c.storage.read_into(disk),"downloaded rest reloads from disk")
	check(disk.expedition_equipment_slot()==2 and equal_json(disk.s.equipment,other.model.s.equipment),"disk preserves selection and ownership")
	var before=disk.s.duplicate(true);check(not disk.expedition_equipment_action("eq_weapon_wa01_1_1"),"equipped foreign copy cannot transfer")
	check(disk.s.equipment==before.equipment and disk.s.gear==before.gear,"rejection preserves gear ownership")
	c.model=World.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:c.model.create_action(arg)
	c.model.create_action("pick_teiris","sc");c.model.create_action("go","sc");c.model.s.dialogue_r21.queue=[];c.model.s.items.level_scroll=2
	for arg in ["cls_sanctioned","slot_acc","scroll"]:check(c.model.shop_action(arg,"shop"),"shop source selection "+arg)
	await c.upload();check(c.account.rev==3,"shop selection uses the existing server schema")
	await other.download();check(equal_json(other.model.shop_selection(),c.model.shop_selection()),"class slot and scroll selection survive actual D1")
	check(other.model.shop_action("target_teiris","shop") and other.model.s.members.teiris.level==2,"downloaded source scroll selection continues")
	check(other.model.shop_selection()=={"cls":"sanctioned","slot":"acc","target":""},"scroll completion retains class and slot")
	await other.upload();check(other.account.rev==4,"second device source shop action uploads")
	await c.download();check(c.model.s.members.teiris.level==2 and c.model.s.items.level_scroll==1,"next download preserves the scroll transaction")
	await c.delete_account();check(not c.connected(),"temporary account erased")
	c.queue_free();other.queue_free();await process_frame
	if had_preferences:FileAccess.open(Cloud.PREFS,FileAccess.WRITE).store_buffer(preferences)
	else:DirAccess.remove_absolute(Cloud.PREFS)
	FileAccess.open("res://../verification/finish-r24/round4/cloud-rest.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("CLOUD FINISH ROUND4 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
