extends SceneTree
const World=preload("res://game/expansion_world.gd")
const Face=preload("res://ui/battle_face_r17.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.content_scale_size=Vector2i(720,500); root.size=Vector2i(720,500)
	var bg=ColorRect.new(); bg.color=Color("f4efe3"); bg.size=Vector2(720,500); root.add_child(bg)
	var w=World.new(); var i=0
	for p in w.config.companions:
		var face=Face.new(); face.configure(p.id); root.add_child(face)
		face.position=Vector2(10+(i%6)*120,5+int(i/6)*100); face.size=Vector2(100,62)
		var label=Label.new(); label.text=p.name; root.add_child(label)
		label.position=face.position+Vector2(0,64); label.add_theme_font_override("font",preload("res://assets/fonts/GowunBatang-Bold.ttf")); label.add_theme_font_size_override("font_size",12); label.add_theme_color_override("font_color",Color("111715"))
		i+=1
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../verification/ui-r17/roster-faces.png")
	quit()
