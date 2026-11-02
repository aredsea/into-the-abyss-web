extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const W=preload("res://game/settings_world_r22.gd")
const L=preload("res://game/localization_r22.gd")
var checks=0
var failures=[]
var captures=[]
var observed={}
var folder="res://../verification/town-r21/round11/render"
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():create_timer(180).timeout.connect(func():quit(98));call_deferred("run")
func settle():await process_frame;await process_frame
func click(s,id):
	check(s.controls.has(id),"control exists "+id)
	if s.controls.has(id):s.controls[id].pressed.emit();await settle()
func capture(s,tag,dim):
	await settle();await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y]
	check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name)
	var view=s.town_view
	if tag=="codex-en":
		for id in ["all","rec","el","cls"]:
			var b=s.controls["p7_filter_"+id]
			check(b.autowrap_mode==TextServer.AUTOWRAP_OFF,"codex filters never wrap")
	if tag in ["status-en","member-en","status-ko","member-ko"]:
		for n in view.find_children("*","Label",true,false):
			var decimal=RegEx.new();decimal.compile("^[0-9]+[.][0-9]+$")
			check(decimal.search(n.text)==null,"source-rounded stat: "+n.text)
	if tag in ["shop-en","smithy-en","recruit-en"]:
		var id=tag.trim_suffix("-en");var node=view.boxes.get("title:"+id)
		check(node!=null and node.texture.resource_path.ends_with("-en.svg"),"source English SVG "+id)
	var ko=RegEx.new();ko.compile("[가-힣]")
	for node in view.find_children("*","Control",true,false):
		if not (node is Label or node is Button):continue
		if node.text=="":continue
		var inset=Vector2.ZERO
		if node is Button:
			var style=node.get_theme_stylebox("normal");inset=Vector2(style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT),style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM))
		var room=node.size-inset
		var need=node.get_theme_font("font").get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,room.x if node.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,node.get_theme_font_size("font_size"))
		check(need.x<=room.x+1 and need.y<=room.y+2,"glyph bounds "+name+":"+node.text.left(70)+" need "+str(need)+" room "+str(room))
		if L.language(s.model.s)=="en" and ko.search(node.text):observed[node.text]=true
	if view.get("body")!=null and view.get("scroll")!=null:check(view.body.size.x<=view.scroll.size.x+1,"fluid body fits "+tag)
func fresh():
	var w=W.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	for id in ["hildegard","berenga","bargut"]:
		w.s.owned.append(id)
	w.s.party=["hildegard","berenga","bargut"];return w
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round11-ui-%d-%d.json"%[dim.x,dim.y];root.add_child(s);s.motion_reduced=true
		s.model=W.new();s.screen="town";s._draw_screen();await click(s,"p8_open");await click(s,"p8_lang_en");await click(s,"p8_back")
		await capture(s,"create-en",dim)
		check(s.town_view.title is Label and s.town_view.title.text=="New adventurer","English creation title")
		s.model=fresh();s.screen="town";s.model.s.settings.lang="en";s._draw_screen()
		for page in ["town","party","member","skills","bag","depart","shop","inn","guild","recruit","equipment","smithy","research","codex","status","inventory","journal","places","people","cloud"]:
			s.who="hildegard";s.go(page);await capture(s,page+"-en",dim)
			if page=="town":check(s.controls.town_settings.text=="Settings","town settings translated")
			if page=="depart":check(s.controls.dungeon_floor.get_item_text(0).begins_with("Floor 1:"),"localized source floor template")
		s.model=fresh();s.model.s.settings.lang="en";s.go("cards");await capture(s,"cards-empty-en",dim)
		s.model.s.hand=["key","camp"];s.go("cards");await capture(s,"cards-filled-en",dim)
		s.shop_tab="gear";s.go("shop");await capture(s,"shop-gear-en",dim);s.shop_tab="items"
		check(s.model.depart_dungeon(1,117),"English expedition departs")
		s.model.dismiss_dialogue_queue();s.go("explore");await capture(s,"explore-en",dim)
		s.model.s.run.phase="rest";s.model.enter_dungeon_rest();s.model.dismiss_dialogue_queue();s.go("explore");await capture(s,"rest-en",dim)
		await click(s,"retreat");await capture(s,"retreat-en",dim);await click(s,"accept")
		s.model.dismiss_dialogue_queue();s.go("summary");await capture(s,"summary-en",dim)
		# Settings return must preserve P1 creation stage and chosen meeting.
		s.model=W.new();s.model.s.settings.lang="en";s.model.s.ui.page=2;s.screen="town";s._draw_screen();var before=s.model.s.duplicate(true)
		await click(s,"p8_open");await click(s,"p8_back");check(s.model.s==before,"create settings roundtrip state")
		s.model=fresh();s.model.s.creation_r22.complete=false;s.model.s.scene="scenario";s.model.s.ui.sel="teiris";s.model.s.settings.lang="en";s._draw_screen();await capture(s,"meeting-en",dim)
		before=s.model.s.duplicate(true);await click(s,"p8_open");await click(s,"p8_back");check(s.model.s==before,"meeting settings roundtrip state")
		# Dialogue speaker name is dynamic source data, in either language.
		for lang in ["ko","en"]:
			s.model=fresh();s.model.s.settings.lang=lang;s.who="hildegard";s.model.begin_dialogue("hildegard");s.screen="inn";s._draw_screen();await capture(s,"dialogue-"+lang,dim)
			var texts=s.town_view.find_children("*","Label",true,false).map(func(x):return x.text)
			check(("힐데가" if lang=="ko" else "Hildegard") in texts,"canonical speaker "+lang)
			if lang=="ko":
				s.model=fresh();s.who="hildegard";s.go("member");await capture(s,"member-ko",dim)
				s.go("status");await capture(s,"status-ko",dim)
		s.model=fresh();s.who="persona";s.model.s.settings.lang="en";s.go("equipment");await capture(s,"equipment-persona-en",dim)
		check(s.controls.member_choice.item_count==s.model.s.owned.size()+1 and s.town_view.boxes.has("persona_portrait"),"P6 persona equipment picker and neutral portrait")
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/town-r21/round11/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"untranslated_observed":observed.keys()},"  "))
	print("TOWN UI ROUND11 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
