extends "res://tests/ui_phase4_screens_r23_test.gd"
func run():
	var cases=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase4/ui-edges-oracle.json"))
	for c in cases:
		var w=fixture();var g=c.before.G;w.s.settings={"lang":"ko"};w.s.persona.cls=g.persona.cls;w.s.persona.name=g.persona.name;w.s.persona.lv=40;w.s.owned=["haldric"];w.s.party=[];w.s.members.persona.level=40;w.s.members.haldric.level=40;w.s.gear=[];w.s.gold=g.gold
		for cid in w.s.equipment:w.s.equipment[cid]={}
		for i in c.before.bag.size():w.s.gear.append(source_entry(w,c.before.bag[i],i+1))
		var old=g.equip.haldric.get("weapon","") if g.equip.haldric is Dictionary else ""
		if old!="":w.s.gear.append(source_entry(w,old,w.s.gear.size()+1));w.s.equipment.haldric={"weapon":w.s.gear.size()}
		w.s.serial=w.s.gear.size();w._clamp_members();var state=State.new(w);state.ui.sel="haldric";state.bg=g.ui.bg.duplicate()
		if c.kind.ends_with("_un"):state.unequip("haldric","weapon")
		else:state.bg_action("eq_haldric" if c.kind.ends_with("_equip") else "sell")
		var codes=[]
		for e in state.entries():codes.append(e.code)
		codes.sort();var expected=c.after.bag.duplicate();expected.sort();check(codes==expected,"P2539/P2593 "+c.kind+" bag multiplicity")
		var e=w.gear_entry(int(w.s.equipment.get("haldric",{}).get("weapon",0)));var actual=w.gear.code(e) if not e.is_empty() else ""
		check(actual==c.after.equipped,"P2539/P2593 "+c.kind+" equipped");check(w.s.gold==c.after.gold,"P2593 "+c.kind+" gold");check(state.ui.msg==c.after.msg,"P2539/P2593 "+c.kind+" notice got="+state.ui.msg+" expected="+c.after.msg);check(state.bg.sel==c.after.sel,"P2593 "+c.kind+" selection")
		state.persist();var store=preload("res://game/world_store.gd").new();store.path="user://ui-phase4-edge-"+c.kind+".json";check(store.write(w.s)==OK,"edge write");var resumed=World.new();check(store.read_into(resumed),"edge resume "+c.kind)
	FileAccess.open("res://../verification/parity-r23/ui-phase4/ui-edge-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"));print("UI PHASE4 EDGE CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
