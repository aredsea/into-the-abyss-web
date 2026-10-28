extends SceneTree
const Screen = preload("res://ui/world_screen.gd")
const World = preload("res://game/expansion_world.gd")
const Portrait = preload("res://ui/character_portrait.gd")
func _initialize() -> void: call_deferred("review")
func review() -> void:
	var out = ProjectSettings.globalize_path("res://../../../work/portrait-r10").simplify_path()
	DirAccess.make_dir_recursive_absolute(out)
	for dimensions in [Vector2i(390,844),Vector2i(360,780)]:
		root.content_scale_size = dimensions; root.size = dimensions
		var screen = Screen.new(); root.add_child(screen); screen.size = dimensions
		# Fresh in-memory fixture only: the user's save is neither read for assertions nor written.
		screen.model = World.new(); screen.motion_reduced = true
		for page in ["town","party","member"]:
			screen.screen = page; screen.who = "hildegard"; screen._draw_screen()
			await process_frame; await process_frame; await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out+"/"+page+"-"+str(dimensions.x)+".png")
		root.remove_child(screen); screen.queue_free()
	root.content_scale_size = Vector2i(880,340); root.size = Vector2i(880,340)
	for i in range(4):
		var bg = ColorRect.new(); bg.color = Color("252d30"); bg.position = Vector2(i*220,0); bg.size=Vector2(220,340); root.add_child(bg)
		var portrait = Portrait.new(); portrait.configure(Portrait.FACE_IDS[i]); portrait.position=Vector2(i*220+10,10); portrait.size=Vector2(200,300); root.add_child(portrait)
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/faces-review.png")
	print("Rendered town, roster, detail at 390 and 360, plus enlarged portrait review")
	quit()
