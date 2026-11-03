extends "res://tests/ui_panels_r22_test.gd"
const View=preload("res://game/ui_semantics_r23.gd")
const L=preload("res://game/localization_r22.gd")
func run():
	folder="res://../verification/parity-r23/ui-phase3/render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932)]:
		for lang in ["ko","en"]:
			root.content_scale_size=dim;root.size=dim
			var s=Screen.new();s.size=dim;s.storage.path="user://ui-phase3-"+lang+str(dim.x)+".json";root.add_child(s);s.model=fixture();s.model.s.settings={"lang":lang,"diff":2,"chron":1};s.motion_reduced=true;s.panels_r22=State.new(s.model);s.screen="codex";s._draw_screen();await settle()
			s.panels_r22.cx("f_elbad");s._draw_screen();await settle()
			check(not s.controls.has("p7_filter_sub"),"invalid alphabetic group cannot create source subfilters")
			check(s.controls.p7_filter_el.get_theme_color("font_color")!=preload("res://ui/town_theme_r21.gd").PAPER,"invalid group has no selected source element tab")
			s.panels_r22.cx("f_el9_ice");s._draw_screen();await settle()
			check(s.controls.p7_filter_sub.selected==-1,"unknown child leaves every source subfilter unselected")
			await click(s,"p7_filter_el")
			var specs=View.tabs("el",lang);var combo=s.controls.p7_filter_sub
			check(combo.item_count==specs.size()-4,"source element choices count")
			for i in combo.item_count:check(combo.get_item_text(i)==preload("res://tests/source_locale_r24.gd").text(specs[i+4].text,lang),"source element choice text/order with selected-language dictionary")
			combo.select(1);combo.item_selected.emit(1);await settle()
			check(s.panels_r22.ui.tab=="el_fire","element filter changes native state")
			check(s.controls.p7_filter_el.get_theme_color("font_color")==preload("res://ui/town_theme_r21.gd").PAPER,"group remains selected for child filter")
			var resumed=World.new();check(s.storage.read_into(resumed) and resumed.s.panels_r22.tab=="el_fire","source filter survives save/reload")
			await capture(s,"ui-filter-"+lang,dim)
			await click(s,"p7_filter_rec");await click(s,"p7_select_levia")
			var labels=s.town_view.find_children("*","Label",true,false)
			check(labels.any(func(v):return v.text.contains(View.kind(true,lang))),"source active label visible")
			check(labels.any(func(v):return v.text.contains(View.kind(false,lang))),"source passive label visible")
			var expected_candidates=0
			for slot in R.DATA.slots:expected_candidates+=mini(4,s.panels_r22.candidates("levia",slot[0]).size())
			var candidates=s.controls.keys().filter(func(id):return id.begins_with("p7_cand_"))
			check(candidates.size()==expected_candidates,"source four candidates per slot")
			for id in candidates:check(s.controls[id].icon!=null and s.controls[id].has_meta("source_icon"),"source candidate icon and Lv")
			# Component boundary only: the full battle screen integration is a remaining row.
			var old_run=s.model.s.run.duplicate(true);var before_eq=s.model.s.equipment.duplicate(true)
			var preview_entry=s.model.gear_entry(int(candidates[0].trim_prefix("p7_cand_")))
			s.model.s.run={"phase":"battle","battle":{}}
			check(not s.panels_r22.candidates("levia","weapon").is_empty(),"source previews remain queryable in battle")
			check(not s.panels_r22.equip("levia",preview_entry) and s.model.s.equipment==before_eq and s.panels_r22.ui.msg!="","battle equip action rejects and preserves equipment")
			s.model.s.run=old_run;s.panels_r22.ui.msg=""
			# The actual grid uses the source values including decimals and missing values.
			s.town_view.stats({"hp":0,"mp":12,"str":1.25,"agi":-1,"int":99999,"def":7,"spd":1.5},1,0);await settle()
			labels=s.town_view.find_children("*","Label",true,false)
			check(labels.any(func(v):return v.text=="1.25"),"stat grid preserves source decimal")
			await click(s,"p7_cx_bag");check(s.screen=="inventory","bag action opens native screen")
			check(s.controls.p7_bg_cls.get_item_text(0)==L.u("전체",{},lang),"source bag chip label")
			s.panels_r22.bg_action("f_cls_warrior");s.panels_r22.bg_action("f_rar_legend");s._draw_screen();await settle();await click(s,"p7_bg_sel_1")
			var item=s.model.gear.by_id[s.panels_r22.selected().id]
			check(s.town_view.find_children("*","TextureRect",true,false).any(func(v):return v.get_meta("source_icon","")==View.icon(item) and v.texture!=null),"source gear card icon exists in actual UI")
			await capture(s,"ui-gear-"+lang,dim)
			root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/parity-r23/ui-phase3/ui-native-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("UI SEMANTICS NATIVE R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
