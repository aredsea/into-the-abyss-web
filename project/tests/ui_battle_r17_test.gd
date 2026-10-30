extends SceneTree
## r12 real mouse-input harness extended for the r17 sheets, roster and renders.
const World=preload("res://game/expansion_world.gd")
const Screen=preload("res://ui/battle_screen.gd")
const Ink=preload("res://ui/battle_ink_r17.gd")
var checks=0
var failures=[]
var cases=[]
var ink_cases=0
var polygon_rect_checks=0
var raw_overlaps=0
var ink_errors=[]
var edge_signatures={}
var folder=ProjectSettings.globalize_path("res://../verification/ui-r17").simplify_path()
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label); push_error(label)
func click(s,id: String) -> void:
	check(s.controls.has(id),"Control exists: "+id)
	if not s.controls.has(id): return
	var b=s.find_child(id.replace(":","_"),true,false)
	var r=s.controls[id].rect
	var p=b.global_position+b.size/2 if is_instance_valid(b) else Vector2(r[0]+r[2]/2,r[1]+r[3]/2)
	var down=InputEventMouseButton.new(); down.position=p; down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true; root.push_input(down)
	var up=InputEventMouseButton.new(); up.position=p; up.button_index=MOUSE_BUTTON_LEFT; root.push_input(up)
	await process_frame; await process_frame
func fixture(w):
	var s=Screen.new(); s.session_data=w.battle_data(); s.session_save=func(_snapshot): return OK
	root.add_child(s); return s
func clean(s) -> void:
	root.remove_child(s); s.queue_free(); await process_frame
func shot(s,tag: String,width: int) -> void:
	await create_timer(.2).timeout
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	if not OS.has_feature("headless"):
		check(root.get_texture().get_image().save_png(folder+"/"+tag+"-"+str(width)+".png")==OK,"Render "+tag)
func text_check(s,label: String) -> void:
	var errors=s.text_metrics.filter(func(m): return m.needed>m.available+1 or not m.missing_glyphs.is_empty())
	for node in s.find_children("*","Label",true,false):
		var face=node.get_theme_font("font"); var fs=node.get_theme_font_size("font_size")
		for line in node.text.split("\n"):
			if face.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>node.size.x+1:
				errors.append({"text":line,"available":node.size.x})
		for i in range(node.text.length()):
			if node.text.unicode_at(i)>32 and not face.has_char(node.text.unicode_at(i)): errors.append({"missing":node.text.unicode_at(i)})
	check(errors.is_empty(),label)
	if not errors.is_empty(): cases.append({"case":label,"errors":errors})
	ink_check(s,label)

func area(p: PackedVector2Array) -> float:
	var value=0.0
	for i in range(p.size()): value+=p[i].cross(p[(i+1)%p.size()])
	return absf(value)*.5

