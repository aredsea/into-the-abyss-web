extends "res://tests/ui_reskin_r24_test.gd"
## Second-pass visual contracts. Gameplay assertions remain in the source suites.
var readability=[]
func _initialize():
	create_timer(600).timeout.connect(func():push_error("round2 watchdog");quit(98));call_deferred("run")
func scan(s,tag,dim):
	super(s,tag,dim)
	if dim.x==390:
		for n in s.find_children("*","Label",true,false):
			if not n.is_visible_in_tree() or n.text=="" or n.get_theme_color("font_color").a==0:continue
			if n.get_parent().has_meta("resource_values"):continue
			if n.get_theme_font_size("font_size")<12:readability.append({"screen":tag,"text":n.text,"size":n.get_theme_font_size("font_size"),"path":str(n.get_path())})
func run():
	folder="res://../verification/reskin-r24/render"
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round2-ui-%d.json"%OS.get_process_id();root.add_child(s);s.motion_reduced=true;s.model=party_world()
		for page in ["town","member","member_details","skills","guild","recruit","research","shop","inn","smithy","depart","formation","settings","cloud"]:
			s.who="teiris";await show(s,page,page,dim)
			if page in ["guild","recruit","research","shop","inn","smithy"]:
				var figures=s.town_view.find_children("*","Control",true,false).filter(func(n):return n.get_script()==preload("res://ui/portrait_slot_r24.gd") and n.character_id in ["fenella","loredana","pietro","dorothea","hanna"])
				check(figures.size()==1,"one NPC figure "+page)
				if figures.size()==1:check(figures[0].source_path.begins_with("res://assets/portraits-r24/npc/"),"NPC uses alpha master "+page)
		for cid in ["fenella","loredana","pietro","dorothea","hanna"]:
			s.journal_r22.person=cid;await show(s,"people","person-"+cid,dim)
			var copy=""
			for n in s.town_view.body.find_children("*","Label",true,false):copy+=n.text.replace(" ","").replace("\n","")
			var original=s.model.Places.profile(cid)
			for raw in original.lines:
				# The established renderer resolves {{user}} from the saved persona.
				# Compare the exact source copy after that same existing substitution.
				var text=preload("res://game/localization_r22.gd").display(str(raw),s.model.s).trim_prefix("## ").trim_prefix("- ").replace("**","").replace(" ","").replace("\n","")
				check(copy.contains(text),"biography copy unchanged "+cid+" "+text.left(12))
			s.town_view.scroll.scroll_vertical=100000;await shot(s,"person-"+cid+"-end",dim)
		s.model.s.summary={};await show(s,"summary","summary-empty",dim)
		check(s.controls.has("summary_home") and s.town_view.boxes.has("empty_summary_paper"),"empty result has a clear paper lane and next action")
		for outcome in ["victory","defeat"]:
			var w=preload("res://game/town_world_r21.gd").new();w.s.dungeon_r21.best=60;w.depart_dungeon(1 if outcome=="victory" else 27,117);w.s.run.phase="battle"
			var b=w.ModernBattle.new(w.battle_data());var turns=0
			while b.result.is_empty() and turns<1500:
				if b.player_turn() and not b.ally(b.current_id).charging:b.choose_enemy(b.living(false)[0].id);b.act("attack")
				else:b.automatic_turn()
				turns+=1
			check(b.result==outcome,"natural round2 "+outcome);w.record_battle(b.snapshot())
			s.model=w;s.screen="explore";s._draw_screen();await settle();s._process(.21);await settle()
			await shot(s,"result-"+outcome,dim)
			check(is_instance_valid(s.result_view),"result visible "+outcome)
			if is_instance_valid(s.battle):s.battle.queue_free();s.battle=null
			s.model=party_world();s._draw_screen();await settle()
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/reskin-r24/round2/diagnostics.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"inventory":inventory,"audit":audit,"small_type":readability},"\t"))
	print("ROUND2 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size()," SMALL TYPE ",readability.size());quit(0 if failures.is_empty() else 1)
