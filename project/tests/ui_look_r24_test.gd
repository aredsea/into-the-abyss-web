extends "res://tests/ui_panels_r22_test.gd"
## Read-only visual inventory plus pointer-driven creation smoke; isolated saves.
const W24=preload("res://game/settings_world_r22.gd")
const Create24=preload("res://ui/create_screen.gd")
var phase="after"
var inventory=[]
func ready_world():
	var w=W24.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	w.s.dialogue_r21.queue=[];return w
func shot(s,tag,dim):
	# The legacy detail shell alone has a 0.18s content fade. Capture its
	# settled ink, rather than mistaking an intermediate alpha for text color.
	if not is_instance_valid(s.town_view) and not s.motion_reduced:await create_timer(.22).timeout
	await settle();await settle();await RenderingServer.frame_post_draw
	var suffix="-reduced" if s.motion_reduced and phase=="after" else ""
	var name=tag+"-%dx%d"%[dim.x,dim.y]+suffix+".png"
	check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name)
	captures.append(name);inventory.append({"screen":tag,"file":name,"size":[dim.x,dim.y],"reduced":s.motion_reduced})
	if is_instance_valid(s.town_view) and s.town_view is Create24:
		var view=s.town_view
		check(view.body.size.x<=view.scroll.size.x+1,"form horizontal bounds "+name)
		for label in view.find_children("*","Label",true,false):
			var need=label.get_theme_font("font").get_multiline_string_size(label.text,label.horizontal_alignment,label.size.x,label.get_theme_font_size("font_size"))
			check(need.x<=label.size.x+1 and need.y<=label.size.y+2,"form glyph bounds "+tag+":"+label.text)
		for id in s.controls:
			var b=s.controls[id]
			if not b is Button:continue
			var rect=b.get_global_rect()
			check(rect.position.x>=-.5 and rect.end.x<=dim.x+.5,"form control viewport bounds "+name+":"+id)
			if b.get_parent()==view.footer:check(rect.end.x<=view.frame.get_global_rect().end.x-17,"footer inset "+name+":"+id)
			var style=b.get_theme_stylebox("normal");var inset=style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT)
			var need=b.get_theme_font("font").get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_CENTER,b.size.x-inset if b.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,b.get_theme_font_size("font_size"))
			check(need.x+inset<=b.size.x+1 and need.y<=b.size.y and b.size.y>=44,"form button bounds "+name+":"+id)
func tap(s,id):
	check(s.controls.has(id),"control "+id)
	if not s.controls.has(id):return
	var b=s.controls[id]
	# r24: the same control may now live below the first viewport.
	if b is Control:
		var viewport=b.get_parent()
		while viewport!=null and not viewport is ScrollContainer:viewport=viewport.get_parent()
		if viewport is ScrollContainer:
			viewport.ensure_control_visible(b);await process_frame;await process_frame
	var ancestor=b.get_parent()
	while ancestor and not ancestor is ScrollContainer:ancestor=ancestor.get_parent()
	if ancestor is ScrollContainer:ancestor.ensure_control_visible(b);await settle()
	check(not b.disabled,"enabled "+id)
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=b.get_global_rect().get_center();root.push_input(e)
	await settle()
func show(s,page,tag,dim):
	s.screen=page;s._draw_screen();await shot(s,tag,dim)
