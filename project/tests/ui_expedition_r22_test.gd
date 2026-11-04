extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/expedition_world_r22.gd")
const Create=preload("res://ui/create_screen.gd")
const Town=preload("res://ui/town_screen_r21.gd")
const Supply=preload("res://game/expedition_supply_r22.gd")
var folder="res://../verification/expedition-r22/render"
var checks=0
var failures=[]
var captures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func ready_world():
	var w=World.new()
	w.create_action("race_human");w.create_action("nat_border");w.create_action("cls_warrior");w.create_action("auto");w.create_action("done");w.create_action("pick_teiris","sc");w.create_action("go","sc")
	w.s.dialogue_r21.queue=[];return w
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
	else:
		var p=b.get_parent()
		while p and not p is ScrollContainer:p=p.get_parent()
		if p is ScrollContainer:p.ensure_control_visible(b);await process_frame;await process_frame
	check(not b.disabled,"enabled "+id)
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=b.get_global_rect().get_center();root.push_input(e)
	await process_frame;await process_frame
func show(s,page):
	s.model.s.dialogue_r21.queue=[];s.message="";s.screen=page;s._draw_screen()
	await process_frame;await process_frame
func capture(s,tag,dim):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y]
	check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name)
	if s.town_view is Town:
		for row in s.town_view.metrics:
			check(row.needed<=row.available+1,"text fits "+name+row.text)
	for id in s.controls:
		var b=s.controls[id]
		if b is Button and b.text!="":
			var style=b.get_theme_stylebox("normal");var inset=Vector2(style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT),style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM))
			var room=b.size-inset;var needed=b.get_theme_font("font").get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,room.x if b.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,b.get_theme_font_size("font_size"))
			check(needed.x<=room.x+1 and needed.y<=room.y+1,"button fits "+name+id)
func force_clear(w):
	w.s.run.phase="battle";w.s.run.final=true;w.s.run.kind="boss"
	var b=w.ModernBattle.new(w.battle_data())
	for e in b.data.enemies:e.hp=0;e.gauge=0
	b.result="victory";w.record_battle(b.snapshot());w.finish_battle();w.s.dialogue_r21.queue=[]
func battle_click(b,id):
	check(b.controls.has(id),"battle control "+id)
	if not b.controls.has(id):return
	var r=b.controls[id].rect;var p=Vector2(r[0]+r[2]/2,r[1]+r[3]/2)
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=p;root.push_input(e)
	await process_frame;await process_frame
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://p5-ui-%dx%d-%d.json"%[dim.x,dim.y,OS.get_process_id()];root.add_child(s);s.model=ready_world();s.motion_reduced=true
		s.model.s.dungeon_r21.best=27;s.model.selected_floor=28;s.model.s.persona.fight=0;s.model.s.party=["teiris"]
		s.model.set_sortie_mode(1) # This fixture checks dungeon floor 28, not the fresh quest default.
		await show(s,"depart")
		check(not s.controls.start_run.disabled and s.controls.start_run.tooltip_text.contains("위험합니다") and s.controls.start_run.tooltip_text.contains("전열"),"source soft warnings explain risk without blocking departure")
		check(s.controls.dungeon_floor.selected==-1 or s.controls.dungeon_floor.get_selected_id()==28,"paged picker never displays a different floor as the active selection")
		await capture(s,"source-warning",dim)
		s.model=ready_world()
		s.model.s.dungeon_r21.best=8
		s.model.set_sortie_mode(1)
		await show(s,"depart");await capture(s,"floors",dim)
		await click(s,"floor_next");await capture(s,"floor-page",dim);await click(s,"dungeon_floor")
		# Native PopupMenu is a separate OS window; the root viewport injector does
		# not route keys there. Exercise its public selection signal like the P6 picker.
		var floor_pick=s.controls.dungeon_floor;floor_pick.get_popup().hide();floor_pick.select(0);floor_pick.item_selected.emit(0)
		await process_frame;await process_frame
		check(s.model.selected_floor==7,"native selector maps paged source floor id")
		s.model.select_dungeon_floor(1);s.model.depart_dungeon(1,1)
		await show(s,"explore");await capture(s,"entry",dim)
		s.model.s.run.loot_items.hp_s=2;s.model.s.run.loot_items.sh_s=1;s.model.s.run.gold=51;s.model.s.run.log=["탐색 1: 낡은 주머니에서 주화 51닢을 찾았다.","탐색 2: 회복약 (소) 둘을 주웠다."]
		s.model.s.run.last=s.model.s.run.log[-1]
		await show(s,"explore");await capture(s,"discovery",dim);await click(s,"expedition_log");await capture(s,"log",dim)
		await click(s,"log_back");await click(s,"dungeon_bag");await capture(s,"supplies",dim);await click(s,"item:hp_s");await capture(s,"targets",dim)
		s.model.s.members.persona.hp=1;s._draw_screen();await click(s,"target:persona");await click(s,"use_selected");check(s.model.supplies("hp_s")==1 and s.model.s.items.hp_s==0,"pointer pouch first persona potion")
		s.model.s.run.step=5;s.model.enter_dungeon_rest()
		var it=s.model.gear.catalog.items.filter(func(e):return e.cls=="warrior" and e.rarity=="common")[0];s.model.add_gear(it.id);var uid=s.model.s.serial
		await show(s,"explore");await capture(s,"rest",dim);await click(s,"rest_equipment");await capture(s,"equipment",dim);await click(s,"equip:"+str(uid));check(s.model.s.equipment.persona.has(it.slot),"pointer rest equipment")
		await click(s,"equipment_back");await click(s,"retreat");await capture(s,"retreat-confirm",dim)
		s.confirm={};s.model.s.run.gold=151;s.model.s.run.xp=120;force_clear(s.model)
		await show(s,"summary");await capture(s,"settlement",dim);await click(s,"summary_next");check(s.model.s.run.floor==2 and s.model.active(),"pointer continuous descent")
		await show(s,"explore");await capture(s,"next-floor",dim)
		s.model.s.run.phase="battle";s.model.s.run.loot_items.hp_s=2
		await show(s,"explore");check(s.battle.state is Supply,"P5 native supply adapter connected")
		s.battle.motion_reduced=true
		# Source CTB may open with enemies; select supplies on a real ready ally turn.
		while s.battle.busy or not s.battle.state.player_turn():await process_frame
		s.battle.state.ally("persona").hp=1
		s.battle._toggle_supplies();await process_frame;await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(folder+"/combat-supplies-%dx%d.png"%[dim.x,dim.y])==OK,"native supply sheet capture");captures.append("combat-supplies-%dx%d.png"%[dim.x,dim.y])
		await battle_click(s.battle,"item:hp_s");await battle_click(s.battle,"ally:persona")
		check(s.battle._supply_reason().is_empty(),"native persona supply target selected")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open("res://../verification/expedition-r22/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("EXPEDITION UI R22 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
