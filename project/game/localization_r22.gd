extends RefCounted
## One source-backed dictionary for P1/P7/P10/settings. Never translate save values.
const DATA=preload("res://data/localization-r22.json").data
const Josa=preload("res://game/josa_r22.gd")
static var patterns=[]
static var cache={}
static func language(s: Dictionary) -> String:return "en" if s.get("settings",{}).get("lang","")=="en" else "ko"
static func t(value: String,lang="ko") -> String:return DATA.words.get(value,value) if lang=="en" else value
static func u(src: String,vars: Dictionary={},lang="ko") -> String:
	var tpl=DATA.ui.get(src,src) if lang=="en" else src
	var re=RegEx.new();re.compile("\\{([A-Za-z0-9_]+):?([^{}]*)\\}")
	var out="";var pos=0
	for m in re.search_all(tpl):
		out+=tpl.substr(pos,m.get_start()-pos);var key=m.get_string(1)
		if not vars.has(key):out+=m.get_string()
		else:
			var v=t(vars[key],lang) if vars[key] is String else str(int(vars[key])) if (vars[key] is float or vars[key] is int) and vars[key]==floor(vars[key]) else str(vars[key]);out+=v
			if m.get_string(2)!="" and lang=="ko":out+=Josa.tail(v,m.get_string(2),lang)
		pos=m.get_end()
	return out+tpl.substr(pos)
static func _patterns() -> void:
	if not patterns.is_empty():return
	var token=RegEx.new();token.compile("\\{([A-Za-z0-9_]+):?([^{}]*)\\}")
	for src in DATA.ui:
		var matches=token.search_all(src)
		if matches.is_empty():continue
		var expression="^";var pos=0;var keys=[]
		for m in matches:
			for ch in src.substr(pos,m.get_start()-pos):expression+=("\\" if ch in "\\.^$|?*+()[]{}" else "")+ch
			# Runtime formatted counts must not capture an entire Korean sentence.
			expression+="([+-]?[0-9]+(?:\\.[0-9]+)?)" if m.get_string(1) in ["n","exp","gold"] else "(.+?)";keys.append(m.get_string(1));pos=m.get_end()
		for ch in src.substr(pos):expression+=("\\" if ch in "\\.^$|?*+()[]{}" else "")+ch
		var re=RegEx.new();re.compile(expression+"$");patterns.append({"re":re,"src":src,"keys":keys})
static func render(value: String,lang="ko") -> String:
	if lang!="en":return value
	if DATA.ui.has(value):return DATA.ui[value]
	if DATA.words.has(value):return DATA.words[value]
	if cache.has(value):return cache[value]
	# Join fields before generic templates; a {name} template must not swallow metadata.
	for separator in ["\n"," · "]:
		if value.contains(separator):
			var pieces=[]
			for part in value.split(separator):pieces.append(render(part,lang))
			return separator.join(pieces)
	_patterns()
	for item in patterns:
		var m=item.re.search(value)
		if m:
			var vars={}
			for i in item.keys.size():vars[item.keys[i]]=m.get_string(i+1)
			var result=u(item.src,vars,lang);cache[value]=result;return result
	return value
static func profile(id: String,fallback: Dictionary,lang="ko") -> Dictionary:return DATA.profiles.get(id,fallback) if lang=="en" else fallback
static func fit_title(label: Label,maximum: int) -> void:
	var width=label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,maximum).x
	label.add_theme_font_size_override("font_size",mini(maximum,maxi(18,int(floor(maximum*label.size.x/maxf(1,width))))))
