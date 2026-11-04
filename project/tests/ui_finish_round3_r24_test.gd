extends "res://tests/ui_look_r24_test.gd"
func visible_copy(s):
	for l in s.town_view.find_children("*","Label",true,false):
		if l.has_meta("source_npc_caption") or l.has_meta("inn_status"):
			check(l.get_visible_line_count()==l.get_line_count(),"all caption lines are visible "+l.text)
			var need=l.get_theme_font("font").get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x,l.get_theme_font_size("font_size"))
			check(need.x<=l.size.x+1 and need.y<=l.size.y+1,"caption text fits "+l.text)
func run():
	folder="res://../verification/finish-r24/round3/after";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(390,844),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://finish-r24-r3-%d-%d.json"%[OS.get_process_id(),dim.x];root.add_child(s)
		for lang in ["ko","en"]:
			for key in ["talk","meal","gift","rest"]:
				s.model=ready_world();s.model.s.settings.lang=lang;s.who="teiris";s.screen="inn";s._draw_screen();await settle()
				var before=s.model.s.duplicate(true)
				await tap(s,"inn:"+key)
				var e=s.model.TOWN_RULES.DATA.inn[key]
				check(s.model.s.members.teiris.aff==before.members.teiris.aff+1,"immediate source affection "+key)
				check(s.model.s.gold==before.gold-e.cost,"immediate source cost "+key)
				check(s.model.s.day==before.day+(1 if e.day else 0),"immediate source day "+key)
				if key=="talk":
					check(not s.model.s.dialogue_r21.pending.is_empty(),"authored story remains accessible after immediate source action")
					var paid=s.model.s.members.teiris.aff
					var resumed=W24.new();check(s.storage.read_into(resumed),"prepaid narrative resumes")
					check(resumed.s.members.teiris.aff==paid,"resume retains immediate affection")
					await tap(s,"dialogue_choice:c1");check(s.model.s.members.teiris.aff==paid,"narrative choice does not pay twice")
					await tap(s,"dialogue_done")
				else:check(s.model.s.dialogue_r21.pending.is_empty(),"non-dialogue action has no pending choice")
				check(s.screen=="inn","action retains inn screen")
				if key=="talk":
					await shot(s,"inn-talk-done-"+lang,dim)
					visible_copy(s)
					check(s.controls["inn:talk"].disabled,"daily talk disabled immediately")
					var resumed=W24.new();check(s.storage.read_into(resumed),"action save resumes")
					check(resumed.s.members.teiris.aff==s.model.s.members.teiris.aff,"affection persists")
			# The shared portrait path also serves every existing NPC hero.
			for page in ["guild","recruit","research","shop","smithy"]:
				s.model=ready_world();s.model.s.settings.lang=lang;s.screen=page;s._draw_screen();await settle()
				check(s.town_view.find_children("*","Label",true,false).all(func(l):return l.text!="d"),"NPC name is not a raw id initial")
				await shot(s,"npc-"+page+"-"+lang,dim)
				visible_copy(s)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/finish-r24/round3/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures}))
	print("UI FINISH ROUND3 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
