extends "res://tests/ui_look_r24_test.gd"
const Display4=preload("res://game/create_display_r24.gd")
const L=preload("res://game/localization_r22.gd")
var observations=[]
var emitted=[]
func collect_emitted(s,tag):
	for node in s.town_view.find_children("*","Control",true,false):
		if node is Label or node is Button:emitted.append({"screen":"round4/"+tag,"lang":L.language(s.model.s),"kind":"text","text":node.text})
		if node.tooltip_text!="":emitted.append({"screen":"round4/"+tag,"lang":L.language(s.model.s),"kind":"tooltip","text":node.tooltip_text})
func check_form(s,kind,p):
	var view=s.town_view;var display=Display4.new();var entries=display.page(kind,p,L.language(s.model.s))
	check(view.content_entries==entries,"actual form consumes source model "+kind)
	var ink=[]
	for label in view.body.find_children("*","Label",true,false):ink.append(label.text)
	for e in entries:
		check(ink.has(e.text) or e.role in ["adjust"],"actual form displays "+e.text)
		if e.get("sub","")!="":check(ink.has(e.sub),"actual description displays "+e.sub)
		if e.role=="stat":
			var meters=view.body.find_children("*","Control",true,false).filter(func(n):return n.get_meta("source_stat","")==e.key)
			check(meters.size()==1 and meters[0].base_ratio==e.base_ratio and meters[0].total_ratio==e.total_ratio,"actual original base/bonus stat ratios "+e.key)
	for b in display.controls(entries):
		check(s.controls.has(b.id),"actual source control "+b.id)
		if s.controls.has(b.id):check(s.controls[b.id].disabled==b.disabled,"actual disabled state "+b.id)
	observations.append({"kind":kind,"lang":L.language(s.model.s),"entries":entries})
func run():
	folder="res://../verification/finish-r24/round4/after";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(390,844),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://finish-r24-r4-%d-%d.json"%[OS.get_process_id(),dim.x];root.add_child(s)
		for lang in ["ko","en"]:
			for kind in ["race","nation","class","stats"]:
				s.model=W24.new();s.message="";s.model.s.settings.lang=lang
				for arg in ["race_beast","nat_border","cls_warrior"]:s.model.create_action(arg)
				var p=s.model.s.persona
				if kind=="race":p.lineage=""
				if kind=="nation":p.nation="";p.race="수인"
				if kind=="class":p.cls=""
				if kind=="stats":p.bonus_total=0;p.bonus_custom=1
				s.model.s.ui.page={"race":1,"nation":2,"class":3,"stats":4}[kind];s._draw_screen();await settle()
				check_form(s,kind,s.model.persona_rules.view(s.model.s));collect_emitted(s,"create-"+kind);await shot(s,"create-"+kind+"-"+lang,dim)
				s.town_view.scroll.scroll_vertical=100000;await shot(s,"create-"+kind+"-end-"+lang,dim)
				if kind=="stats":
					check(s.controls.cr_tot_m1.disabled and s.controls.cr_tot_m5.disabled,"zero total cannot decrement")
					p.bonus_total=99;s._draw_screen();await settle();check(s.controls.cr_tot_p1.disabled and s.controls.cr_tot_p5.disabled,"maximum total cannot increment")
			# Inline rest controls use the same source helpers and persist selection.
			s.model=ready_world();s.message="";s.model.s.settings.lang=lang;s.model.depart_dungeon(1,7);s.model.s.run.phase="rest";s.model.s.dialogue_r21.queue=[]
			s.model.bank_expedition_gear(["wa01.1.1","wa01.2.1"]);s.screen="explore";s._draw_screen();await settle()
			check(s.controls.has("ex_who_1") and s.controls.has("ex_eq_weapon_wa01_1_1"),"inline rest member and source code controls")
			var before=s.model.s.equipment.persona.duplicate(true)
			s.town_view.source_action("ex_eq_weapon_wa01_1_1");await settle()
			check(s.model.s.equipment.persona!=before,"actual inline equip updates the live account")
			check(s.controls.has("ex_un_weapon"),"actual inline unequip appears")
			s.town_view.source_action("ex_un_weapon");await settle();check(s.model.s.equipment.persona.is_empty(),"actual inline unequip")
			for sc in s.town_view.find_children("*","ScrollContainer",true,false):sc.scroll_vertical=100000
			await shot(s,"rest-gear-"+lang,dim)
			collect_emitted(s,"rest-gear")
			for full in [false,true]:
				s.model=ready_world();s.message="";s.model.s.settings.lang=lang;s.model.s.dialogue_r21.queue=[]
				if full:
					var save=preload("res://game/gear_save_r22.gd").new()
					for i in 2000:s.model.s.serial+=1;s.model.s.gear.append(save.entry("wa01.1.1",s.model.s.serial))
				s.model.depart_dungeon(1,7);s.model.s.run.gold=21;s.model.s.run.xp=55;s.model.s.run.wins=3;s.model.s.run.loot_gear=["wa01.2.1","wa01.3.1"]
				check(s.model.settle("retreat"),"summary source message fixture")
				s.model.s.dialogue_r21.queue=[];s.screen="summary";s._draw_screen();await settle();collect_emitted(s,"summary-full" if full else "summary")
				check(s.model.s.ui.msg.contains("discarded" if lang=="en" else "버려졌습니다") if full else s.model.s.ui.msg.contains("Equipment" if lang=="en" else "장비:"),"settlement reports equipment or bag capacity loss")
				await shot(s,"summary-"+("full-" if full else "")+lang,dim)
			s.model=ready_world();s.message="";s.model.s.settings.lang=lang;s.model.s.dialogue_r21.queue=[];s.screen="inn";s.who="teiris";s._draw_screen();await settle()
			await tap(s,"inn:meal")
			check(s.model.s.gold==275 and s.model.s.members.teiris.aff==1,"actual inn dispatcher confirms the economic action once")
			check(s.town_view.find_children("*","Label",true,false).any(func(l):return l.text==s.model.s.ui.msg),"actual source affection feedback is visible")
			collect_emitted(s,"inn-confirmed");await shot(s,"inn-confirmed-"+lang,dim)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/finish-r24/round4/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"observations":observations}))
	FileAccess.open("res://../verification/finish-r24/round4/screen-strings.json",FileAccess.WRITE).store_string(JSON.stringify(emitted))
	print("UI FINISH ROUND4 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
