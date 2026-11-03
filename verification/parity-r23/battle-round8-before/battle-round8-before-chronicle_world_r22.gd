extends "res://game/persona_world.gd"
## Additive event facade. Does not change combat, rewards, RNG or affinity rules.
const Chronicle=preload("res://game/chronicle_store_r22.gd")
const Places=preload("res://game/town_places_r22.gd")
var chron_depth=0
var chron_before={}
var chron_tail=[]
func _begin() -> void:
	if chron_depth==0:chron_before={"day":s.day,"owned":s.owned.duplicate(),"members":s.members.duplicate(true)};chron_tail=[]
	chron_depth+=1
func _end(ok: bool,kind="") -> void:
	chron_depth-=1
	if chron_depth>0 or not ok:return
	var old=chron_before;var levels=[];var affection=[]
	var order=s.owned.duplicate();order.push_front("persona")
	for id in order:
		if id not in old.owned and id!="persona":
			if kind in ["meet","guild"]:Chronicle.add(s,"First met "+Chronicle.english(person(id).name)+", who joined as a companion." if kind=="meet" else Chronicle.english(person(id).name)+" joined as a companion through a guild introduction.",old.day)
			continue
		var m=s.members[id];var b=old.members.get(id,m)
		if m.level>b.level:
			var name=s.persona.get("name","{{user}}") if id=="persona" else person(id).name
			levels.append(Chronicle.english("{{user}}" if name=="" else name)+" Lv %d → %d"%[b.level,m.level])
		if id!="persona":affection.append([id,b.aff,m.aff])
	if not levels.is_empty():Chronicle.add(s,"Leveled up: "+", ".join(levels),old.day)
	for a in affection:Chronicle.affection_changed(s,a[0],a[1],a[2],old.day)
	for line in chron_tail:Chronicle.add(s,line,old.day)
func create_action(arg: String,kind="cr") -> bool:
	_begin();var ok=super(arg,kind);_end(ok,"meet");return ok
func recruit() -> bool:
	_begin();var ok=super();_end(ok,"guild");return ok
func inn(id: String,action: String) -> bool:
	_begin();var ok=super(id,action);_end(ok);return ok
func choose_dialogue(choice_id: String) -> bool:
	var cid=s.dialogue_r21.pending.get("who","")
	var before=float(s.members.get(cid,{}).get("aff",0))
	if not super(choice_id):return false
	Chronicle.affection_changed(s,cid,before,float(s.members[cid].aff))
	return true
func award_persona_exp(st: Dictionary) -> Dictionary:
	_begin();var gains=super(st);_end(true);return gains
func finish_battle() -> bool:
	_begin();var ok=super();_end(ok);return ok
func settle(result: String) -> bool:
	_begin()
	var previous=s.run.duplicate(true);var day=s.day;var old_gears=s.gear.map(func(g):return g.uid)
	var boss="";var zone="";var first=false
	if r21() and result in ["clear","defeat"]:
		var enc=encounter_plan().enc
		if not enc.fl.is_empty():boss=dungeon_rules.foes[enc.fl[0]].name
		var info=dungeon_rules.floor_info(int(s.run.floor));zone=dungeon_rules.zones[info.zone].name
		first=info.dk==0 and info.ord>=3 and info.zone not in s.dungeon_r21.cleared_bosses
	var ok=super(result)
	if ok:
		if previous.has("source_quest"):
			if result in ["clear","defeat"]:Chronicle.add(s,("Completed" if result=="clear" else "Failed")+" the quest '"+Chronicle.english(previous.source_quest.get("title",previous.source_quest.get("name","")))+"'.",day)
		elif previous.get("data_version",0)==21:
			var f=str(int(previous.floor))
			if result=="clear":
				Chronicle.add(s,"Cleared Great Dungeon floor "+f+"; boss: "+Chronicle.english(boss),day)
				if first:chron_tail.append("First defeated "+Chronicle.english(boss)+", the zone boss of "+Chronicle.english(zone))
			elif result=="retreat":Chronicle.add(s,"Retreated from Great Dungeon floor "+f,day)
			else:Chronicle.add(s,"Failed the Great Dungeon floor "+f+" run"+(" before boss "+Chronicle.english(boss) if previous.get("final",false) else ""),day)
		for g in s.gear:
			if g.uid not in old_gears:Chronicle.legendary(s,gear.by_id[g.id],day)
	_end(ok);return ok
func chronicle_home() -> void:
	if s.run.get("phase","")!="done" or s.summary.get("result","")!="clear" or s.run.get("rift_id","")!="" or s.run.has("source_quest") or s.run.get("data_version",0)!=21 or s.run.has("chronicle_choice"):return
	s.run.chronicle_choice="home";Chronicle.add(s,"Returned to Torva after clearing floor "+str(int(s.run.floor)))
func depart_dungeon(f: int,seed: int=0,rift_id: String="",stars: int=1) -> bool:
	var previous=s.run.duplicate(true);var cleared=s.summary.get("result","")=="clear";var result=super(f,seed,rift_id,stars)
	if result and cleared and previous.get("phase","")=="done" and previous.get("data_version",0)==21 and previous.get("rift_id","")=="" and not previous.has("chronicle_choice") and not previous.has("source_quest") and rift_id=="" and f==int(previous.floor)+1:
		Chronicle.add(s,"After clearing floor %d, descended directly to floor %d"%[previous.floor,f])
	return result
func restore(value: Variant) -> bool:
	if not value is Dictionary or not Chronicle.valid(value):return false
	return super(value)
