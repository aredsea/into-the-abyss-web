extends SceneTree
const World=preload("res://game/settings_world_r22.gd")
const Battle=preload("res://game/battle_v3.gd")
var checks=0
var failures=[]
func check(ok,label):
	checks+=1
	if not ok: failures.append(label);push_error(label)
func _initialize(): call_deferred("run")
func run():
	var w=World.new()
	for action in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(action)
	w.seed_source=func():return 4242
	w.create_action("pick_teiris","sc");w.create_action("go","sc");w.s.dialogue_r21.queue=[]
	w.depart_dungeon(1,1234);w.s.run.phase="battle"
	var b=Battle.new(w.battle_data())
	var observations=[]
	for count in [0,1,3,400,11200]:
		for a in b.data.allies:
			b.data.depletions=count;b.data.last_kill=a.name
			var saved=JSON.parse_string(JSON.stringify(b.snapshot()))
			var copy=Battle.new(w.battle_data())
			check(copy.restore(saved),"restore "+str(count)+" "+a.id)
			check(copy.data.depletions==count and copy.data.last_kill==a.name,"outcome metadata preserved")
			check(copy.snapshot().last_kill==a.id,"wire stores only a known id")
			observations.append({"count":count,"id":a.id,"restored":copy.data.last_kill})
	b.data.depletions=3;b.data.last_kill=b.data.allies[0].name
	var snapshot=b.snapshot()
	var state=w.s.duplicate(true);state.run.battle=snapshot
	FileAccess.open("res://../verification/finish-r24/round3/resume-state.json",FileAccess.WRITE).store_string(JSON.stringify(state))
	for absent in [["depletions"],["last_kill"],["depletions","last_kill"]]:
		var old=snapshot.duplicate(true)
		for key in absent:old.erase(key)
		var copy=Battle.new(w.battle_data());copy.data.depletions=99;copy.data.last_kill="stale"
		check(copy.restore(old),"legacy optional fields "+str(absent))
		check(copy.data.depletions==(0 if "depletions" in absent else 3),"legacy depletion default")
		check(copy.data.last_kill==("" if "last_kill" in absent else b.data.allies[0].name),"legacy killer default")
	for key in ["depletions","last_kill"]:
		var invalid=[-1,.5,11201,"3",true,null,[],{}] if key=="depletions" else ["fake","enemy_1","x".repeat(41),1,true,null,[],{}]
		for value in invalid:
			var bad=snapshot.duplicate(true);bad[key]=value
			var copy=Battle.new(w.battle_data());var before=copy.snapshot()
			check(not copy.restore(bad),"reject "+key+" "+str(value))
			check(copy.snapshot()==before,"failed restore is atomic "+key)
	# The original reported name-only probe must survive verbatim.
	check(snapshot.depletions==3 and snapshot.last_kill==b.data.allies[0].id,"reported loss regression")
	var phrases=[]
	for name in [b.data.allies[0].name,Battle.CombatDisplay.unit_name(b.data.allies[0],"en")]:
		b.data.last_kill=name+"의 기술";var wire=b.snapshot();var copy=Battle.new(w.battle_data())
		check(wire.last_kill==b.data.allies[0].id,"known killer extracted from source phrase")
		check(copy.restore(wire),"id-only phrase snapshot resumes")
		phrases.append({"before":b.data.last_kill,"wire":wire.last_kill,"after":copy.data.last_kill,"equal":b.data.last_kill==copy.data.last_kill})
	var collision=Battle.new(w.battle_data());var actor=collision.ally("teiris");var foe=collision.living(false)[0]
	collision.data.allies[0].name=actor.name;foe.hp=1
	collision._damage(actor,foe,100000,0,false,1,{"source_opt":{"name":"attack"},"source_at":0.0})
	check(foe.hp==0,"duplicate-name actual attack kills the target")
	check(collision.snapshot().last_kill=="teiris","killer identity survives a colliding persona name")
	var result={"checks":checks,"failures":failures,"observations":observations,"wire_last_kill":"known companion/persona id or empty","known_difference":{"reason":"The required ID-only wire field cannot retain the canonical skill phrase.","phrases":phrases}}
	FileAccess.open("res://../verification/finish-r24/round3/resume-results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("FINISH RESUME R24 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
