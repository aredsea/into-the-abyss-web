extends "res://tests/gear_r23_test.gd"
const PanelState=preload("res://game/panels_state_r22.gd")
func source_equipment(w) -> Dictionary:
	var out={}
	for cid in ["persona","hildegard"]:
		out[cid]={}
		for slot in w.s.equipment.get(cid,{}):out[cid][slot]=w.gear.code(w.gear_entry(int(w.s.equipment[cid][slot])))
	return out
func source_bag(w) -> Array:
	return w.s.gear.filter(func(e):return w.wearer(int(e.uid))=="").map(func(e):return w.gear.code(e))
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-round2-oracle.json"))
	var r=GearRules.new();var smith=World.new().gear
	for method in ["work_of","work_note","work_cut","work_gear_label"]:check(smith.has_method(method),"source helper missing: "+method)
	if smith.has_method("work_note"):
		for f in o.work:
			var actual=smith.work_of(f.input)
			eqcheck("work_of",nul(actual),f.value)
			if f.input is Dictionary and actual!=null:
				actual["identity_probe"]=true;check(f.input.has("identity_probe"),"work_of returns original table identity");f.input.erase("identity_probe")
		for f in o.notes:
			var note=smith.work_note(f.work)
			if counts.get("work_note",0)==0:FileAccess.open("res://../verification/parity-r23/round2-note-probe.json",FileAccess.WRITE).store_string(JSON.stringify({"actual":note,"expected":f.value,"work":f.work},"  "))
			eqcheck("work_note",note,f.value)
		for f in o.cut:eqcheck("work_cut",smith.work_cut(f.input,func(x):return x),f.value)
		for f in o.labels:eqcheck("work_gear_label",smith.work_gear_label(f.code),f.value)
	for f in o.transactions:
		for cid in f.game.equip:
			if f.game.equip[cid] is Array:f.game.equip[cid]={}
		for cid in f.value.equip:
			if f.value.equip[cid] is Array:f.value.equip[cid]={}
		var g=f.game.duplicate(true);var bag=f.bag.duplicate();var result=r.callv(f.method,[g,bag]+f.args)
		eqcheck("source_transaction_result",result if result is Array else [nul(result)],f.result)
		eqcheck("source_transaction_state",g,f.value);eqcheck("source_transaction_bag",bag,f.after)
		var w=ready_world();w.s.owned=["hildegard"];w.s.party=[];w.s.gear=[];w.s.serial=0;w.s.gold=f.game.gold
		set_level(w,"persona",40);set_level(w,"hildegard",40);w.s.equipment.persona={};w.s.equipment.hildegard={}
		for code in f.bag:
			w.s.serial+=1;w.s.gear.append(w.combat_gear_adapter.entry(code,w.s.serial))
		for cid in f.game.equip:
			for slot in f.game.equip[cid]:
				var code=f.game.equip[cid][slot]
				if code=="":continue
				w.s.serial+=1;w.s.gear.append(w.combat_gear_adapter.entry(code,w.s.serial));w.s.equipment[cid][slot]=w.s.serial
		var uid=0
		if f.method in ["gear_equip","gear_sell"]:
			var code=f.args[-1]
			# Native callers choose a UID. Choose the first bag match; use a worn
			# match only to verify that an absent bag entry is rejected.
			for e in w.s.gear:
				if w.gear.code(e)==code and w.wearer(int(e.uid))=="":uid=e.uid;break
			if uid==0:
				for e in w.s.gear:
					if w.gear.code(e)==code:uid=e.uid;break
		var ok=false
		if f.method=="gear_equip":ok=w.equip(f.args[0],uid)
		elif f.method=="gear_unequip":ok=w.unequip(f.args[0],f.args[1])
		elif f.method=="gear_sell":ok=w.sell_gear(uid)
		elif f.method=="gear_sell_common":
			var panel=PanelState.new(w);panel.bg_action("sellc");ok=true
		if f.method!="gear_sell_common":eqcheck("native_transaction_result",ok,f.result[0])
		eqcheck("native_transaction_gold",w.s.gold,f.value.gold)
		var actual=source_bag(w);var expected=f.after.duplicate();actual.sort();expected.sort()
		eqcheck("native_transaction_bag",actual,expected)
		var eq=f.value.equip.duplicate(true)
		for cid in ["persona","hildegard"]:
			if not eq.has(cid):eq[cid]={}
		for cid in eq:
			if eq[cid] is Array:eq[cid]={}
			for slot in eq[cid].keys():
				if eq[cid][slot]=="":eq[cid].erase(slot)
		eqcheck("native_transaction_equipment",source_equipment(w),eq)
		# Actual native save resume for each transaction, preserving all UIDs.
		var reloaded=World.new();var persisted=JSON.parse_string(JSON.stringify(w.s))
		check(reloaded.restore(persisted),"transaction restore "+f.method)
		if not same([reloaded.s.gold,source_bag(reloaded),source_equipment(reloaded)],[w.s.gold,source_bag(w),source_equipment(w)]):
			FileAccess.open("res://../verification/parity-r23/round2-resume-mismatch.json",FileAccess.WRITE).store_string(JSON.stringify({"source":f,"before":w.s,"after":reloaded.s},"  "))
		eqcheck("native_transaction_resume",[reloaded.s.gold,source_bag(reloaded),source_equipment(reloaded)],[w.s.gold,source_bag(w),source_equipment(w)])
	var w=ready_world();w.facility="smithy"
	w.smithy_work=[{"kind":"forge","code":"wa01.1.1","name":"fixture","success":true,"level":1}]
	check(w.complete_smithy(),"complete creates receipt")
	check(w.receipt.has("source_note"),"receipt retains original source work note")
	if w.receipt.has("source_note"):eqcheck("receipt_note",w.receipt.source_note,o.notes.filter(func(f):return f.work.forge.size()==1 and f.work.proc.size()==0 and f.work.forge[0].ok)[0].value)
	FileAccess.open("res://../verification/parity-r23/round2-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts},"  "))
	print("GEAR R23 ROUND2 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
