extends "res://tests/ui_look_r24_test.gd"
func run():
	folder="res://../verification/finish-r24/round2/after";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(390,844),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://finish-r24-round2-%d-%d.json"%[OS.get_process_id(),dim.x];root.add_child(s)
		for lang in ["ko","en"]:
			s.model=ready_world();s.model.s.settings.lang=lang;s.model.s.creation_r22.legacy=true
			s.model.s.persona.cls="";s.model.s.persona.fight=0;s.screen="depart";s._draw_screen();await settle()
			check(s.controls.has("so_fight_1") and not s.controls.so_fight_1.disabled,"missing-class fight button enabled "+lang)
			await shot(s,"sortie-legacy-"+lang,dim)
			await tap(s,"so_fight_1");check(s.model.s.persona.fight==1,"missing-class toggle updates state "+lang)
			s.model=ready_world();s.model.s.settings.lang=lang;s.model.s.persona.name="{{user}}";s.model.s.items.level_scroll=2
			s.model.s.chronicle_r22={"list":["Day 1: First met Teiris, who joined as a companion."],"queue":[]}
			for page in ["journal","facility_scroll"]:
				s.screen=page;s._draw_screen();await settle();await shot(s,page+"-"+lang,dim)
				for node in s.find_children("*","Control",true,false):
					if node is Label or node is Button:check(not node.text.contains("{{"),"resolved placeholder "+page)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/finish-r24/round2/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"))
	print("UI FINISH ROUND2 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
