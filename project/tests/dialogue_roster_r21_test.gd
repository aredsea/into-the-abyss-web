extends SceneTree
const W=preload("res://game/settings_world_r22.gd")
const C=preload("res://game/chronicle_store_r22.gd")
const L=preload("res://game/localization_r22.gd")
var checks=0
var failures=[]
var samples={}
var totals={"characters":0,"scenes":0,"choices":0,"barks":0,"transitions":0}
const OUT="res://../verification/town-r21/round13/"
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func fresh():
	var w=W.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	return w
func sample(w,key):
	var raw=JSON.stringify(w.s);var input=JSON.parse_string(raw);var input_before=JSON.stringify(input);var copy=W.new()
	check(copy.restore(input),"native integrated restore "+key)
	check(JSON.stringify(input)==input_before,"restore input immutable "+key)
	check(copy.s.dialogue_r21==input.dialogue_r21,"dialogue roundtrip "+key)
	samples[key]=input
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w=fresh();var base=w.s.duplicate(true)
	var values=[-80,-40,0,30,60,90,120,170]
	var up=[-59,-19,20,50,80,100,150]
	var down=[-61,-21,19,49,79,99,149.5]
	for person in w.config.companions:
		var id=person.id;var d=w.dialogue.data(id);totals.characters+=1
		check(not d.is_empty() and d.name==L.canonical_names(person.name),"canonical name "+id)
		check(d.speech.address_terms.player_to_companion is String,"nested address metadata "+id)
		for row in d.inn:
			totals.scenes+=1
			for choice in row.choices:
				totals.choices+=1;w.s=base.duplicate(true)
				if id not in w.s.owned:w.s.owned.append(id)
				w.s.members[id].aff=values[d.stage_order.find(row.stage)]
				for other in d.inn:
					if other.id!=row.id:w.s.dialogue_r21.seen[other.id]=1
				var rng=w.s.rng;var gold=w.s.gold
				check(w.begin_dialogue(id) and w.s.dialogue_r21.pending.scene==row.id,"unseen selection "+row.id)
				check(w.choose_dialogue(choice.id),"actual choice "+row.id+choice.id)
				check(w.s.dialogue_r21.response.lines==choice.response and w.s.dialogue_r21.response.text==choice.text,"verbatim response "+row.id)
				check(w.s.rng==rng and w.s.gold==gold,"presentation preserves gameplay "+row.id)
				check(not w.choose_dialogue(choice.id) and not w.begin_dialogue(id),"one payment/day "+row.id)
		for row in d.transitions:
			totals.transitions+=1;w.s=base.duplicate(true)
			if id not in w.s.owned:w.s.owned.append(id)
			var idx=d.stage_order.find(row.to)
			var before=down[idx-1] if row.direction=="up" else up[idx]
			w.s.members[id].aff=before
			var chron=C.entries(w.s).size()
			check(w.begin_dialogue(id),"boundary opens "+row.id)
			var scene=w.dialogue.scene(id,w.s.dialogue_r21.pending.scene)
			for c in scene.choices:
				if c.aff==(2 if row.direction=="up" else -2):check(w.choose_dialogue(c.id),"boundary choice "+row.id);break
			check(w.s.dialogue_r21.response.transition.get("id","")==row.id,"actual stage scene "+row.id)
			check(C.entries(w.s).size()==chron+1,"one chronicle fact "+row.id)
			var state=JSON.stringify(w.s)
			check(not w.choose_dialogue("c1") and JSON.stringify(w.s)==state,"duplicate no chronicle/payment "+row.id)
		for row in d.dungeon:
			for i in row.variants.size():
				totals.barks+=1;w.s=base.duplicate(true)
				if id not in w.s.owned:w.s.owned.append(id)
				w.s.party=[id];w.s.members[id].aff=values[d.stage_order.find(d.dungeon_bands[row.band][0])]
				w.s.dialogue_r21.bark_counts[row.event]=i
				w.emit_bark(row.event,id)
				check(w.s.dialogue_r21.queue.size()==1 and w.s.dialogue_r21.queue[0].lines==[row.variants[i]],"engine bark variant "+id+row.event+str(i))
		# Every character supplies real native saves in each persistent presentation state.
		w.s=base.duplicate(true)
		if id not in w.s.owned:w.s.owned.append(id)
		w.s.members[id].aff=19
		for row in d.inn:w.s.dialogue_r21.seen[row.id]=1
		check(w.begin_dialogue(id),"seen replay "+id);sample(w,id+"_pending")
		var scene=w.dialogue.scene(id,w.s.dialogue_r21.pending.scene)
		for c in scene.choices:
			if c.aff==2:w.choose_dialogue(c.id);break
		sample(w,id+"_response");w.close_dialogue();w.aff_add(id,-2);sample(w,id+"_transition")
		w.dismiss_dialogue_queue();w.s.party=[id];w.emit_bark("departure",id);sample(w,id+"_bark")
		print("ROSTER ",id," complete")
	FileAccess.open(OUT+"save-specimens.json",FileAccess.WRITE).store_string(JSON.stringify(samples,"  "))
	FileAccess.open(OUT+"dialogue-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"totals":totals,"samples":samples.size()},"  "))
	print("DIALOGUE ROSTER CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
