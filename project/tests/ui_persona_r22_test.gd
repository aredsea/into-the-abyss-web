extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/persona_world.gd")
const Create=preload("res://ui/create_screen.gd")
var folder="res://../verification/persona-r22/render"
var checks=0
var failures=[]
var captures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func click(s,id):
	check(s.controls.has(id),"control "+id)
	if not s.controls.has(id):return
	var b=s.controls[id]
	# r24: the same control may now live below the first viewport.
	if b is Control:
		var viewport=b.get_parent()
		while viewport!=null and not viewport is ScrollContainer:viewport=viewport.get_parent()
		if viewport is ScrollContainer:
			viewport.ensure_control_visible(b);await process_frame;await process_frame
	if s.town_view is Create and s.town_view.body.is_ancestor_of(b):
		s.town_view.scroll.ensure_control_visible(b);await process_frame;await process_frame
	var point=b.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=point;root.push_input(e)
	await process_frame;await process_frame
func capture(s,tag,dim):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y]
	check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name)
	var view=s.town_view
	if view is Create:
		check(view.body.size.x<=view.scroll.size.x+1,"no horizontal form overflow "+name)
		for l in view.find_children("*","Label",true,false):
			var font=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size");var need=font.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x,fs)
			check(need.y<=l.size.y+1,"label fits "+name+l.text)
		for id in s.controls:
			var b=s.controls[id]
			if b is Button:
				var style=b.get_theme_stylebox("normal");var inset=Vector2(style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT),style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM))
				var room=b.size-inset;var font=b.get_theme_font("font");var need=font.get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_CENTER,room.x if b.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,b.get_theme_font_size("font_size"))
				check(need.x<=room.x+1 and need.y<=room.y+1,"button text fits "+name+id)
				check(b.size.y>=44,"touch height "+id)
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://persona-ui-a7-%dx%d-%d-%d.json"%[dim.x,dim.y,OS.get_process_id(),Time.get_ticks_msec()];root.add_child(s);s.model=World.new();s._draw_screen();s.motion_reduced=true
		await capture(s,"race",dim)
		await click(s,"cr_race_beast");await click(s,"cr_lin_cat");await click(s,"cr_next");await capture(s,"nation",dim)
		await click(s,"cr_nat_naerin");check(s.model.s.persona.nation=="" and s.model.s.ui.msg!="","blocked origin explains reason")
		await capture(s,"blocked",dim)
		await click(s,"cr_nat_border");await click(s,"cr_next");await capture(s,"class",dim)
		await click(s,"cr_cls_archer");await click(s,"cr_next");await click(s,"cr_tot_free");await click(s,"cr_tot_p5");await click(s,"cr_auto");await capture(s,"points",dim)
		check(s.model.persona_rules.left(s.model.s.persona)==0 and s.model.s.persona.bonus_total==10,"pointer allocation source contract")
		await click(s,"cr_next");await capture(s,"confirm",dim);await click(s,"cr_done")
		await click(s,"sc_pick_teiris");await capture(s,"scenario",dim);await click(s,"sc_go");await capture(s,"town",dim)
		check(s.model.s.gold==300 and s.model.s.owned==["teiris"],"first meeting pointer creates one companion")
		await click(s,"depart");await capture(s,"sortie",dim);await click(s,"so_fight_0")
		check(s.model.s.persona.fight==0,"pointer commander mode")
		await click(s,"so_tg_teiris");await capture(s,"empty",dim);check(s.controls.start_run.disabled,"zero members cannot depart")
		await click(s,"so_fight_1");await capture(s,"solo",dim);check(not s.controls.start_run.disabled,"persona solo can depart")
		await click(s,"start_run");check(s.model.active() and s.model.s.run.persona_party==["persona"],"solo departure preserves party")
		await capture(s,"explore",dim)
		if dim==Vector2i(390,844):
			s.model.s.run.phase="battle";s._draw_screen();await process_frame;await process_frame;await RenderingServer.frame_post_draw
			check(is_instance_valid(s.battle),"persona native combat opens")
			check(root.get_texture().get_image().save_png(folder+"/persona-battle-390x844.png")==OK,"persona native battle capture")
			s.battle._ally_pressed("persona");await process_frame;await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder+"/persona-status-390x844.png")==OK,"persona native status placeholder capture")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open("res://../verification/persona-r22/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("PERSONA UI R22 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
