extends SceneTree
const World=preload("res://game/town_world_r21.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/town-r21/round7/hooks-oracle.json"))
	var w=World.new();var base=w.s.duplicate(true)
	for row in oracle.inn:
		w.s=base.duplicate(true);w.s.gold=row.gold;w.s.day=3;w.s.members.hildegard.aff=row.a
		if row.used:w.s.acts["hildegard_"+row.act]=3
		w.inn("hildegard",row.act)
		check(is_equal_approx(w.s.members.hildegard.aff,row.after),"Lua inn affection")
		check(w.s.gold==row.money and w.s.day==row.day,"Lua inn cost/day")
		check(w.s.npc_aff_r21.get("dorothea",0)==row.npc,"Lua inn NPC hook")
	for row in oracle.party:
		w.s=base.duplicate(true);w.s.party=row.ids.duplicate()
		for id in row.ids:
			if id not in w.s.owned:w.s.owned.append(id)
			w.s.members[id].aff=row.a
		w.aff_party(row.amount)
		for id in row.ids:check(is_equal_approx(w.s.members[id].aff,row.after[id]),"Lua party synergy "+id)
	for row in oracle.npc:
		w.s.npc_aff_r21.dorothea=row.a;w.npc_like("dorothea")
		check(w.s.npc_aff_r21.dorothea==row.after,"Lua NPC cap")
	for id in ["hildegard","marceline","teiris"]:
		w.s=base.duplicate(true)
		if id not in w.s.owned:w.s.owned.append(id)
		var d=w.dialogue.data(id)
		var values=[-80,-40,0,30,60,90,120,170]
		for row in d.inn:
			for choice in row.choices:
				w.s=base.duplicate(true)
				if id not in w.s.owned:w.s.owned.append(id)
				var before=float(values[d.stage_order.find(row.stage)])
				w.s.members[id].aff=before
				# Force this scene to be the first unseen scene in its stage.
				for other in d.inn:
					if other.id!=row.id:w.s.dialogue_r21.seen[other.id]=1
				var rng=w.s.rng
				check(w.begin_dialogue(id),"begin scene "+row.id)
				check(w.s.dialogue_r21.pending.scene==row.id,"unseen scene priority")
				check(w.s.members[id].aff==before and not w.s.acts.has(id+"_talk"),"opening does not pay affection")
				var saved=JSON.parse_string(JSON.stringify(w.s));var untouched=saved.duplicate(true);var copy=World.new()
				check(copy.restore(saved) and saved==untouched,"pending roundtrip / input immutable")
				w=copy
				check(not w.choose_dialogue("invalid"),"invalid choice atomic")
				check(w.choose_dialogue(choice.id),"choice completes")
				var after=w.TOWN_RULES.aff_next(before,choice.aff)
				check(is_equal_approx(w.s.members[id].aff,after),"choice replaces talk +1")
				check(not w.choose_dialogue(choice.id) and not w.begin_dialogue(id),"no duplicate / daily limit")
				check(w.s.rng==rng and w.s.dialogue_r21.seen[row.id]==1,"presentation has no gameplay RNG")
				saved=JSON.parse_string(JSON.stringify(w.s));copy=World.new()
				check(copy.restore(saved),"reaction survives reload")
				check(copy.close_dialogue() and not copy.close_dialogue(),"reaction close once")
				copy.s.day+=1;check(copy.begin_dialogue(id),"new day reopens")
		for event in ["departure","floor_entry","discovery","battle_start","victory","elite_boss_before","boss_defeat","ally_low_hp","self_wounded","ally_down","rest","sealed_cache","return","defeat"]:
			for a in [0,50,150]:check(not w.dialogue.bark(id,a,event,0).is_empty(),"all bark situations/bands")
		for pair in [[19,21],[51,49],[-80,170],[170,-80]]:
			check(not w.dialogue.transition(id,pair[0],pair[1]).is_empty(),"up/down / final crossed boundary")
	w.s=base.duplicate(true);w.s.members.hildegard.aff=19;w.begin_dialogue("hildegard")
	var scene=w.dialogue.scene("hildegard",w.s.dialogue_r21.pending.scene)
	for c in scene.choices:
		if c.aff==2:w.choose_dialogue(c.id);break
	check(w.s.dialogue_r21.response.transition.get("to","")=="신뢰","stage change in reaction")
	w.s=base.duplicate(true);var legacy=w.s.duplicate(true);legacy.erase("dialogue_r21");legacy.erase("npc_aff_r21")
	check(w.restore(legacy) and w.s.dialogue_r21.seen.is_empty(),"old save additive migration")
	var schema_one=preload("res://game/world_state.gd").new().s.duplicate(true)
	schema_one.day=7;schema_one.hand=["key","camp"];schema_one.acts["hildegard_talk"]=7
	schema_one=JSON.parse_string(JSON.stringify(schema_one))
	var schema_one_input=schema_one.duplicate(true)
	check(w.restore(schema_one) and schema_one==schema_one_input,"schema one migration input immutable")
	check(w.s.schema==2 and w.s.hand==["key","camp"] and w.s.acts.hildegard_talk==7 and w.s.dialogue_r21.pending.is_empty(),"schema one preserves hands/day/actions")
	var malformed=w.s.duplicate(true);malformed.dialogue_r21.pending={"who":"hildegard","scene":"x","day":0}
	var previous=w.s.duplicate(true);check(not w.restore(malformed) and w.s==previous,"malformed state atomic rejection")
	check(w.begin_dialogue("bargut") and w.s.members.bargut.aff==1 and w.s.dialogue_r21.pending.is_empty(),"missing content original fallback")
	w.s=base.duplicate(true)
	for row in w.dialogue.data("hildegard").inn:w.s.dialogue_r21.seen[row.id]=1
	check(w.begin_dialogue("hildegard"),"all scenes seen still playable")
	var repeated=w.dialogue.scene("hildegard",w.s.dialogue_r21.pending.scene)
	check(w.s.dialogue_r21.seen[repeated.id]==1 and not repeated.seen.is_empty(),"seen replay keeps original choices")
	w.s=base.duplicate(true);w.depart_dungeon(1,123);w.s.run.phase="battle";w.dismiss_dialogue_queue()
	var battle=World.ModernBattle.new(w.battle_data());var snap=battle.snapshot()
	snap.units.hildegard.hp=1;w.record_battle(snap)
	check(w.s.dialogue_r21.queue.any(func(r):return r.event=="self_wounded") and w.s.dialogue_r21.queue.any(func(r):return r.event=="ally_low_hp"),"engine snapshot crisis hooks")
	var n=w.s.dialogue_r21.queue.size();w.record_battle(snap);check(w.s.dialogue_r21.queue.size()==n,"crisis bark once per fighter/battle")
	snap.units.hildegard.hp=0;w.record_battle(snap);check(w.s.dialogue_r21.queue[-1].event=="ally_down","engine snapshot down hook")
	var restored=World.new();check(restored.restore(JSON.parse_string(JSON.stringify(w.s))),"live battle / crisis queue restore")
	w.s=base.duplicate(true);w.s.gold=1000
	var q=w.s.board[0];check(w.accept_quest(q.id) and w.s.npc_aff_r21.fenella==1,"accept quest NPC hook")
	check(w.depart_accepted_quest(),"source quest starts")
	w.s.members.hildegard.aff=99;check(w.settle("clear") and w.s.members.hildegard.aff==100.4,"quest source affection +2")
	w.s=base.duplicate(true);w.depart_dungeon(1,123);check(w.s.dialogue_r21.queue.size()==2,"departure / floor entry")
	w.dismiss_dialogue_queue();w.s.run.wins=2;w.s.members.hildegard.aff=99
	check(w.settle("retreat") and w.s.members.hildegard.aff==100.4,"aggregate battle win source hook")
	check(not w.settle("retreat") and w.s.members.hildegard.aff==100.4,"settlement idempotent")
	w.s=base.duplicate(true);w.depart_dungeon(1,123);w.s.run.wins=2;w.s.members.hildegard.aff=99
	check(w.settle("clear") and w.s.members.hildegard.aff==101.6,"boss +3 source hook")
	w.s=base.duplicate(true);w.depart_dungeon(1,123);w.s.run.wins=2
	check(w.settle("defeat") and w.s.members.hildegard.aff==0,"no affection on defeat")
	var out={"checks":checks,"failures":failures,"lua_inn":oracle.inn.size(),"lua_party":oracle.party.size(),"lua_npc":oracle.npc.size()}
	FileAccess.open("res://../verification/town-r21/round7/dialogue-results.json",FileAccess.WRITE).store_string(JSON.stringify(out,"  "))
	print("DIALOGUE PLAYER R21 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
