extends "res://tests/ui_look_r24_test.gd"
## Regression for the previously untested scroll/footer intersection.
var bottoms=[]

func visible_in(control: Control,viewport: Control) -> bool:
	var r=control.get_global_rect();var bounds=viewport.get_global_rect()
	return r.position.x>=bounds.position.x-1 and r.end.x<=bounds.end.x+1 and r.position.y>=bounds.position.y-1 and r.end.y<=bounds.end.y+1

func bottom(s,tag,dim):
	await settle()
	var views=s.town_view.find_children("*","ScrollContainer",true,false)
	check(not views.is_empty(),"scroll exists "+tag)
	if views.is_empty():return
	var viewport=views[0];var content=viewport.get_child(0)
	# Every actionable row can be brought wholly above the fixed footer.
	for id in s.controls:
		var b=s.controls[id]
		if not content.is_ancestor_of(b):continue
		viewport.ensure_control_visible(b);await settle()
		check(visible_in(b,viewport),"whole action reachable "+tag+":"+id)
	viewport.scroll_vertical=100000;await settle()
	var last=content.get_child(content.get_child_count()-1)
	if last is GridContainer:last=last.get_child(last.get_child_count()-1)
	check(visible_in(last,viewport),"whole final row visible "+tag)
	if s.town_view is Create24:
		check(viewport.get_global_rect().end.y<=s.town_view.footer.get_global_rect().position.y-16,"footer clearance "+tag)
	bottoms.append({"screen":tag,"size":[dim.x,dim.y],"scroll_bottom":viewport.get_global_rect().end.y,"last_bottom":last.get_global_rect().end.y,"scroll_offset":viewport.scroll_vertical,"reduced":s.motion_reduced})
	await shot(s,tag,dim)

func run():
	folder="res://../verification/look-r24/after"
	var sizes=[Vector2i(360,780),Vector2i(390,664),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800),Vector2i(360,780)]
	for index in sizes.size():
		var dim=sizes[index];root.content_scale_size=dim;root.size=dim
		var s=Screen.new();s.size=dim;s.storage.path="user://look-r24-bottom-%d-%d.json"%[OS.get_process_id(),index];root.add_child(s);s.model=W24.new();s.motion_reduced=index==sizes.size()-1
		for arg in ["race_beast","lin_cat","nat_border","cls_archer","auto"]:s.model.create_action(arg)
		for page in range(1,6):
			s.model.s.ui.page=page;s._draw_screen();await bottom(s,"create-step%d-end"%page,dim)
			s.town_view.scroll.scroll_vertical=0;await settle()
			if page==4:
				await tap(s,"cr_tot_free");await tap(s,"cr_tot_p5");await tap(s,"cr_auto")
				for id in ["cr_auto","cr_clear","cr_up_spd"]:check(visible_in(s.controls[id],s.town_view.scroll),"action stays visible after allocation "+id)
				await shot(s,"create-points-action",dim)
				await tap(s,"cr_clear")
				check(visible_in(s.controls.cr_clear,s.town_view.scroll),"clear stays visible after rebuild")
				await bottom(s,"create-custom-end",dim)
				await tap(s,"cr_auto")
		await tap(s,"cr_done");await bottom(s,"meeting-empty-end",dim)
		await tap(s,"sc_pick_teiris");await bottom(s,"meeting-end",dim)
		s.model=ready_world();s.cloud.account={"code":"","pin":"","rev":0,"auto":false,"synced":false};s.cloud.notice="클라우드에 연결하면 다른 기기에서도 이어할 수 있습니다.";s.screen="cloud";s._draw_screen();await bottom(s,"cloud-end",dim)
		s.cloud.account={"code":"ABCD-EFGH-JKMP","pin":"23456789AB","rev":1,"auto":false,"synced":true};s.cloud.first_credentials=true;s._draw_screen();await bottom(s,"cloud-credentials-end",dim)
		s.cloud.first_credentials=false;s.cloud.conflict={"rev":2,"summary":{"day":2,"level":2,"best":1,"gold":275,"companions":1}};s._draw_screen();await bottom(s,"cloud-conflict-end",dim)
		s.cloud.conflict={};s.cloud_connecting=true;s._draw_screen();await bottom(s,"cloud-connect-end",dim);s.cloud_connecting=false
		s.cloud_confirmation={"prompt":"서버 기록을 불러올까요? 이 기기 기록은 백업에 남습니다.","callback":func():pass};s._draw_screen();await bottom(s,"cloud-confirm-end",dim);s.cloud_confirmation={}
		s.screen="rank";s.cloud.rank={"n":3,"pct":34,"best":1,"top":2,"at":1793577600};s._draw_screen();await bottom(s,"rank-end",dim)
		root.remove_child(s);s.queue_free();await settle()
	FileAccess.open("res://../verification/look-r24/round3/bottom-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"bottoms":bottoms},"\t"))
	print("LOOK R24 BOTTOM CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
