extends SceneTree
## Render-based verification: real Godot images, never synthetic effect mockups.
const World=preload("res://game/expansion_world.gd")
const Screen=preload("res://ui/battle_screen.gd")
const Original=preload("res://ui/character_sprite.gd")
const Body=preload("res://ui/battle_body_r18.gd")
const Presentation=preload("res://ui/combat_presentation.gd")
const Signature=preload("res://ui/signature_sequence.gd")
const Motion=preload("res://ui/motion_library.gd")
const WorldScreen=preload("res://ui/world_screen.gd")
var folder=ProjectSettings.globalize_path("res://../verification/ui-r18").simplify_path()
var checks=0
var failures=[]
var measurements=[]
var hashes={}
var contact_cases=0
var layout_cases=0
var text_cases=0
var cutin_intersections=0
var enemy_measurements=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func capture(path: String) -> Image:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	check(image.save_png(folder+"/"+path)==OK,"Save "+path)
	return image
func clear(node) -> void:
	node.get_parent().remove_child(node); node.queue_free(); await process_frame
func fixture(w):
	var s=Screen.new(); s.session_data=w.battle_data(); s.session_save=func(_x): return OK
	root.add_child(s); return s
func alpha_bounds(image: Image) -> Rect2i:
	var lo=Vector2i(image.get_width(),image.get_height()); var hi=Vector2i(-1,-1)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a>.1: lo=lo.min(Vector2i(x,y)); hi=hi.max(Vector2i(x,y))
	return Rect2i(lo,hi-lo+Vector2i.ONE)
func measure_body(id: String,dim: Vector2i,after: bool) -> Dictionary:
	var viewport=SubViewport.new(); viewport.size=Vector2i(300,300); viewport.transparent_bg=true; root.add_child(viewport)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var body=Body.new() if after else Original.new()
	body.idle_enabled=true
	if after: body.battle_pixels=true
	body.configure(id); viewport.add_child(body); body.set_process(false)
	var field_h=288 if dim.x==390 else 224
	body.size=Vector2(180,160 if dim.x==390 else 150) if after else Vector2(dim.x*.38,minf(145,field_h-128))
	body.position=Vector2(50,280-body.size.y)
	await process_frame; await RenderingServer.frame_post_draw
	var box=alpha_bounds(viewport.get_texture().get_image())
	var report={"id":id,"width":dim.x,"after":after,"visible_height":box.size.y,"visible_width":box.size.x,"box":[box.position.x,box.position.y,box.size.x,box.size.y]}
	await clear(viewport); return report
