extends SceneTree
const Base=preload("res://tests/expedition_r22_test.gd")
var checks=0
var failures=[]
var groups={}
var helper=Base.new()
func check(ok: bool,label: String,group: String):
	checks+=1
	if not groups.has(group):groups[group]={"checks":0,"failures":0}
	groups[group].checks+=1
	if not ok:
		failures.append(label);groups[group].failures+=1
		if failures.size()<12:print("MISMATCH ",label)
func setup():
	var w=helper.ready_world()
	w.s.persona.name="";w.s.persona.lv=10;w.s.members.persona.level=10
	w.s.owned=["lynette","marceline","urda","haldric"];w.s.party=["lynette"]
	for id in {"lynette":15,"marceline":9,"urda":10,"haldric":40}:w.s.members[id].level={"lynette":15,"marceline":9,"urda":10,"haldric":40}[id]
	return w
func _initialize():call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-pass2-oracle.json"))
	for r in oracle.names:
		var w=setup();w.s.persona.name=r.name
		check(w.person("persona").name==r.value,"persona name "+r.name,"pname")
		check(w.expedition_member_name("persona")==r.explore,"exploration persona name "+r.name,"explore_pname")
		for id in r.members:
			check(w.has_method("expedition_member_name") and w.call("expedition_member_name",id)==r.members[id],"member name "+id,"member_name")
		for id in r.who:check(w.expedition_member_name(id)==r.who[id],"level display name "+id,"level_who")
	var zone_world=setup()
	for r in oracle.zone_titles:
		zone_world.s.settings={"lang":r.lang}
		check(zone_world.has_method("dungeon_zone_title") and zone_world.call("dungeon_zone_title",zone_world.dungeon_rules.floor_info(int(r.floor)))==r.value,"zone title "+str([r.lang,r.floor]),"zone_title")
	var labels=setup()
	for r in oracle.labels:
		# Source charm_potion belongs to excluded 79-sex content. Keep its row
		# partial in the ledger; do not port or claim equality for that name.
		if r.id!="charm_potion":check(labels.expedition_item_name(r.id)==r.name,"item name "+r.id,"itname")
		check(labels.expedition_item_rarity(r.id)==(null if r.rarity is bool else r.rarity),"item rarity "+r.id,"rar_of")
		check(labels.expedition_gear_label(r.id)==r.gear,"gear label "+r.id,"gear_label")
		labels.s.settings={"lang":"en"}
		check(labels.expedition_gear_label(r.id,true)==r.english,"English gear label "+r.id,"gear_label_en")
		check(labels.expedition_gear_label(r.id)==r.ui_english,"English UI gear label "+r.id,"gear_label_ui_en")
		labels.s.settings={"lang":"ko"}
		check(labels.expedition_gear_label(r.id,true)==r.english,"English scene label in Korean UI "+r.id,"gear_label_en_ko")
	for r in oracle.formation:
		var w=setup();w.s.persona.cls=r.cls;w.s.persona.fight=int(r.fight);w.s.party=r.party.duplicate()
		if not w.has_method("sortie_members"):check(false,"missing sortie members","members");continue
		check(helper.same(w.call("sortie_members"),r.members),"formation "+str([r.cls,r.fight,r.party]),"members")
		check(helper.same(w.s.party,r.clean),"clean formation "+str(r.party),"members")
		check(helper.same(w.call("sortie_persona_role"),{"row":r.row,"cls":r.label}),"persona class "+r.cls,"prow")
	for r in oracle.ordered:
		var w=setup();w.s.party=r.party.duplicate()
		check(w.has_method("sortie_candidate_records") and helper.same(w.call("sortie_candidate_records",r.filter),r.value),"candidate records "+str([r.filter,r.party]),"ordered")
	for r in oracle.summary:
		var w=setup();w.s.persona.fight=int(r.fight);w.s.party=r.party.duplicate();w.s.settings={"lang":r.lang}
		var quest={} if r.q is Array else r.q # Lua JSON encodes an empty table as [].
		check(w.has_method("sortie_quest_summary") and helper.same(w.call("sortie_quest_summary",quest),r.value),"quest summary "+str([r.fight,r.party,r.q]),"summary")
	for r in oracle.slots:
		var w=setup();w.depart_dungeon(1,7);w.s.run.persona_pm=r.pm.duplicate(true)
		check(w.has_method("expedition_members") and helper.same(w.call("expedition_members"),r.value),"sparse members "+str(r.pm),"run_members")
		for i in range(6):
			var key=w.call("expedition_equip_key",i) if w.has_method("expedition_equip_key") else "missing"
			check(key==("" if r.keys[i] is bool else r.keys[i]),"slot "+str(i),"equip_key")
	for r in oracle.use:
		var w=setup();w.s.persona.name="{{user}}";w.depart_dungeon(1,7);w.s.run.phase=r.phase
		w.s.members.persona.hp=r.hp;w.s.members.persona.mp=1;w.s.run.maxima.persona={"hp":101,"mp":71};w.s.run.last="before";w.s.run.log=["old"]
		var key=w.web_item_id(r.id);w.s.items[key]=1;w.use_expedition_item(key,"persona")
		var actual={"hp":w.s.members.persona.hp,"mp":w.s.members.persona.mp,"last":w.s.run.last,"log":w.s.run.log,"stock":w.s.items[key]}
		check(helper.same(actual,r.value),"outside item text "+str([r.id,r.phase,r.hp,actual,r.value]),"use_text")
	for r in oracle.rest:
		var w=setup();w.s.persona.name="가온";w.s.party=[];w.depart_dungeon(1,7)
		w.s.members.persona.hp=r.hp;w.s.members.persona.mp=r.mp;w.s.run.maxima.persona={"hp":101,"mp":71};w.enter_dungeon_rest()
		check(helper.same({"hp":w.s.members.persona.hp,"mp":w.s.members.persona.mp,"last":w.s.run.last,"log":w.s.run.log,"phase":w.s.run.phase,"ask":w.s.run.ask},r.value),"rest text "+str([r.hp,r.mp]),"rest_text")
	for r in oracle.discovery:
		var w=setup();w.s.party=[];w.s.persona.name="가온";w.s.dungeon_r21.best=int(r.floor);w.depart_dungeon(int(r.floor),int(r.seed));w.s.run.step=int(r.step)
		w.s.members.persona.hp=1;w.s.members.persona.mp=1;w.s.run.maxima.persona={"hp":101,"mp":71};w.s.run.last="before";w.advance()
		var actual={"phase":w.s.run.phase,"step":w.s.run.step,"elites":w.s.run.elites,"last":w.s.run.last,"log":w.s.run.log,"gold":w.s.run.gold,"items":w.s.run.loot_items,"gear":w.s.run.loot_gear,"hp":w.s.members.persona.hp,"mp":w.s.members.persona.mp}
		var expected=r.value.duplicate(true)
		if expected.items is Array:expected.items={}
		check(helper.same(actual,expected),"exploration complete projection "+str([r.floor,r.seed,actual,expected]),"discovery_text")
	for r in oracle.retreat:
		var w=setup();w.s.gold=int(r.value.gold)-(21 if r.arg=="retreat_yes" and r.ask and r.phase in ["explore","rest"] else 0)
		w.depart_dungeon(1,7);w.s.run.phase=r.phase;w.s.run.ask=r.ask;w.s.run.gold=21
		if not w.has_method("expedition_retreat"):check(false,"missing retreat transition","retreat");continue
		w.call("expedition_retreat",r.arg)
		check(helper.same({"ask":w.s.run.ask,"phase":w.s.run.phase,"gold":w.s.gold},r.value),"retreat "+str([r.phase,r.ask,r.arg]),"retreat")
		# Ask is data, so a pending prompt survives the native save projection.
		if w.active():
			var save=JSON.parse_string(JSON.stringify(w.s));var restored=setup()
			check(restored.restore(save) and restored.s.run.ask==w.s.run.ask,"retreat save continuation","retreat_resume")
	var report={"checks":checks,"failures":failures,"groups":groups}
	var f=FileAccess.open("res://../verification/parity-r23/expe-pass2-results.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "));f.close()
	print("EXPE PASS2 R23 CHECKS ",checks," FAILURES ",failures.size()," GROUPS ",groups)
	helper.free();quit(0 if failures.is_empty() else 1)
