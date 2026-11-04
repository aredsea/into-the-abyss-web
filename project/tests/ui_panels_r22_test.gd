extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/persona_world.gd")
const R=preload("res://game/panels_rules_r22.gd")
const Shell=preload("res://ui/panel_screen_r22.gd")
const State=preload("res://game/panels_state_r22.gd")
var folder="res://../verification/panels-r22/render"
var checks=0
var failures=[]
var captures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():
	create_timer(90).timeout.connect(func():push_error("UI watchdog expired");quit(98));call_deferred("run")
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
	if s.town_view is Shell and s.town_view.body.is_ancestor_of(b):s.town_view.scroll.ensure_control_visible(b);await settle()
	var point=b.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=point;root.push_input(e)
	await settle()
func capture(s,tag,dim):
	await settle();await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y];check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name)
	var view=s.town_view
	if view is Shell:
		check(view.body.size.x<=view.scroll.size.x+1,"horizontal body fits "+name)
		for l in view.find_children("*","Label",true,false):
			var font=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size");var need=font.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x,fs)
			check(need.y<=l.size.y+2,"label fits "+name+":"+l.text)
			check(need.x<=l.size.x+1,"label ink fits width "+name+":"+l.text)
			if view.body.is_ancestor_of(l):check(l.get_global_rect().end.x<=view.scroll.get_global_rect().end.x+1,"label stays in scroll width "+name+":"+l.text)
		for id in s.controls:
			var b=s.controls[id]
			if b is Button:
				check(b.size.y>=44,"touch height "+id)
				var style=b.get_theme_stylebox("normal");var inset=Vector2(style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT),style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM))
				var room=b.size-inset;var need=b.get_theme_font("font").get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_CENTER,room.x if b.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,b.get_theme_font_size("font_size"))
				check(need.x<=room.x+1 and need.y<=room.y+1,"button text fits "+name+id)
func fixture():
	var w=World.new();w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town";w.s.owned=["levia","marceline","naran","teiris","haldric"];w.s.party=["marceline","naran","teiris"];w.s.persona.cls="전사";w.s.persona.race="인간";w.s.persona.nation="경계도시";w.s.persona.name="당신";w.s.persona.lv=40;w.s.members.persona.level=40;w.s.favs=["marceline","naran","teiris"]
	for id in w.s.owned:w.s.members[id].level=40
	w.s.members.marceline.aff=100.8;w.s.members.naran.aff=-20;w.s.members.teiris.aff=150
	w.s.gear=[]
	for i in range(w.gear.catalog.items.size()):
		var item=w.gear.catalog.items[i];w.s.gear.append({"id":item.id,"seed":1235+i,"uid":i+1,"forge":0,"tries":0,"source_r21":true})
	w.s.serial=w.s.gear.size();w._clamp_members();return w
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://p7-ui-%d.json"%dim.x;root.add_child(s);s.model=fixture();s.motion_reduced=true;s.screen="town";s._draw_screen();await settle()
		await click(s,"panels");check(s.screen=="codex","home menu opens codex");await capture(s,"codex",dim)
		var unknown=R.codex_list(s.model.s.owned).filter(func(id):return id not in s.model.s.owned)[0]
		check(s.controls.p7_select_marceline.disabled==false and s.controls["p7_select_"+unknown].disabled,"owned/unmet selection locking")
		await click(s,"p7_next");await click(s,"p7_next");await capture(s,"unmet-page3",dim);await click(s,"p7_filter_rec");await capture(s,"recruited",dim)
		await click(s,"p7_select_levia");await click(s,"p7_fav");check(s.model.s.favs.size()==3 and s.panels_r22.ui.msg.contains("3명"),"favorite 3 cap through pointer");await capture(s,"favorite-cap",dim)
		await click(s,"p7_cx_back");await click(s,"p7_select_marceline");await capture(s,"detail",dim)
		s.town_view.scroll.scroll_vertical=400;await capture(s,"skills",dim)
		await click(s,"p7_fav");check("marceline" not in s.model.s.favs,"favorite remove pointer")
		await click(s,"p7_fav");check("marceline" in s.model.s.favs,"favorite add pointer")
		await click(s,"p7_cx_bag");check(s.screen=="inventory" and s.panels_r22.bg.cls=="paladin","detail bag class filter")
		await capture(s,"filtered-bag",dim)
		s.panels_r22.bg_action("f_cls_warrior");s.panels_r22.bg_action("f_rar_legend");s._draw_screen();await settle();await click(s,"p7_bg_sel_1");await capture(s,"comparison",dim)
		await click(s,"p7_bg_sell");var count=s.model.s.gear.size();check(s.panels_r22.bg.conf!="","legend confirmation pointer");await capture(s,"sale-confirm",dim);check(s.town_view.scroll.scroll_vertical>0,"confirmation stays visible")
		await click(s,"p7_bg_sell");check(s.model.s.gear.size()==count-1,"confirmed sale changes one item")
		s.panels_r22.bg_action("f_rar_common");s._draw_screen();await click(s,"p7_bg_sel_1");await click(s,"p7_bg_eq_persona");check(s.model.s.equipment.persona.has("weapon") or s.model.s.equipment.persona.has("armor") or s.model.s.equipment.persona.has("acc"),"persona equip pointer")
		s.panels_r22.bg_action("f_cls_all");s.panels_r22.bg_action("f_rar_all");s._draw_screen();await capture(s,"bag-all",dim)
		var bulk=s.panels_r22.bulk();var gold=s.model.s.gold;await click(s,"p7_bg_sellc");check(s.model.s.gold==gold+bulk.gold and s.panels_r22.bulk().count==0,"bulk sale quote and mutation pointer")
		await click(s,"p7_tab_status");await capture(s,"status",dim)
		s.town_view.scroll.scroll_vertical=10000;await capture(s,"favorites",dim)
		await click(s,"p7_open_marceline");check(s.screen=="codex" and s.panels_r22.ui.sel=="marceline","favorite opens same detail")
		s.panels_r22.ui.sel="";s.panels_r22.ui.tab="rec";var owned=s.model.s.owned;s.model.s.owned=[];s._draw_screen();await capture(s,"empty-filter",dim);s.model.s.owned=owned
		s.panels_r22.ui.sel="persona";s._draw_screen();await capture(s,"persona",dim)
		s.go("bag");await click(s,"bag_tab:equipment");check(s.screen=="inventory","legacy bag tab opens P7")
		s.go("party");await click(s,"roster_all");check(s.screen=="codex","roster menu opens P7")
		s.who="marceline";s.model.s.members.marceline.aff=99.9;s.go("inn");await capture(s,"inn-stage",dim)
		if dim==Vector2i(360,780):
			s.model.s.owned=R.DATA.order.duplicate();s.screen="codex"
			for cid in R.DATA.order:
				s.panels_r22.ui.sel=cid;s._draw_screen();await settle()
				for l in s.town_view.find_children("*","Label",true,false):
					var need=l.get_theme_font("font").get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x,l.get_theme_font_size("font_size"))
					check(need.x<=l.size.x+1 and need.y<=l.size.y+2,"30-name glyph bounds "+cid+":"+l.text)
					if s.town_view.body.is_ancestor_of(l):check(l.get_global_rect().end.x<=s.town_view.scroll.get_global_rect().end.x+1,"30-name scroll bounds "+cid+":"+l.text)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/panels-r22/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("PANELS UI R22 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
