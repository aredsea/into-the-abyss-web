extends SceneTree
func _initialize():
	var root=ProjectSettings.globalize_path("res://../verification/cloud-r22")
	DirAccess.make_dir_recursive_absolute(root)
	var model=preload("res://game/persona_world.gd").new()
	var fresh=model.s.duplicate(true)
	for action in ["race_human","nat_"+model.persona_rules.data.nations[0].id,"cls_warrior","auto","done"]:model.create_action(action)
	# Use the source's first valid nation rather than assuming a display name.
	if model.s.scene=="create":
		model.s.persona.nation=model.persona_rules.data.nations[0].name
		model.create_action("done")
	model.create_action("pick_marceline","sc")
	model.create_action("go","sc")
	var legacy=preload("res://game/town_world_r21.gd").new()
	var specimens={"fresh":fresh,"town":model.s.duplicate(true),"legacy2":legacy.s.duplicate(true)}
	model.depart_dungeon(1,1234)
	specimens.run=model.s.duplicate(true)
	model.s.gold=10000
	model.s.run={};model.s.dialogue_r21.queue=[]
	model.process_gear("marceline")
	specimens.gear=model.s.duplicate(true)
	model.inn("marceline","meal")
	specimens.meal=model.s.duplicate(true)
	var migrations={}
	for name in DirAccess.get_files_at(root+"/../persona-r22/legacy"):
		if not name.ends_with(".json"):continue
		var value=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy/"+name))
		var loaded=preload("res://game/persona_world.gd").new()
		if loaded.restore(value):migrations[name]=loaded.s
	FileAccess.open(root+"/native-migrations.json",FileAccess.WRITE).store_string(JSON.stringify(migrations,"\t"))
	var file=FileAccess.open(root+"/fixtures.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(specimens,"\t"))
	print("CLOUD FIXTURES ",model.s.scene," ",model.s.owned)
	quit()
