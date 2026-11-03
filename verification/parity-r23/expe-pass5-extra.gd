extends SceneTree
const Core=preload("res://tests/expe_pass5_r23_test.gd")
var core=Core.new()
func _initialize():call_deferred("run")
func run():
	var cases=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-pass5-extra-oracle.json"))
	var w=core.helper.setup()
	for row in cases:
		row.G.lang=row.lang
		if row.R.get("summary",{}).get("items") is Array:row.R.summary.items={}
		var actual=core.project(w.source_expedition_view(row.kind,row.G,row.R))
		core.check(core.helper.same(actual,row.visible),"extra "+str([row.kind,row.lang,row.R.floor,actual,row.visible]),row.kind)
	FileAccess.open("res://../verification/parity-r23/expe-pass5-extra-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":core.checks,"failures":core.failures,"groups":core.groups},"  "))
	print("EXPE PASS5 EXTRA CHECKS ",core.checks," FAILURES ",core.failures.size())
	var ok=core.failures.is_empty();core.helper.helper.free();core.helper.free();core.free();quit(0 if ok else 1)
