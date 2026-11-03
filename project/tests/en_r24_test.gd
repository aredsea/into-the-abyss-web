extends SceneTree
const L=preload("res://game/localization_r22.gd")
const D=preload("res://game/dialogue_locale_r24.gd")
const World=preload("res://game/town_world_r21.gd")
var checks=0
var failures=[]
var korean=RegEx.new()
func check(ok: bool,message: String):
	checks+=1
	if not ok:failures.append(message);push_error(message)
func _initialize():
	korean.compile("[가-힣ㄱ-ㅎㅏ-ㅣ]")
	call_deferred("run")
func run():
	var en={"settings":{"lang":"en"},"persona":{"name":"Traveler"}}
	var ko={"settings":{"lang":"ko"},"persona":{"name":"Traveler"}}
	var args=OS.get_cmdline_user_args()
	var ids=Array(args[0].split(",")) if not args.is_empty() else ["adeline","altan","bargut"]
	var fields=0
	for id in ids:
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue-r21/"+id+".json"))
		check(data.get("en",{}).has("speech"),"English voice guide "+id)
		for path in data.get("en",{}).get("display",{}):
			var source=D.source_at(data,path);var expected=data.en.display[path];fields+=1
			check(not source.is_empty(),"valid original path "+id+"/"+path)
			check(L.authored_display(source,en)==expected,"English field selected "+id+"/"+path)
			check(korean.search(L.authored_display(source,en))==null,"English contains no Hangul "+id+"/"+path)
			check(L.authored_display(source,ko)==source,"Korean exact original "+id+"/"+path)
		var row=data.inn[0]
		check(L.authored_display("\n".join(row.lines),en)=="\n".join(row.lines.map(func(t):return D.render(t))),"joined lines "+id)
		var w=World.new()
		if id not in w.s.owned:w.s.owned.append(id)
		w.s.settings={"lang":"en"};w.s.members[id].aff=-80
		check(w.begin_dialogue(id),"English dialogue opens "+id)
		var original=w.dialogue.scene(id,w.s.dialogue_r21.pending.scene)
		check(w.choose_dialogue(original.choices[0].id),"English choice works "+id)
		var saved=JSON.stringify(w.s);var response=w.s.dialogue_r21.response
		check(response.text==original.choices[0].text and response.lines==original.choices[0].response,"saved response remains Korean "+id)
		check(korean.search(L.authored_display(response.text,en))==null,"saved response translated "+id)
		check(korean.search(L.authored_display("\n".join(response.lines),en))==null,"saved reaction translated "+id)
		L.authored_display(response.text,ko);L.authored_display(response.text,en)
		check(JSON.stringify(w.s)==saved,"language display does not mutate save "+id)
		var restored=World.new();var input=JSON.parse_string(saved);var before=JSON.stringify(input)
		check(restored.restore(input) and JSON.stringify(input)==before,"existing save roundtrip "+id)
		check(korean.search(L.authored_display(restored.s.dialogue_r21.response.text,en))==null,"restored response translated "+id)
	check(L.authored_display("{{user}}",en)=="Traveler","persona substitution after translation")
	check(L.authored_display("Unlisted custom text",en)=="Unlisted custom text","unknown custom text preserved")
	var output={"checks":checks,"failures":failures,"characters":ids,"fields":fields}
	FileAccess.open("res://../verification/en-r24/dialogue-test.json",FileAccess.WRITE).store_string(JSON.stringify(output,"  "))
	print("EN R24 CHECKS ",checks," FIELDS ",fields," FAILURES ",failures.size())
	quit(0 if failures.is_empty() else 1)
