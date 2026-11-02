extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/town_world_r21.gd")
var checks=0
var failures=[]
var captures=[]
var folder=ProjectSettings.globalize_path("res://../verification/town-r21/round7/render")
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func click(s,id):
	check(s.controls.has(id),"pointer target "+id)
	if not s.controls.has(id):return
	var rect=s.controls[id].get_global_rect()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=rect.get_center();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e)
	await process_frame;await process_frame
func layout(s,dim):
	await process_frame;await process_frame
	for l in s.town_view.find_children("*","Label",true,false):
		var font=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size")
		var needed=font.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		check(needed.x<=l.size.x+1 and needed.y<=l.size.y+1,"text fits "+l.text)
	var controls=[]
	for id in s.controls:
		var b=s.controls[id];var rect=b.get_global_rect()
		check(Rect2(Vector2.ZERO,Vector2(dim)).grow(1).encloses(rect),"control in viewport "+id)
		if id.begins_with("dialogue_choice:"):
			check(rect.size.y>=44,"touch choice >=44px")
			var font=b.get_theme_font("font");var fs=b.get_theme_font_size("font_size")
			var needed=font.get_multiline_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,b.size.x-24,fs)
			check(needed.y<=b.size.y-12,"choice text fits "+b.text)
		controls.append([id,rect])
	for i in range(controls.size()):
		for j in range(i+1,controls.size()):check(not controls[i][1].grow(-1).intersects(controls[j][1].grow(-1)),"no control overlap")
func capture(name):
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder+"/"+name+".png")==OK,"capture "+name);captures.append(name)
func run():
	DirAccess.make_dir_recursive_absolute(folder)
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(430,932),Vector2i(390,664),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round7-dialogue-fixture.json";root.add_child(s);s.model=World.new();s.motion_reduced=true
		var base=s.model.s.duplicate(true)
		for id in ["hildegard","marceline","teiris"]:
			for a in [-80,-40,0,19,49,79,99,149,170]:
				s.model.s=base.duplicate(true);s.who=id
				if id not in s.model.s.owned:s.model.s.owned.append(id)
				s.model.s.members[id].aff=a;s.go("inn")
				await click(s,"inn:talk");check(s.controls.has("dialogue_choice:c1"),"actual inn opens authored choices")
				await layout(s,dim)
				if a==0 and dim.x in [360,430]:await capture(id+"-choices-"+str(dim.x))
				var row=s.model.dialogue.scene(id,s.model.s.dialogue_r21.pending.scene)
				var choice="c1"
				for c in row.choices:
					if c.aff==2:choice=c.id
				await click(s,"dialogue_choice:"+choice);await layout(s,dim)
				check(s.controls.has("dialogue_done") and s.model.s.dialogue_r21.pending.is_empty(),"response controls / committed state")
				if id=="hildegard" and a==19 and dim.x in [360,430]:await capture("hildegard-transition-"+str(dim.x))
				await click(s,"dialogue_done");check(s.controls["inn:talk"].disabled,"daily used state visible")
		if dim.x in [360,430]:
			# Every authored scene and all three choice labels at both phone extremes.
			for id in ["hildegard","marceline","teiris"]:
				for row in s.model.dialogue.data(id).inn:
					s.model.s=base.duplicate(true)
					if id not in s.model.s.owned:s.model.s.owned.append(id)
					s.model.s.dialogue_r21.pending={"who":id,"scene":row.id,"day":s.model.s.day}
					s.go("inn");await layout(s,dim)
					var body=[]
					for l in s.town_view.find_children("*","Label",true,false):
						if l.position.y>=322:body.append(l.get_rect())
					for i in range(body.size()):
						for j in range(i+1,body.size()):check(not body[i].grow(-1).intersects(body[j].grow(-1)),"all scene text separation "+row.id)
		# Battle prelude leaves battle source untouched and opens only after acknowledgement.
		s.model.s=base.duplicate(true);s.model.depart_dungeon(1,123);s.go("explore")
		await click(s,"dialogue_continue");check(s.controls.has("advance"),"departure then exploration")
		s.model.s.run.phase="battle";s.model.emit_bark("battle_start");s._draw_screen()
		check(not is_instance_valid(s.battle) and s.controls.has("dialogue_continue"),"battle line before combat")
		await click(s,"dialogue_continue");check(is_instance_valid(s.battle),"combat after line")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open("res://../verification/town-r21/round7/ui-dialogue-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("DIALOGUE UI R21 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
