extends SceneTree
const Portrait = preload("res://ui/character_portrait.gd")
func _initialize() -> void:
	call_deferred("render_review")
func render_review() -> void:
	root.content_scale_size = Vector2i(840, 420)
	root.size = Vector2i(840, 420)
	var background = ColorRect.new()
	background.color = Color("172323"); background.size = Vector2(840,420)
	root.add_child(background)
	var ids = ["hildegard", "bargut", "teiris", "berenga"]
	for i in range(ids.size()):
		var portrait = Portrait.new()
		portrait.position = Vector2(i * 210 + 10, 10)
		portrait.size = Vector2(190, 380)
		portrait.configure(ids[i]); root.add_child(portrait)
	await process_frame
	await RenderingServer.frame_post_draw
	var output = "res://../../../work/motion-r9/portrait-review.png"
	var result = root.get_texture().get_image().save_png(output)
	if result != OK: push_error("Portrait review render failed"); quit(1); return
	quit()
