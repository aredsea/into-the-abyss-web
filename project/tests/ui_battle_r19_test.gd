extends SceneTree
const Screen=preload("res://ui/battle_screen.gd")
const World=preload("res://game/expansion_world.gd")
var folder=ProjectSettings.globalize_path("res://../verification/ui-r19").simplify_path()
var checks=0
var failures=[]
var measurements={}
var action_counts=[]
var overflow_cases=0
func click(s,id: String) -> void:
	var b=s.find_child(id.replace(":","_"),true,false)
	check(is_instance_valid(b),"Input control "+id)
	if not is_instance_valid(b): return
	var point=b.global_position+b.size/2
	for pressed in [true,false]:
		var event=InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed; root.push_input(event)
	await process_frame; await process_frame
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures.append(message); push_error(message)
func fixture():
	var world=World.new(); world.depart(); world.travel("patrol")
	var s=Screen.new(); s.session_data=world.battle_data(); s.session_save=func(_x):return OK
	s.session_context={"floor":2}; root.add_child(s); s.motion_reduced=true
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_scene.json"))
	# Test-only fixture, isolated from every saved state and data file.
	for spec in [["hildegard",118,118,33,33],["bargut",93,93,40,40],["teiris",77,77,20,86],["berenga",63,79,72,99]]:
		var a=s.state.ally(spec[0]); a.hp=spec[1]; a.mhp=spec[2]; a.mp=spec[3]; a.mmp=spec[4]
		var original=data.allies.filter(func(x):return x.id==a.id)[0]
		a.skills=original.skills.duplicate(true)
	for e in s.state.data.enemies:
		e.hp=62 if e.id=="executor" else 47 if e.id=="apprentice" else 37
		e.mhp=163 if e.id=="executor" else e.hp
		e.gauge=18.0 if e.id=="executor" else e.gauge
	s.state.turn_count=3; s.state.current_id="hildegard"; s.state.last_ally="hildegard"
	s.state.data.queue=["hildegard","executor","teiris","orb","bargut","apprentice","berenga","lantern"]
	s.busy=false; s.history_origin=0
	s.state.inventory={"hp_s":3,"mp_s":2,"bandage":1}
	return s
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	for dim in [Vector2i(390,844),Vector2i(360,780)]:
		root.content_scale_size=dim; root.size=dim
		for mode in ["base","target","status","skills","supplies","log"]:
			var s=fixture()
			if mode=="target": s.pending_action="attack"
			if mode=="status": s.ally_open="berenga"
			if mode=="skills":
				s.skills_open=true; s.state.current_id="teiris"; s.state.last_ally="teiris"
				s.state.data.queue=["teiris","orb","bargut","apprentice","berenga","lantern","hildegard","executor"]
			if mode=="supplies":
				s.items_open=true; s.pending_action="item:hp_s"; s.state.selected_ally="berenga"; s.supply_target_set=true
			if mode=="log":
				s.log_open=true; s.log_title="예시 전투 기록"
				s.display_history=[{"turn":1,"actor":"hildegard","name":"힐데가르트","action":"일반 공격"},{"turn":1,"actor":"executor","name":"집행 인형","action":"과열"},{"turn":2,"actor":"teiris","name":"테이리스","action":"마력 폭발 준비"}]
			s._rebuild(); await process_frame; await process_frame; await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder+"/"+mode+"-"+str(dim.x)+".png")==OK,"Capture "+mode+str(dim.x))
			var boxes={}; var labels=[]
			for node in s.find_children("*","Control",true,false):
				if node.has_meta("r19_box"):
					var r=node.get_global_rect(); boxes[node.get_meta("r19_box")]=[r.position.x,r.position.y,r.size.x,r.size.y]
				if node is Label and not node.text.is_empty():
					var r=node.get_global_rect(); var face=node.get_theme_font("font"); var fs=node.get_theme_font_size("font_size")
					labels.append({"text":node.text,"rect":[r.position.x,r.position.y,r.size.x,r.size.y],"font":fs,"width":face.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x,"align":node.horizontal_alignment,"baseline":r.position.y+(r.size.y-face.get_height(fs))/2+face.get_ascent(fs)})
			measurements[mode+"-"+str(dim.x)]={"boxes":boxes,"labels":labels}
			for m in s.text_metrics: check(m.needed<=m.available+1 and m.missing_glyphs.is_empty(),"Text fits "+mode+str(dim.x)+m.text)
			check(not s.controls.has("skills"),"No extra skill button")
			if mode=="skills": check(not s.controls.has("close"),"Skills has no close")
			if mode=="base":
				var before=s.state.snapshot(); s.state.ally("hildegard").mp=0; s._action_pressed("duty")
				check(s.skills_open and not s.busy,"Unavailable card opens sheet without acting")
				s._close_sheets(); s.state.restore(before)
			root.remove_child(s); s.queue_free(); await process_frame
	# Count real actions for every companion, rather than assuming four.
	var w=World.new()
	for p in w.config.companions:
		var roster=World.new()
		if p.id not in roster.s.party: roster.s.party[0 if p.row=="전열" else 2]=p.id
		roster.depart(); roster.travel("patrol")
		var model=Screen.ModernBattle.new(roster.battle_data()); model.current_id=p.id
		var ids=model.actions().keys().filter(func(id):return not id.begins_with("item:"))
		action_counts.append({"id":p.id,"name":p.name,"count":ids.size(),"actions":ids})
		check(ids.size()<=6,"Roster action count recorded "+p.id)
		if ids.size()>4:
			var screen=Screen.new(); screen.session_data=roster.battle_data(); screen.session_save=func(_x):return OK
			root.add_child(screen); screen.state.current_id=p.id; screen.state.last_ally=p.id; screen.busy=false; screen.motion_reduced=true; screen._rebuild()
			var before=JSON.stringify(screen.state.snapshot())
			await click(screen,"action:"+ids[3]); overflow_cases+=1
			check(screen.skills_open,"Fourth grid cell opens overflow "+p.id)
			for id in ids:
				if id!="attack": check(screen.controls.has("skill:"+id),"Overflow retains action "+p.id+id)
			check(JSON.stringify(screen.state.snapshot())==before,"Opening overflow never acts")
			root.remove_child(screen); screen.queue_free(); await process_frame
	# New journal entries carry structure; no journal is written to saves.
	var journal_screen=fixture(); journal_screen.pending_action="attack"; journal_screen._commit()
	check(journal_screen.display_history.size()==1,"One journal entry per committed action")
	check(journal_screen.display_history[0].actor=="hildegard" and journal_screen.display_history[0].action=="일반 공격","Journal keeps actor and action")
	check(not journal_screen.state.snapshot().has("display_history"),"Journal does not change save schema")
	journal_screen.playback_generation+=1; journal_screen.motion.skip(); await process_frame
	journal_screen.playback_generation+=1; root.remove_child(journal_screen); journal_screen.queue_free(); await process_frame; await process_frame
	var restore_world=World.new(); restore_world.depart(); restore_world.travel("patrol")
	var saved=Screen.ModernBattle.new(restore_world.battle_data()); saved._event("이어하기 전투의 문장 기록")
	var restored=Screen.new(); restored.session_data=restore_world.battle_data(); restored.session_snapshot=saved.snapshot(); restored.session_save=func(_x):return OK
	root.add_child(restored); restored.motion_reduced=true; restored.log_open=true; restored._rebuild()
	check(restored.legacy_history==saved.history,"Restored legacy prose is retained")
	check(restored.find_children("*","Label",true,false).any(func(n):return n.text.contains("이어하기 전투의 문장 기록")),"Restored prose is displayed")
	root.remove_child(restored); restored.queue_free(); await process_frame
	var f=FileAccess.open(folder+"/r19-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"measurements":measurements,"action_counts":action_counts,"overflow_input_cases":overflow_cases},"  ")); f.close()
	print("R19: ",checks," checks / ",failures.size()," failures")
	await create_timer(.5).timeout # Drain the journal-input case's real WAV playback.
	quit(0 if failures.is_empty() else 1)
