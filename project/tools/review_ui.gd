extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/expansion_world.gd")
const Battle=preload("res://ui/battle_screen.gd")
func _initialize() -> void: call_deferred("review")
func shot(path: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func review() -> void:
	var out=ProjectSettings.globalize_path("res://../../../work/ui-r11").simplify_path()
	var checks=[]
	for dimensions in [Vector2i(390,844),Vector2i(360,780)]:
		root.content_scale_size=dimensions; root.size=dimensions
		var screen=Screen.new(); root.add_child(screen); screen.size=dimensions
		screen.model=World.new(); screen.motion_reduced=true
		for page in ["town","party","member","depart","bag","shop","inn","guild","smithy","equipment","research","journal","cards"]:
			screen.screen=page; screen.who="hildegard"; screen._draw_screen()
			await shot(out+"/"+page+"-"+str(dimensions.x)+".png")
			checks.append({"page":page,"width":dimensions.x,"content":screen.content.size.x,"available":screen.scroll.size.x,"horizontal_overflow":screen.content.size.x>screen.scroll.size.x+1})
		screen.model.depart(); screen.screen="explore"; screen._draw_screen()
		await shot(out+"/explore-"+str(dimensions.x)+".png")
		screen.model.settle("retreat"); screen.screen="summary"; screen._draw_screen()
		await shot(out+"/summary-"+str(dimensions.x)+".png")
		screen.screen="town"; screen._ask("원정에 필요한 보급품을 구입할까요?",func(): return true)
		await shot(out+"/confirm-"+str(dimensions.x)+".png")
		root.remove_child(screen); screen.queue_free()
		var fixture=World.new(); fixture.depart()
		var battle=Battle.new(); battle.session_data=fixture.battle_data(); root.add_child(battle); battle.size=dimensions; battle.motion_reduced=true
		await shot(out+"/battle-"+str(dimensions.x)+".png")
		checks.append({"page":"battle","width":dimensions.x,"text_errors":battle.text_metrics.filter(func(m): return m.needed>m.available+1 or not m.missing_glyphs.is_empty())})
		root.remove_child(battle); battle.queue_free()
	var file=FileAccess.open(out+"/layout-checks.json",FileAccess.WRITE); file.store_string(JSON.stringify(checks,"  "))
	print("UI review rendered, layout evidence written")
	quit()
