extends SceneTree
const World=preload("res://game/town_world_r21.gd")
const Screen=preload("res://ui/world_screen.gd")
var checks=0
var failures=[]
var folder=ProjectSettings.globalize_path("res://../verification/town-r21/round3")
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func run():
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(390,664),Vector2i(1280,800),Vector2i(430,932)]:
		root.content_scale_size=dim;root.size=dim
		for outcome in ["victory","defeat"]:
			var w=World.new();w.s.dungeon_r21.best=60;w.depart_dungeon(1 if outcome=="victory" else 27,117);w.s.run.phase="battle"
			var b=World.ModernBattle.new(w.battle_data());var turns=0
			while b.result.is_empty() and turns<1500:
				if b.player_turn() and not b.ally(b.current_id).charging:b.choose_enemy(b.living(false)[0].id);b.act("attack")
				else:b.automatic_turn()
				turns+=1
			check(b.result==outcome,"natural result fixture "+outcome);w.record_battle(b.snapshot())
			var s=Screen.new();s.size=dim;s.storage.path="user://round3-results-fixture.json";root.add_child(s);s.model=w;s.motion_reduced=true;s._draw_screen()
			await process_frame;await process_frame;await process_frame
			s._process(.21);await process_frame
			check(is_instance_valid(s.result_view),"town result shell "+outcome)
			if not is_instance_valid(s.result_view):quit(1);return
			check(is_instance_valid(s.battle) and not s.model.s.run.battle.is_empty(),"terminal battle kept until confirmation")
			var gold=w.s.gold;var run_gold=w.s.run.gold
			for l in s.result_view.find_children("*","Label",true,false):
				var f=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size");var n=f.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
				check(n.x<=l.size.x+1 and n.y<=l.size.y+1,"result text fits "+l.text)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder+"/render/"+outcome+"-"+str(dim.x)+("x664" if dim.y==664 else "")+".png")
			check(w.s.gold==gold and w.s.run.gold==run_gold,"view alone pays no reward")
			var rect=s.controls.result_continue.get_global_rect()
			check(Rect2(Vector2.ZERO,Vector2(dim)).encloses(rect),"result continue within viewport")
			for down in [true,false]:
				var e=InputEventMouseButton.new();e.position=rect.get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e)
			await process_frame;await process_frame
			check(not is_instance_valid(s.battle),"existing battle exit used")
			check(s.screen==("explore" if outcome=="victory" else "summary"),"result routes to "+s.screen)
			var saved=w.s.duplicate(true);s._leave_battle();check(w.s==saved,"result cannot pay twice")
			root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open(folder+"/result-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"outcomes":2,"sizes":5},"  "))
	print("TOWN RESULT R21 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
