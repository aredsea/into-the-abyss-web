extends SceneTree
const Screen=preload("res://ui/battle_screen.gd")
const World=preload("res://game/settings_world_r22.gd")
const Visual=preload("res://ui/persona_visual_adapter.gd")
const WorldScreen=preload("res://ui/world_screen.gd")
var checks=0
var failures=[]
var captures=[]
var observed={}
var overflow=[]
var folder="res://../verification/data-r21/a8-ui"
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		if failures.size()<25:push_error(msg)
		failures.append(msg)
func _initialize():call_deferred("run")
func click(s,id: String):
	check(s.controls.has(id),"control "+id)
	if not s.controls.has(id):return
	var point=Vector2.ZERO
	if s.controls[id] is Control:point=s.controls[id].get_global_rect().get_center()
	else:
		var r=s.controls[id].rect;point=Vector2(r[0]+r[2]/2,r[1]+r[3]/2)
	var node=s.find_child(id.replace(":","_"),true,false)
	if is_instance_valid(node):point=node.get_global_rect().get_center()
	for down in [true,false]:
		var e=InputEventMouseButton.new();e.position=point;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=down;root.push_input(e)
	await process_frame;await process_frame
func capture(s,tag: String,save=true):
	await process_frame;await RenderingServer.frame_post_draw
	for metric in s.text_metrics:
		observed[metric.text]=true
		check(metric.missing_glyphs.is_empty(),"glyph "+metric.text)
		if metric.needed>metric.available+.6:overflow.append({"tag":tag,"metric":metric})
		check(metric.needed<=metric.available+.6,"overflow "+tag+" "+metric.text+" "+str(metric.needed)+" / "+str(metric.available))
	if save:
		var name=tag+".png";check(root.get_texture().get_image().save_png(folder+"/"+name)==OK,"capture "+name);captures.append(name)
func fixture(c: Dictionary,combo: Array,lang: String):
	var w=World.new();w.s.scene="town";w.s.creation_r22={"complete":true,"legacy":true};w.s.persona.cls=c.name;w.s.persona.stats=c.base.duplicate(true);w.s.persona.lv=10;w.s.members.persona.level=10
	w.s.persona.skill={"prefix":combo[0],"suffix":combo[1],"prefix_lv":{combo[0]:10},"suffix_lv":{combo[1]:10}}
	w.s.owned=["felice","naran","sorel"];w.s.party=w.s.owned.duplicate();w.s.settings.lang=lang
	for id in w.s.owned:w.s.members[id].level=10
	w.depart_dungeon(1,12345);w.s.run.phase="battle"
	var s=Screen.new();s.session_data=w.battle_data();s.session_save=func(_v):return OK
	s.size=root.size;root.add_child(s);s.motion_reduced=true;s.busy=false;s.state.current_id="persona";s.state.last_ally="persona";s.state.selected_ally="persona"
	s.state.ally("persona").mp=s.state.ally("persona").mmp
	s.state.inventory={"hp_s":3,"mp_s":3,"bandage":1};s._rebuild()
	return s
func run():
	Visual.prepare();DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var config=JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	var combos=[["strike","bane"],["sweep","tempo"],["rend","bleed"],["element","abyss"],["element","weaken"],["mend","regen"],["balm","guard"],["ward","crit"],["bulwark","regen"]]
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		for index in range(config.classes.size()):
			var c=config.classes[index];var s=fixture(c,combos[index%combos.size()],"en")
			var tag="%s-%dx%d"%[c.id,dim.x,dim.y]
			await capture(s,tag+"-base")
			s._toggle_skills();await capture(s,tag+"-skills");s._close_sheets()
			await click(s,"ally:persona");await capture(s,tag+"-status");s._close_sheets()
			await click(s,"supplies");await capture(s,tag+"-supplies");s._close_sheets()
			s.display_history=[{"turn":1,"actor":"persona","name":s.state.ally("persona").name,"action":s.state.ally("persona").skills.personal.name}]
			await click(s,"log");await capture(s,tag+"-log");s._close_sheets()
			if dim==Vector2i(360,780):
				s._toggle_skills();await process_frame
				var personal=s.find_child("skill_personal",true,false)
				if is_instance_valid(personal):
					personal.get_parent().get_parent().ensure_control_visible(personal);await process_frame;await process_frame
				await click(s,"skill:personal")
				var target=s.state.ally("persona").skills.personal.target
				if target=="적 1":await click(s,"enemy:"+s.state.selected_enemy)
				elif target=="아군 1":await click(s,"ally:persona")
				check(s.state.turn_count==1,"persona pointer skill "+c.id)
				await process_frame;await process_frame
				if is_instance_valid(s.motion) and is_instance_valid(s.motion.signature):
					var signature=s.motion.signature
					check(signature.heading.text.contains("\n") or signature.heading.text.length()>0,"persona cut title")
					check(signature.art.name==s.state.ally("persona").name,"persona cut actor")
				await capture(s,tag+"-cut")
			root.remove_child(s);s.queue_free();await process_frame
	# Full prefix/suffix coverage at the minimum viewport without capturing duplicates.
	root.content_scale_size=Vector2i(360,780);root.size=Vector2i(360,780)
	for p in World.PersonaResearch.data.prefixes:
		for q in World.PersonaResearch.data.suffixes:
			if not World.PersonaResearch.compatible(p,q):continue
			var s=fixture(config.classes[0],[p.id,q.id],"en")
			await capture(s,"pair-"+p.id+"-"+q.id,false);s._toggle_skills();await capture(s,"pair-skills-"+p.id+"-"+q.id,false)
			root.remove_child(s);s.queue_free();await process_frame
	var town=WorldScreen.new();town.size=root.size;town.storage.path="user://a8-research-%d.json"%OS.get_process_id();root.add_child(town)
	town.model=World.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:town.model.create_action(arg)
	town.model.create_action("pick_teiris","sc");town.model.create_action("go","sc")
	town.model.s.gold=10000;town.screen="research";town.who="teiris";town._draw_screen()
	var old_slots=town.model.s.research.duplicate(true)
	await click(town,"research_editor");check(town.research_edit and town.who=="persona","actual research entry targets single persona")
	for kind in ["prefixes","suffixes"]:
		var pick=town.controls["ps_part:"+kind];pick.select(1);pick.item_selected.emit(1);await process_frame;await process_frame
	await click(town,"ps_up:prefix");check(town.model.s.persona_research_r22.spent==60,"research pointer immediate cost")
	await click(town,"ps_save");check(town.model.PersonaResearch.ready(town.model.s.persona.skill),"research pointer confirms persona skill")
	check(town.model.s.research==old_slots,"research UI preserves companion slots")
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder+"/research-360x780.png")==OK,"research capture");captures.append("research-360x780.png")
	root.remove_child(town);town.queue_free();await process_frame
	FileAccess.open("res://../verification/data-r21/a8-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"overflow":overflow,"captures":captures,"observed":observed.keys()},"\t"))
	print("COMBAT A8 UI CHECKS ",checks," FAILURES ",failures.size()," OVERFLOW ",overflow.size()," CAPTURES ",captures.size());quit(0 if failures.is_empty() else 1)
