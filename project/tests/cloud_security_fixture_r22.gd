extends SceneTree
const World=preload("res://game/persona_world.gd")
const Battle=preload("res://game/battle_v3.gd")
var specimens={}
func _initialize():
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/cloud-r22/fixtures.json"))
	var m=World.new();m.restore(fixture.town)
	m.begin_dialogue("marceline");specimens.pending=m.s.duplicate(true)
	var row=m.dialogue.scene("marceline",m.s.dialogue_r21.pending.scene)
	m.choose_dialogue(row.choices[0].id);specimens.response=m.s.duplicate(true)
	m.close_dialogue();m.s.members.marceline.aff=19;m.aff_add("marceline",2)
	specimens.transition=m.s.duplicate(true)
	# Real engine snapshots, including enemy effects and changing unit state.
	for floor_no in [1,3,15,30,60,90,150,240,360,420]:
		m=World.new();m.restore(fixture.town)
		m.s.dungeon_r21.best=419;m.s.dungeon_r21.sel=420
		m.depart_dungeon(floor_no,1234)
		m.s.run.phase="battle"
		var b=Battle.new(m.battle_data())
		for step in range(18):
			m.s.run.battle=b.snapshot();specimens["battle_%d_%d"%[floor_no,step]]=m.s.duplicate(true)
			if not b.result.is_empty():break
			if b.player_turn():b.act("attack")
			else:b.automatic_turn()
		m.s.run.phase="explore";m.s.run.battle={};m.settle("retreat")
		specimens["settlement_%d"%floor_no]=m.s.duplicate(true)
	FileAccess.open("res://../verification/cloud-r22/p9b/legitimate-fixtures.json",FileAccess.WRITE).store_string(JSON.stringify(specimens,"\t"))
	print("CLOUD SECURITY FIXTURES ",specimens.size());quit()
