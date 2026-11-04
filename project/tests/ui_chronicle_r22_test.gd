extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/chronicle_world_r22.gd")
const Journal=preload("res://ui/journal_screen_r22.gd")
const P=preload("res://game/town_places_r22.gd")
const C=preload("res://game/chronicle_store_r22.gd")
var folder="res://../verification/chronicle-r22/render"
var checks=0
var failures=[]
var captures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():
	create_timer(120).timeout.connect(func():push_error("UI watchdog expired");quit(98));call_deferred("run")
func settle():await process_frame;await process_frame
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
	if s.town_view is Journal and s.town_view.body.is_ancestor_of(b):s.town_view.scroll.ensure_control_visible(b);await settle()
	var point=b.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=point;root.push_input(e)
	await settle()
func bounds(s,tag):
	var view=s.town_view
	if not view is Journal:return
	check(view.body.size.x<=view.scroll.size.x+1,"body width "+tag)
	for l in view.find_children("*","Label",true,false):
		var need=l.get_theme_font("font").get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x,l.get_theme_font_size("font_size"))
		check(need.x<=l.size.x+1 and need.y<=l.size.y+2,"glyph bounds "+tag+":"+l.text)
		if view.body.is_ancestor_of(l):check(l.get_global_rect().end.x<=view.scroll.get_global_rect().end.x+1,"scroll right "+tag)
	for id in s.controls:
		var b=s.controls[id]
		if b is Button:
			var need=b.get_theme_font("font").get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_CENTER,-1,b.get_theme_font_size("font_size"))
			check(b.size.y>=44 and need.x+16<=b.size.x and need.y<=b.size.y,"touch/text bounds "+tag+":"+id)
func capture(s,tag,dim):
	await settle();await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y];check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name);bounds(s,name)
func fixture():
	var w=World.new();w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town";w.s.owned=["naran","marceline","teiris"];w.s.party=w.s.owned.duplicate();w.s.persona.cls="전사";w.s.persona.race="인간";w.s.persona.nation="경계도시";w.s.persona.name="당신";return w
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://p10-ui-%d-%d.json"%[dim.x,dim.y];root.add_child(s);s.model=fixture();s.motion_reduced=true;s.screen="town";s._draw_screen();await settle()
		await capture(s,"town-entry",dim);await click(s,"town_places");check(s.screen=="places","town place entry");await capture(s,"places-town",dim)
		for pid in ["archive","gate","alley","lamp"]:
			await click(s,"p10_place_"+pid);var before=s.model.s.duplicate(true);await click(s,"p10_visit");check(s.model.s.place==pid,"actual place move "+pid)
			for key in ["gold","day","rng","acts","town_r21","quest","items"]:check(s.model.s[key]==before[key],"place preserves "+key)
			await capture(s,"place-"+pid,dim)
		await click(s,"p10_place_archive");await click(s,"p10_resident_isolde");check(s.screen=="people" and s.journal_r22.person=="isolde","resident opens correct profile");await capture(s,"isolde",dim)
		s.town_view.scroll.scroll_vertical=10000;await capture(s,"isolde-end",dim);await click(s,"p10_people_back");await capture(s,"people",dim)
		s.town_view.scroll.scroll_vertical=10000;await capture(s,"people-end",dim)
		await click(s,"p10_tab_journal");await capture(s,"empty",dim)
		C.add(s.model.s,"First met Naran, who joined as a companion.",1);C.affection_changed(s.model.s,"naran",19,20,2)
		C.add(s.model.s,"Cleared Great Dungeon floor 3; boss: "+C.english("기록 수호자"),3)
		C.add(s.model.s,"Leveled up: Naran Lv 1 → 3, Marceline Lv 1 → 3, Teiris Lv 1 → 3, "+"아주 긴 기록 ".repeat(15),3)
		s._draw_screen();await capture(s,"facts",dim)
		await click(s,"p10_toggle");check(s.model.s.settings.chron==0,"toggle off through pointer");var list=C.entries(s.model.s);C.add(s.model.s,"not stored");check(C.entries(s.model.s)==list,"off retains old records and skips new ones");await capture(s,"disabled",dim)
		await click(s,"p10_toggle");check(s.model.s.settings.chron==1,"toggle on")
		await click(s,"p10_legacy");await capture(s,"legacy",dim);await click(s,"p10_facts");check(C.entries(s.model.s)==list,"legacy view preserves facts")
		s.save_error=ERR_CANT_CREATE;s._draw_screen();await capture(s,"save-error",dim);await click(s,"save_retry");check(s.save_error==OK,"save retry")
		# Every fixed profile is laid out at the narrowest device, including leaders.
		if dim==Vector2i(360,780):
			for id in P.DATA.profiles:
				s.journal_r22.person=id;s.screen="people";s._draw_screen();await settle();bounds(s,"all profiles "+id)
		# Existing facility routes remain functional.
		s.go("places");await settle();await click(s,"p10_place_guild");await click(s,"p10_facility");check(s.screen=="guild","facility connection")
		s.go("journal");s.model.s.run={"phase":"explore"};s.go("places");check(s.controls.p10_visit.disabled,"active run cannot move town location")
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/chronicle-r22/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("CHRONICLE UI R22 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
