extends "res://tests/ui_look_r24_test.gd"
## Same content fixtures before/after; real scroll bounds and pointer navigation.
var defects=[]
func _initialize():
	create_timer(360).timeout.connect(func():quit(98));call_deferred("run")
func inspect(s,tag):
	var v=s.town_view
	if v.get("scroll")!=null:
		check(v.scroll.get_global_rect().end.y<=v.frame.get_global_rect().end.y-76 if s.screen!="settings" else v.scroll.get_global_rect().end.y<=s.size.y-16,"scroll clears footer "+tag)
		check(v.body.size.x<=v.scroll.size.x+1,"body width "+tag)
	for node in v.find_children("*","Control",true,false):
		if node is Label:
			var need=node.get_theme_font("font").get_multiline_string_size(node.text,node.horizontal_alignment,node.size.x,node.get_theme_font_size("font_size"))
			check(need.x<=node.size.x+1 and need.y<=node.size.y+2,"glyph "+tag+":"+node.text)
		if node is Button:
			var rect=node.get_global_rect()
			check(rect.position.x>=-.5 and rect.end.x<=s.size.x+.5,"button width "+tag+":"+node.text)
			if str(node.get_meta("town_r21_box","")).begins_with("dialogue_"):
				check(rect.size.y>=44,"dialogue physical touch height "+tag+":"+node.text)
	var sc=v.get("scroll")
	if sc==null:
		var found=v.find_children("*","ScrollContainer",true,false)
		if not found.is_empty():sc=found[-1]
	if sc!=null:
		sc.scroll_vertical=100000;await settle()
		check(sc.get_child(0).get_global_rect().end.y<=sc.get_global_rect().end.y+1,"last row reachable "+tag)
		for id in s.controls:
			var b=s.controls[id]
			if not b is Button or not sc.is_ancestor_of(b):continue
			sc.ensure_control_visible(b);await settle()
			check(sc.get_global_rect().encloses(b.get_global_rect()),"whole action reachable "+tag+":"+id)
		sc.scroll_vertical=100000;await settle()
func snap(s,page,tag,dim):
	await show(s,page,tag,dim)
	if phase=="after":await inspect(s,tag)
	var sc=s.town_view.get("scroll")
	if sc==null:
		var found=s.town_view.find_children("*","ScrollContainer",true,false)
		if not found.is_empty():sc=found[-1]
	if sc!=null:
		sc.scroll_vertical=100000;await shot(s,tag+"-end",dim)
func run():
	for a in OS.get_cmdline_user_args():
		if a in ["before","after"]:phase=a
	folder="res://../verification/look-r24/round4/"+phase;DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var sizes=[Vector2i(390,844),Vector2i(1280,800)] if phase=="before" else [Vector2i(360,780),Vector2i(390,664),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800),Vector2i(360,780)]
	for i in sizes.size():
		var dim=sizes[i];root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://look-round4-%d-%d.json"%[OS.get_process_id(),i];root.add_child(s);s.model=ready_world();s.motion_reduced=phase=="after" and i==sizes.size()-1
		s.model.s.owned=["hildegard","bargut","teiris","marceline"];s.model.s.party=s.model.s.owned.duplicate();s.who="teiris"
		for item in s.model.gear.catalog.items.slice(0,25):s.model.s.gear.append({"id":item.id,"seed":1235,"uid":s.model.s.gear.size()+1,"forge":0,"tries":0,"source_r21":true})
		s.model.s.serial=s.model.s.gear.size()
		for page in ["codex","status","inventory","journal","places","people","settings","facility_scroll"]:await snap(s,page,page,dim)
		s.panels_r22.ui.sel="teiris";await snap(s,"codex","codex-detail",dim);s.panels_r22.ui.sel=""
		s.panels_r22.bg_action("sel_1");await snap(s,"inventory","inventory-detail",dim);s.panels_r22.bg_action("back")
		s.journal_r22.place="archive";await snap(s,"places","place-archive",dim)
		s.journal_r22.person="isolde";await snap(s,"people","person-isolde",dim)
		s.reset_r22=true;await snap(s,"settings","settings-reset",dim);s.reset_r22=false
		s.model.s.members.teiris.aff=25;s.screen="inn";s._draw_screen();await settle();await tap(s,"inn:talk");await shot(s,"dialogue",dim)
		if phase=="after":await inspect(s,"dialogue")
		var found=s.town_view.find_children("*","ScrollContainer",true,false)
		if not found.is_empty():found[-1].scroll_vertical=100000;await shot(s,"dialogue-end",dim)
		var choice=""
		for id in s.controls:
			if id.begins_with("dialogue_choice:"):choice=id;break
		if choice!="":
			await tap(s,choice);await shot(s,"dialogue-response",dim)
			if phase=="after":await inspect(s,"dialogue-response")
			found=s.town_view.find_children("*","ScrollContainer",true,false)
			if not found.is_empty():found[-1].scroll_vertical=100000;await shot(s,"dialogue-response-end",dim)
		s.model=ready_world();s.model.depart_dungeon(1,117);s.model.s.dialogue_r21.queue=[]
		await snap(s,"expedition_log","expedition-log",dim)
		if phase=="after":
			# Reuse the existing expedition UI fixture's text, with enough entries to
			# force scrolling; this changes only this isolated test world.
			s.model.s.run.log=[]
			for n in range(8):s.model.s.run.log.append_array(["탐색 1: 낡은 주머니에서 주화 51닢을 찾았다.","탐색 2: 회복약 (소) 둘을 주웠다."])
			s.model.s.run.gold=51;s.model.s.run.loot_items.hp_s=2
			await snap(s,"expedition_log","expedition-log-long",dim)
			s.model=ready_world();s.model.s.items.level_scroll=2
			await snap(s,"facility_scroll","facility-scroll-enabled",dim)
			await tap(s,"scroll_target:persona");check(s.model.s.persona.lv==2 and s.model.s.items.level_scroll==1,"scroll row pointer keeps source result")
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/look-r24/round4/"+phase+"-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"inventory":inventory},"\t"))
	print("LOOK ROUND4 ",phase," CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
