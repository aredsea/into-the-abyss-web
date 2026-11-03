extends RefCounted
## 26-start input boundary; source-shaped records do not alter native saves.
const State=preload('res://game/battle_source_state_r23.gd')
const Stats=preload('res://game/battle_stats_r23.gd')
const Data=preload('res://game/battle_source_data_r23.gd')
const Persona=preload('res://game/persona_research_r21.gd')
const Random=preload('res://game/guild_rules_r21.gd')
static var dungeon=preload('res://game/dungeon_rules_r21.gd').new()
static func level(world: Dictionary,id: String) -> int:
	var raw=world.persona.get('lv')
	if not State.truth(raw):raw=world.get('lv')
	var persona=clampi(int(floor(Stats.number(raw,1))),1,40)
	if id=='persona':return persona
	if id not in world.get('roster',[]):return 1
	var levels=world.get('lvl',{});return clampi(int(floor(Stats.number(levels.get(id),persona))),1,40) if levels is Dictionary else persona
static func equipment(world: Dictionary,id: String) -> Variant:
	var equips=world.get('equip',{});var raw=equips.get(id) if equips is Dictionary else null
	if not raw is Dictionary:return null
	var result={}
	for slot in ['weapon','armor','acc']:
		if raw.get(slot) is String and raw[slot]!='':result[slot]=raw[slot]
	return null if result.is_empty() else result
static func member(world: Dictionary,id: String,cls: String) -> Dictionary:
	var value={"id":id,"cls":cls,"L":level(world,id)}
	State.put(value,'eq',equipment(world,id));State.put(value,'forge',world.get('forge'))
	return value
static func battle_pm(world: Dictionary) -> Array:
	var result=[];var p=world.persona
	if (p.get('fight') if State.truth(p.get('fight')) else 1)==1:
		var cls=Stats.cls_of(p.get('cls',''));var m=member(world,'persona',cls.get('id','warrior'))
		m.race=p.get('race','');m.lin=p.get('lineage','');m.nat=p.get('nation','')
		if p.get('stats') is Dictionary or p.get('stats') is Array:m.ps=p.stats
		if Persona.ready(p.get('skill')):m.skill=Persona.clean(p.skill)
		result.append(m)
	for id in world.get('party',[]):
		if result.size()>=4:break
		var cast=Data.CAST.get(id,{})
		if not cast.is_empty() and id in world.get('roster',[]):result.append(member(world,id,Stats.cls_of(cast.cls).get('id','warrior')))
	while result.size()<4:result.append({"id":"","cls":"","L":1})
	return result
static func quest_compose(world: Dictionary,quest: Dictionary,party: Array) -> Variant:
	var n=0
	for m in party:
		if m.id!='':n+=1
	var stars=clampf(Stats.number(quest.get('stars'),1),1,4);var rid=''
	var name=quest.get('rift','')
	for rift in dungeon.config.rifts:
		if name==rift.name or name==rift.quest_name:rid=rift.id;break
	if rid=='' or not State.truth(quest.get('cmp')):return null
	world.n=Stats.number(world.get('n'),0)+1
	var seed=int(floor(Random.random(int(floor(Stats.number(world.get('seed'),0))),int(world.n))*2147483646))
	var difficulty=quest.get('difficulty')
	if difficulty not in ['낮음','중간','높음','엘리트']:
		var raw=Stats.number(quest.get('stars'),1);difficulty='높음' if raw>=3 else '중간' if raw>=2 else '낮음'
	var kind='rift_core' if quest.get('kind')=='토벌' else 'battle' if difficulty=='낮음' else 'elite'
	return dungeon.compose(seed,{"kind":kind,"rift_id":rid,"stars":minf(stars,3),"party_n":n})
