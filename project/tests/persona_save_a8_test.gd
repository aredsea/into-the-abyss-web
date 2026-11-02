extends SceneTree
const World=preload("res://game/settings_world_r22.gd")
const Battle=preload("res://game/battle_v3.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func same(a,b) -> bool:
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size(): return false
		for k in a:
			if not b.has(k) or not same(a[k],b[k]): return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size(): return false
		for i in range(a.size()):
			if not same(a[i],b[i]): return false
		return true
	if a is float or a is int: return absf(float(a)-float(b))<.0000001
	return a==b
func _init():call_deferred("run")
func run():
	var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy-specimens.json"))
	for specimen in legacy:
		var input=JSON.parse_string(FileAccess.get_file_as_string(specimen.path));var before=input.duplicate(true);var w=World.new()
		check(w.restore(input),"legacy loads "+specimen.path)
		check(input==before,"input unchanged")
		for id in before.get("research",{}):check(w.s.research[id]==before.research[id],"companion slot preserved "+id)
		check(w.s.get("research_editor_r21",{})==before.get("research_editor_r21",{}),"paid companion drafts preserved")
		var roundtrip=World.new();check(roundtrip.restore(JSON.parse_string(JSON.stringify(w.s))),"legacy repeated restore")
		check(roundtrip.s.research==w.s.research,"slots roundtrip")
	var w=World.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:w.create_action(arg)
	w.create_action("pick_teiris","sc");w.create_action("go","sc")
	check(w.s.creation_r22.complete,"actual creation")
	var slots=w.s.research.duplicate(true);var editors=w.s.research_editor_r21.duplicate(true)
	w.s.gold=10000
	check(w.research_action("persona","ps_pre_strike"),"choose prefix")
	check(not w.research_action("persona","ps_save"),"incomplete cannot save")
	check(w.research_action("persona","ps_suf_bleed"),"choose suffix")
	check(w.research_action("persona","ps_up_pre"),"pay first reinforcement")
	check(w.s.gold==9940 and w.s.persona_research_r22.spent==60,"source cost 60 immediate")
	check(not w.PersonaResearch.ready(w.s.persona.skill),"draft not equipped")
	check(not w.PersonaResearch.ready(w.source_pm()[0].skill),"draft not in combat source")
	var r=World.new();check(r.restore(JSON.parse_string(JSON.stringify(w.s))),"paid persona draft restore")
	check(same(r.s.persona_research_r22,w.s.persona_research_r22),"paid draft lossless "+str(r.s.persona_research_r22)+" / "+str(w.s.persona_research_r22))
	check(r.research_action("persona","ps_save"),"save persona skill")
	check(r.s.persona.skill.prefix_lv.strike==1 and r.s.gold==9940,"save no second charge")
	check(r.s.research==slots and r.s.research_editor_r21==editors,"companion slots and drafts remain byte-equivalent JSON values")
	check(not r.research_action("persona","ps_save"),"repeat save no change")
	check(r.depart_dungeon(1,12345),"depart")
	check(not r.research_action("persona","ps_pre_sweep"),"active research blocked")
	r.s.run.phase="battle"
	var d=r.battle_data();var b=Battle.new(d)
	check(b.ally("persona").skills.has("personal") and b.ally("persona").skills.has("guard"),"persona skill plus defense")
	b.current_id="persona";b.selected_ally="persona";b.selected_enemy=b.living(false)[0].id
	var mp=b.ally("persona").mp;var paid=b.cost("personal")
	check(b.act("personal"),"actual persona action")
	check(b.ally("persona").mp==mp-paid,"persona MP payment")
	r.s.run.battle=b.snapshot()
	var loaded=World.new();check(loaded.restore(JSON.parse_string(JSON.stringify(r.s))),"world midfight restore")
	var resumed=Battle.new(loaded.battle_data());check(resumed.restore(loaded.s.run.battle),"combat midfight restore")
	check(same(resumed.snapshot(),b.snapshot()),"combat all fields roundtrip")
	# Source TR.persona stops while its owner is down and resumes after revival.
	var persona=resumed.ally("persona");var friend=resumed.data.allies[1]
	friend.hp=1;resumed.set_persona_regen(friend,7,2);persona.hp=0;resumed._ally_down(persona)
	resumed._round_tick();check(friend.hp==1 and friend.effects.persona_regen.turns==2,"dead persona suspends its round hook")
	persona.hp=1;resumed._round_tick();check(friend.hp>=8 and friend.effects.persona_regen.turns==1,"revived persona resumes round hook")
	var invalid=r.s.duplicate(true);invalid.persona.skill.prefix_lv.strike=11
	var previous=loaded.s.duplicate(true);check(not loaded.restore(invalid) and loaded.s==previous,"invalid skill atomic rejection")
	invalid=r.s.duplicate(true);invalid.persona_research_r22={"draft":r.s.persona.skill.duplicate(true),"spent":-1}
	check(not loaded.restore(invalid) and loaded.s==previous,"invalid paid draft atomic rejection")
	var prepared=World.new()
	for arg in ["race_human","nat_border","cls_warrior","auto","done"]:prepared.create_action(arg)
	prepared.create_action("pick_marceline","sc");prepared.create_action("go","sc")
	prepared.s.owned.append("hildegard");prepared.s.party.append("hildegard")
	check(prepared.depart_dungeon(1,12345),"human synergy departure")
	prepared.s.run.phase="done";prepared.s.party=["marceline"];prepared.s.persona.fight=0
	check(prepared.party_count("race","인간")==1,"completed run does not freeze preparation synergy")
	var changed=World.new();check(changed.restore(JSON.parse_string(JSON.stringify(prepared.s))),"previous synergy vitals survive party edit")
	check(changed.s.members==JSON.parse_string(JSON.stringify(prepared.s.members)),"previous vitals are preserved")
	FileAccess.open("res://../verification/data-r21/a8-save-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"legacy":legacy.size()},"\t"))
	print("PERSONA SAVE A8 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
