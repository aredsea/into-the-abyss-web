extends SceneTree
## Diagnostic only: a known gap must remain a gap in the parity ledger.
func _initialize():call_deferred("run")
func run():
	var w=preload("res://game/settings_world_r22.gd").new()
	for action in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(action)
	w.seed_source=func():return 4242
	w.create_action("pick_teiris","sc");w.create_action("go","sc");w.s.dialogue_r21.queue=[]
	w.depart_dungeon(1,1234);w.s.run.phase="battle"
	var Battle=preload("res://game/battle_v3.gd");var b=Battle.new(w.battle_data())
	b.data.depletions=3;b.data.last_kill="테이리스"
	var before={"depletions":b.data.depletions,"last_kill":b.data.last_kill}
	var snapshot=b.snapshot();var copy=Battle.new(w.battle_data());var ok=copy.restore(snapshot)
	var after={"depletions":copy.data.get("depletions",0),"last_kill":copy.data.get("last_kill","")}
	var state=w.s.duplicate(true);state.run.battle=snapshot
	var result={"restored":ok,"before":before,"after":after,"equal":before==after,"state":state}
	FileAccess.open("res://../verification/finish-r24/round2/resume-probe.json",FileAccess.WRITE).store_string(JSON.stringify(result))
	print("FINISH RESUME PROBE ",JSON.stringify({"restored":ok,"before":before,"after":after,"equal":before==after}));quit(0 if ok else 1)
