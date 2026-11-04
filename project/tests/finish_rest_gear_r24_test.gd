extends "res://tests/finish_r24_test.gd"
func _initialize():
	create_timer(90).timeout.connect(func():push_error("rest gear watchdog");quit(98));call_deferred("run")
func setup_row(f):
	var w=ready_world();var g=f.G;w.s.settings={"lang":f.lang}
	w.s.persona.name=g.persona.name;w.s.owned=g.roster.duplicate();w.s.party=g.party.duplicate()
	set_level(w,"persona",int(g.persona.lv));set_level(w,"teiris",int(g.lvl.teiris))
	w.s.gear=[];w.s.serial=0;w.s.equipment.persona={};w.s.equipment.teiris={}
	var imported=Save.new().import_codes(w.s,{"bag":";".join(f.bag),"equip":g.equip})
	check(imported.ok,"rest fixture import");w.s=imported.state
	check(w.depart_dungeon(1,7),"rest fixture departure")
	w.s.run.phase=g.dungeon.run.phase;w.s.run.last=g.dungeon.run.last;w.s.ui.sel="ex:"+str(int(g.dungeon.run.sel))
	return w
func rest_observe(w):
	var eq={"persona":{},"teiris":{}}
	for who in eq:
		for slot in w.s.equipment.get(who,{}):eq[who][slot]=w.gear.code(w.gear_entry(int(w.s.equipment[who][slot])))
	return {"bag":source_bag(w),"equip":eq,"gold":w.s.gold}
func rest_equipment(g):
	var eq={"persona":{},"teiris":{}}
	for who in eq:
		if not g.get(who) is Dictionary:continue
		for slot in g[who]:
			if g[who][slot]!="":eq[who][slot]=g[who][slot]
	return eq
func visible(entries):
	var words=[];var buttons=[]
	for e in entries:
		words.append(e.text)
		if e.get("sub","")!="":words.append(e.sub)
		if e.has("action"):buttons.append({"id":e.action,"text":e.text+(" "+e.sub if e.get("sub","")!="" else ""),"disabled":not e.enabled,"selected":e.get("selected",false)})
	return {"text":plain24(" ".join(words)),"buttons":buttons}
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round4/expe-oracle.json"));var observations=[]
	var first={}
	for f in oracle.views:
		var w=setup_row(f);var actual=visible(w.source_expedition_view("gear_card"))
		if actual.text!=f.text and failures.size()<3:print("REST DIFF ",actual.text," EXPECT ",f.text)
		eqcheck("rest/gear/copy",actual.text,f.text);eqcheck("rest/gear/buttons",actual.buttons,f.buttons)
		eqcheck("rest/gear/normalized_selection",w.expedition_equipment_slot(),f.R.sel)
	for f in oracle.actions:
		var w=setup_row(f);w.expedition_equipment_action(f.arg)
		var expected={"bag":f.after_bag,"equip":rest_equipment(f.after.equip),"gold":w.s.gold}
		if rest_observe(w)!=expected and not first.has("action"):
			first.action=true;print("REST ACTION DIFF ",f.arg," ACTUAL ",rest_observe(w)," EXPECT ",expected)
		eqcheck("rest/gear/action",rest_observe(w),expected)
		eqcheck("rest/gear/action_selection",w.expedition_equipment_slot(),f.after.dungeon.run.sel)
		eqcheck("rest/gear/action_message",w.s.run.last,f.after.dungeon.run.last)
		observations.append({"arg":f.arg,"phase":f.G.dungeon.run.phase,"last":w.s.run.last})
		if f.G.dungeon.run.phase=="rest":
			var next=World.new();check(next.restore(JSON.parse_string(JSON.stringify(w.s))),"rest gear real save resume")
			eqcheck("rest/gear/resume",rest_observe(next),rest_observe(w));eqcheck("rest/gear/selection_resume",next.expedition_equipment_slot(),w.expedition_equipment_slot())
	FileAccess.open("res://../verification/finish-r24/round4/rest-gear-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts,"actions":observations}))
	print("FINISH REST GEAR CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
