extends "res://tests/combat_a6_r22_test.gd"
const Clock=preload("res://game/combat_clock_r22.gd")
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/clock-oracle.json"))
	for row in source.rows:
		var input=row.units.duplicate(true);var before=JSON.stringify(input)
		var got=Clock.preview(input,input.map(func(u):return u.speed),"u%d"%row.cur,int(row.count))
		var want=row.expected.map(func(i):return "u%d"%i)
		check(same(got,want),"clock/preview/%d/%d/%d"%[row.count,row.cur,row.alive],got,want)
		check(row.unchanged and JSON.stringify(input)==before,"clock/preview leaves input untouched")
	var f=FileAccess.open("res://../verification/parity-r23/clock-latest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 CLOCK ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
