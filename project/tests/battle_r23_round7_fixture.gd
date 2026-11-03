extends "res://tests/combat_a6_r22_fixture.gd"
var forced_evade: Variant=null
func _enemy_evade(e: Dictionary,a: Dictionary) -> bool:
	return forced_evade if forced_evade!=null else super(e,a)