func run():
	for arg in OS.get_cmdline_user_args():
		if arg in ["before","after"]:phase=arg
	folder="res://../verification/look-r24/"+phase;DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var sizes=[Vector2i(390,844),Vector2i(1280,800)] if phase=="before" else [Vector2i(360,780),Vector2i(390,664),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800),Vector2i(360,780)]
	for index in sizes.size():
		var dim=sizes[index];root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://look-r24-%s-%d-%d.json"%[phase,OS.get_process_id(),index];root.add_child(s);s.model=W24.new();s.motion_reduced=phase=="after" and index==sizes.size()-1;s._draw_screen()
		# Cloud prefs use a separate file from the world save; make the visual
		# fixture independent of earlier local integration-test credentials.
		s.cloud.account={"code":"","pin":"","rev":0,"auto":false,"synced":false};s.cloud.rank={};s.cloud.notice="클라우드에 연결하면 다른 기기에서도 이어할 수 있습니다."
		await shot(s,"create-race",dim);await tap(s,"cr_race_beast");await tap(s,"cr_lin_cat");await shot(s,"create-lineage",dim)
		await tap(s,"cr_next");await shot(s,"create-nation",dim);await tap(s,"cr_nat_naerin");await shot(s,"create-blocked",dim)
		await tap(s,"cr_nat_border");await tap(s,"cr_next");await shot(s,"create-class",dim);await tap(s,"cr_cls_archer");await tap(s,"cr_next");await tap(s,"cr_tot_free");await tap(s,"cr_tot_p5");await tap(s,"cr_auto");await shot(s,"create-points",dim)
		check(s.model.persona_rules.left(s.model.s.persona)==0,"pointer allocation unchanged")
		await tap(s,"cr_next");await shot(s,"create-confirm",dim);await tap(s,"cr_done");await shot(s,"meeting-empty",dim);await tap(s,"sc_pick_teiris");await shot(s,"meeting",dim)
		s.town_view.scroll.scroll_vertical=10000;await shot(s,"meeting-end",dim);await tap(s,"sc_go");check(s.model.s.owned==["teiris"],"meeting creates original companion")
		var resumed=W24.new();check(s.storage.read_into(resumed),"creation save round trip")
		for key in ["race","lineage","nation","cls"]:check(resumed.s.persona[key]==s.model.s.persona[key],"persona preserved by save "+key)
		for key in s.model.s.persona.bonus:check(int(resumed.s.persona.bonus[key])==int(s.model.s.persona.bonus[key]),"persona bonus preserved "+key)
		if phase=="before":
			s.model=ready_world()
			for page in ["town","party","member","skills","settings","codex","status","inventory","places","people","journal","guild","recruit","research","shop","inn","smithy","equipment","bag","depart","formation","cards","cloud","rank"]:
				if page in ["member","skills"]:s.who="teiris"
				await show(s,page,page,dim)
			s.journal_r22.place="archive";await show(s,"places","place-archive",dim)
			s.journal_r22.person="isolde";await show(s,"people","person-isolde",dim)
			s.reset_r22=true;await show(s,"settings","settings-reset",dim);s.reset_r22=false
			s.cloud.account={"code":"ABCD-EFGH-JKMP","pin":"23456789AB","rev":1,"auto":false,"synced":true};s.cloud.first_credentials=true;await show(s,"cloud","cloud-credentials",dim)
			s.cloud.first_credentials=false;s.cloud.conflict={"rev":2,"summary":{"day":2,"level":2,"best":1,"gold":275,"companions":1}};await show(s,"cloud","cloud-conflict",dim)
			s.cloud.conflict={};s.cloud.rank={"n":3,"pct":34,"best":1,"top":2,"at":1793577600};await show(s,"rank","rank-record",dim)
			s.cloud_confirmation={"prompt":"서버 기록을 불러올까요? 이 기기 기록은 백업에 남습니다.","callback":func():pass};await show(s,"cloud","cloud-confirm",dim);s.cloud_confirmation={}
			s.model=ready_world();s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[]
			await show(s,"explore","explore",dim);await show(s,"expedition_log","expedition-log",dim)
			s.model.s.run.phase="rest";await show(s,"explore","explore-rest",dim)
			s.model.s.run.phase="battle";s.screen="explore";s._draw_screen();await shot(s,"battle",dim)
			s.model=ready_world();s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[];s.model.expedition_retreat("retreat");s.model.expedition_retreat("retreat_yes");s.model.s.dialogue_r21.queue=[];await show(s,"summary","summary",dim)
		else:
			# Non-creation surfaces changed this round are included in every size.
			s.model=ready_world();await show(s,"cloud","cloud",dim);await show(s,"rank","rank",dim)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/look-r24/"+phase+"-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"inventory":inventory},"\t"))
	print("LOOK R24 ",phase," CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
