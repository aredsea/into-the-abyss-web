extends "res://tests/combat_a6_r22_test.gd"
const Display=preload("res://game/combat_display_r22.gd")
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/display-oracle.json"))
	for row in source.rows:
		var got=Display.schedule(row.event)
		check(same(got,row.expected),"display/%s/%d"%[row.event.k,row.variant],got,row.expected)
	var f=FileAccess.open("res://../verification/parity-r23/display-latest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 DISPLAY ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
