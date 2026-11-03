extends "res://../verification/parity-r23/round4-before-miko-core.gd"
var freeze_finish=false
func _finish_turn(scale: float=1) -> void:
	if not freeze_finish: super(scale)
