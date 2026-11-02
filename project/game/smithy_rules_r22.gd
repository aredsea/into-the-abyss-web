extends "res://game/commerce_rules_r21.gd"
static var note_rules=preload("res://game/gear_rules_r22.gd").new()
## Original order is gear catalog order, including the no-character fallback.
func classes(persona_class: String,roster_classes: Array) -> Array:
	var out=[]
	for cls in [persona_class]+roster_classes:
		if cls not in out and catalog.pools.has(cls):out.append(cls)
	if out.is_empty():
		for item in catalog.items:
			if item.cls not in out:out.append(item.cls)
	return out

func process_for(seed: int,n: int,persona_class: String,roster_classes: Array,level: int) -> Dictionary:
	return process_source(seed,n,classes(persona_class,roster_classes),level)

# 82-smithy locals: source-shaped ledger and English scene summary. Receipts keep
# the complete native ledger; the source summary alone has the eight-item limit.
func work_of(value: Variant) -> Variant:
	if not value is Dictionary:return null
	if value.get("forge",[]).size()+value.get("proc",[]).size()==0:return null
	return value

func work_gear_label(value: String) -> String:
	var r=note_rules.gear_roll(value)
	if r.is_empty():return "Unknown equipment"
	var loc=preload("res://game/localization_r22.gd")
	var rarity={"common":"Common","fine":"Uncommon","rare":"Rare","epic":"Epic","legend":"Legendary"}
	return loc.t(r.item.name,"en")+" ("+rarity[r.rarity]+", Lv "+str(int(r.lv))+")"

func work_forge_note(e: Dictionary) -> String:
	return work_gear_label(e.code)+(" succeeded, now +" if e.ok else " failed, stays at +")+str(int(e.lv))

func work_process_note(code: String) -> String:return work_gear_label(code)

func work_cut(list: Array,render: Callable) -> String:
	var out=[]
	for i in range(list.size()):
		if i>=8:out.append("and "+str(list.size()-8)+" more");break
		out.append(render.call(list[i]))
	return "; ".join(out)

func work_note(work: Dictionary) -> String:
	var parts=[]
	if not work.get("forge",[]).is_empty():parts.append("Refining: "+work_cut(work.forge,work_forge_note)+".")
	if not work.get("proc",[]).is_empty():parts.append("Processing: "+work_cut(work.proc,work_process_note)+" received.")
	return " ".join(parts)
