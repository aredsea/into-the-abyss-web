extends SceneTree
const Screen=preload("res://ui/world_screen.gd")
const World=preload("res://game/facilities_world_r22.gd")
var checks=0
var failures=[]
var captures=[]
var folder="res://../verification/facilities-r22/render"
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func ready_world():
	var w=World.new()
	w.create_action("race_human");w.create_action("nat_border");w.create_action("cls_warrior");w.create_action("auto");w.create_action("done");w.create_action("pick_teiris","sc");w.create_action("go","sc")
	w.s.gold=100000;w.s.dialogue_r21.queue=[];return w
func click(s,id):
	check(s.controls.has(id),"control "+id)
	if not s.controls.has(id):return
	var b=s.controls[id];var parent=b.get_parent()
	while parent and not parent is ScrollContainer:parent=parent.get_parent()
	if parent is ScrollContainer:parent.ensure_control_visible(b);await process_frame;await process_frame
	check(not b.disabled,"enabled "+id)
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;e.position=b.get_global_rect().get_center();root.push_input(e)
	await process_frame;await process_frame
func capture(s,tag,dim):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var name=tag+"-%dx%d.png"%[dim.x,dim.y]
	check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name)
	if s.town_view:
		for row in s.town_view.metrics:check(row.needed<=row.available+1,"text fits "+tag+row.text)
	for id in s.controls:
		var b=s.controls[id]
		if b is Button and b.text!="":
			var needed=b.get_theme_font("font").get_string_size(b.text,HORIZONTAL_ALIGNMENT_LEFT,-1,b.get_theme_font_size("font_size"))
			check(needed.x<=b.size.x+2,"button text "+tag+id)
func _initialize():call_deferred("run")
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://p6-ui-%dx%d.json"%[dim.x,dim.y];root.add_child(s);s.model=ready_world();s.motion_reduced=true
		s.go("shop");await process_frame;await capture(s,"shop",dim)
		await click(s,"buy:level_scroll");await click(s,"shop_scroll");await capture(s,"scroll-targets",dim)
		var lv=s.model.s.persona.lv;await click(s,"scroll_target:persona");check(s.model.s.persona.lv==lv+1,"pointer persona scroll")
		await click(s,"scroll_back");await click(s,"shop_equipment");await capture(s,"ten-classes",dim)
		check(s.controls.shop_class.item_count==10,"ten class choices independent of ownership")
		s.controls.shop_class.select(9);s.controls.shop_class.item_selected.emit(9);await process_frame
		var cls=s.model.shop_classes()[9];var row=s.model.shop_stock(cls,s.gear_filter)[0]
		await click(s,"buygear:"+row.id);check(s.model.stock_sold(row.code),"pointer unowned class purchase")
		await click(s,"back");await capture(s,"shop-receipt",dim);check(s.controls.has("receipt_done"),"purchase departure receipt")
		await click(s,"receipt_done");s.go("smithy");await capture(s,"smithy-forge",dim)
		await click(s,"sm_tab:process");await capture(s,"smithy-process",dim)
		await click(s,"process_gear");var gold=s.model.s.gold;check(s.model.s.commerce_r21.process_n==1,"pointer process counter")
		await capture(s,"smithy-result",dim);await click(s,"back")
		check(s.screen=="smithy" and s.model.s.gold==gold,"return blocked after process")
		await capture(s,"smithy-blocked",dim)
		# A blocked navigation notice must not cover the recovery control.
		await click(s,"smithy_done");await capture(s,"smithy-receipt",dim)
		await click(s,"receipt_done");await click(s,"sm_tab:forge");var uid=s.model.s.gear[0].uid
		await click(s,"forge:"+str(int(uid)));check(s.model.gear_entry(uid).tries==1,"pointer forge spends one attempt directly, as source sm_try")
		await click(s,"smithy_done");await click(s,"receipt_done");await click(s,"back")
		s.go("guild");await capture(s,"guild",dim)
		var first=s.model.s.board[0].id;await click(s,"quest:"+str(int(first)))
		check(s.model.s.quest.id==first,"pointer accept quest")
		var rejected=s.model.s.board[1].id;await click(s,"quest_reject:"+str(int(rejected)));check(not s.model.s.board.any(func(q):return q.id==rejected),"pointer reject quest while another active")
		await capture(s,"guild-active",dim)
		await click(s,"quest_abandon");check(s.model.s.quest.is_empty(),"pointer abandon and refill directly, as source gd_drop")
		s.go("inn");await capture(s,"inn",dim)
		s.go("town");s.model.s.owned=[];s.model.s.party=[];s.go("inn");await capture(s,"inn-empty",dim)
		root.remove_child(s);s.queue_free();await process_frame
	FileAccess.open("res://../verification/facilities-r22/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("FACILITIES UI R22 CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(1 if failures else 0)
