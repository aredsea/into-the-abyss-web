extends "res://tests/finish_r24_test.gd"
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round4/oracle.json"))
	var display=Display24.new()
	var first={}
	for f in oracle.pages:
		var entries=display.page(f.kind,f.p,f.lang)
		if display.visible(entries)!=f.text and not first.has(f.kind+f.lang):
			first[f.kind+f.lang]=true;print("CREATE DIFF ",f.kind," ",f.lang," ACTUAL ",display.visible(entries)," EXPECTED ",f.text)
		eqcheck("create/"+f.kind+"/copy",display.visible(entries),f.text)
		eqcheck("create/"+f.kind+"/controls",display.controls(entries),f.buttons)
		if f.kind=="stats":eqcheck("create/stats/meters",display.meters(entries),f.bars)
	for f in oracle.totals:
		var entries=display.total_entries(f.p,f.lang)
		eqcheck("create/total/copy",display.visible(entries),f.text)
		eqcheck("create/total/controls",display.controls(entries),f.buttons)
	FileAccess.open("res://../verification/finish-r24/round4/create-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts},"\t"))
	print("FINISH CREATE CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
