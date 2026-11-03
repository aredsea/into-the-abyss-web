extends RefCounted
## The source panel has a few hardcoded Korean filter labels even in English.
## Apply its own T dictionary to those labels for the requested language repair.
static func text(value: String,lang: String) -> String:
	if lang!="en":return value
	var locale=preload("res://game/localization_r22.gd")
	var keys=["화염","냉기","번개","바람","신성","어둠","무","사수"]
	for c in preload("res://data/panels-r22.json").data.classes:keys.append(c.name)
	keys.sort_custom(func(a,b):return a.length()>b.length())
	var out=" "+value+" "
	for key in keys:out=out.replace(" "+key+" "," "+str(locale.render(key,"en"))+" ")
	return out.strip_edges()
