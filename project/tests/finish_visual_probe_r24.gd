extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844)
	var s=preload("res://ui/world_screen.gd").new();s.size=root.size;root.add_child(s)
	s.model=preload("res://game/settings_world_r22.gd").new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:s.model.create_action(arg)
	s.model.create_action("pick_teiris","sc");s.model.create_action("go","sc")
	s.model.s.dialogue_r21.queue=[];s.model.s.settings.lang="en";s.model.inn("teiris","talk");s.who="teiris";s.screen="inn";s._draw_screen()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var rows=[]
	for l in s.town_view.find_children("*","Label",true,false):
		if "Dorothea" in l.text or "done" in l.text.to_lower():
			var fs=l.get_theme_font_size("font_size");var needed=l.get_theme_font("font").get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode else -1,fs)
			rows.append({"text":l.text,"size":[l.size.x,l.size.y],"font":fs,"needed":[needed.x,needed.y],"lines":l.get_line_count(),"visible_lines":l.get_visible_line_count(),"width":l.get_theme_font("font").get_string_size(l.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x})
	s.town_view.npc_hero("missing_npc_provider","","",365)
	var omitted=not s.town_view.boxes.has("portrait_fallback:missing_npc_provider") and not s.town_view.boxes.has("portrait:missing_npc_provider:town-main")
	FileAccess.open("res://../verification/finish-r24/round3/visual-probe.json",FileAccess.WRITE).store_string(JSON.stringify({"captions":rows,"missing_npc_omitted":omitted}))
	print("VISUAL PROBE ",JSON.stringify(rows)," MISSING NPC OMITTED ",omitted);quit(0 if omitted else 1)