func label_checks(seq,width: int) -> void:
	text_cases+=1
	check(not seq.face_rect.intersects(seq.title_rect.grow(3)),"Face/title clearance "+seq.character_id+str(width))
	check(not seq.face_rect.intersects(seq.byline_rect.grow(3)),"Face/name clearance")
	check(not seq.title_rect.intersects(seq.byline_rect),"Title/name clearance")
	var shapes=seq.band_polygons()
	check(shapes==seq.band_polygons(),"Seeded cutin silhouette")
	var visible_ink=Geometry2D.clip_polygons(shapes[0],shapes[1])
	for label in [seq.heading,seq.byline]:
		var rect=Rect2(label.position,label.size).grow(3)
		var poly=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
		for patch in visible_ink:
			for intersection in Geometry2D.intersect_polygons(poly,patch):
				if intersection.size()>2: cutin_intersections+=1
		check(cutin_intersections==0,"Visible red brush/text intersection zero")
		var font=label.get_theme_font("font"); var fs=label.get_theme_font_size("font_size")
		for line in label.text.split("\n"):
			check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x<=label.size.x+1,"Cutin line fits "+line)
		for ch in label.text:
			check(ch=="\n" or ch==" " or font.has_char(ch.unicode_at(0)),"Cutin glyph "+ch)
		check(label.position.x+label.size.x<=width,"Cutin right edge")
		check(label.get_minimum_size().y<=label.size.y+1,"Cutin vertical fit "+label.text)
		# Decorative brush edges are outside a protected solid-ink interior.
		check(label.position.y>=seq.size.y*.46-58,"Brush upper clearance")
		check(label.position.y+label.get_minimum_size().y<seq.size.y*.46+62,"Brush lower clearance")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder+"/frames")
	DirAccess.make_dir_recursive_absolute(folder+"/previews")
	var w=World.new(); w.depart(); w.travel("patrol")
	var ids=w.config.companions.map(func(p):return p.id)
	for dim in [Vector2i(390,844),Vector2i(360,780)]:
		root.content_scale_size=dim; root.size=dim
		for id in ids:
			measurements.append(await measure_body(id,dim,false))
			var m=await measure_body(id,dim,true); measurements.append(m)
			check(m.visible_height>=140 and m.visible_height<=175,"Body height "+id+str(dim.x)+" = "+str(m.visible_height))
		var s=fixture(w); await process_frame
		await capture("base-"+str(dim.x)+".png")
		for e in s.state.data.enemies:
			var b=e.bbox; var shape=Vector2(b[2]-b[0],b[3]-b[1])
			var old_big=minf(103,65+((288 if dim.x==390 else 224)-224)*.594)
			var old_small=minf(75,(288 if dim.x==390 else 224)-old_big-91)
			var old_h=old_big if e.id=="executor" else old_small
			var old_w=119 if e.id=="executor" else minf(112,dim.x/3.0-4)
			var before_h=shape.y*minf(old_h/shape.y,old_w/shape.x)
			var node=s.enemy_visuals[e.id].node
			enemy_measurements.append({"id":e.id,"width":dim.x,"before_height":before_h,"after_height":node.size.y})
		# Every nonempty subset of all four enemies, rather than only prefixes.
		var all_enemies=s.state.data.enemies.duplicate(true)
		for mask in range(1,16):
			s.state.data.enemies=[]
			for i in range(4):
				if mask&(1<<i): s.state.data.enemies.append(all_enemies[i].duplicate(true))
			s._rebuild(); layout_cases+=1
			var rects=[]
			for key in s.controls:
				if key.begins_with("enemy:"):
					var a=s.controls[key].rect; var rect=Rect2(a[0],a[1],a[2],a[3])
					check(rect.size.x>=44 and rect.size.y>=44,"44px enemy touch")
					for previous in rects: check(not rect.intersects(previous),"Disjoint enemy plates")
					rects.append(rect)
			for metric in s.text_metrics: check(metric.needed<=metric.available+1 and metric.missing_glyphs.is_empty(),"Enemy subset text "+str(mask))
		await clear(s)
		for id in ids:
			var roster=World.new()
			var member=roster.config.companions.filter(func(p):return p.id==id)[0]
			if id not in roster.s.party: roster.s.party[0 if member.row=="전열" else 2]=id
			roster.depart(); roster.travel("patrol")
			s=fixture(roster); s.busy=true; s.animation_ally=id; s.state.current_id=id; s.state.last_ally=id; s._rebuild(); await process_frame
			for ally in s.state.data.allies: ally.hp=int(ally.mhp*.55); ally.mp=ally.mmp
			s.state.selected_ally=id; s.state.selected_enemy="executor"; s._rebuild()
			var before=s._capture_visual_before()
			check(s.state.act("personal"),"Real personal action "+id)
			s._present_action(before,id,"personal")
			var fx=s.motion; fx.set_process(false); fx.signature.set_process(false)
			if id=="hildegard": check(fx.targets==[fx.source_rect],"Frost guard stays on ally despite enemy intimidation change")
			check(fx.clock.duration+fx.clock.hitstop<=2.2,"Personal <=2.2s "+id)
			fx._process(.28)
			label_checks(fx.signature,dim.x)
			await capture("frames/"+id+"-cutin-"+str(dim.x)+".png")
			fx._process(fx.clock.impact_at-.28+fx.clock.hitstop+.06)
			await capture("frames/"+id+"-impact-"+str(dim.x)+".png")
			fx.skip(); await process_frame
			await clear(s)
		# Three genuine frame sequences at phone width for animated WebP delivery.
		if dim.x==360:
			for spec in [["teiris","personal"],["naran","personal"],["hildegard","attack"]]:
				var id=spec[0]; var action=spec[1]; var roster=World.new()
				if id not in roster.s.party: roster.s.party[0]=id
				roster.depart(); roster.travel("patrol"); s=fixture(roster)
				s.busy=true; s.animation_ally=id; s.state.current_id=id; s.state.last_ally=id; s.state.selected_enemy="executor"
				s.state.ally(id).mp=s.state.ally(id).mmp; s._rebuild()
				var before=s._capture_visual_before(); check(s.state.act(action),"Real preview action")
				s._present_action(before,id,action)
				var fx=s.motion; fx.set_process(false)
				var count=ceili((fx.clock.duration+fx.clock.hitstop)*20)+2
				for i in range(count):
					if is_instance_valid(fx): fx._process(.05 if i>0 else 0.0)
					await capture("previews/"+id+"-"+action+"-%03d.png"%i)
				await clear(s)
	# Effects-only framebuffer hashes exclude names, portraits and character art.
	# Exercise the unchanged world's real caller, including its completion hook.
	for dim in [Vector2i(390,844),Vector2i(360,780)]:
		root.content_scale_size=dim; root.size=dim
		var town=WorldScreen.new(); town.size=Vector2(dim); root.add_child(town)
		for id in ["naran","hildegard"]:
			town._show_art(id); await process_frame; await process_frame
			var sequences=town.art_preview.find_children("*","Control",true,false).filter(func(n):return n is Signature)
			check(sequences.size()==1,"World preview creates one signature")
			var seq=sequences[0]; seq.externally_timed=true; seq.elapsed=.28; seq.refresh()
			label_checks(seq,roundi(seq.size.x))
			await capture("world-preview-"+id+"-"+str(dim.x)+".png")
			seq.externally_timed=false; seq._process(seq.duration); await process_frame
			check(not is_instance_valid(seq),"World preview completes")
			town._close_art(); await process_frame
		await clear(town)
	root.content_scale_size=Vector2i(360,240); root.size=Vector2i(360,240)
	for id in ids:
		var surface=Node2D.new(); root.add_child(surface)
		var info=Body.info(id)
		surface.draw.connect(func(): Screen.CombatFX.paint(surface,info.element,info.fx,1.16,1.1,1.65,Rect2(10,80,100,140),[Rect2(210,60,100,140)],false,true,Rect2()))
		var image=await capture("frames/"+id+"-fx-only.png")
		var digest=HashingContext.new(); digest.start(HashingContext.HASH_SHA256); digest.update(image.get_data()); hashes[id]=digest.finish().hex_encode()
		await process_frame; surface.queue_redraw(); await process_frame; await RenderingServer.frame_post_draw
		check(image.get_data()==root.get_texture().get_image().get_data(),"Same time identical pixels "+id)
		await clear(surface)
	var unique={}
	for value in hashes.values(): unique[value]=true
	check(unique.size()==30,"Thirty different effect-only pixel hashes")
	# General attacks, all elements, supports and enemy use the same renderer.
	for element in ["ice","bolt","fire","holy","wind","dark","none"]:
		for action in ["attack","guard","taunt","item:hp_s","enemy"]:
			var fx=Presentation.new(); fx.character_id="hildegard"; fx.element=element; fx.action=action; fx.enemy_action=action=="enemy"
			fx.source_rect=Rect2(10,80,100,140); fx.targets=[Rect2(210,60,100,140)]; fx.hurt_targets=fx.targets; fx.damaging=action in ["attack","enemy"]
			root.add_child(fx); fx.set_process(false); fx.clock.elapsed=fx.clock.impact_at+.06; fx.clock.impacted=true; fx.queue_redraw()
			await capture("frames/general-"+action.replace(":","-")+"-"+element+".png"); await clear(fx)
	# Repeated skip before/after contact, including all 30 personal effects.
	for id in ids:
		for mode in ["skip_before","skip_after","reduced"]:
			var fx=Presentation.new(); fx.character_id=id; fx.action="personal"; fx.reduced=mode=="reduced"
			fx.field=Rect2(0,0,360,240); fx.source_rect=Rect2(10,80,100,140); root.add_child(fx); fx.set_process(false)
			contact_cases+=1
			if mode=="skip_before": fx.skip(); fx.skip()
			else:
				fx._process(fx.clock.impact_at-.001); check(fx.impact_count==0,"No early contact")
				fx._process(.001); check(fx.impact_count==1,"One contact")
				if mode=="reduced":
					check(fx.clock.duration==.36 and fx.clock.hitstop==0,"Short static reduced path")
					check(fx._step()==Vector2.ZERO and fx.shake_offset()==Vector2.ZERO and fx.reaction_offset()==Vector2.ZERO and not fx.hit_flash(),"No reduced movement/flash")
					fx.queue_redraw(); await capture("frames/reduced-"+id+".png")
				fx.skip(); fx.skip()
			check(fx.impact_count==1,"Repeated skip contact exactly once "+id+mode)
			await process_frame
	# Render a colored texture through the actual hit material: brightness
	# modulation cannot pass this white-silhouette positive control.
	var flash=Presentation.new(); flash.damaging=true; flash.source_rect=Rect2(10,30,100,160); root.add_child(flash); flash.set_process(false)
	flash._process(flash.clock.impact_at)
	check(flash.hit_flash(),"Flash begins at contact")
	var viewport=SubViewport.new(); viewport.size=Vector2i(24,24); viewport.transparent_bg=true; root.add_child(viewport)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var source=Image.create(24,24,false,Image.FORMAT_RGBA8); source.fill(Color(.8,.2,.1,1))
	var picture=TextureRect.new(); picture.texture=ImageTexture.create_from_image(source); picture.material=flash.hit_material; picture.size=Vector2(24,24); viewport.add_child(picture)
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	var white=viewport.get_texture().get_image().get_pixel(12,12)
	check(white.r>.99 and white.g>.99 and white.b>.99 and white.a>.99,"Rendered hit silhouette is white")
	check(not flash.hit_flash(),"Flash ends after two process frames, including hitstop")
	await clear(viewport); flash.skip(); await process_frame
	await create_timer(.3).timeout
	var report={"checks":checks,"failures":failures,"body_measurements":measurements,"enemy_measurements":enemy_measurements,"enemy_subset_layout_cases":layout_cases,"cutin_text_cases":text_cases,"cutin_foreground_intersections":cutin_intersections,"effect_only_sha256":hashes,"unique_effect_hashes":unique.size(),"contact_cases":contact_cases}
	var f=FileAccess.open(folder+"/r18-results.json",FileAccess.WRITE); f.store_string(JSON.stringify(report,"  ")); f.close()
	print("R18: ",checks," checks / ",failures.size()," failures; ",unique.size()," distinct effect hashes")
	quit(0 if failures.is_empty() else 1)
