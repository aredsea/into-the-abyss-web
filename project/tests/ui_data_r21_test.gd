extends SceneTree
const World=preload("res://game/dungeon_world_r21.gd")
const Screen=preload("res://ui/battle_screen.gd")
const Town=preload("res://ui/world_screen.gd")
var checks=0
var failures=[]
var overflow=0
var names=0
var folder=ProjectSettings.globalize_path("res://../verification/data-r21")
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<=12: push_error(msg)
func _initialize(): call_deferred("run")
func run():
	for width in [390,360]:
		root.content_scale_size=Vector2i(width,844); root.size=Vector2i(width,844)
		var w=World.new(); w.s.dungeon_r21.best=54; w.depart_dungeon(55,20261031)
		w.s.run.phase="battle"
		var data=w.battle_data()
		# All source names, including deep prefix, in every r20 nameplate width.
		for count in [4,5,7]:
			var enc=data.encounter_r21.enc; enc.fl=[]; enc.fg=[]; enc.ne=count
			for i in range(count): enc.fl.append("apprentice_doll"); enc.fg.append("")
			data.enemies=w.make_enemies(data.encounter_r21,data.allies)
			var s=Screen.new(); s.session_data=data; s.session_save=func(_x):return OK
			root.add_child(s)
			await process_frame; await process_frame; await process_frame
			print("UI_R21 ready ",width,"/",count," tree=",s.is_inside_tree()," ready=",s.is_node_ready()," state=",s.state!=null)
			if s.state==null: check(false,"screen failed to initialize"); quit(1); return
			s.motion_reduced=true; s.set_process(false)
			for f in w.dungeon_rules.catalog.enemies:
				for e in s.state.data.enemies: e.name="깊은 "+f.name
				s._rebuild(); names+=count
				for e in s.state.data.enemies:
					var hud=s.enemy_visuals[e.id].hud
					var labels=hud.find_children("*","Label",true,false)
					for label in labels:
						var face=label.get_theme_font("font"); var size=label.get_theme_font_size("font_size")
						var needed=face.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x*label.scale.x
						var available=hud.size.x-6
						if needed>available+.1: overflow+=1
						check(needed<=available+.1,"name/HP overflow %d/%d/%s"%[width,count,f.id])
					check(labels[0].tooltip_text=="깊은 "+f.name,"canonical tooltip")
				await process_frame
			for e in s.state.data.enemies: e.name="깊은 제국 근위대의 잔해"
			s._rebuild(); await process_frame; await process_frame; await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(folder+"/battle-%d-%d.png"%[width,count])==OK,"screenshot")
			root.remove_child(s); s.queue_free(); await process_frame
		var town=Town.new(); town.size=Vector2(width,844); town.storage.path="user://data-r21-ui-test.json"; root.add_child(town)
		await process_frame; town.model=World.new(); town.go("depart")
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		check(town.controls.has("dungeon_floor") and town.controls.has("start_run"),"dungeon selector entry")
		root.get_texture().get_image().save_png(folder+"/selector-%d.png"%width)
		town.model.depart_dungeon(1,117); town.go("explore")
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder+"/explore-%d.png"%width)
		root.remove_child(town); town.queue_free(); await process_frame
	var report={"checks":checks,"failures":failures.size(),"details":failures,"widths":[390,360],"source_names":100,"nameplates":names,"overflow":overflow}
	FileAccess.open(folder+"/ui-results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("UI_DATA_R21 checks=%d failures=%d nameplates=%d overflow=%d"%[checks,failures.size(),names,overflow]); quit(0 if failures.is_empty() else 1)
