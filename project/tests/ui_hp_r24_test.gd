extends SceneTree
const Gauge=preload("res://ui/resource_gauge_r24.gd")
const Screen=preload("res://ui/battle_screen.gd")
const World=preload("res://game/dungeon_world_r21.gd")
const Host=preload("res://ui/world_screen.gd")
var folder=ProjectSettings.globalize_path("res://../verification/hp-r24")
var checks=0
var failures=[]
var captures=[]
var readings=[]
func _initialize():
	create_timer(180).timeout.connect(func():push_error("HP test watchdog");quit(98));call_deferred("run")
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures.append(message);push_error(message)
func settle():await process_frame;await process_frame
func capture(tag: String):
	await settle();await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder+"/"+tag+".png")==OK,"capture "+tag);captures.append(tag+".png")
func fixture():
	var world=World.new();world.depart_dungeon(1,123);world.s.run.phase="battle"
	var data=world.battle_data();var plan=data.encounter_r21.duplicate(true)
	plan.enc.fl=["raging_lecturer"];plan.enc.fg=["boss"];plan.enc.ne=1;data.encounter_r21=plan;data.enemies=world.make_enemies(plan,data.allies)
	var s=Screen.new();s.session_data=data;s.session_save=func(_value):return OK
	root.add_child(s)
	for spec in [["hildegard",62,118,23,33],["bargut",65,93,40,40],["teiris",14,77,20,86],["berenga",0,79,72,99]]:
		var a=s.state.ally(spec[0]);a.hp=spec[1];a.mhp=spec[2];a.mp=spec[3];a.mmp=spec[4];a.shield=20 if a.id=="bargut" else 0
	for e in s.state.data.enemies:
		e.hp=62;e.mhp=163;e.phase=2
	s.state.turn_count=3;s.state.current_id="hildegard";s.state.last_ally="hildegard";s.state.data.queue=["hildegard","executor","teiris","orb","bargut","apprentice","berenga","lantern"]
	# Source composition uses reserved slots. Queue entries refer only to visible units.
	s.state.data.queue=["hildegard",s.state.data.enemies[0].id,"teiris","bargut","berenga"]
	s.busy=false;s.resource_history.clear();s._rebuild()
	return s
func assert_readouts(s):
	for node in s.find_children("*","Control",true,false):
		if node.has_meta("resource_values"):
			for l in node.get_children():
				check(l.position.x+l.size.x*l.scale.x<=node.size.x+2,"resource number fits "+l.text)
		if node is Gauge:
			check(node.size.y==9 if node.hp else node.size.y==3,"shared bar thickness")
			check(node.get_global_rect().end.x<=s.frame.end.x+1,"gauge inside frame")
