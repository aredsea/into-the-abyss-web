extends "res://../verification/parity-r23/battle-round7-before-battle_v3.gd"
var freeze_finish=false
var forced_evade: Variant=null
func _finish_turn(scale: float=1) -> void:
	if not freeze_finish:super(scale)
func _enemy_evade(e: Dictionary,a: Dictionary) -> bool:
	return forced_evade if forced_evade!=null else super(e,a)
