extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const W=preload("res://game/settings_world_r22.gd")
const Settings=preload("res://ui/settings_screen_r22.gd")
const L=preload("res://game/localization_r22.gd")
var folder="res://../verification/settings-r22/render"
var checks=0
var failures=[]
var captures=[]
var untranslated={}
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():create_timer(180).timeout.connect(func():quit(98));call_deferred("run")
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
	var view=s.town_view
	if view.get("body")!=null and view.body.is_ancestor_of(b):view.scroll.ensure_control_visible(b);await settle()
	var point=b.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=point;root.push_input(e)
	await settle()
func bounds(s,tag):
	var view=s.town_view
	if view.get("body")==null:return
	check(view.body.size.x<=view.scroll.size.x+1,"body width "+tag)
	var korean=RegEx.new();korean.compile("[가-힣]")
	for label in view.find_children("*","Label",true,false):
		var need=label.get_theme_font("font").get_multiline_string_size(label.text,label.horizontal_alignment,label.size.x,label.get_theme_font_size("font_size"))
		check(need.x<=label.size.x+1 and need.y<=label.size.y+2,"glyph bounds "+tag+":"+label.text.left(75))
		if L.language(s.model.s)=="en" and korean.search(label.text):untranslated[label.text]=true
		if view.body.is_ancestor_of(label):check(label.get_global_rect().end.x<=view.scroll.get_global_rect().end.x+1,"scroll right "+tag)
	for id in s.controls:
		var b=s.controls[id]
		if b is Button:
			var style=b.get_theme_stylebox("normal");var inset=style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT)
			var need=b.get_theme_font("font").get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_CENTER,b.size.x-inset if b.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,b.get_theme_font_size("font_size"))
			check(b.size.y>=44 and need.x+inset<=b.size.x+1 and need.y<=b.size.y,"touch/text bounds "+tag+":"+id+":"+b.text)
			if L.language(s.model.s)=="en" and korean.search(b.text):untranslated[b.text]=true
func capture(s,tag,dim):
	await settle();await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y];check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name);bounds(s,name)
func fixture():
	var w=W.new();w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town";w.s.owned=["naran","marceline","teiris"];w.s.party=w.s.owned.duplicate();w.s.persona.cls="전사";w.s.persona.race="인간";w.s.persona.nation="경계도시";w.s.persona.name="당신";return w
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://p8-ui-%d-%d.json"%[dim.x,dim.y];root.add_child(s);s.model=W.new();s.motion_reduced=true;s.screen="town";s._draw_screen();await settle()
		await capture(s,"create-ko",dim);await click(s,"p8_open");await capture(s,"settings-ko",dim)
		await click(s,"p8_lang_en");check(L.language(s.model.s)=="en","English immediate");await capture(s,"settings-en",dim)
		for diff in [1,3,2]:await click(s,"p8_diff_"+str(diff));check(s.model.s.settings.diff==diff,"difficulty pointer "+str(diff))
		await click(s,"p8_chron_0");check(s.model.s.settings.chron==0,"chron off");await click(s,"p8_chron_1")
		await click(s,"p8_back");check(s.controls.has("cr_race_human"),"back to create");await capture(s,"create-en",dim)
		# Scenario source prose, creation bonus page, and sortie are localized through the shared form.
		s.model.s.persona.race="인간";s.model.s.persona.nation="경계도시";s.model.s.persona.cls="전사";s.model.s.ui.page=4;s._draw_screen();await capture(s,"points-en",dim)
		s.model.s.scene="scenario";s.model.s.ui.sel="marceline";s._draw_screen();await capture(s,"scenario-en",dim)
		check(s.town_view.body.find_children("*","Label",true,false).any(func(x):return x.text.begins_with("On a spring morning")),"source scenarios_en text")
		s.model=fixture();s.model.s.settings.lang="en";s.screen="formation";s._draw_screen();await capture(s,"sortie-en",dim)
		for page in ["codex","status","inventory","places","people","journal"]:
			s.go(page);await capture(s,page+"-en",dim)
		s.go("codex");s.panels_r22.ui.sel="naran";s._draw_screen();await capture(s,"codex-detail-en",dim)
		s.journal_r22.person="isolde";s.go("people");await capture(s,"isolde-en",dim)
		check(s.town_view.body.find_children("*","Label",true,false).any(func(x):return x.text.contains("Keeper of Torva")),"source lore_en profile")
		s.go("town");await click(s,"town_settings");await capture(s,"settings-town-en",dim)
		var before=s.model.s.duplicate(true);await click(s,"p8_reset");check(s.reset_r22,"reset armed");await capture(s,"reset-en",dim)
		await click(s,"p8_reset_no");check(not s.reset_r22 and s.model.s==before,"cancel preserves world")
		s.save_error=ERR_CANT_CREATE;s._draw_screen();await capture(s,"save-error-en",dim);await click(s,"save_retry");check(s.save_error==OK,"save retry")
		await click(s,"p8_lang_ko");await click(s,"p8_reset");await capture(s,"reset-ko",dim)
		await click(s,"p8_reset_yes");check(not s.model.s.creation_r22.complete and s.model.s.gold==300,"confirmed reset to create")
		check(FileAccess.file_exists(s.storage.archive_path),"reset archive exists")
		await click(s,"p8_open");await click(s,"p8_lang_en");await click(s,"p8_back");check(L.language(s.model.s)=="en","language from fresh create")
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/settings-r22/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"untranslated_observed":untranslated.keys()},"  "))
	print("SETTINGS UI R22 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
