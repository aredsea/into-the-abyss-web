extends "res://tests/ui_panels_r22_test.gd"
const L=preload("res://game/localization_r22.gd")
const Create=preload("res://ui/create_screen.gd")
func run():
	folder="res://../verification/parity-r23/phase2/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/phase2/oracle.json"))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932)]:
		for lang in ["ko","en"]:
			root.content_scale_size=dim;root.size=dim
			var s=Screen.new();s.size=dim;s.storage.path="user://r23-phase2-"+lang+str(dim.x)+".json";root.add_child(s)
			s.model=preload("res://game/settings_world_r22.gd").new();s.model.s.settings.lang=lang;s.motion_reduced=true;s._draw_screen();await settle()
			await click(s,"cr_race_human")
			var expected=""
			for f in o.syn:
				if f.lang==lang and f.entry.get("id")=="human":expected=f.display
			check(s.town_view is Create,"creation screen uses native form")
			var labels=s.town_view.find_children("*","Label",true,false)
			check(labels.any(func(label):return label.text==expected),"source synergy sentence visible in "+lang)
			for label in labels:
				var needed=label.get_theme_font("font").get_multiline_string_size(label.text,label.horizontal_alignment,label.size.x,label.get_theme_font_size("font_size"))
				check(needed.y<=label.size.y+2,"creation label fits "+lang+label.text)
			for label in labels:
				if label.text==expected:s.town_view.scroll.ensure_control_visible(label)
			await settle()
			await capture(s,"synergy-"+lang,dim)
			s.model=fixture();s.model.s.settings={"lang":lang,"diff":2,"chron":1};s.model.s.persona.name='<A&B>"';s.model.s.panels_r22={"future_panel_field":{"keep":[1,"old"]}};s.panels_r22=State.new(s.model);s.panels_r22.ui.panel="codex";s.panels_r22.ui.sel="levia";s.panels_r22.ui.tab="rec";s.screen="codex";s._draw_screen();await settle()
			await click(s,"p7_tab_status")
			check(s.panels_r22.ui.panel=="status" and s.panels_r22.ui.sel=="" and s.panels_r22.ui.tab=="me","HUD panel switch clears old selection through source handler")
			await click(s,"p7_tab_inventory")
			check(s.screen=="inventory" and s.panels_r22.ui.tab=="bag","status bag tab uses source handler")
			var entry=s.panels_r22.entries().filter(func(e):return s.model.gear.by_id[e.id].cls=="warrior" and s.panels_r22.can_equip("persona",e)=="")[0]
			s.panels_r22.bg.sel=entry.code;s._draw_screen();await settle()
			var label=L.u("{name}에게 장착",{"name":'<A&B>"'},lang)
			check(s.controls.p7_bg_eq_persona.text==label,"native label translates once and shows special characters literally")
			s.town_view.scroll.ensure_control_visible(s.controls.p7_bg_eq_persona);await settle();await capture(s,"member-"+lang,dim)
			await click(s,"p7_bg_eq_persona")
			check(s.model.s.equipment.persona[s.model.gear.by_id[entry.id].slot]==entry.uid,"translated persona action equips the selected UID")
			var restored=World.new();check(s.storage.read_into(restored),"panel state and member action survive save resume")
			check(restored.s.persona.name=='<A&B>"' and restored.s.panels_r22.panel=="status" and restored.s.panels_r22.tab=="bag","saved names and source panel state survive resume")
			var extra=restored.s.panels_r22.get("future_panel_field")
			check(extra is Dictionary and extra.get("keep") is Array and extra.keep.size()==2 and extra.keep[0]==1 and extra.keep[1]=="old","unknown saved panel fields survive navigation and reload: "+JSON.stringify(extra))
			root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/parity-r23/phase2/native-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("UI REMAINING NATIVE R23 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
