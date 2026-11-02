extends "res://tests/a7_baseline_battle_v3.gd"
var freeze_finish=false
func _finish_turn(scale: float=1) -> void:
	if not freeze_finish: super(scale)
