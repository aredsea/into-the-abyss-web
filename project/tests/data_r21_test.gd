extends SceneTree
const Rules=preload("res://game/dungeon_rules_r21.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:
		failures.append(msg)
		if failures.size()<=20: push_error(msg)
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
	if a is float or a is int: return (b is float or b is int) and absf(float(a)-float(b))<=maxf(1e-10,absf(float(a))*1e-12)
	return a==b
func _init(): call_deferred("run")
func run():
	var rules=Rules.new(); var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/data-r21/lua-oracle.json"))
	check(rules.foes.size()==100 and rules.zones.size()==10 and rules.rifts.size()==6 and rules.catalog.families.size()==30,"catalog counts")
	for i in range(oracle.samples.size()):
		var s=oracle.samples[i]; var enc=rules.compose(int(s.seed),s.ctx)
		if enc.has("floor"): enc.dn={"floor":enc.floor,"kind":"explore" if s.explore else "boss","party_n":s.ctx.party_n}
		check(same(enc,s.enc),"composition %d: %s != %s" % [i,JSON.stringify(enc),JSON.stringify(s.enc)])
		var el=rules.floor_level(s.avg,rules.floor_info(int(enc.floor))) if enc.has("floor") else s.avg
		check(el==s.el,"level %d" % i)
		for j in range(enc.fl.size()):
			var d=rules.foe_def(enc,j,int(el)); var actual=rules.foe_stats(enc,d,int(el))
			check(same(actual,s.stats[j]),"stats %d/%d: %s != %s" % [i,j,JSON.stringify(actual),JSON.stringify(s.stats[j])])
		if enc.has("floor"): check(rules.gold(int(enc.floor),enc.kind)==s.gold,"gold %d" % i)
	for i in range(oracle.allStats.size()):
		var s=oracle.allStats[i]; var info=rules.floor_info(int(s.floor)); var enc={"fl":[s.id],"fg":[""],"floor":s.floor,"order":info.ord,"dk":info.dk,"star":rules.floor_star(info),"zk":info.zone,"dn":{"kind":"explore","party_n":4}}
		check(same(rules.foe_stats(enc,rules.foe_def(enc,0,int(s.el)),int(s.el)),s.stats),"individual stat %d" % i)
	for i in range(oracle.rolls.size()):
		var s=oracle.rolls[i]
		check(same(Rules.mix(int(s.seed),int(s.floor),int(s.step),1),s.mix),"mix %d" % i)
		check(rules.battle_seed(int(s.seed),int(s.floor),int(s.step))==s.battle_seed,"battle seed %d" % i)
		var roll=rules.ex_roll(int(s.seed),int(s.floor),int(s.step),int(s.elites),["warrior","assassin","sanctioned","priest"])
		check(same(roll,s.roll),"explore %d: %s != %s" % [i,JSON.stringify(roll),JSON.stringify(s.roll)])
	for q in oracle.quests:
		check(same(rules.level_reward(q.quest.lv),q.mult) and rules.quest_gold(q.quest,int(q.quest.lv))==q.gold and rules.quest_fight(q.quest)==q.fight,"source quest reward and encounter")
	var report={"checks":checks,"failures":failures.size(),"details":failures,"composition_samples":oracle.samples.size(),"individual_stats":oracle.allStats.size(),"exploration_samples":oracle.rolls.size()}
	FileAccess.open("res://../verification/data-r21/differential.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DATA_R21 checks=%d failures=%d composition=%d stats=%d exploration=%d" % [checks,failures.size(),oracle.samples.size(),oracle.allStats.size(),oracle.rolls.size()]); quit(0 if failures.is_empty() else 1)
