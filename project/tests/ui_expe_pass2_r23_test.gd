extends "res://tests/ui_expedition_r22_test.gd"
func run():
	folder="res://../verification/parity-r23/pass2-render"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var screen=Screen.new();screen.size=dim;screen.storage.path="user://expe-pass2-ui-%dx%d-%d.json"%[dim.x,dim.y,OS.get_process_id()]
		root.add_child(screen);screen.model=ready_world();screen.motion_reduced=true
		var w=screen.model;w.s.persona.name="가온";w.depart_dungeon(1,6);w.s.run.gold=21
		await show(screen,"explore");await click(screen,"retreat")
		check(w.s.run.ask and screen.controls.has("accept"),"retreat request saves original ask")
		await click(screen,"cancel")
		check(not w.s.run.ask and w.active() and screen.confirm.is_empty(),"cancel clears saved ask")
		await click(screen,"retreat")
		var saved=JSON.parse_string(JSON.stringify(w.s));var resumed=ready_world()
		check(resumed.restore(saved),"pending retreat save accepted")
		screen.model=resumed;screen.confirm={};await show(screen,"explore")
		check(resumed.s.run.ask and screen.controls.has("accept") and screen.controls.has("cancel"),"pending retreat reconstructs controls after restore")
		await capture(screen,"retreat-resumed",dim)
		var bank=resumed.s.gold;await click(screen,"accept")
		check(not resumed.active() and resumed.s.summary.result=="retreat" and resumed.s.gold==bank+21,"resumed confirmation settles exactly once")
		var settled=JSON.stringify(resumed.s)
		check(not resumed.expedition_retreat("retreat_yes") and JSON.stringify(resumed.s)==settled,"stale repeated confirmation cannot settle")
		await show(screen,"summary");await capture(screen,"retreat-settled",dim)
		screen.queue_free();await process_frame;await process_frame
	var result={"checks":checks,"failures":failures,"captures":captures}
	FileAccess.open("res://../verification/parity-r23/expe-pass2-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("EXPE PASS2 UI CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size())
	quit(0 if failures.is_empty() else 1)
