extends "res://tests/finish_r24_test.gd"
func run():
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round2/oracle.json"))
	var adapter=Save.new()
	for row in fixture.bank:
		var w=ready_world();w.s.gear=[];w.s.serial=0;w.s.equipment.persona={}
		for i in int(row.size):w.s.serial+=1;w.s.gear.append(adapter.entry("wa01.1.1",w.s.serial))
		var result=w.bank_expedition_gear(row.codes)
		eqcheck("P3195.bank.full",[result.gear,result.lost,w.s.gear.size()],[row.got,row.lost,row.after])
		var copy=World.new();check(copy.restore(JSON.parse_string(JSON.stringify(w.s))),"bank saved resume")
		eqcheck("P3195.bank.resume",observe(copy),observe(w))
	for row in fixture.fight:
		var w=ready_world();w.s.settings={"lang":row.lang};w.s.persona.cls=row.cls;w.s.persona.fight=row.fight
		w.s.persona.name="";w.s.ui.msg=""
		w.s.owned=["teiris","hildegard","bargut","marceline"];w.s.party=row.party.duplicate()
		var entries=w.source_preparation_view("fight");var words=[];var buttons=[]
		for e in entries:
			words.append(e.text)
			if e.role=="button":buttons.append({"id":e.action,"label":e.text,"selected":e.selected,"enabled":e.enabled})
		eqcheck("P3020.fight.view",plain24(" ".join(words)),row.text)
		eqcheck("P3020.fight.buttons",buttons,row.buttons)
		check(w.set_fight(1),"fight selection accepted without class")
		eqcheck("P3020.fight.transition",{"fight":w.s.persona.fight,"party":w.s.party,"msg":w.s.ui.msg},row.after)
	FileAccess.open("res://../verification/finish-r24/round2/unit-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts},"\t"))
	print("FINISH ROUND2 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
