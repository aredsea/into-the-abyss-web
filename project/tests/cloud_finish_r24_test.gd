extends SceneTree
const World=preload("res://game/settings_world_r22.gd")
const Battle=preload("res://game/battle_v3.gd")
const Store=preload("res://game/settings_save_r22.gd")
const Cloud=preload("res://game/cloud_store_r22.gd")
var checks=0
var failures=[]
func check(ok,label):
	checks+=1
	if not ok:failures.append(label);push_error(label)
func _initialize():create_timer(90).timeout.connect(func():quit(98));call_deferred("run")
func run():
	var had_preferences=FileAccess.file_exists(Cloud.PREFS)
	var preferences=FileAccess.get_file_as_bytes(Cloud.PREFS) if had_preferences else PackedByteArray()
	var c=Cloud.new();root.add_child(c);c.model=World.new();c.storage=Store.new("user://finish-r24-cloud-source.json")
	c.config.server_url=OS.get_environment("ABYSS_TEST_SERVER");c.account={"code":"","pin":"","rev":0,"auto":false,"synced":false}
	var input=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round3/resume-state.json"))
	check(c.model.restore(input),"real native battle state restores")
	await c.create_account();check(c.account.rev==1 and c.can_upload(),"D1 accepts new battle fields")
	var other=Cloud.new();root.add_child(other);other.model=World.new();other.storage=Store.new("user://finish-r24-cloud-target.json");other.config.server_url=c.config.server_url
	other.account={"code":c.account.code,"pin":c.account.pin,"rev":1,"auto":false,"synced":false}
	await other.download();check(other.account.synced,"second device downloaded battle")
	check(other.model.s.run==c.model.s.run,"cloud preserves the complete run")
	var b=Battle.new(other.model.battle_data());check(b.restore(other.model.s.run.battle),"cloud battle resumes")
	check(b.data.depletions==3,"cloud depletion count preserved")
	check(b.snapshot().last_kill==input.run.battle.last_kill and b.data.last_kill!="","cloud killer id/name preserved")
	var local=World.new();check(other.storage.read_into(local),"downloaded battle reloads from local disk")
	check(local.s.run.battle==input.run.battle,"disk preserves both metadata fields")
	# Legacy snapshots do not acquire invented outcome data during server validation.
	for key in ["depletions","last_kill"]:c.model.s.run.battle.erase(key)
	await c.upload();check(c.account.rev==2,"D1 still accepts legacy battle snapshots")
	await other.download();var old=Battle.new(other.model.battle_data());check(old.restore(other.model.s.run.battle),"legacy cloud battle resumes")
	check(old.data.depletions==0 and old.data.last_kill=="","legacy defaults remain 0/empty")
	c.model=World.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:c.model.create_action(arg)
	c.model.create_action("pick_teiris","sc");c.model.create_action("go","sc");c.model.s.dialogue_r21.queue=[]
	c.model.s.members.teiris.aff=19
	check(c.model.begin_inn_talk("teiris"),"inn commits source action before narrative")
	var paid=c.model.s.members.teiris.aff
	await c.upload();check(c.account.rev==3,"existing acts map carries the prepaid narrative without a new server field")
	await other.download();check(not other.model.s.dialogue_r21.pending.is_empty(),"prepaid narrative downloads")
	check(other.model.choose_dialogue("c1"),"downloaded narrative choice can complete")
	check(other.model.s.members.teiris.aff==paid,"cloud resume cannot pay inn affection twice")
	check(other.model.s.dialogue_r21.queue.is_empty() and not other.model.s.dialogue_r21.response.transition.is_empty(),"cloud stage change appears once in the narrative response")
	check(not other.model.choose_dialogue("c1"),"duplicate narrative commit rejected")
	await c.delete_account();check(not c.connected(),"test account erased")
	c.queue_free();other.queue_free();await process_frame
	if had_preferences:FileAccess.open(Cloud.PREFS,FileAccess.WRITE).store_buffer(preferences)
	else:DirAccess.remove_absolute(Cloud.PREFS)
	FileAccess.open("res://../verification/finish-r24/round3/cloud-fields.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures}))
	print("CLOUD FINISH R24 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
