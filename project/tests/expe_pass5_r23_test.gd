extends SceneTree
const Previous=preload("res://tests/expe_pass3_r23_test.gd")
var helper=Previous.new()
var checks=0
var failures=[]
var groups={}
func check(ok: bool,message: String,group: String):
	checks+=1
	if not groups.has(group):groups[group]={"checks":0,"failures":0}
	groups[group].checks+=1
	if not ok:
		failures.append(message);groups[group].failures+=1
		if failures.size()<12:print("MISMATCH ",message)
func _initialize():call_deferred("run")
func norm(value: String) -> String:
	var re=RegEx.new();re.compile("\\s+");return re.sub(value,"",true)
func project(entries: Array) -> Dictionary:
	var text="";var buttons=[];var pips=[];var bars=[]
	for e in entries:
		text+=e.text+e.get("sub","")
		if e.has("action"):buttons.append({"action":e.action if e.enabled else "","enabled":e.enabled,"text":norm(e.text+e.get("sub",""))})
		if e.role=="pip":pips.append({"text":e.text,"state":e.state})
		if e.role=="bar":bars.append({"kind":e.kind,"ratio":snappedf(e.ratio,.001)})
	return {"text":norm(text),"buttons":buttons,"pips":pips,"bars":bars}
func empty_dict(v: Variant) -> Variant:return {} if v is Array and v.is_empty() else v
func source_empty(g: Dictionary) -> void:
	for key in ["exp","lvl"]:
		if g.has(key):g[key]=empty_dict(g[key])
	if g.get("town") is Dictionary and g.town.has("acts"):g.town.acts=empty_dict(g.town.acts)
func run():
	var w=helper.setup()
	check(w.persona_rules.has_method("award_result"),"full award boundary absent","award")
	check(w.has_method("source_expedition_view"),"source visible sections absent","view")
	check(w.TOWN_RULES.has_method("source_town"),"source town normalization absent","town")
	var o=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/expe-pass5-oracle.json"))
	if o is Dictionary and w.persona_rules.has_method("award_result"):
		var names={}
		for c in w.config.companions:names[c.id]=c.name
		for r in o.award:
			var g=r.input.G.duplicate(true);source_empty(g);var expected=r.value.G.duplicate(true);source_empty(expected)
			var result=w.persona_rules.award_result(g,r.input.st,r.lang,names)
			check(helper.same(result.gains,empty_dict(r.value.gains)) and helper.same(g,expected),"award state "+str([r.lang,r.mode,r.input.st,result,g,expected]),"award")
			check(helper.same(result.lines,r.value.lines),"award lines "+str([r.lang,r.mode,result.lines,r.value.lines]),"award")
			var again=w.persona_rules.award_result(g,r.input.st,r.lang,names)
			check(helper.same(again.gains,empty_dict(r.again.gains)) and helper.same(again.lines,r.again.lines),"award replay "+str([r.lang,r.mode,again,r.again]),"award")
			check(helper.same(result.chron+again.chron,r.chron),"award chronicle "+str([r.lang,r.mode,result.chron+again.chron,r.chron]),"award")
		for r in o.town:
			if r.kind=="party":
				var names_actual=w.town_source_party({"persona":{"name":r.name,"fight":r.fight},"party":r.party})
				check(helper.same(names_actual,r.value),"town party preserves persona / duplicate / unknown order","town_party")
				check(norm("".join(w.town_source_tags(names_actual,r.lang)))==r.html_visible.text,"town visible tags translation and order","town_tags");continue
			if r.kind=="name":check(w.town_source_name(r.id)==r.value,"town name "+r.id,"town_name");continue
			if r.kind!="normalize":continue
			var g=empty_dict(r.input).duplicate(true);source_empty(g);var expected=empty_dict(r.value).duplicate(true);source_empty(expected)
			var town=w.TOWN_RULES.source_town(g)
			check(helper.same(g,expected),"town defaults "+str([g,expected]),"town")
			town.marker=true;check(g.town.marker==true and r.alias,"town same reference","town")
		for r in o.run:
			var g=r.input.duplicate(true);var actual=w.source_run(g)
			check(helper.same(g,r.value) and helper.same(actual,r.run),"ex_run normalize side effects "+str([g,r.value,actual,r.run]),"run")
		for r in o.view:
			var g=r.G.duplicate(true);g.lang=r.lang
			var actual=project(w.source_expedition_view(r.kind,g,r.R,r.extra if r.extra is Dictionary else {}))
			check(helper.same(actual,r.visible),"view "+str([r.kind,r.lang,actual,r.visible]),r.kind)
		for r in o.step:
			w=helper.setup();w.s.members.persona.level=10;w.s.settings={"lang":r.lang};check(w.depart_dungeon(1,int(r.seed)),"step departure","step")
			w.s.run.step=int(r.step);w.s.run.ask=r.ask;w.advance()
			var actual=state(w);var expected=r.value.duplicate(true);expected.items=empty_dict(expected.items)
			check(helper.same(actual,expected),"step observable state "+str([r.lang,r.seed,r.step,r.ask,actual,expected]),"step")
		for r in o.rest:
			w=helper.setup();w.s.members.persona.level=10;w.s.settings={"lang":r.lang};w.s.party=[];w.depart_dungeon(1,7)
			w.s.members.persona.hp=int(r.h);w.s.members.persona.mp=0;w.s.run.maxima.persona={"hp":101,"mp":71};w.s.run.step=5
			for i in range(int(r.repeats)):w.enter_dungeon_rest()
			var actual=state(w);var expected=r.value.duplicate(true);expected.items=empty_dict(expected.items)
			check(helper.same(actual,expected),"rest repeated "+str([r.lang,r.h,r.repeats,actual,expected]),"rest")
		for r in o.start:
			w=helper.setup();w.s.members.persona.level=10;w.s.dungeon_r21.best=2;w.selected_floor=int(r.selection)
			check(w.start_selected_dungeon() and w.s.run.floor==r.floor and w.s.run.phase==r.phase and w.s.run.last==r.last,"selected departure normalize "+str(r),"start")
		for r in o.sortie:
			w=helper.setup();w.s.members.persona.level=10;w.s.settings={"lang":r.lang};w.s.persona.fight=int(r.fight);w.s.party=r.party.duplicate();w.s.ui.tab=r.filter;w.selected_floor=28;w.s.dungeon_r21.best=27
			# The canonical fixture passes dn_floor_view(28).el as q.lv to summary.
			# Select that dungeon explicitly; a fresh game's default is quest mode.
			w.set_sortie_mode(1)
			for id in w.s.owned:w.s.members[id].aff=r.aff
			var actual=project(w.source_sortie_view(r.kind))
			check(helper.same(actual,r.visible),"sortie "+str([r.kind,r.lang,r.fight,r.party,r.filter,r.aff,actual,r.visible]),"sortie_"+r.kind)
	FileAccess.open("res://../verification/parity-r23/expe-pass5-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"groups":groups},"  "))
	print("EXPE PASS5 CHECKS ",checks," FAILURES ",failures.size())
	helper.helper.free();helper.free();quit(0 if failures.is_empty() else 1)

func state(w) -> Dictionary:
	var r=w.source_expedition_state();var run=w.s.run
	return {"phase":r.phase,"step":r.step,"elites":run.elites,"ask":r.ask,"last":r.last,"log":run.log,"hp":r.hp,"mp":r.mp,"gold":r.loot.gold,"exp":r.exp,"items":r.loot.items,"gear":r.loot.gear}