func run():
	await process_frame
	DirAccess.make_dir_recursive_absolute(folder)
	# Exact clock contract including interruption, healing, KO and reduced motion.
	var h={};Gauge.observe(h,"unit",100,false,0);var hit=Gauge.observe(h,"unit",50,false,1)
	check(hit.value==50 and Gauge.trail_at(hit,1)==100,"fill immediate, trail holds")
	check(Gauge.trail_at(hit,1.4)>99.99,"0.4 second hold")
	check(Gauge.trail_at(hit,1.525)>50 and Gauge.trail_at(hit,1.525)<75,"cubic ease out")
	check(is_equal_approx(Gauge.trail_at(hit,1.7),50),"trail completed by .7")
	check(Gauge.observe(h,"unit",80,false,1.8).from==80,"healing has no trail")
	check(Gauge.observe(h,"unit",20,true,2).from==20,"reduced immediate")
	check(Gauge.observe(h,"unit",0,false,3).from==0,"KO is empty")
	for dim in [Vector2i(360,780),Vector2i(390,664),Vector2i(390,844),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		for reduced in [false,true]:
			var s=fixture();s.motion_reduced=reduced
			var tag="%dx%d%s"%[dim.x,dim.y,"-reduced" if reduced else ""]
			var before=s.state.snapshot()
			Gauge.observe(s.resource_history,"hildegard",90,false)
			Gauge.observe(s.resource_history,"hildegard",62,reduced)
			s._rebuild();assert_readouts(s)
			check(s.state.snapshot()==before,"drawing preserves battle + rng "+tag)
			check(s._phase_thresholds(s.state.data.enemies[0])==[s.state.dungeon_enemy_r21.rules.catalog.tune.boss.phase_hp],"source phase threshold "+tag)
			await capture("states-"+tag)
			s.pending_action="attack";s._rebuild();await capture("target-"+tag)
			s.pending_action="";s.ally_open="bargut";s._rebuild();await capture("status-"+tag)
			s.ally_open="berenga";s._rebuild();await capture("status-ko-"+tag)
			s.ally_open="";s.items_open=true;s.pending_action="item:hp_s";s.state.inventory.hp_s=2;s.state.selected_ally="bargut";s.supply_target_set=true;s._rebuild();await capture("supply-target-"+tag)
			s.items_open=false;s.pending_action="";s.state.ally("bargut").hp=93;s._rebuild();await capture("shield-cap-"+tag)
			root.remove_child(s);s.queue_free();await settle()
	# The same live battle component: three exact sampled animation frames.
	root.content_scale_size=Vector2i(390,844);root.size=Vector2i(390,844)
	var s=fixture();s.motion_reduced=false
	for sample in [0.0,.4,.7]:
		var exact=Gauge.trail_at({"value":62,"from":90,"at":0},sample)
		s.resource_history.hildegard={"value":62,"from":exact,"at":Gauge.now()+10}
		s._rebuild()
		# Freeze clock samples by reading them explicitly into the rendering journal.
		var value=Gauge.trail_at(s.resource_history.hildegard,Gauge.now())
		for gauge in s.find_children("*","Control",true,false):
			if gauge is Gauge and gauge.current==62 and gauge.maximum==118:
				gauge.journal={"value":62,"from":value,"at":Gauge.now()+10};gauge.set_process(false);gauge.queue_redraw()
		readings.append({"seconds":sample,"current":62,"trail":value})
		await capture("trail-%.1f"%sample)
	var before_hit=s._capture_visual_before();s.state.ally("hildegard").hp=40
	var snapshot=s.state.snapshot();s._motion_impact(before_hit,"executor","enemy")
	check(s.resource_history.hildegard.value==40 and s.resource_history.hildegard.from>=62,"impact callback starts trail from previous display")
	check(s.state.snapshot()==snapshot,"impact presentation does not mutate combat/rng")
	root.remove_child(s);s.queue_free();await settle()
	# Wall-clock capture of the running component, without a frozen journal.
	s=fixture();s.motion_reduced=false
	var started=Gauge.now();s.resource_history.hildegard={"value":62,"from":90,"at":started};s._rebuild()
	for sample in [0.0,.4,.7]:
		while Gauge.now()-started<sample:await process_frame
		await RenderingServer.frame_post_draw
		var elapsed=Gauge.now()-started
		var filename="live-trail-%.1f.png"%sample
		check(root.get_texture().get_image().save_png(folder+"/"+filename)==OK,"live trail frame "+filename);captures.append(filename)
		readings.append({"live_requested_seconds":sample,"actual_seconds":elapsed,"current":62,"trail":Gauge.trail_at(s.resource_history.hildegard,started+elapsed)})
	root.remove_child(s);s.queue_free();await settle()
	# Cover all existing town resource surfaces, preserving real stored values.
	var host=Host.new();host.size=Vector2(390,844);host.storage.path="user://hp-r24-test.json";root.add_child(host);await settle()
	host.model=Host.World.new();host.model.seed_source=func():return 4242
	host.model.create_action("race_human");host.model.create_action("nat_border");host.model.create_action("cls_warrior");host.model.create_action("auto");host.model.create_action("done");host.model.create_action("pick_teiris","sc");host.model.create_action("go","sc")
	host.model.s.owned=["hildegard","bargut","teiris","berenga"];host.model.s.party=host.model.s.owned.duplicate();host.model.s.persona.fight=0;host.model.s.dialogue_r21.queue=[];host.model._clamp_members();host.motion_reduced=true
	for page in ["member","equipment","depart","status","codex"]:
		host.who="hildegard";host.go(page);await settle();await capture("world-"+page)
	host.model.s.items.hp_s=2;host.go("bag");host.selected_item="hp_s";host.selected_target="hildegard";host._draw_screen();await capture("world-item-target")
	host.selected_item="";host.selected_target="";host.model.depart_dungeon(1,123);host.model.s.dialogue_r21.queue=[];host.go("explore");await settle()
	for sc in host.town_view.find_children("*","ScrollContainer",true,false):sc.scroll_vertical=100000
	await capture("world-explore")
	root.remove_child(host);host.queue_free();await settle()
	var file=FileAccess.open(folder+"/hp-results.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"trail_frames":readings},"  "));file.close()
	print("HP R24 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)


