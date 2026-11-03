extends SceneTree
const Base=preload("res://tests/expedition_r22_test.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
	checks+=1
	if not ok:failures.append(label);print("MISMATCH ",label)
func _initialize():call_deferred("run")
func run():
	var base=Base.new();var w=base.ready_world()
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-format-oracle.json"))
	for row in oracle.format:check(w.expedition_aff_format(row.value)==row.text,"aff decimal "+str(row.value))
	for row in oracle.note:
		w.s.settings={"lang":row.lang};w.s.owned=["lynette"];w.s.members.lynette.aff=199.75
		var summary={};w.expedition_aff_note({"pm":[{"id":"lynette"}],"wins":1},"retreat",summary)
		check(base.same(summary.aff,row.value),"settled quarter text "+row.lang)
		check(w.s.members.lynette.aff==row.after,"settled quarter amount "+row.lang)
	var result={"checks":checks,"failures":failures}
	FileAccess.open("res://../verification/parity-r23/expe-format-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("EXPE FORMAT R23 CHECKS ",checks," FAILURES ",failures.size())
	base.free();quit(0 if failures.is_empty() else 1)
