extends "res://tests/ui_hp_r24_test.gd"
var boxes=[]
func click_enemy(s,id,part):
	# Force a different selection first so a missed click cannot pass unchanged.
	var other=s.state.data.enemies.filter(func(e):return e.id!=id)[0]
	s.state.choose_enemy(other.id);s._rebuild();await settle()
	var node=s.find_children("*","Control",true,false).filter(func(n):return n.get_meta("r19_box","")==part+":"+id)[0]
	var point=node.get_global_rect().get_center()
	for pressed in [true,false]:
		var event=InputEventMouseButton.new();event.position=point;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed;root.push_input(event)
	await settle();check(s.state.selected_enemy==id,"real input selects "+part+":"+id)
func _initialize():
	folder=ProjectSettings.globalize_path("res://../verification/hp-r24/round2")
	create_timer(180).timeout.connect(func():push_error("HP round2 watchdog");quit(98));call_deferred("run")
func inspect(s,tag):
	var plates=[];var arts=[]
	var targets=[]
	for key in s.controls:
		if key.begins_with("enemy:"):
			var a=s.controls[key].rect;var r=Rect2(a[0],a[1],a[2],a[3])
			for previous in targets:check(not r.intersects(previous),tag+" enemy touch regions disjoint")
			targets.append(r)
	for node in s.find_children("*","Control",true,false):
		if node.has_meta("r19_box"):
			var key=str(node.get_meta("r19_box"))
			if key.begins_with("enemy-hud:"):plates.append(node)
			if key.begins_with("enemy-art:"):arts.append(node)
	for plate in plates:
		var pr=plate.get_global_rect();var bar: Control;var row: Control
		for node in plate.get_children():
			if node is Gauge:bar=node
			if node.has_meta("resource_values"):row=node
		check(is_instance_valid(bar) and is_instance_valid(row),tag+" plate has shared resources")
		if not is_instance_valid(bar) or not is_instance_valid(row):continue
		check(s.field_visual.get_global_rect().encloses(pr),tag+" whole plate inside battlefield")
		for l in row.get_children():
			check(l.get_global_rect().position.y>=bar.get_global_rect().end.y+1,tag+" glyph line separated from bar "+l.text)
			check(pr.encloses(l.get_global_rect()),tag+" full font line inside plate "+l.text)
		for other in plates:
			if other!=plate:check(not pr.intersects(other.get_global_rect()),tag+" plates disjoint")
		for art in arts:check(not pr.intersects(art.get_global_rect()),tag+" plate clear of enemy sprite "+str(art.get_meta("r19_box")))
		boxes.append({"capture":tag,"enemy":str(plate.get_meta("r19_box")),"plate":[pr.position.x,pr.position.y,pr.size.x,pr.size.y],"bar_bottom":bar.get_global_rect().end.y,"number_top":row.get_global_rect().position.y})
	assert_readouts(s)
func run():
	await process_frame;DirAccess.make_dir_recursive_absolute(folder)
	for dim in [Vector2i(360,780),Vector2i(390,664),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		for reduced in [false,true]:
			var s=fixture();s.motion_reduced=reduced
			var tag="%dx%d%s"%[dim.x,dim.y,"-reduced" if reduced else ""]
			for mode in ["states","target"]:
				Gauge.observe(s.resource_history,"hildegard",90,false);Gauge.observe(s.resource_history,"hildegard",62,reduced)
				s.pending_action="attack" if mode=="target" else "";s._rebuild();await settle()
				inspect(s,mode+"-"+tag);await capture(mode+"-"+tag)
			root.remove_child(s);s.queue_free();await settle()
	# Build four real source-backed slots; the lone-boss fixture has no reserves.
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=fixture();s.motion_reduced=true
		var world=World.new();var plan=s.state.data.encounter_r21.duplicate(true)
		plan.enc.fl=["raging_lecturer","apprentice_doll","apprentice_doll","apprentice_doll"];plan.enc.fg=["boss","mob","mob","mob"];plan.enc.ne=4
		var data=s.state.data.duplicate(true);data.encounter_r21=plan;data.enemies=world.make_enemies(plan,data.allies)
		s.state=Screen.ModernBattle.new(data);s.state.current_id="hildegard";s.state.last_ally="hildegard";s.busy=false
		for e in s.state.data.enemies:e.hp=62;e.mhp=163
		s.state.data.enemies[0].phase=2
		check(s.state.data.enemies.size()==4,"four actual enemy controls")
		# Reuse the long canonical boss name to exercise each small plate's ellipsis.
		for e in s.state.data.enemies:e.name="폭주한 강의 인형"
		for mode in ["multi","multi-target"]:
			s.pending_action="attack" if mode=="multi-target" else "";s._rebuild();await settle()
			var tag=mode+"-%dx%d"%[dim.x,dim.y];inspect(s,tag);await capture(tag)
			if mode=="multi-target":
				s.pending_action=""
				for e in s.state.data.enemies:
					await click_enemy(s,e.id,"enemy-hud")
					await click_enemy(s,e.id,"enemy-art")
		root.remove_child(s);s.queue_free();await settle()
	var f=FileAccess.open(folder+"/results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"boxes":boxes},"  "));f.close()
	print("HP R24 ROUND2 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
