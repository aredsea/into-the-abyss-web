extends "res://tests/ui_facilities_r22_test.gd"
func run():
	folder="res://../verification/parity-r23/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://r23-ui-%d.json"%dim.x;root.add_child(s);s.model=ready_world();s.motion_reduced=true
		s.model.s.items.charm_potion=1;s.go("shop");await process_frame
		var labels=s.town_view.metrics.filter(func(m):return m.text=="매혹의 비약")
		check(labels.size()==1,"owned no-sale bonus appears in shop")
		check(not s.controls.has("buy:charm_potion"),"no sale button for bonus")
		var found=[]
		for n in s.find_children("*","Label",true,false):
			if n.text=="매혹의 비약":found.append(n)
		if not found.is_empty():
			var parent=found[0].get_parent()
			while parent and not parent is ScrollContainer:parent=parent.get_parent()
			if parent is ScrollContainer:parent.scroll_vertical=1000000
		await capture(s,"shop-bonus",dim)
		s.model.s.items.erase("charm_potion");s._draw_screen();await process_frame
		check(not s.town_view.metrics.any(func(m):return m.text=="매혹의 비약"),"unowned no-sale item hidden")
		s.model.s.members[s.model.s.owned[0]].aff=-60;s.who=s.model.s.owned[0];s.go("inn");await process_frame
		check(s.town_view.metrics.any(func(m):return m.text.begins_with("낯섦 · 호감 -60")),"source gd_tier is used by ordinary inn")
		s.model.s.members[s.who].aff=99.95;s._draw_screen();await process_frame
		check(s.town_view.metrics.any(func(m):return m.text.begins_with("깊은 인연 · 호감 99 /")),"ordinary inn floors the displayed current affection")
		s.queue_free();await process_frame
	FileAccess.open("res://../verification/parity-r23/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("GEAR R23 UI CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
