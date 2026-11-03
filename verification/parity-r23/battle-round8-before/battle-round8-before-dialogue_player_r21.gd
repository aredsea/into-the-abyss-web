extends RefCounted
## Content is read-only. Selection and bark variation never consume gameplay RNG.
const Aff=preload("res://game/town_rules_r21.gd")
var cache={}

func data(who: String) -> Dictionary:
	if cache.has(who):return cache[who]
	var path="res://data/dialogue-r21/"+who+".json"
	var value=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	cache[who]=value if value is Dictionary and value.get("character_id","")==who else {}
	return cache[who]

func scene(who: String,id: String) -> Dictionary:
	for row in data(who).get("inn",[]):
		if row.id==id:return row
	return {}

func select_scene(who: String,aff: float,seen: Dictionary) -> Dictionary:
	var rows=data(who).get("inn",[]).filter(func(row):return row.stage==Aff.aff_stage(aff))
	var chosen={};var count=9223372036854775807
	for row in rows:
		var n=int(seen.get(row.id,0))
		if n<count:chosen=row;count=n
	return chosen

func transition(who: String,before: float,after: float) -> Dictionary:
	var d=data(who);var stages=d.get("stage_order",[])
	var a=stages.find(Aff.aff_stage(before));var b=stages.find(Aff.aff_stage(after))
	if a<0 or b<0 or a==b:return {}
	var previous=stages[b-1 if b>a else b+1]
	for row in d.get("transitions",[]):
		if row.from==previous and row.to==stages[b]:return row.duplicate(true)
	return {}

func bark(who: String,aff: float,event: String,index: int) -> String:
	var d=data(who);var stage=Aff.aff_stage(aff);var band=""
	for key in d.get("dungeon_bands",{}):
		if stage in d.dungeon_bands[key]:band=key;break
	for row in d.get("dungeon",[]):
		if row.event==event and row.band==band and not row.variants.is_empty():return row.variants[posmod(index,row.variants.size())]
	return ""
