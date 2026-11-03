extends "res://tests/ui_facilities_r22_test.gd"
func run():
	folder="res://../verification/parity-r23/gear-render-round4";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://gear-visual-probe.json";root.add_child(s);s.model=ready_world();s.motion_reduced=true;s.model.s.gold=100000
		s.go("smithy");s.model.smithy_action("tab_process");s.model.smithy_action("proc");s._draw_screen();await process_frame
		var sc=s.town_view.stage.get_children().filter(func(n):return n is ScrollContainer)[0]
		var page=sc.get_child(0);var labels=page.get_children().filter(func(n):return n is Label)
		sc.ensure_control_visible(labels[-1]);await process_frame;await capture(s,"smithy-result-card",dim)
		s.model.complete_smithy();s.model.acknowledge_receipt();s.go("recruit");s.model.recruit();s._draw_screen();await process_frame
		sc=s.town_view.stage.get_children().filter(func(n):return n is ScrollContainer)[0];page=sc.get_child(0)
		var joined=s.model.s.town_r21.meet
		var full=preload("res://game/panels_rules_r22.gd").DATA.cast[joined].full
		labels=page.get_children().filter(func(n):return n is Label and n.text==full)
		if not labels.is_empty():sc.scroll_vertical=int(labels[0].position.y)-32
		await process_frame;await capture(s,"recruit-recent-card",dim)
		s.queue_free();await process_frame
	FileAccess.open("res://../verification/parity-r23/gear-round4-visual-probe-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("GEAR VISUAL PROBE CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
