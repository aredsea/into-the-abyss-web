extends "res://tests/ui_hp_r24_round2_test.gd"
var markers=[]
func _initialize():
	folder=ProjectSettings.globalize_path("res://../verification/hp-r24/round3")
	create_timer(180).timeout.connect(func():push_error("HP round3 watchdog");quit(98));call_deferred("run")
func inspect_marker(s,tag):
	var hit=s.find_child("enemy_executor",true,false)
	var found=0
	for node in hit.get_children():
		if not node is Polygon2D:continue
		found+=1
		var bounds=Rect2(node.global_position-Vector2(5.66,5.66),Vector2(11.32,11.32))
		check(node.color==s.RED,tag+" red target marker")
		check(s.field_visual.get_global_rect().encloses(bounds),tag+" whole marker inside field")
		var nearest=INF
		for plate in s.find_children("*","Control",true,false):
			if not str(plate.get_meta("r19_box","")).begins_with("enemy-hud:"):continue
			var pr=plate.get_global_rect()
			check(not bounds.intersects(pr),tag+" marker clear of "+str(plate.get_meta("r19_box")))
			var gap=maxf(maxf(pr.position.x-bounds.end.x,bounds.position.x-pr.end.x),maxf(pr.position.y-bounds.end.y,bounds.position.y-pr.end.y))
			nearest=minf(nearest,gap)
		check(nearest>=3.99,tag+" marker has 4px plate gap")
		markers.append({"capture":tag,"bounds":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],"plate_gap":nearest})
	check(found==1,tag+" one boss marker")
func run():
	await process_frame;DirAccess.make_dir_recursive_absolute(folder)
	for dim in [Vector2i(360,780),Vector2i(390,664),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		for reduced in [false,true]:
			var s=fixture();s.motion_reduced=reduced;s.pending_action="attack"
			var before=s.state.snapshot()
			Gauge.observe(s.resource_history,"hildegard",90,false);Gauge.observe(s.resource_history,"hildegard",62,reduced)
			s._rebuild();await settle()
			var tag="target-%dx%d%s"%[dim.x,dim.y,"-reduced" if reduced else ""]
			inspect(s,tag);inspect_marker(s,tag)
			check(s.state.snapshot()==before,tag+" rendering preserves combat and rng")
			await capture(tag)
			root.remove_child(s);s.queue_free();await settle()
	# Existing four-enemy selection path, without recapturing unrelated screens.
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=fixture();s.motion_reduced=true
		var world=World.new();var plan=s.state.data.encounter_r21.duplicate(true)
		plan.enc.fl=["raging_lecturer","apprentice_doll","apprentice_doll","apprentice_doll"];plan.enc.fg=["boss","mob","mob","mob"];plan.enc.ne=4
		var data=s.state.data.duplicate(true);data.encounter_r21=plan;data.enemies=world.make_enemies(plan,data.allies)
		s.state=Screen.ModernBattle.new(data);s.state.current_id="hildegard";s.state.last_ally="hildegard";s.busy=false
		for e in s.state.data.enemies:e.hp=62;e.mhp=163;e.name="폭주한 강의 인형"
		s.state.data.enemies[0].phase=2;s.pending_action="attack";s._rebuild();await settle()
		var tag="multi-target-%dx%d"%[dim.x,dim.y];inspect(s,tag);inspect_marker(s,tag)
		s.pending_action=""
		for e in s.state.data.enemies:
			await click_enemy(s,e.id,"enemy-hud")
			await click_enemy(s,e.id,"enemy-art")
		root.remove_child(s);s.queue_free();await settle()
	var f=FileAccess.open(folder+"/results.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"boxes":boxes,"markers":markers},"  "));f.close()
	print("HP R24 ROUND3 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
