extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/town_world_r21.gd")
const Portrait=preload("res://ui/town_portrait_r21.gd")
var checks=0
var failures=[]
var captures={}
var folder=ProjectSettings.globalize_path("res://../verification/town-r21/round3")
func check(ok: bool,message: String):
	checks+=1
	if not ok:
		failures.append(message)
		if failures.size()<30:push_error(message)
func _initialize():call_deferred("run")
func click(s,id):
	check(s.controls.has(id),"pointer control "+id)
	if not s.controls.has(id):return
	var b=s.controls[id];var p=b.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e)
	await process_frame;await process_frame
func capture(s,name,width):
	var tag=str(width)
	if root.size.y==664 and not tag.ends_with("x664"):tag+="x664"
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	check(is_instance_valid(s.town_view),"default measured route "+name)
	check(root.get_texture().get_image().save_png(folder+"/render/"+name+"-"+tag+".png")==OK,"capture "+name)
	if not is_instance_valid(s.town_view):return
	for l in s.town_view.find_children("*","Label",true,false):
		var f=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size")
		var n=f.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		check(n.x<=l.size.x+1,"width "+name+"/"+l.text)
		check(n.y<=l.size.y+1,"height "+name+"/"+l.text)
	var buttons=[]
	for id in s.controls:
		var b=s.controls[id];var p=b.get_parent();var clipped=false
		while p!=s and p!=null:
			if p is ScrollContainer:clipped=true;break
			p=p.get_parent()
		if clipped:continue
		var r=b.get_global_rect();check(Rect2(Vector2.ZERO,s.size).grow(1).encloses(r),"bounds "+name+"/"+id)
		buttons.append([id,r])
	for i in range(buttons.size()):
		for j in range(i+1,buttons.size()):check(not buttons[i][1].grow(-1).intersects(buttons[j][1].grow(-1)),"overlap "+name+"/"+buttons[i][0]+"/"+buttons[j][0])
	check(s.controls.keys().filter(func(k):return k.begins_with("nav:")).size()==5,"five nav "+name)
	captures[name+"-"+tag]={"screen":s.screen,"controls":s.controls.size(),"preview":s.town_r21_preview}
func run():
	DirAccess.make_dir_recursive_absolute(folder+"/render")
	var w=World.new();var portraits=0;var fallback=0
	for c in w.config.companions:
		for slot in Portrait.SLOTS:
			var path=Portrait.preferred_path(c.id,slot);check(path.begins_with("res://assets/portraits-r21-web/slots/"),"C atlas preferred "+c.id+"/"+slot)
			var atlas=load(path);var raw=Image.load_from_file("res://assets/portraits-r21/slots/"+c.id+"-"+slot+".png")
			check(atlas is AtlasTexture,"deduplicated AtlasTexture "+path)
			check(atlas.get_size()==Vector2(raw.get_size()),"native dimensions "+path);portraits+=1
	for id in w.dungeon_rules.foes:
		var art=w.art_for(id);check(not art.fallback and art.path==w.dungeon_rules.foes[id].art,"real enemy art "+id)
		if art.fallback:fallback+=1
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(390,664),Vector2i(1280,800),Vector2i(430,932)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.model=preload("res://game/town_world_r21.gd").new();s.size=dim;s.storage.path="user://round3-ui-fixture.json";root.add_child(s);s.model=World.new();s.motion_reduced=true
		check(not s.town_r21_preview,"no flag on default route")
		for page in ["town","party","member","skills","equipment","guild","recruit","inn","shop","smithy"]:
			s.go(page);await capture(s,page,str(dim.x)+("x664" if dim.y==664 else ""))
		s.shop_tab="gear";s.go("shop");await capture(s,"shopgear",dim.x)
		s.go("skills");await process_frame;await click(s,"signature_preview");check(is_instance_valid(s.art_preview),"town art shell opened")
		await process_frame;await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(folder+"/render/art-"+str(dim.x)+("x664" if dim.y==664 else "")+".png")==OK,"art shell capture")
		await click(s,"art_close");check(not s.controls.has("art_back"),"art controls cleaned on close")
		# Real pointer purchases and confirmation cancellation never reset a save.
		s.shop_tab="items";s.go("shop");await process_frame
		var gold=s.model.s.gold;var stock=s.model.s.items.hp_s;var cost=s.model.price(s.model.item_def("hp_s"))
		await click(s,"buy:hp_s");check(s.model.s.gold==gold-cost and s.model.s.items.hp_s==stock+1,"pointer shop charges source-rounded cost")
		s.go("guild");await process_frame;await click(s,"guild:recruit");check(s.screen=="recruit","dedicated recruitment route")
		s.go("inn");await process_frame;await click(s,"inn:meal")
		check(s.model.s.gold==gold-cost-25,"source inn meal commits its cost immediately")
		check(s.controls["inn:meal"].disabled,"source inn meal daily limit is immediate")
		var after_meal=s.model.s.duplicate(true)
		check(not s.model.inn(s.who,"meal") and s.model.s==after_meal,"duplicate meal is rejected atomically")
		s.go("depart");await process_frame;await click(s,"start_run");await click(s,"dialogue_continue");await capture(s,"explore",dim.x)
		await click(s,"nav:depart");check(s.screen=="explore","active expedition nav resumes instead of departure")
		await click(s,"retreat");await capture(s,"retreat",dim.x)
		var snapshot=JSON.stringify(s.model.s);await click(s,"cancel");check(JSON.stringify(s.model.s)==snapshot,"retreat cancellation does not mutate run")
		s.model.s.run.phase="rest";s.model.enter_dungeon_rest();s.go("explore");await click(s,"dialogue_continue");await capture(s,"rest",dim.x)
		s.go("cards");await capture(s,"cards-empty",dim.x)
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open(folder+"/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"portrait_slots":portraits,"enemy_art_fallbacks":fallback},"  "))
	print("TOWN ROUND3 UI CHECKS ",checks," FAILURES ",failures.size()," PORTRAIT SLOTS ",portraits," ENEMY FALLBACKS ",fallback)
	quit(0 if failures.is_empty() else 1)
