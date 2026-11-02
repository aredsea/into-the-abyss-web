extends "res://tests/ui_persona_town_round8_test.gd"
const M=preload("res://game/chronicle_world_r22.gd")
const Portrait=preload("res://ui/town_portrait_r21.gd")
func fresh():
	var w=M.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	return w
func portrait_counts(node: Node,out: Dictionary):
	if node is Portrait:out[node.character_id]=out.get(node.character_id,0)+1
	for c in node.get_children():portrait_counts(c,out)
func preparation(s):
	var counts={};portrait_counts(s.town_view,counts)
	for id in counts:check(counts[id]==1,"one portrait per companion: "+id)
	for id in s.model.s.party:check(counts.get(id)==1,"selected companion visible once "+id)
	for i in range(3):check(s.town_view.boxes.has("route_picture:"+str(i)),"illustrated source route "+str(i))
	var underline=s.town_view.boxes.nav_active.get_global_rect()
	for l in s.town_view.find_children("*","Label",true,false):
		if l.text=="원정":check(l.get_global_rect().end.y<underline.position.y,"active underline below expedition glyphs")
func run():
	folder="res://../verification/town-r21/round9/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	create_timer(180).timeout.connect(func():push_error("round9 UI watchdog");quit(98))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932),Vector2i(390,664),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round9-ui-%dx%d.json"%[dim.x,dim.y];root.add_child(s);s.model=fresh();s.motion_reduced=true;s.screen="town";s._draw_screen()
		await capture(s,"town",dim)
		await click(s,"panels");check(s.screen=="codex" and s.panels_return=="town","home P7 entry")
		await click(s,"p7_tab_status");await capture(s,"status",dim)
		await click(s,"p7_back");check(s.screen=="town","P7 closes to town")
		await click(s,"nav:party");await click(s,"roster_all");check(s.screen=="codex" and s.panels_return=="party","roster P7 entry")
		await click(s,"p7_select_teiris");await click(s,"p7_fav");check(s.model.s.favs==["teiris"],"favorite saved with persona")
		await capture(s,"codex-detail",dim);await click(s,"p7_back");check(s.screen=="party","detail closes to roster")
		await click(s,"nav:bag");await click(s,"bag_tab:equipment");check(s.screen=="inventory","bag P7 entry")
		await capture(s,"inventory",dim);await click(s,"p7_tab_status");await click(s,"nav:journal")
		check(s.screen=="journal" and s.journal_return=="status","P7 to P10 navigation")
		await click(s,"p10_back");check(s.screen=="status","journal closes to status")
		await click(s,"p7_back");check(s.screen=="bag","nested back does not form a loop")
		await click(s,"nav:town");await click(s,"town_places");await click(s,"p10_place_archive");await click(s,"p10_resident_isolde")
		await capture(s,"resident",dim);await click(s,"p10_tab_journal");await capture(s,"chronicle",dim);await click(s,"p10_back");check(s.screen=="town","P10 tabs retain original return")
		await click(s,"nav:depart");await capture(s,"participate",dim);preparation(s)
		s.model.s.owned=["hildegard","bargut","teiris","berenga"];s.model.set_fight(0);s.model.s.party=s.model.s.owned.duplicate();s._draw_screen()
		await capture(s,"command-four",dim);preparation(s)
		await click(s,"so_fight_1");await capture(s,"participate-four",dim);preparation(s)
		# Four front-row members require sideways scrolling only within that row.
		s.model.s.owned=s.model.config.companions.map(func(c):return c.id);s.model.set_fight(0)
		s.model.s.party=s.model.s.owned.filter(func(id):return s.model.person(id).row=="전열").slice(0,4);s._draw_screen()
		await capture(s,"all-front",dim);preparation(s)
		var last=s.model.s.party[-1];await click(s,"so_tg_"+last);check(last not in s.model.s.party,"hidden front portrait scrolls into reach and removes")
		s.model.s.party=[];s._draw_screen();await capture(s,"empty",dim);check(s.controls.start_run.disabled,"empty command blocks departure")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open("res://../verification/town-r21/round9/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("TOWN UI ROUND9 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
