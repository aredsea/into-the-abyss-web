extends "res://game/battle_v3.gd"
## Isolate an enemy action from CTB scheduling; damage/effects remain production code.
func _start_ctb() -> void: pass
func _finish_turn(_interval_scale: float=1) -> void:
	dungeon_enemy_r21.end_effects(unit(current_id))
	unit(current_id).remaining+=10000
	turn_count+=1
