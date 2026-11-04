extends "res://tests/finish_r24_test.gd"
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/finish-r24/round3/oracle.json"))
	var w=ready_world()
	for row in oracle.inn:
		w=ready_world();w.s.day=row.before.town.day;w.s.gold=row.before.gold;w.s.acts={}
		if row.before.town.acts is Dictionary:w.s.acts=row.before.town.acts.duplicate(true)
		w.s.members.teiris.aff=row.before.aff.teiris
		var before=w.s.duplicate(true);var result=w.inn("teiris",row.verb)
		var actual={"gold":w.s.gold,"day":w.s.day,"aff":w.s.members.teiris.aff,"acts":w.s.acts}
		var expected={"gold":row.after.gold,"day":row.after.town.day,"aff":row.after.aff.teiris,"acts":row.after.town.acts if row.after.town.acts is Dictionary else {}}
		eqcheck("P2961.inn.state",actual,expected)
		eqcheck("P2961.inn.return",result,row.after.pending!="")
		var npc_calls=row.after.npc_calls
		eqcheck("P2961.inn.npc",w.s.npc_aff_r21.get("dorothea",0),npc_calls.size())
		if not result:eqcheck("P2961.inn.atomic",w.s,before)
		if result and row.verb=="talk" and row.before.gold==300:
			var story=ready_world();story.s.dialogue_r21.queue=[];story.s.members.teiris.aff=row.before.aff.teiris
			check(story.begin_inn_talk("teiris"),"source talk keeps narrative accessible")
			eqcheck("P2961.story.immediate",story.s.members.teiris.aff,row.after.aff.teiris)
			var staged=story.s.dialogue_r21.queue.size()>0
			var copy=World.new();check(copy.restore(JSON.parse_string(JSON.stringify(story.s))),"prepaid stage change resumes")
			check(copy.choose_dialogue("c1"),"prepaid source story completes")
			eqcheck("P2961.story.no-double",copy.s.members.teiris.aff,row.after.aff.teiris)
			check(not copy.s.dialogue_r21.response.transition.is_empty() if staged else copy.s.dialogue_r21.response.transition.is_empty(),"stage change stays in narrative response")
			check(copy.s.dialogue_r21.queue.is_empty(),"no duplicate stage-change overlay after story")
	var texture=ImageTexture.create_from_image(Image.create(1,1,false,Image.FORMAT_RGBA8))
	for row in oracle.npcs:
		w.s.settings={"lang":row.lang};w.s.npc_aff_r21={"dorothea":row.aff}
		var provider={}
		for entry in row.list:provider[entry[0]]=texture if row.provider=="html" else "broken" if row.provider=="invalid" else null
		var actual=w.source_npc_rows(row.list,provider,row.useG);var text=[]
		for entry in actual:text.append(entry.name+" "+entry.role)
		if plain24(" ".join(text))!=row.text:print("NPC DIFFERENCE ",plain24(" ".join(text))," EXPECTED ",row.text)
		eqcheck("P2826.npcs.full",plain24(" ".join(text)),row.text)
		check(actual.size()==(2 if row.provider=="html" else 0),"provider omission and order")
	FileAccess.open("res://../verification/finish-r24/round3/facilities-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"counts":counts}))
	print("FINISH FACILITIES R24 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
