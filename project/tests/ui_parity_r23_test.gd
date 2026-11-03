extends "res://tests/ui_panels_r22_test.gd"
## Source CX_CAND=4 previews; all 12 candidates remain reachable through the bag.
func run():
	folder="res://../verification/parity-r23/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932)]:
		for lang in ["ko","en"]:
			root.content_scale_size=dim;root.size=dim
			var s=Screen.new();s.size=dim;s.storage.path="user://r23-ui-"+lang+str(dim.x)+".json";root.add_child(s)
			s.model=fixture();s.model.s.settings={"lang":lang,"diff":2,"chron":1};s.motion_reduced=true;s.screen="codex";s.panels_r22=State.new(s.model);s.panels_r22.ui.sel="levia";s._draw_screen();await settle()
			var expected=s.panels_r22.candidates("levia","weapon");check(expected.size()==12,"source 12 candidates")
			for i in expected.size():check(s.controls.has("p7_cand_"+str(int(expected[i].uid)))==(i<4),"source previews only the first four candidates")
			await capture(s,"candidates-"+lang,dim)
			var preview=expected[3];await click(s,"p7_cand_"+str(int(preview.uid)))
			check(s.model.s.equipment.levia.weapon==preview.uid,"fourth preview equips through pointer")
			var restored=World.new();check(s.storage.read_into(restored),"candidate save reload accepted")
			check(restored.s.equipment.levia.weapon==preview.uid,"preview UID survives reload")
			var last=expected.back();await click(s,"p7_cx_bag")
			var list=s.panels_r22.listing();var at=-1
			for i in list.size():
				if list[i].uid==last.uid:at=i;break
			check(at>=0,"twelfth candidate is reachable in source bag flow")
			if at<0:quit(1);return
			for i in int(at/R.BAG_PAGE):await click(s,"p7_next")
			await click(s,"p7_bg_sel_"+str(at%R.BAG_PAGE+1));await capture(s,"ui-candidate12-bag-"+lang,dim)
			await click(s,"p7_bg_eq_levia")
			check(s.model.s.equipment.levia.weapon==last.uid,"twelfth candidate equips through actual bag pointer")
			restored=World.new();check(s.storage.read_into(restored) and restored.s.equipment.levia.weapon==last.uid,"bag candidate UID survives reload")
			await click(s,"p7_tab_codex");s.panels_r22.ui.sel="";s.panels_r22.ui.tab="rec";s.panels_r22.cx("pg_999");s._draw_screen();await settle()
			check(s.panels_r22.ui.page<=1,"rendered codex page clamps stale selection")
			root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/parity-r23/ui-native-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("UI NATIVE R23 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
