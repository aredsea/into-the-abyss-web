extends "res://tests/ui_dialogue_r21_test.gd"
const L24=preload("res://game/localization_r22.gd")
var hangul24=RegEx.new()
func language_check(s):
	for node in s.town_view.find_children("*","Control",true,false):
		if node is Label or node is Button:
			check(hangul24.search(node.text)==null,"English UI has no Korean: "+node.text)
		if node is Label and node.get_meta("authored_copy",false):
			check(node.get_visible_line_count()>=node.get_line_count(),"all authored lines fit label: "+node.text)
			var sc=ScrollUI.scroller(node)
			if sc:
				check(sc.get_child(0).get_global_rect().grow(1).encloses(node.get_global_rect()),"complete authored text inside scroll content: "+node.text)
func run():
	folder=ProjectSettings.globalize_path("res://../verification/en-r24/render")
	DirAccess.make_dir_recursive_absolute(folder)
	hangul24.compile("[가-힣ㄱ-ㅎㅏ-ㅣ]")
	var scenes=0
	var ids=[]
	for filename in DirAccess.get_files_at("res://data/dialogue-r21"):
		if not filename.ends_with(".json"):continue
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue-r21/"+filename))
		if data.get("en",{}).has("display"):ids.append(filename.get_basename())
	for dim in [Vector2i(360,780),Vector2i(430,932)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://en-r24-ui-fixture.json";root.add_child(s);s.model=World.new();s.motion_reduced=true
		s.model.s.settings={"lang":"en"};var base=s.model.s.duplicate(true)
		for id in ids:
			for row in s.model.dialogue.data(id).inn:
				s.model.s=base.duplicate(true)
				if id not in s.model.s.owned:s.model.s.owned.append(id)
				s.model.s.members[id].aff=[-80,-40,0,30,60,90,120,170][s.model.dialogue.data(id).stage_order.find(row.stage)]
				s.model.s.dialogue_r21.pending={"who":id,"scene":row.id,"day":s.model.s.day}
				s.go("inn");await layout(s,dim);language_check(s);scenes+=1
				if row==s.model.dialogue.data(id).inn[0]:
					await capture(id+"-choices-en-"+str(dim.x))
					if dim.x==360:
						var last=s.controls["dialogue_choice:"+row.choices[-1].id]
						ScrollUI.scroller(last).ensure_control_visible(last)
						await process_frame;await process_frame;await layout(s,dim)
						await capture(id+"-choices-bottom-en-360")
			# Existing Korean response and transition payloads resolve after reload.
			s.model.s=base.duplicate(true)
			if id not in s.model.s.owned:s.model.s.owned.append(id)
			s.model.s.members[id].aff=19;s.model.begin_dialogue(id)
			var row=s.model.dialogue.scene(id,s.model.s.dialogue_r21.pending.scene)
			for choice in row.choices:
				if choice.aff>0:s.model.choose_dialogue(choice.id);break
			s.go("inn");await layout(s,dim);language_check(s)
			if dim.x==360:await capture(id+"-response-en-"+str(dim.x))
			s.model.close_dialogue();s.model.s.dialogue_r21.queue=[];s.model.s.party=[id];s.model.emit_bark("departure",id)
			check(s.model.s.dialogue_r21.queue.size()==1,"bark fixture emitted "+id)
			# A transition in the queue must translate its stage heading too.
			var transition=s.model.dialogue.transition(id,19,21)
			transition.who=id;transition.kind="transition";s.model.s.dialogue_r21.queue.append(transition)
			s.go("inn");await layout(s,dim);language_check(s)
			if dim.x==430:await capture(id+"-journey-en-"+str(dim.x))
		root.remove_child(s);s.queue_free();await process_frame
	var output={"checks":checks,"failures":failures,"scenes":scenes,"captures":captures}
	FileAccess.open("res://../verification/en-r24/ui-test.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("EN R24 UI CHECKS ",checks," SCENES ",scenes," FAILURES ",failures.size())
	quit(0 if failures.is_empty() else 1)
