extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const Portrait=preload("res://ui/town_portrait_r21.gd")
var folder=ProjectSettings.globalize_path("res://../verification/town-r21")
var checks=0
var failures=[]
var measurements={}
var overflow=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func _initialize() -> void: call_deferred("run")
func click(s,id: String) -> void:
	var b=s.controls[id]; var point=b.global_position+b.size*b.get_global_transform().get_scale()/2
	for pressed in [true,false]:
		var ev=InputEventMouseButton.new(); ev.position=point; ev.button_index=MOUSE_BUTTON_LEFT; ev.pressed=pressed; root.push_input(ev)
	await process_frame; await process_frame
func fixture(dim):
	var s=Screen.new(); s.size=dim; s.storage.path="user://town-r21-fixture.json";s.town_r21_preview=true
	root.add_child(s); s.motion_reduced=true
	return s
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder+"/render")
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(1280,800)]:
		root.content_scale_size=dim; root.size=dim
		var s=fixture(dim)
		for mode in ["town","party","member","skills"]:
			s.who="hildegard"; s.go(mode); await process_frame;await process_frame;await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder+"/render/"+mode+"-"+str(dim.x)+".png")==OK,"capture "+mode+str(dim.x))
			var frame=s.town_view.stage; var boxes={}
			for id in s.town_view.boxes:
				var n=s.town_view.boxes[id]; var r=n.get_global_rect()
				boxes[id]=[r.position.x,r.position.y,r.size.x,r.size.y]
			var labels=[]
			for n in s.town_view.find_children("*","Label",true,false):
				var font=n.get_theme_font("font"); var fs=n.get_theme_font_size("font_size")
				var need=font.get_multiline_string_size(n.text,n.horizontal_alignment,n.size.x if n.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
				var missing=[]
				for c in n.text:
					if c not in ["\n"," "] and not font.has_char(c.unicode_at(0)): missing.append(c)
				labels.append({"text":n.text,"rect":rect(n.get_global_rect()),"needed":[need.x,need.y],"available":[n.size.x,n.size.y],"missing":missing})
				check(missing.is_empty(),"glyphs "+mode+n.text)
				# Long authoritative notes are reached through their details action.
				if n.autowrap_mode==TextServer.AUTOWRAP_OFF:
					var fits=need.x<=n.size.x+1
					if not fits: overflow+=1
					check(fits,"horizontal text "+mode+n.text)
				else: check(need.y<=n.size.y+1,"wrapped text height "+mode+n.text)
			var visible_buttons=[]
			for id in s.controls:
				var b=s.controls[id]; var r=b.get_global_rect()
				if id.begins_with("member:") or id.begins_with("skill_detail:"): continue # scroll content
				var fits=Rect2(Vector2.ZERO,Vector2(dim)).grow(1).encloses(r)
				check(fits,"visible control bounds "+mode+id)
				visible_buttons.append([id,r])
			for i in range(visible_buttons.size()):
				for j in range(i+1,visible_buttons.size()):
					var a=visible_buttons[i];var b=visible_buttons[j]
					check(not a[1].grow(-1).intersects(b[1].grow(-1)),"button overlap "+mode+a[0]+"/"+b[0])
			check(s.controls.keys().filter(func(id):return id.begins_with("nav:")).size()==5,"five navigation "+mode)
			for metric in s.town_view.metrics: check(metric.needed<=metric.available+1,"published text width "+mode+metric.text)
			measurements[mode+"-"+str(dim.x)]={"boxes":boxes,"labels":labels}
		# Actual pointer navigation; no direct QA mutation bridge in production.
		s.go("town"); await process_frame
		await click(s,"nav:party"); check(s.screen=="party","pointer roster")
		await click(s,"member:hildegard"); check(s.screen=="member","pointer member")
		await click(s,"tab:skills"); check(s.screen=="skills","pointer skills")
		await click(s,"skill_detail:atk"); check(s.screen=="member_details","pointer skill details")
		await click(s,"back"); check(s.screen=="skills","detail back retains skills context")
		await click(s,"back"); check(s.screen=="party","pointer back")
		s.go("member"); await process_frame;await click(s,"tab:formation")
		check(s.screen=="formation" and s.controls.has("formation:0") and s.controls.has("gear_for_member"),"formation tab exposes formation and gear")
		s.catalog_all=true; s.go("party"); await process_frame
		check(s.controls.keys().filter(func(id):return id.begins_with("member:")).size()==30,"all 30 companions accessible in scroll")
		root.remove_child(s);s.queue_free();await process_frame
	check(Portrait.preferred_path("hildegard","face")=="res://assets/portraits-r10/hildegard-face.png","original fallback face")
	check(Portrait.preferred_path("hildegard","bust")=="res://assets/portraits-r10/hildegard-cutout.png","original fallback bust")
	var stable=Screen.new();stable.storage.path="user://town-r21-stable-fixture.json";stable.size=Vector2(390,844);root.add_child(stable)
	check(not stable.town_r21_preview and not is_instance_valid(stable.town_view),"unapproved comps disconnected from default route")
	for page in ["town","party","member","depart","bag","guild","shop","smithy","inn","equipment","journal"]:
		stable.go(page);await process_frame;await process_frame
		check(stable.controls.keys().filter(func(id):return id.begins_with("nav:")).size()==5,"stable five nav "+page)
	root.remove_child(stable);stable.queue_free();await process_frame
	var f=FileAccess.open(folder+"/ui-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"horizontal_overflow":overflow,"measurements":measurements},"  "));f.close()
	print("TOWN UI R21 CHECKS ",checks," FAILURES ",failures.size()," OVERFLOW ",overflow);quit(1 if failures else 0)
func rect(r: Rect2) -> Array:return [r.position.x,r.position.y,r.size.x,r.size.y]
