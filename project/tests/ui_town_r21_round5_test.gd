extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/town_world_r21.gd")
var checks=0
var failures=[]
var captures=[]
var folder=ProjectSettings.globalize_path("res://../verification/town-r21/round5")
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
	for l in s.town_view.find_children("*","Label",true,false):
		var font=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size")
		var needed=font.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		check(needed.x<=l.size.x+1 and needed.y<=l.size.y+1,"text fits "+l.text)
	var visible=[]
	for id in s.controls:
		var rect=s.controls[id].get_global_rect()
		check(Rect2(Vector2.ZERO,Vector2(dim)).grow(1).encloses(rect),"control within viewport "+id)
		visible.append([id,rect])
	for i in range(visible.size()):
		for j in range(i+1,visible.size()):check(not visible[i][1].grow(-1).intersects(visible[j][1].grow(-1)),"no control collision "+visible[i][0]+"/"+visible[j][0])
func run():
	DirAccess.make_dir_recursive_absolute(folder+"/render")
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(390,664),Vector2i(1280,800),Vector2i(430,932)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://round5-ui-fixture.json";root.add_child(s);s.model=World.new();s.model.s.gold=100000;s.motion_reduced=true
		s.go("research");await click(s,"research_editor");await capture(s,"research-empty",dim)
		check(s.controls.ps_save.disabled and s.controls["ps_part:suffixes"].disabled,"incomplete composition cannot save")
		s.controls["ps_part:prefixes"].item_selected.emit(1);await process_frame;await process_frame
		check(s.model.research_work(s.who).prefix=="strike" and s.controls.ps_save.disabled,"prefix selection needs suffix")
		s.controls["ps_part:suffixes"].item_selected.emit(1);await process_frame;await process_frame
		check(not s.controls.ps_save.disabled and s.model.tactic(s.who).is_empty(),"complete draft not equipped until confirmed")
		var gold=s.model.s.gold;await click(s,"ps_up:prefix")
		check(s.model.s.gold==gold-60 and s.model.tactic(s.who).is_empty(),"pointer upgrades draft for source cost")
		await capture(s,"research-draft",dim)
		var saved=JSON.parse_string(JSON.stringify(s.model.s));var copy=World.new()
		check(copy.restore(saved),"draft restore from fixture")
		s.model=copy;s._draw_screen();await process_frame
		check(s.model.research_work(s.who).prefix_lv.strike==1 and not s.controls.ps_save.disabled,"draft survives screen and state reload")
		await click(s,"ps_save");await capture(s,"research-saved",dim)
		check(s.model.tactic(s.who).prefix.id=="strike" and s.controls.ps_save.disabled,"pointer commits exactly once")
		check(s.model.s.gold==gold-60,"save charges no second fee")
		await click(s,"research_legacy");check(s.controls.has("compose"),"existing controls still reachable")
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open(folder+"/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("TOWN ROUND5 UI CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
