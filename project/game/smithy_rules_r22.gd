extends "res://game/commerce_rules_r21.gd"
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