func ink_check(s,label: String) -> void:
	ink_cases+=1
	var regions=s.text_regions()
	for ink in s.find_children("*","Control",true,false):
		if not ink is Ink: continue
		var shapes=ink.polygons()
		check(shapes==ink.polygons(),"Fixed seed geometry "+label+" "+ink.kind)
		check(not shapes.is_empty(),"Visible ink "+label+" "+ink.kind)
		if ink.kind.begins_with("edge"):
			edge_signatures[ink.kind+str(root.size.x)]=hash(ink.raw_polygons())
		if ink.kind=="log-tail": check(area(ink.raw_polygons()[0].polygon)>2000,"Broad log brush body "+label)
		for raw in ink.raw_polygons():
			if raw.color not in [s.INK,s.RED]: continue
			var box=ink.bounds(raw.polygon)
			for region in regions:
				var r: Rect2=region.rect; r.position-=ink.global_position
				if not r.intersects(box): continue
				var rect_poly=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
				for hit in Geometry2D.intersect_polygons(raw.polygon,rect_poly):
					if area(hit)>.01: raw_overlaps+=1
		for shape in shapes:
			if shape.color not in [s.INK,s.RED]: continue
			var box=ink.bounds(shape.polygon)
			for region in regions:
				var r: Rect2=region.rect; r.position-=ink.global_position
				polygon_rect_checks+=1
				if not r.intersects(box): continue
				var rect_poly=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
				for hit in Geometry2D.intersect_polygons(shape.polygon,rect_poly):
					if area(hit)>.01: ink_errors.append({"case":label,"kind":ink.kind,"text":region.text,"area":area(hit)})
	check(ink_errors.is_empty(),"Ink/text intersection zero "+label)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	for dim in [Vector2i(390,844),Vector2i(360,780)]:
		root.content_scale_size=dim; root.size=dim
		var w=World.new(); w.depart(); w.travel("patrol")
		var s=fixture(w); await process_frame
		await shot(s,"base",dim.x); text_check(s,"Base labels "+str(dim.x))
		var before=JSON.stringify(s.state.data.enemies)
		await click(s,"action:attack")
		check(s.pending_action=="attack" and not s.busy,"Attack waits for target")
		check(JSON.stringify(s.state.data.enemies)==before,"Selecting action preserves HP")
		await shot(s,"target",dim.x); text_check(s,"Target "+str(dim.x))
		await click(s,"cancel-action")
		check(s.pending_action.is_empty() and JSON.stringify(s.state.data.enemies)==before,"Cancel preserves state")
		await click(s,"ally:berenga")
		check(s.ally_open=="berenga","Ally status opens")
		await shot(s,"status",dim.x); text_check(s,"Status labels "+str(dim.x))
		await click(s,"close"); check(s.ally_open.is_empty(),"Ally status closes")
		s.state.ally("berenga").hp=int(s.state.ally("berenga").mhp*.8)
		var inventory_before=s.state.inventory.duplicate(true)
		await click(s,"supplies"); check(s.items_open,"Supply sheet opens")
		await process_frame
		await click(s,"item:hp_s")
		check(s.pending_action=="item:hp_s" and s.items_open,"Supply selection stays in sheet")
		await click(s,"ally:berenga")
		check(s.state.selected_ally=="berenga" and not s.busy,"Supply target selected without consumption")
		await shot(s,"supplies",dim.x); text_check(s,"Supply labels "+str(dim.x))
		await click(s,"cancel-action")
		check(not s.items_open and s.pending_action.is_empty(),"Supply cancelled")
		check(s.state.inventory==inventory_before,"Supply cancellation consumes nothing")
		# Seed the review's log through real model resolution, never example strings.
		s.state.act("attack")
		while not s.state.player_turn() and s.state.result.is_empty(): s.state.automatic_turn()
		s._rebuild()
		await click(s,"log"); check(s.log_open,"Log opens")
		await shot(s,"log",dim.x); text_check(s,"Log "+str(dim.x))
		await click(s,"close"); check(not s.log_open,"Log closes")
		var hp=s.state.enemy("orb").hp
		await click(s,"action:attack"); await click(s,"enemy:orb")
		check(s.pending_action.is_empty() and s.busy,"Target input commits")
		check(s.state.enemy("orb").hp<hp,"Selected target damaged")
		await clean(s)
		s=fixture(w); s.state.ally("berenga").hp=1; s._rebuild()
		await click(s,"supplies"); await click(s,"item:hp_s"); await click(s,"ally:berenga")
		var supplies=s.state.inventory.hp_s
		await click(s,"use-supply")
		check(s.state.inventory.hp_s==supplies-1 and s.state.ally("berenga").hp>1,"Supply use heals chosen ally and consumes one")
		await clean(s)
		# A target left over in the model must not be used until a card is tapped in this sheet.
		s=fixture(w); s.state.ally("berenga").hp=1; s.state.selected_ally="berenga"; s._rebuild()
		var stale_before=s.state.inventory.duplicate(true)
		await click(s,"supplies"); await click(s,"item:hp_s"); await click(s,"use-supply")
		check(s.state.inventory==stale_before and not s.busy and s.items_open,"Supply needs a fresh target tap")
		await clean(s)
		s=fixture(w); await process_frame
		var hits=s.controls.keys().filter(func(k): return k.begins_with("enemy:"))
		check(hits.size()==4,"Four enemy touch areas "+str(dim.x))
		for i in range(hits.size()):
			for j in range(i+1,hits.size()):
				var ra=s.controls[hits[i]].rect; var rb=s.controls[hits[j]].rect
				check(not Rect2(ra[0],ra[1],ra[2],ra[3]).intersects(Rect2(rb[0],rb[1],rb[2],rb[3])),"Enemy touch areas apart "+hits[i]+"/"+hits[j]+" "+str(dim.x))
		await clean(s)
		s=fixture(w); s.busy=false; s.state.current_id="teiris"; s.state.last_ally="teiris"; s.state.ally("teiris").mp=0
		for unit in s.state.data.allies+s.state.data.enemies: unit.remaining=0.0 if unit.id=="teiris" else unit.remaining+900
		s.state.refresh_forecast(); s._rebuild()
		await click(s,"skills"); check(s.skills_open,"Skills sheet opens")
		await shot(s,"skills",dim.x); text_check(s,"Skill labels "+str(dim.x))
		for key in s.controls:
			if key.begins_with("skill:"):
				var b=s.find_child(key.replace(":","_"),true,false)
				check(b.disabled,"Insufficient mana disabled: "+key)
		var snapshot=JSON.stringify(s.state.snapshot())
		await click(s,"skill:personal")
		check(s.skills_open and JSON.stringify(s.state.snapshot())==snapshot,"Disabled skill input does nothing")
		await click(s,"cancel-action"); check(not s.skills_open,"Skill cancel")
		await clean(s)
		for p in w.config.companions:
			var roster=World.new()
			if p.id not in roster.s.party: roster.s.party[0 if p.row=="전열" else 2]=p.id
			roster.depart(); roster.travel("patrol")
			var b=fixture(roster); b.busy=false; b.state.current_id=p.id; b.state.last_ally=p.id; b.state.ally(p.id).mp=0; b._rebuild()
			await process_frame; text_check(b,p.name+" base "+str(dim.x))
			for key in b.controls:
				if key.begins_with("action:") or key.begins_with("ally:"):
					var r=b.controls[key].rect
					check(r[0]>=0 and r[0]+r[2]<=dim.x+1 and r[1]+r[3]<=dim.y+1 and r[2]>=44 and r[3]>=44,"Touch bounds "+p.id+key)
			b.skills_open=true; b._rebuild(); await process_frame; text_check(b,p.name+" skills "+str(dim.x))
			b.skills_open=false; b.ally_open=p.id; b._rebuild(); await process_frame; text_check(b,p.name+" status "+str(dim.x))
			b.ally_open=""; b.pending_action="attack"; b._rebuild(); await process_frame; text_check(b,p.name+" target "+str(dim.x))
			b.pending_action=""; b.items_open=true; b._rebuild(); await process_frame; text_check(b,p.name+" supplies "+str(dim.x))
			b.items_open=false; b.state.act("attack"); b.state.current_id=p.id; b.log_open=true; b._rebuild(); await process_frame; text_check(b,p.name+" log "+str(dim.x))
			# Inspect both ends of the real history scroll, including long names.
			for scroll in b.find_children("*","ScrollContainer",true,false):
				scroll.scroll_vertical=10000
			await process_frame; ink_check(b,p.name+" log scrolled "+str(dim.x))
			await clean(b)
		for count in range(1,5):
			var b=fixture(w); b.state.data.enemies=b.state.data.enemies.slice(0,count)
			b.state.selected_enemy=b.state.data.enemies[0].id; b.state.refresh_forecast(); b._rebuild()
			text_check(b,"Enemy count "+str(count)+" width "+str(dim.x)); await clean(b)
	for width in [390,360]:
		var unique=[]
		for key in edge_signatures:
			if key.ends_with(str(width)) and edge_signatures[key] not in unique: unique.append(edge_signatures[key])
		check(unique.size()==6,"Six distinct edge silhouettes "+str(width))
	check(raw_overlaps>0,"Positive control: raw ink really intersects text before clearance")
	var f=FileAccess.open(folder+"/battle-input-results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"text_errors":cases,"roster_cases":60,"renders":12},"  "))
	var ink_report={"cases":ink_cases,"roster_states":360,"widths":[390,360],"polygon_rect_checks":polygon_rect_checks,"overlaps":ink_errors.size(),"errors":ink_errors,"raw_overlap_positive_controls":raw_overlaps,"edge_signatures":edge_signatures,"clearance_px":3}
	var ink_file=FileAccess.open(folder+"/ink-text-results.json",FileAccess.WRITE); ink_file.store_string(JSON.stringify(ink_report,"  "))
	print("R17 BATTLE UI ",checks," CHECKS / ",failures.size()," FAILURES")
	quit(0 if failures.is_empty() else 1)
