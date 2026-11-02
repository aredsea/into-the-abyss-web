extends RefCounted
const L=preload("res://game/localization_r22.gd")
static func difficulty(s: Dictionary) -> Dictionary:
	var v=s.get("settings",{}).get("diff",2);var n=2
	if (v is float or v is int or v is String) and str(v).is_valid_float():n=int(floor(float(v)))
	return L.DATA.difficulties[(n if n>=1 and n<=3 else 2)-1]
static func apply(s: Dictionary,values: Dictionary) -> bool:
	if not s.get("settings",{}) is Dictionary:return false
	var changed=false
	for key in ["lang","diff","chron"]:
		var v=values.get(key)
		if not v is String:continue
		if (key=="lang" and v not in ["ko","en"]) or (key=="diff" and v not in ["1","2","3"]) or (key=="chron" and v not in ["0","1"]):continue
		if not s.has("settings"):s.settings={}
		s.settings[key]=v if key=="lang" else int(v);changed=true
	return changed
