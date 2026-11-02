extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/town_world_r21.gd")
var checks=0
var failures=[]
var captures={}
var folder=ProjectSettings.globalize_path("res://../verification/town-r21")
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures.append(message);push_error(message)
func _initialize():call_deferred("run")
func click(s,id):
	check(s.controls.has(id),"control exists "+id)
	if not s.controls.has(id):return
	var b=s.controls[id];var p=b.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=p;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e)
	await process_frame;await process_frame
func capture(s,name,width):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder+"/render/"+name+"-"+str(width)+".png")==OK,"capture "+name)
	if not is_instance_valid(s.town_view):return
	var view=s.town_view;var boxes={}
	for key in view.boxes:
		var r=view.boxes[key].get_global_rect();boxes[key]=[r.position.x,r.position.y,r.size.x,r.size.y]
	for l in view.find_children("*","Label",true,false):
		var font=l.get_theme_font("font");var fs=l.get_theme_font_size("font_size")
		var need=font.get_multiline_string_size(l.text,l.horizontal_alignment,l.size.x if l.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		check(need.x<=l.size.x+1,"text width "+name+"/"+l.text)
		check(need.y<=l.size.y+1,"text height "+name+"/"+l.text)
	var visible=[]
	for key in s.controls:
		var b=s.controls[key];var r=b.get_global_rect();var p=b.get_parent();var clipped=false
		while p!=s and p!=null:
			if p is ScrollContainer:clipped=true;break
			p=p.get_parent()
		if clipped:continue
		check(Rect2(Vector2.ZERO,s.size).grow(1).encloses(r),"control bounds "+name+"/"+key)
		visible.append([key,r])
	for i in range(visible.size()):
		for j in range(i+1,visible.size()):check(not visible[i][1].grow(-1).intersects(visible[j][1].grow(-1)),"overlap "+name+"/"+visible[i][0]+"/"+visible[j][0])
	check(s.controls.keys().filter(func(k):return k.begins_with("nav:")).size()==5,"five nav "+name)
	captures[name+"-"+str(width)]={"screen":s.screen,"boxes":boxes,"preview":s.town_r21_preview}
func run():
	for dim in [Vector2i(390,844),Vector2i(360,780),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.model=preload("res://game/town_world_r21.gd").new();s.size=dim;s.storage.path="user://round2-ui-fixture.json";root.add_child(s);s.model=World.new();s.motion_reduced=true
		for page in ["depart","formation","bag","journal"]:
			s.go(page);check(is_instance_valid(s.town_view),"finished route default "+page)
			await capture(s,page,dim.x)
		s.model.s.members.hildegard.hp=58;s.model.s.members.bargut.hp=68;s.go("bag");await process_frame
		await click(s,"item:hp_s");await capture(s,"target",dim.x)
		check(s.controls.use_selected.disabled,"no implicit target")
		await click(s,"target:hildegard");await capture(s,"target-selected",dim.x)
		var preview=s.model.item_preview("hp_s","hildegard");var stock=s.model.s.items.hp_s
		await click(s,"use_selected")
		check(s.model.s.members.hildegard.hp==preview.after and s.model.s.items.hp_s==stock-1,"actual pointer item use equals preview")
		await click(s,"item_cancel");check(s.selected_item.is_empty(),"target cancel")
		s.go("depart");await process_frame;await click(s,"start_run")
		check(s.model.r21() and s.screen=="explore","default departure enters source floor run")
		s.town_r21_preview=true;s.go("explore");await capture(s,"explore",dim.x)
		s.model.s.run.phase="rest";s.model.enter_dungeon_rest();s.go("explore");await capture(s,"rest",dim.x)
		s.go("cards");await capture(s,"cards-empty",dim.x)
		s.model.s.hand=["key","camp"];s.go("cards");await capture(s,"cards",dim.x)
		s.go("explore");await process_frame;await click(s,"retreat");await capture(s,"retreat",dim.x)
		await click(s,"cancel");check(s.model.active(),"retreat cancel keeps run")
		s.go("explore");await process_frame;await click(s,"retreat");await click(s,"accept")
		check(s.screen=="summary" and not s.model.active(),"return settles once")
		await capture(s,"summary",dim.x)
		var gold=s.model.s.gold;s.go("town");s.go("summary");check(s.model.s.gold==gold,"summary revisit cannot pay twice")
		root.remove_child(s);s.queue_free();await process_frame
	# Coverage evidence includes unchanged fallback screens. These captures are
	# labelled "legacy" in the owner sheet; they are never counted as new panels.
	root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844)
	var legacy=Screen.new();legacy.model=preload("res://game/town_world_r21.gd").new();legacy.size=Vector2(390,844);legacy.storage.path="user://round2-coverage-fixture.json";root.add_child(legacy);legacy.model=World.new();legacy.motion_reduced=true
	for page in ["equipment","guild","research","shop","smithy","inn"]:
		legacy.go(page);await capture(legacy,"legacy-"+page,390)
	legacy.go("guild");await capture(legacy,"legacy-recruit",390)
	legacy.shop_tab="gear";legacy.go("shop");await capture(legacy,"legacy-shopgear",390)
	legacy.go("equipment");legacy._show_art("hildegard");await capture(legacy,"legacy-art",390);legacy._close_art()
	legacy.model=World.new();legacy.model.depart();legacy.model.travel("archive");legacy.model.travel("cache");legacy.go("explore");await capture(legacy,"legacy-cache",390)
	root.remove_child(legacy);legacy.queue_free();await process_frame
	for result in ["victory","defeat"]:
		var bw=World.new();bw.s.dungeon_r21.best=60;bw.depart_dungeon(1 if result=="victory" else 27,117);bw.s.run.phase="battle"
		var data=bw.battle_data();var simulation=World.ModernBattle.new(data);var turns=0
		while simulation.result.is_empty() and turns<1500:
			if simulation.player_turn() and not simulation.ally(simulation.current_id).charging:
				simulation.choose_enemy(simulation.living(false)[0].id);simulation.act("attack")
			else:simulation.automatic_turn()
			turns+=1
		check(simulation.result==result,"coverage natural battle outcome "+result)
		var bs=preload("res://ui/battle_screen.gd").new();bs.session_data=data;bs.session_snapshot=simulation.snapshot();bs.session_save=func(_s):return OK
		root.add_child(bs)
		await process_frame;await process_frame;await process_frame
		check(bs.state!=null,"coverage battle initializes after viewport transition")
		if bs.state==null:root.remove_child(bs);bs.queue_free();quit(1);return
		bs.motion_reduced=true;bs.busy=false;bs.set_process(false)
		bs._rebuild();await process_frame;await process_frame;await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(folder+"/render/legacy-"+result+"-390.png")==OK,"unchanged battle result capture "+result)
		root.remove_child(bs);bs.queue_free();await process_frame
	FileAccess.open(folder+"/ui-round2-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("TOWN ROUND2 UI CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
