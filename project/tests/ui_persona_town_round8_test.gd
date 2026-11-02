extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/persona_world.gd")
const Create=preload("res://ui/create_screen.gd")
const Sortie=preload("res://ui/persona_sortie_screen.gd")
var checks=0
var failures=[]
var folder="res://../verification/town-r21/round8/render"
var captures=[]
func _initialize():call_deferred("run")
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func click(s,id):
	check(s.controls.has(id),"pointer target "+id)
	if not s.controls.has(id):return
	var b=s.controls[id]
	var parent=b.get_parent()
	while parent!=s and parent!=null:
		if parent is ScrollContainer:parent.ensure_control_visible(b);await process_frame;await process_frame;break
		parent=parent.get_parent()
	for pressed in [true,false]:
		var e=InputEventMouseButton.new();e.position=b.get_global_rect().get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;root.push_input(e)
	await process_frame;await process_frame
func capture(s,name,dim):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var file="%s-%dx%d.png"%[name,dim.x,dim.y];captures.append(file)
	check(root.get_texture().get_image().save_png(folder+"/"+file)==OK,"capture "+file)
	for l in s.town_view.find_children("*","Label",true,false):
		var font=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size")
		var needed=font.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		check(needed.x<=l.size.x+1 and needed.y<=l.size.y+1,"caption fits "+file+"/"+l.text)
	var visible=[]
	for id in s.controls:
		var b=s.controls[id];var rect=b.get_global_rect();var parent=b.get_parent();var scrolled=false
		while parent!=s and parent!=null:
			if parent is ScrollContainer:scrolled=true;break
			parent=parent.get_parent()
		if b is Button:
			var needed=b.get_theme_font("font").get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_CENTER,-1,b.get_theme_font_size("font_size"))
			check(needed.x+12<=b.size.x and needed.y<=b.size.y,"button text fits "+file+"/"+id)
		if id.begins_with("so_") or id in ["start_run","dungeon_floor","accepted_quest"]:check(rect.size.y>=43.9,"44px touch "+file+"/"+id)
		if not scrolled:
			check(Rect2(Vector2.ZERO,Vector2(dim)).grow(1).encloses(rect),"button in viewport "+file+"/"+id)
			visible.append([id,rect])
	for i in range(visible.size()):
		for j in range(i+1,visible.size()):check(not visible[i][1].grow(-1).intersects(visible[j][1].grow(-1)),"button overlap "+file+"/"+visible[i][0]+"/"+visible[j][0])
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932),Vector2i(390,664),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round8-ui-%dx%d.json"%[dim.x,dim.y];root.add_child(s);s.model=World.new();s.motion_reduced=true;s._draw_screen()
		await capture(s,"create",dim)
		for id in ["cr_race_human","cr_next","cr_nat_border","cr_next","cr_cls_warrior","cr_next","cr_tot_20","cr_auto","cr_next","cr_done","sc_pick_teiris"]:await click(s,id)
		await capture(s,"meeting",dim);await click(s,"sc_go")
		await click(s,"inn");await click(s,"inn:talk");await click(s,"dialogue_choice:c1");await click(s,"dialogue_done")
		check(s.model.s.members.teiris.aff!=0,"first companion dialogue actual pointer")
		await click(s,"nav:town");await click(s,"guild");await click(s,"guild:recruit");await click(s,"recruit")
		check(s.model.s.owned.size()==2 and s.model.s.members[s.model.s.owned[-1]].level==s.model.s.persona.lv,"pointer recruit canonical persona")
		await click(s,"nav:depart");await capture(s,"participate",dim)
		check(s.town_view is Sortie and s.town_view.boxes.has("background:departure") and s.town_view.boxes.has("persona_slot"),"reference preparation with persona slot")
		await click(s,"so_fight_0");await capture(s,"command",dim);check(s.model.s.persona.fight==0,"commander pointer")
		await click(s,"so_tg_teiris");check(s.controls.start_run.disabled,"empty commander blocked")
		await click(s,"so_fight_1");check(not s.controls.start_run.disabled,"persona solo allowed")
		# Fill all four slots, then switch: the fourth companion waits.
		s.model.s.owned=["hildegard","bargut","teiris","berenga"];s.model.set_fight(0);s.model.s.party=s.model.s.owned.duplicate();s._draw_screen()
		await capture(s,"command-four",dim);await click(s,"so_fight_1");await capture(s,"participate-four",dim)
		check(s.model.s.party.size()==3 and s.model.sortie_ids().size()==4,"three companion rule")
		s.model.s.ui.tab="front";s._draw_screen();await capture(s,"front",dim)
		check(s.controls.has("so_tg_teiris") and s.controls.so_tg_teiris.text=="","selected back-row portrait stays removable while standby filter changes")
		s.model.s.ui.tab="";check(s.model.accept_quest(s.model.s.board[0].id),"accepted source quest fixture")
		s._draw_screen();await capture(s,"accepted-quest",dim)
		check(s.controls.has("accepted_quest"),"quest and selected floor are separate departures")
		await click(s,"start_run")
		check(s.model.active() and s.model.s.run.persona_party.size()==4,"reference UI starts P1 expedition")
		s.model=World.new();check(s.model.restore(preload("res://game/town_world_r21.gd").new().s),"old commander UI fixture")
		s.screen="depart";s._draw_screen();await capture(s,"legacy-command",dim)
		check(s.controls.so_fight_1.disabled and not s.controls.start_run.disabled,"old classless save remains playable as commander")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open("res://../verification/town-r21/round8/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("PERSONA TOWN UI ROUND8 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
