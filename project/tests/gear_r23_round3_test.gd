extends "res://tests/gear_r23_test.gd"
var mismatches=[]
func eq3(group: String,a,b):
	if not same(a,b):mismatches.append({"group":group,"index":counts.get(group,0)+1,"actual":a,"expected":b})
	eqcheck(group,a,b)
func tagged(v):
	if v==null:return {"kind":"nil"}
	return {"kind":"boolean" if v is bool else "string" if v is String else "number","value":v}
func run():
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/gear-round3-oracle.json"))
	var r=GearRules.new();var smith=World.new().gear;var town=TownRules.new()
	for method in ["pct","fx_clear"]:check(smith.has_method(method),"missing source helper "+method)
	check(town.has_method("inn_act_visible"),"missing act_visible")
	check(town.has_method("aff_add_source"),"missing source affection callback boundary")
	if smith.has_method("pct"):
		for f in o.pct:eq3("pct",smith.pct(PackedByteArray(f.bytes).decode_double(0) if f.has("bytes") else f.input),f.value)
	if smith.has_method("fx_clear"):
		for f in o.fx:
			var g=f.input.duplicate(true);eqcheck("fx_return",tagged(smith.fx_clear(g)),f.result);eqcheck("fx_state",g,f.value)
	if town.has_method("inn_act_visible"):
		for f in o.visible:eqcheck("act_visible",town.call("inn_act_visible",f.game,f.act,f.cid),f.value)
	if town.has_method("aff_add_source"):
		for f in o.aff:
			var g=f.input.duplicate(true);var calls=[];var callback=Callable()
			if f.callback:callback=func(state,cid,a,b):calls.append({"same":is_same(state,g),"cid":cid,"before":a,"after":b})
			eqcheck("aff_result",town.call("aff_add_source",g,f.cid,f.amount,callback),f.result)
			eqcheck("aff_state",g,f.value);eq3("aff_callback",calls,f.calls)
	for f in o.restrict:
		var g=f.game.duplicate(true);var bag=f.bag.duplicate();eqcheck("restrict_return",tagged(r.gear_restrict(g,bag)),f.result)
		eqcheck("restrict_state",g,f.value);eqcheck("restrict_bag",r.bag_load(";".join(bag)),f.after)
		if not f.writes.is_empty():eqcheck("restrict_written_raw",";".join(bag),f.writes[-1].value)
	for f in o.transactions:
		var g=f.game.duplicate(true);var bag=f.bag.duplicate();var result=r.callv(f.method,[g,bag]+f.args);var tags=[]
		for v in result:tags.append(tagged(v))
		eqcheck("invalid_transaction_return",tags,f.result);eqcheck("invalid_transaction_state",g,f.value);eqcheck("invalid_transaction_bag",bag,f.after)
	for f in o.handlers:
		if f.scene!="inn" or f.mode==0:continue
		var parts=f.arg.split("_")
		if parts.size()!=2 or parts[0] not in ["talk","meal","gift","rest"] or parts[1]!="hildegard":continue
		var native=ready_world();native.s.owned=["hildegard"];native.s.gold=f.game.gold;native.s.day=f.game.town.day
		native.s.acts=f.game.town.acts.duplicate(true) if f.game.town.acts is Dictionary else {}
		native.s.members.hildegard.aff=f.game.aff.hildegard
		if f.mode==2:native.s.dialogue_r21.pending={"who":"hildegard"}
		native.inn("hildegard",parts[0])
		eqcheck("native_inn_gold",native.s.gold,f.value.gold);eqcheck("native_inn_day",native.s.day,f.value.town.day)
		eqcheck("native_inn_aff",native.s.members.hildegard.aff,f.value.aff.hildegard)
		eqcheck("native_inn_acts",native.s.acts,f.value.town.acts if f.value.town.acts is Dictionary else {})
	var w=ready_world();w.facility="smithy";w.smithy_fx={"kind":"forge","success":true};w.smithy_select("process")
	check(w.smithy_fx.is_empty(),"tab clears source and native effect state")
	check(w.smithy_source_fx.is_empty(),"source effect keys also removed")
	w.smithy_fx={"kind":"process","name":"fixture"};check(w.smithy_source_fx.has("proc_fx"),"process uses source proc_fx slot")
	w.smithy_fx={"kind":"forge","success":false};check(w.smithy_source_fx.has("forge_fx") and not w.smithy_source_fx.has("proc_fx"),"next forge replaces prior processing effect")
	w.smithy_fx={};check(w.smithy_source_fx.is_empty(),"empty native effect erases both source fields")
	FileAccess.open("res://../verification/parity-r23/round3-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts,"mismatches":mismatches},"  "))
	print("GEAR R23 ROUND3 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
