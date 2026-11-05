extends SceneTree
# Writes a real mid-battle save with 5+ enemy slots; server/abyss-save/test/finish-r24.mjs validates it.
const World=preload("res://game/settings_world_r22.gd")
const Battle=preload("res://game/battle_v3.gd")
func _initialize():create_timer(60).timeout.connect(func():quit(98));call_deferred("run")
func run():
	var input=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round3/resume-state.json"))
	var model=World.new()
	if not model.restore(input):printerr("restore failed");quit(1);return
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/lua-oracle.json"))
	var sample=null
	for q in oracle.samples:
		if int(q.enc.ne)>=5:sample=q;break
	if sample==null:printerr("no 5-slot encounter");quit(1);return
	var d=model.battle_data()
	d.enemies=model.make_enemies({"enc":sample.enc,"el":int(sample.el)},d.allies)
	d.encounter_r21.enc=sample.enc;d.encounter_r21.el=int(sample.el)
	var b=Battle.new(d.duplicate(true))
	var snap=b.snapshot()
	var slots=[]
	for id in snap.units.keys():
		if String(id).begins_with("r21_slot_"):slots.append(id)
	if slots.is_empty():printerr("snapshot has no r21_slot unit");quit(1);return
	var resumed=Battle.new(d.duplicate(true))
	if not resumed.restore(JSON.parse_string(JSON.stringify(snap))):printerr("snapshot does not resume");quit(1);return
	input.run.battle=snap
	var path="res://../server/abyss-save/test/battle-slot-r24.json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(input))
	print("BATTLE SLOT SNAPSHOT slots=",slots," units=",snap.units.size())
	quit(0)
