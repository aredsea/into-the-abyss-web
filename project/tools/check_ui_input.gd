extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/expansion_world.gd")
var failures=0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i(360,780); root.size=Vector2i(360,780)
	var screen=Screen.new(); root.add_child(screen); screen.size=Vector2(360,780); screen.model=World.new(); screen.motion_reduced=true
	for entry in [["nav:party","party",0.5],["nav:town","town",0.85],["shop","shop",0.5],["nav:town","town",0.5],["town_formation","party",0.5],["member:hildegard","member",0.5]]:
		await process_frame; await process_frame
		var rect=screen.controls[entry[0]].get_global_rect()
		var point=rect.position+Vector2(rect.size.x*0.5,rect.size.y*entry[2])
		var move=InputEventMouseMotion.new(); move.position=point; root.push_input(move)
		var down=InputEventMouseButton.new(); down.position=point; down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; root.push_input(down)
		var up=InputEventMouseButton.new(); up.position=point; up.button_index=MOUSE_BUTTON_LEFT; root.push_input(up)
		await process_frame
		if screen.screen!=entry[1]: failures+=1; push_error("Input failed: "+entry[0])
	print("UI INPUT CHECKS 6 FAILURES ",failures)
	quit(1 if failures else 0)
