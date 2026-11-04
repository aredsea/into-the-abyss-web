extends "res://tests/ui_expedition_r22_test.gd"
const Core=preload("res://tests/expe_pass5_r23_test.gd")
var core=Core.new()
var observations=[]
func collect(node: Node,out: Array) -> void:
	if node.has_meta("expe_entry"):
		var e=node.get_meta("expe_entry").duplicate(true)
		if node is Label or node is Button:
			check(node.get_meta("source_copy_r24",node.text)==e.text,"rendered source text is intact")
			if node.has_meta("source_copy_r24"):
				check(node.get_children().filter(func(c):return c is TextureRect and c.texture.resource_path.ends_with("/star.svg")).size()==e.text.count("★"),"each source star is rendered by the approved vector icon")
			if node is Button:check(node.disabled==not e.enabled,"source button activation rendered")
		out.append(e)
	for child in node.get_children():collect(child,out)
func observe(s,kind: String):
	var observed=[];collect(s.town_view,observed)
	var items={}
	for key in s.model.s.items:items[s.model.source_item_id(key)]=s.model.s.items[key]
	var g={"items":items,"persona":s.model.s.persona.duplicate(true),"dungeon":s.model.s.dungeon_r21.duplicate(true),"lang":Llang(s)}
	var r=s.model.source_expedition_state() if kind!="sortie" else {}
	var expected=[]
	if kind=="sortie":
		for section in ["cards","summary"]:expected.append_array(s.model.source_sortie_view(section))
		g.merge({"roster":s.model.s.owned.duplicate(),"party":s.model.s.party.duplicate(),"lvl":{},"exp":{},"aff":{},"ui":s.model.s.ui.duplicate(true)})
		for id in g.roster:g.lvl[id]=s.model.s.members[id].level;g.exp[id]=s.model.s.members[id].xp;g.aff[id]=s.model.s.members[id].aff
		g.dungeon.sel=s.model.selected_floor
	else:
		for section in (["head","last","party"] if kind=="explore" else [kind]):expected.append_array(s.model.source_expedition_view(section))
		if kind=="explore" and r.phase=="rest":expected.append_array(s.model.source_expedition_view("gear_card"))
	check(core.helper.same(observed,expected),"actual painted source entries in order "+kind+" "+Llang(s))
	observations.append({"kind":kind,"lang":Llang(s),"G":g,"R":r.duplicate(true),"visible":core.project(observed)})
func Llang(s) -> String:return s.model.ExpeditionText.language(s.model.s)
func run():
	folder="res://../verification/parity-r23/expe-pass5-render";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var specimens={}
	for dim in [Vector2i(360,780),Vector2i(390,844)]:
		root.content_scale_size=dim;root.size=dim
		for lang in ["ko","en"]:
			var s=Screen.new();s.size=dim;s.storage.path="user://expe-pass5-%s-%dx%d-%d.json"%[lang,dim.x,dim.y,OS.get_process_id()]
			root.add_child(s);s.model=ready_world();s.motion_reduced=true
			var w=s.model;w.s.settings={"lang":lang};w.s.persona.name="가온"
			w.s.ui.sel="sortie:dungeon" # The oracle's selected-floor plan is dungeon mode.
			await show(s,"depart");observe(s,"sortie");await capture(s,"sortie-"+lang,dim)
			w.depart_dungeon(1,6);w.s.run.gold=21;w.s.run.xp=55;w.s.run.loot_items.hp_s=2;w.s.items.mp_s=1;w.s.items.hp_l=1;w.s.members.persona.hp=1;w.s.members.persona.mp=0
			w.s.run.last="A&B <tag> \"quotes\""
			await show(s,"explore");observe(s,"explore");await capture(s,"explore-"+lang,dim)
			# A source row's actual native button consumes the exploration pouch first.
			await click(s,"ex_u_hp_s_1");check(w.s.run.loot_items.hp_s==1 and w.s.members.persona.hp>1,"source potion control changes correct member and pouch")
			await click(s,"retreat");observe(s,"retreat");await capture(s,"retreat-"+lang,dim)
			var save=w.s.duplicate(true);var restored=ready_world();check(restored.restore(save),"source prompt full native save resumes")
			s.model=restored;s.confirm={};await show(s,"explore");observe(s,"retreat");await click(s,"cancel")
			check(not restored.s.run.ask,"source cancel survives save resume")
			restored.s.run.step=5;restored.enter_dungeon_rest();await show(s,"explore");observe(s,"explore");await capture(s,"rest-"+lang,dim)
			await click(s,"retreat");await click(s,"accept");check(not restored.active(),"source confirmation settles run")
			await show(s,"summary");observe(s,"done");await capture(s,"done-"+lang,dim)
			specimens[lang+str(dim.x)]=restored.s.duplicate(true)
			var clone=ready_world();check(clone.restore(restored.s.duplicate(true)),"settlement full save resumes")
			check(not clone.settle("retreat") and core.helper.same(clone.s,restored.s),"settlement replay has no observable mutation")
			s.queue_free();await process_frame;await process_frame
	FileAccess.open("res://../verification/parity-r23/expe-pass5-ui-observations.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"  "))
	FileAccess.open("res://../verification/parity-r23/expe-pass5-cloud-save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(specimens,"  "))
	FileAccess.open("res://../verification/parity-r23/expe-pass5-ui-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"  "))
	print("EXPE PASS5 UI CHECKS ",checks," FAILURES ",failures.size()," CAPTURES ",captures.size())
	core.helper.helper.free();core.helper.free();core.free();quit(0 if failures.is_empty() else 1)
