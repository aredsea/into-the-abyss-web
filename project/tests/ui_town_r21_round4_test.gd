extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/town_world_r21.gd")
const Map=preload("res://ui/town_map_r21.gd")
var checks=0
var failures=[]
var folder=ProjectSettings.globalize_path("res://../verification/town-r21/round4")
var captures=[]
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
func capture(s,name,dim):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var tag=str(dim.x)+("x664" if dim.y==664 else "")
	check(root.get_texture().get_image().save_png(folder+"/render/"+name+"-"+tag+".png")==OK,"capture "+name)
	captures.append(name+"-"+tag)
	var view=s.town_view
	check(is_instance_valid(view),"styled view "+name)
	if not is_instance_valid(view):return
	for l in view.find_children("*","Label",true,false):
		var f=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size");var needed=f.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		check(needed.x<=l.size.x+1 and needed.y<=l.size.y+1,"fitting caption "+name+"/"+l.text)
	var visible=[]
	for key in s.controls:
		var b=s.controls[key];var p=b.get_parent();var scrolled=false
		while p!=s and p!=null:
			if p is ScrollContainer:scrolled=true;break
			p=p.get_parent()
		if scrolled:continue
		var rect=b.get_global_rect();check(Rect2(Vector2.ZERO,Vector2(dim)).grow(1).encloses(rect),"viewport button "+name+"/"+key);visible.append([key,rect])
	for i in range(visible.size()):
		for j in range(i+1,visible.size()):check(not visible[i][1].grow(-1).intersects(visible[j][1].grow(-1)),"overlapping buttons "+name+"/"+visible[i][0]+"/"+visible[j][0])
func run():
	DirAccess.make_dir_recursive_absolute(folder+"/render")
	var w=World.new();w.depart_dungeon(1,117);var original=JSON.stringify(w.s)
	for step in range(6):
		var run=w.s.run.duplicate(true);run.step=step
		var before=JSON.stringify(run);var map=Map.new();map.configure(run,5)
		check(map.points.size()==8 and map.progress==step,"source serial states 0..5 plus rest and boss")
		check(JSON.stringify(run)==before,"map never mutates state")
		map.free()
	check(JSON.stringify(w.s)==original,"presentation never rolls source RNG")
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(390,664),Vector2i(1280,800),Vector2i(430,932)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.model=preload("res://game/town_world_r21.gd").new();s.size=dim;s.storage.path="user://round4-ui-fixture.json";root.add_child(s);s.model=World.new();s.motion_reduced=true
		s.go("research");await capture(s,"research",dim)
		check(s.town_view.boxes.has("title:research") and s.town_view.boxes.has("background:research"),"research title and scene")
		await click(s,"compose");check(not s.model.s.research[s.who].prefix.is_empty(),"existing compose handler")
		await capture(s,"research-equipped",dim)
		await click(s,"research_clear");check(s.model.s.research[s.who].prefix.is_empty(),"existing clear handler")
		for page in ["town","party","member","skills","formation","depart","bag","journal","guild","recruit","shop","equipment","smithy","inn"]:
			s.go(page);await capture(s,page,dim)
		s.shop_tab="gear";s.go("shop");await capture(s,"shopgear",dim)
		s.model.s.members.hildegard.hp=58;s.go("bag");await click(s,"item:hp_s");await click(s,"target:hildegard");await capture(s,"target-selected",dim);await click(s,"item_cancel")
		s.model.depart_dungeon(1,117);s.go("explore");var before=s.model.s.duplicate(true);await capture(s,"explore",dim)
		check(s.model.s==before,"map redraw no progress or RNG mutation")
		check(s.town_view.boxes.has("source_progress_map") and not s.controls.has("step:0"),"no fabricated selectable branches")
		await click(s,"retreat");await capture(s,"retreat",dim);await click(s,"cancel")
		s.model.s.run.phase="rest";s.model.enter_dungeon_rest();s.go("explore");await capture(s,"rest",dim)
		s.go("cards");await capture(s,"cards-empty",dim);s.model.s.hand=["key","camp"];s.go("cards");await capture(s,"cards",dim)
		s.go("explore");await click(s,"retreat");await click(s,"accept");await capture(s,"summary",dim)
		# Old route save retains its own existing cache actions; no new event rules.
		s.model=World.new();s.model.depart();s.model.travel("archive");s.model.travel("cache");s.go("explore");await capture(s,"cache",dim)
		check(s.town_view.boxes.has("title:cache") and s.controls.has("leave_cache"),"legacy cache uses new exterior")
		var state=JSON.stringify(s.model.s);s._draw_screen();check(JSON.stringify(s.model.s)==state,"legacy render preserves saved data")
		await click(s,"leave_cache");check(s.model.s.run.resolved,"source cache leave action")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open(folder+"/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"sizes":5,"captures":captures,"serial_map_states":8},"  "))
	print("TOWN ROUND4 UI CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
