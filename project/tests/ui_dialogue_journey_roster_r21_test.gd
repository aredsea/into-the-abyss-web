extends "res://tests/ui_dialogue_roster_r21_test.gd"
## Exercise the production journey renderer, including scrollable stage scenes.
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"render"))
	var w=W.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	var base=w.s.duplicate(true)
	for dim in [Vector2i(360,780),Vector2i(430,932)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round13/journey.json";root.add_child(s);s.model=w;s.motion_reduced=true;s.screen="inn"
		for lang in ["ko","en"]:
			for person in w.config.companions:
				var id=person.id;var d=w.dialogue.data(id)
				w.s=base.duplicate(true);w.s.settings.lang=lang
				if id not in w.s.owned:w.s.owned.append(id)
				w.s.party=[id]
				for row in d.dungeon:
					for i in row.variants.size():
						w.s.dialogue_r21.queue=[];w.s.dialogue_r21.bark_counts[row.event]=i
						w.s.members[id].aff=[-80,-40,0,30,60,90,120,170][d.stage_order.find(d.dungeon_bands[row.band][0])]
						w.emit_bark(row.event,id);s._draw_screen()
						await measure(s,"bark:"+id+row.event+lang+str(dim.x),dim,[row.variants[i]])
						check(s.controls.dialogue_continue.text==("계속" if lang=="ko" else "Continue"),"localized continue button "+id)
				for t in d.transitions:
					var row=t.duplicate(true);row.who=id;row.kind="transition";w.s.dialogue_r21.queue=[row];s._draw_screen()
					await measure(s,"journey-stage:"+id+t.id+lang+str(dim.x),dim,[(L.display(t.from,s.model.s)+" → "+L.display(t.to,s.model.s)+"\n"+L.authored_display(t.situation,s.model.s)+"\n"+"\n".join(t.lines.map(func(x):return L.authored_display(x,s.model.s)))) if lang=="en" else t.from+" → "+t.to+"\n"+t.situation+"\n"+"\n".join(t.lines)])
				if id in ["bargut","berenga"] and dim.x==360:capture("journey-"+id+"-"+lang+"-360")
				print("JOURNEY ",id," ",lang," ",dim.x," complete")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open(OUT+"ui-journey-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"overflow":overflow,"labels_measured":label_count,"states":states,"captures":captures},"  "))
	print("DIALOGUE JOURNEY UI CHECKS ",checks," FAILURES ",failures.size()," OVERFLOW ",overflow);quit(0 if failures.is_empty() else 1)
