extends SceneTree
func _initialize():
	var base=preload("res://tests/expedition_r22_test.gd").new();var w=base.ready_world();var out=[]
	for n in [.05,.15,.25,.35,.45,.55,.65,.75,.85,.95,-.25]:out.append({"value":n,"native":w.expedition_aff_format(n)})
	FileAccess.open("res://../verification/parity-r23/expe-pass3-format-probe.json",FileAccess.WRITE).store_string(JSON.stringify(out))
	base.free();quit()
