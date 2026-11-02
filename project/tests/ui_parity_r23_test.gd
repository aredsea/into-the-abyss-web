extends "res://tests/ui_panels_r22_test.gd"
## Verify every source candidate is reachable and survives an actual save/reload.
func run():
	folder="res://../verification/parity-r23/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932)]:
		for lang in ["ko","en"]:
			root.content_scale_size=dim;root.size=dim
			var s=Screen.new();s.size=dim;s.storage.path="user://r23-ui-"+lang+str(dim.x)+".json";root.add_child(s)
			s.model=fixture();s.model.s.settings={"lang":lang,"diff":2,"chron":1};s.motion_reduced=true;s.screen="codex";s.panels_r22=State.new(s.model);s.panels_r22.ui.sel="levia";s._draw_screen();await settle()
			var expected=s.panels_r22.candidates("levia","weapon");check(expected.size()==12,"source 12 candidates")
			for entry in expected:check(s.controls.has("p7_cand_"+str(int(entry.uid))),"every candidate has an action")
			await capture(s,"candidates-"+lang,dim)
			var last=expected.back();s.town_view.scroll.ensure_control_visible(s.controls["p7_cand_"+str(int(last.uid))]);await settle();await capture(s,"candidate12-"+lang,dim)
			await click(s,"p7_cand_"+str(int(last.uid)))
			check(s.model.s.equipment.levia.weapon==last.uid,"twelfth candidate equips through pointer")
			var restored=World.new();check(s.storage.read_into(restored),"candidate save reload accepted")
			check(restored.s.equipment.levia.weapon==last.uid,"candidate UID survives reload")
			s.panels_r22.ui.sel="";s.panels_r22.ui.tab="rec";s.panels_r22.cx("pg_999");s._draw_screen();await settle()
			check(s.panels_r22.ui.page<=1,"rendered codex page clamps stale selection")
			root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/parity-r23/ui-native-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("UI NATIVE R23 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
