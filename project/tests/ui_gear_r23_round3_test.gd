extends "res://tests/ui_facilities_r22_test.gd"
func run():
	folder="res://../verification/parity-r23/render-round3";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://r23-gear-round3-%d.json"%dim.x;root.add_child(s);s.model=ready_world();s.motion_reduced=true
		s.go("smithy");s.model.smithy_select("process");s._draw_screen();await process_frame
		for rarity in s.model.gear.ORDER:
			var value=s.model.gear.band(s.model.highest_level()).w.get(rarity,0)
			check(s.town_view.metrics.any(func(m):return m.text==s.model.gear.pct(value)+"%"),"native rate uses source %g "+rarity)
		await capture(s,"smithy-process",dim)
		check(s.model.process_gear(),"processing creates an effect")
		check(s.model.smithy_source_fx.has("proc_fx"),"source processing field populated")
		s.model.smithy_select("forge");check(s.model.smithy_source_fx.is_empty(),"tab clears both effects")
		s.model.complete_smithy();s.model.acknowledge_receipt();s.go("inn");await process_frame
		for act in ["talk","meal","gift","rest"]:check(s.controls.has("inn:"+act),"ordinary source action visible "+act)
		await capture(s,"inn-actions",dim)
		s.queue_free();await process_frame
	FileAccess.open("res://../verification/parity-r23/round3-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("GEAR R23 ROUND3 UI CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
