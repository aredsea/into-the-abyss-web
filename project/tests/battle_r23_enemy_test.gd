extends "res://tests/enemy_action_r21_test.gd"
var reports=[]
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/enemy-oracle.json"))
	var w=World.new();w.depart_dungeon(1,12345);w.s.run.phase="battle"
	for row in oracle.rows:
		var b=setup(w,row);var e=b.data.enemies[0]
		match row.op:
			"summon":
				if row.params.variant=="just_died":b._record_hit(e.id,b.data.enemies[3].id,1,0)
				b.dungeon_enemy_r21.summon(e,{"name":"test","enemy":"apprentice_doll","count":row.params.count})
			"phase":b.dungeon_enemy_r21.phase_check()
			"guard":b._flat_enemy(e,row.params.raw);b.dungeon_enemy_r21.phase_check()
			"cancel":b.dungeon_enemy_r21.turn();e.remaining-=10000
		var actual=dump(b);var delta=differences(row.output,actual)
		if int(b.x(b.data.enemies[0]).source_rng)!=int(row.output_rng):delta.append("rng")
		check(delta.is_empty(),"r23/%s/%s/%s"%[row.op,row.id,str(row.params)])
		reports.append({"op":row.op,"params":row.params,"differences":delta,"actual":actual,"expected":row.output})
	var f=FileAccess.open("res://../verification/parity-r23/enemy-latest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"reports":reports},"\t"));f.close()
	print("R23 ENEMY ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
