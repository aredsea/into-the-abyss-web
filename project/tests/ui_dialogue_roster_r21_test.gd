extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const W=preload("res://game/settings_world_r22.gd")
const L=preload("res://game/localization_r22.gd")
const ScrollUI=preload("res://tests/ui_scroll_r24.gd")
const OUT="res://../verification/town-r21/round13/"
var checks=0
var failures=[]
var captures=[]
var states={}
var overflow=0
var label_count=0
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():create_timer(1200).timeout.connect(func():quit(98));call_deferred("run")
func measure(s,tag,dim,expected):
	await process_frame
	await RenderingServer.frame_post_draw
	states[tag.get_slice(":",0)]=int(states.get(tag.get_slice(":",0),0))+1
	var texts=[];var rectangles=[]
	for node in s.town_view.find_children("*","Control",true,false):
		if not (node is Label or node is Button) or node.text.is_empty():continue
		label_count+=1;texts.append(node.text)
		var inset=Vector2.ZERO
		if node is Button:
			var style=node.get_theme_stylebox("normal")
			inset=Vector2(style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT),style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM))
		var room=node.size-inset;var fs=node.get_theme_font_size("font_size")
		var needed=node.get_theme_font("font").get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,room.x if node.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		var fits=needed.x<=room.x+1 and needed.y<=room.y+1
		if not fits:overflow+=1
		check(fits,"glyph overflow "+tag+" "+node.text+" needed="+str(needed)+" room="+str(room))
		if node is Label and ScrollUI.scroller(node)!=null and not node.get_parent() is Button:rectangles.append(ScrollUI.visible_rect(node))
	for text in expected:check(text in texts,"authored text remains verbatim "+tag+" "+text)
	for id in s.controls:
		var rect=s.controls[id].get_global_rect()
		check(ScrollUI.reachable(s.controls[id],Rect2(Vector2.ZERO,Vector2(dim))),"control reachable within viewport "+tag+id)
		check(rect.size.y>=44,"touch target >=44 "+tag+id)
		for other in rectangles:check(not ScrollUI.overlaps(ScrollUI.visible_rect(s.controls[id]),other),"text/button separation "+tag+id)
	var buttons=s.controls.values()
	for i in buttons.size():
		for j in range(i+1,buttons.size()):check(not ScrollUI.overlaps(ScrollUI.visible_rect(buttons[i]),ScrollUI.visible_rect(buttons[j])),"button separation "+tag)
	for i in rectangles.size():
		for j in range(i+1,rectangles.size()):check(not ScrollUI.overlaps(rectangles[i],rectangles[j]),"body text separation "+tag)
func capture(name):
	check(root.get_texture().get_image().save_png(OUT+"render/"+name+".png")==OK,"capture "+name);captures.append(name)
func pointer(s,key):
	await process_frame;await process_frame
	check(s.controls.has(key),"actual pointer target "+key)
	if not s.controls.has(key):return
	var sc=ScrollUI.scroller(s.controls[key])
	if sc:sc.ensure_control_visible(s.controls[key]);await process_frame;await process_frame
	var rect=s.controls[key].get_global_rect()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=rect.get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e)
	await process_frame;await process_frame
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+"render"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://round13"))
	var w=W.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	var base=w.s.duplicate(true)
	for dim in [Vector2i(360,780),Vector2i(430,932)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round13/ui-fixture.json";root.add_child(s);s.model=w;s.motion_reduced=true
		for lang in ["ko","en"]:
			for person in w.config.companions:
				var id=person.id;var d=w.dialogue.data(id);var prefix=id+":"+lang+":"+str(dim.x)
				# Reach the authored screen through the real inn button for every companion.
				w.s=base.duplicate(true);w.s.settings.lang=lang
				if id not in w.s.owned:w.s.owned.append(id)
				s.who=id;s.go("inn");await pointer(s,"inn:talk")
				check(not w.s.dialogue_r21.pending.is_empty(),"inn entry "+prefix)
				if w.s.dialogue_r21.pending.is_empty():
					print("ENTRY DEBUG ",JSON.stringify({"who":s.who,"owned":w.s.owned,"day":w.s.day,"acts":w.s.acts,"response":w.s.dialogue_r21.response,"controls":s.controls.keys(),"message":s.message,"same_model":s.model==w}));quit(1);return
				check(s.controls.dialogue_cancel.text==("나중에 이야기하기" if lang=="ko" else "Cancel"),"localized chrome "+prefix)
				await pointer(s,"dialogue_choice:c1");check(not w.s.dialogue_r21.response.is_empty(),"pointer commits "+prefix)
				await pointer(s,"dialogue_done");check(s.controls["inn:talk"].disabled,"daily limit UI "+prefix)
				var shot=false
				for row in d.inn:
					w.s=base.duplicate(true);w.s.settings.lang=lang
					if id not in w.s.owned:w.s.owned.append(id)
					w.s.members[id].aff=[-80,-40,0,30,60,90,120,170][d.stage_order.find(row.stage)]
					w.s.dialogue_r21.pending={"who":id,"scene":row.id,"day":w.s.day}
					s.screen="inn";s._draw_screen()
					var expected=[row.situation,"\n".join(row.lines)]
					for c in row.choices:expected.append(c.text)
					await measure(s,"unseen:"+prefix+row.id,dim,expected)
					if dim.x==360 and lang=="ko" and id in ["hildegard","berenga","bargut","urda"] and row.stage=="유대" and not shot:
						capture(id+"-360-ko");shot=true
					w.s.dialogue_r21.seen[row.id]=1;s._draw_screen()
					await measure(s,"seen:"+prefix+row.id,dim,[row.seen])
					var pending=w.s.duplicate(true)
					for c in row.choices:
						w.s=pending.duplicate(true);check(w.choose_dialogue(c.id),"all response choices "+prefix+row.id+c.id);s._draw_screen()
						await measure(s,"response:"+prefix+row.id+c.id,dim,[c.text,"\n".join(c.response)])
						check(s.controls.dialogue_done.text==("여관으로" if lang=="ko" else "Lower Town Inn"),"localized return button "+prefix)
				for t in d.transitions:
					w.s=base.duplicate(true);w.s.settings.lang=lang
					if id not in w.s.owned:w.s.owned.append(id)
					var row=d.inn[0];var c=row.choices[0];var transition=t.duplicate(true);transition.who=id;transition.kind="transition"
					w.s.dialogue_r21.response={"who":id,"scene":row.id,"choice":c.id,"text":c.text,"lines":c.response,"before":19,"after":21,"gained":2,"transition":transition}
					s._draw_screen();await measure(s,"transition:"+prefix+t.id,dim,[t.situation+"\n"+"\n".join(t.lines)])
				print("NATIVE ",prefix," scenes/reactions/stages complete")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open(OUT+"ui-dialogue-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"overflow":overflow,"labels_measured":label_count,"states":states,"captures":captures},"  "))
	print("DIALOGUE ROSTER UI CHECKS ",checks," FAILURES ",failures.size()," OVERFLOW ",overflow);quit(0 if failures.is_empty() else 1)
