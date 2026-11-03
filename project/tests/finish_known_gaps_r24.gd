extends SceneTree
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/oracle.json"));var rows=[]
	for f in oracle.unknown_codes:
		var w=preload("res://game/settings_world_r22.gd").new();w.s.persona.cls="전사"
		var bank=w.bank_expedition_gear([f.code]);var imported=preload("res://game/gear_save_r22.gd").new().import_codes(w.s,{"bag":"","equip":{"persona":{"weapon":f.code}}})
		rows.append({"code":f.code,"source":f,"native_bank":bank,"native_import_added":imported.added,"native_import_conflicts":imported.conflicts,"native_equipment":imported.state.equipment.persona,"bank_same":bank.gear==f.bank.gear and bank.lost==f.bank.lost})
	FileAccess.open("res://../verification/finish-r24/known-code-gaps.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"));print("KNOWN CODE GAPS ",JSON.stringify(rows));quit()
