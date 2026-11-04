extends "res://tests/ui_panels_r22_test.gd"
const Layout24=preload("res://ui/portrait_layout_r24.gd")
const Town24=preload("res://ui/town_portrait_r21.gd")
const Face24=preload("res://ui/battle_face_r17.gd")
const Rules24=preload("res://ui/portrait_rules_r22.gd")
const World24=preload("res://game/settings_world_r22.gd")
var inventory=[]
func record_portraits(n: Node,page: String,dim: Vector2i):
	if n is Town24 or n is Face24 or n is Rules24:
		var id=n.id if n is Face24 else n.character_id
		inventory.append({"screen":page,"viewport":[dim.x,dim.y],"id":id,"rect":[n.global_position.x,n.global_position.y,n.size.x,n.size.y],"normalized24":n.normalized24})
	for child in n.get_children():record_portraits(child,page,dim)
func run():
	folder="res://../verification/portrait-r24/after";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for id in Layout24.LANDMARKS:
		check(ResourceLoader.exists(Layout24.path(id)),"R24 master "+id)
		var m=Layout24.LANDMARKS[id]
		for dims in [Vector2(340,428),Vector2(83,58),Vector2(86,181),Vector2(71,67),Vector2(88,93),Vector2(390,360),Vector2(153,192),Vector2(39,45),Vector2(84,51),Vector2(340,280)]:
			for face in [true,false]:
				var crop=Layout24.frame(id,dims,face)
				var eye=(m.eye_y-crop.position.y)/crop.size.y
				check(eye<=.4201 and eye>.10,"eye alignment constrained by full horns/ears "+id)
				check(abs((m.top_y-crop.position.y)/crop.size.y-.10)<.0001,"crown at ten percent "+id)
				check((m.shoulder_y-crop.position.y)/crop.size.y<=.6701,"shoulders precede fade "+id)
				check(m.head_bounds_xyxy[0]>=crop.position.x+crop.size.x*.0299 and m.head_bounds_xyxy[2]<=crop.end.x-crop.size.x*.0299,"ears and horns stay inside "+id)
		for kind in Layout24.SLOT_KINDS:
			var made=Layout24.make_portrait(id,kind,Vector2(84,90))
			check(made.picture!=null and made.slot_kind==kind and made.mouse_filter==Control.MOUSE_FILTER_IGNORE,"factory "+id+kind);made.free()
		var pic=Town24.new();pic.configure(id,"detail-overview")
		check(pic.normalized24 and pic.source_path==Layout24.path(id),"new asset rendered "+id);pic.free()
	check(Layout24.frame("missing",Vector2(0,0))==Rect2(),"missing/zero dimensions")
	check(Layout24.fade(.7)==1 and Layout24.fade(1)==0 and abs(Layout24.fade(.85)-.5)<.001,"bottom thirty percent fade")
	for dim in [Vector2i(390,844),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://portrait-r24-%d.json"%dim.x;root.add_child(s)
		s.model=World24.new();s.model.s.creation_r22={"complete":true,"legacy":true};s.model.s.scene="town";s.model.s.owned=Layout24.LANDMARKS.keys();s.model.s.party=["hildegard","naran","teiris","bargut"];s.model.s.dialogue_r21.queue=[];s.motion_reduced=true;s.catalog_all=true;s.who="naran"
		for page in ["town","party","member","skills","depart","formation","inn","recruit","codex","status"]:
			s.screen=page;s._draw_screen();await settle();await settle();await RenderingServer.frame_post_draw
			var file=page+"-%dx%d.png"%[dim.x,dim.y]
			check(root.get_texture().get_image().save_png(folder+"/"+file)==OK,"screenshot "+file);captures.append(file);record_portraits(s,page,dim)
		s.model.s.creation_r22.complete=false;s.model.s.scene="scenario";s.model.s.ui.sel=s.model.persona_rules.data.scenarios[0].id;s._draw_screen()
		await portrait_capture(s,"creation-meeting",dim);record_portraits(s,"creation-meeting",dim)
		root.remove_child(s);s.queue_free();await settle()
		var battle=preload("res://ui/battle_screen.gd").new()
		battle.session_save=func(_snapshot):return OK
		root.add_child(battle);battle.motion_reduced=true; battle.busy=false
		for status in [false,true]:
			battle.ally_open="berenga" if status else "";battle._rebuild();await portrait_capture(battle,"battle-status" if status else "battle",dim)
		root.remove_child(battle);battle.queue_free();await settle()
	# Actual shared renderer atlas at review size, both required grounds.
	root.content_scale_size=Vector2i(1200,1200);root.size=Vector2i(1200,1200)
	for kind in Layout24.SLOT_KINDS:
		for ground in ["red","paper"]:
			var board=ColorRect.new();board.color=Color("E8452A" if ground=="red" else "EEE6D6");board.size=Vector2(1200,1200);root.add_child(board)
			var i=0
			var ratio={"party_card":86.0/96,"list_row":88.0/93,"chip":1.0,"hero":340.0/428,"detail":1.0,"battle_card":84.0/64}[kind]
			for id in Layout24.LANDMARKS:
				var dims=Vector2(minf(196,210*ratio),minf(210,196/ratio))
				var portrait=Layout24.make_portrait(id,kind,dims);board.add_child(portrait);portrait.position=Vector2((i%6)*200+(200-dims.x)/2,(i/6)*240+25)
				var label=Label.new();label.text=id;label.position=Vector2((i%6)*200+3,(i/6)*240);label.add_theme_color_override("font_color",Color.BLACK);board.add_child(label);i+=1
			await portrait_capture(null,"atlas-"+kind+"-"+ground,Vector2i(1200,1200))
			root.remove_child(board);board.queue_free();await settle()
	FileAccess.open("res://../verification/portrait-r24/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"inventory":inventory},"\t"))
	print("PORTRAIT R24 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)

func portrait_capture(_surface,tag,dim):
	await settle();await RenderingServer.frame_post_draw
	var file=tag+"-%dx%d.png"%[dim.x,dim.y]
	check(root.get_texture().get_image().save_png(folder+"/"+file)==OK,"capture "+file);captures.append(file)
