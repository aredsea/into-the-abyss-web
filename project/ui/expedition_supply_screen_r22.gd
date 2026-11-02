extends "res://ui/battle_screen.gd"
## Keep r17-r20 presentation intact; replace only the P5 supply rules object.
const Supply=preload("res://game/expedition_supply_r22.gd")
func _ready() -> void:
	super()
	var saved=state.snapshot();state=Supply.new(scene_data);state.restore(saved);_rebuild()
func _supply_reason() -> String:
	if pending_action.is_empty():return "보급품 선택"
	var it=state.actions()[pending_action].item;var a=state.ally(state.selected_ally)
	if a.is_empty() or not supply_target_set:return "대상 선택"
	if it.kind=="cleanse" and state.supply_state_ok(it,a):return ""
	return super()
