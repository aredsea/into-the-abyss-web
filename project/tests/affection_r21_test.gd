extends SceneTree
const Rules=preload("res://game/town_rules_r21.gd")
func _init() -> void:
	var file=ProjectSettings.globalize_path("res://../verification/town-r21/round6/affection-oracle.json")
	var rows=JSON.parse_string(FileAccess.get_file_as_string(file))
	if not rows is Array or rows.is_empty():
		push_error("Missing Lua oracle samples")
		quit(1);return
	var failures=0
	for row in rows:
		if Rules.aff_stage(row.a)!=row.stage or not is_equal_approx(Rules.aff_next(row.a,row.amount),row.next):
			failures+=1;push_error("Affection mismatch: "+str(row))
	print("AFFECTION R21 CHECKS ",rows.size()*2," FAILURES ",failures," LUA SAMPLES ",rows.size())
	quit(1 if failures else 0)
