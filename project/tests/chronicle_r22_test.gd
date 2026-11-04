extends SceneTree
const C=preload("res://game/chronicle_store_r22.gd")
const P=preload("res://game/town_places_r22.gd")
const W=preload("res://game/chronicle_world_r22.gd")
const Store=preload("res://game/chronicle_save_r22.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func queue(s):return s.get("chronicle_r22",{}).get("queue",[])
func fixture():
	var w=W.new();w.s.creation_r22={"complete":true,"legacy":true};w.s.scene="town";w.s.owned=["naran","marceline","teiris"];w.s.party=w.s.owned.duplicate();w.s.persona.cls="전사";w.s.persona.race="인간";w.s.persona.nation="경계도시";w.s.persona.fight=0;w.s.persona.name="당신";w.s.gold=5000;return w
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/chronicle-r22/oracle.json"))
	for f in oracle.places:
		var g=f.before.duplicate(true);check(P.place_id(g)==f.id,"place id "+str(f.before))
		check(P.set_place(g,f.dest)==f.moved,"move allowed "+f.dest)
		for key in ["scene","place","ui","forge_fx","proc_fx","sm_work","gold","seed"]:check(g.get(key)==f.value.get(key),"place field "+key+":"+f.dest)
		check(g.town.day==f.before.town.day and g.town.acts==f.before.town.acts,"movement preserves time/actions")
	for f in oracle.chron:
		var s={"town":{"day":f.day},"settings":{"chron":f.off}}
		C.add(s,f.text);C.add(s,f.text);check(queue(s)==f.queue,"chron add "+f.text)
	for f in oracle.aff:
		var s={"day":2};C.affection_changed(s,"naran",f.a,f.b);check(queue(s)==f.queue,"affection %.2f → %.2f"%[f.a,f.b])
	var w=fixture()
	for f in oracle.gear:
		var s={"day":1}
		for id in f.ids:C.legendary(s,w.gear.by_id[id])
		check(queue(s)==f.queue,"legendary source "+str(f.ids))
	for f in oracle.flush:check(C.merged(f.history,f.queue)==f.value,"flush retention/window %d"%f.history.size())
	check(P.DATA.order.size()==10 and P.DATA.profiles.size()==22,"10 places / 22 public fixed profiles")
	check(P.residents("archive")==["isolde"] and P.residents("gate")==["sven","agnes"] and P.residents("lamp").is_empty(),"source residents")
	for id in P.DATA.profiles:
		for line in P.public_lines(id):check(not line.contains("비공개") and not line.contains("숨은 진실") and not line.begins_with(">"),"public only "+id)
	# Real facade calls, including nested battle settlement / XP event observation.
	var fresh=W.new();fresh.s.scene="scenario";fresh.s.ui.sel="naran";fresh.s.persona.cls="전사";fresh.s.persona.race="인간";fresh.s.persona.nation="경계도시";fresh.s.persona.stats=fresh.persona_rules.calc(fresh.s.persona)
	check(fresh.create_action("go","sc"),"first meet transition");check(C.entries(fresh.s)==["Day 1: First met Naran, who joined as a companion."],"actual first meet fact");fresh.create_action("go","sc");check(C.entries(fresh.s).size()==1,"first meet cannot repeat")
	w.s.members.naran.aff=19;check(w.inn("naran","talk"),"inn accepted");check(C.entries(w.s).any(func(x):return x.contains("Naran's affection rose to Trust.")),"inn routes through shared affection event")
	var size=C.entries(w.s).size();check(not w.inn("naran","talk") and C.entries(w.s).size()==size,"repeated locked action adds no fact")
	w.s.chronicle_r22={"list":[],"queue":[]}
	w.award_persona_exp({"exp":5000,"sid":4242,"pm":[{"id":"naran"}]});var levels=C.entries(w.s)
	check(levels.size()==1 and levels[0].contains("Leveled up:"),"XP grouped in one fact")
	w.award_persona_exp({"exp":5000,"sid":4242,"pm":[{"id":"naran"}]});check(C.entries(w.s)==levels,"XP transaction guard")
	w=fixture();var owned=w.s.owned.duplicate();check(w.recruit(),"guild recruit accepted");check(w.s.owned.size()==owned.size()+1 and C.entries(w.s).size()==1 and C.entries(w.s)[0].contains("guild introduction"),"actual recruit fact")
	w=fixture();check(w.depart_dungeon(1,1234),"depart integration");w.s.run.gold=30;w.s.run.xp=10;w.s.run.loot_gear=["wa32.5"];check(w.settle("retreat"),"actual retreat settlement")
	check(C.entries(w.s).any(func(x):return x=="Day 1: Retreated from Great Dungeon floor 1"),"retreat uses event day before native rollover")
	check(C.entries(w.s).any(func(x):return x.contains("Obtained legendary gear: Spear of Torva.")),"obtained reward gear fact")
	var settled=C.entries(w.s);check(not w.settle("retreat") and C.entries(w.s)==settled,"repeat settlement no fact")
	w=fixture();w.s.dungeon_r21.best=2;check(w.depart_dungeon(3,77),"boss fixture depart");w.s.run.phase="battle";w.s.run.final=true;w.s.run.kind="boss";check(w.settle("clear"),"clear integration")
	check(C.entries(w.s).any(func(x):return x.contains("Cleared Great Dungeon floor 3; boss:")) and C.entries(w.s).any(func(x):return x.contains("the zone boss of")),"clear and first zone boss facts")
	w.chronicle_home();var home=C.entries(w.s);w.chronicle_home();check(C.entries(w.s)==home and home.any(func(x):return x.contains("Returned to Torva after clearing floor 3")),"home once")
	w=fixture();w.s.run={"phase":"done","data_version":21,"floor":1,"id":0};w.s.summary={"result":"clear"};w.s.dungeon_r21.best=1;check(w.depart_dungeon(2,77),"direct descent accepted");check(C.entries(w.s).any(func(x):return x.contains("descended directly to floor 2")),"descent fact")
	w=fixture();check(w.depart_dungeon(1,88),"failed run depart");w.s.run.phase="battle";check(w.settle("defeat"),"defeat integration");check(C.entries(w.s).any(func(x):return x.contains("Failed the Great Dungeon floor 1 run")),"failure fact")
	w.s.dungeon_r21.best=1;check(w.depart_dungeon(2,77),"retry after failure accepted");check(not C.entries(w.s).any(func(x):return x.contains("descended directly")),"failure cannot fabricate a clear/descent fact")
	for result in ["clear","defeat"]:
		# G_new deliberately has no offers. This legacy completed-game fixture
		# must visit/fill the guild before selecting an accepted source quest.
		w=fixture();w.fill_source_board();var q=w.s.board.filter(func(v):return v.get("cmp",false))[0];check(w.depart_rift_quest(q,77),"accepted quest depart "+result);check(w.settle(result),"accepted quest settle "+result)
		check(C.entries(w.s).any(func(x):return x.contains(("Completed" if result=="clear" else "Failed")+" the quest '")),"actual quest result fact "+result)
		var facts=C.entries(w.s);check(not w.settle(result) and C.entries(w.s)==facts,"quest repeated settlement "+result)
	# Save is atomic with facts. Old logs survive; loading never invents history.
	for spec in JSON.parse_string(FileAccess.get_file_as_string("res://../verification/persona-r22/legacy-specimens.json")):
		var value=JSON.parse_string(FileAccess.get_file_as_string(spec.path));var saved=value.duplicate(true);var specimen=W.new();check(specimen.restore(value),"real legacy specimen "+spec.path);check(value==saved and specimen.s.log==value.log and not specimen.s.has("chronicle_r22"),"real legacy preserved / no fabricated facts "+spec.path)
	w=fixture();var old=w.s.duplicate(true);old.erase("chronicle_r22");var copy=old.duplicate(true);var restored=W.new();check(restored.restore(old) and old==copy,"legacy input remains immutable")
	check(not restored.s.has("chronicle_r22"),"legacy migration adds no retrospective facts")
	C.entries(restored.s);check(not restored.s.has("chronicle_r22"),"reading empty journal does not mutate a legacy save")
	C.add(restored.s,"確定 한글 😀");var store=Store.new();store.path="user://p10-test-world.json";check(store.write(restored.s)==OK and restored.s.chronicle_r22.queue.is_empty(),"atomic flush persisted")
	var roundtrip=W.new();check(store.read_into(roundtrip) and C.entries(roundtrip.s)==C.entries(restored.s) and roundtrip.s.log==old.log,"roundtrip facts / legacy log")
	var previous=roundtrip.s.duplicate(true);var bad=previous.duplicate(true);bad.chronicle_r22.list=[1];check(not roundtrip.restore(bad) and roundtrip.s==previous,"invalid facts rejected atomically")
	var broken=Store.new();broken.path="res://nonexistent-directory/p10.json";C.add(restored.s,"pending");var pending=restored.s.duplicate(true);check(broken.write(restored.s)!=OK and restored.s==pending,"failed save preserves pending queue")
	FileAccess.open("res://../verification/chronicle-r22/results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"  "))
	print("CHRONICLE R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
