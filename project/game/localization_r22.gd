extends RefCounted
## One source-backed dictionary for P1/P7/P10/settings. Never translate save values.
const DATA=preload("res://data/localization-r22.json").data
const Josa=preload("res://game/josa_r22.gd")
static var patterns=[]
static var cache={}
static func canonical_names(value: String) -> String:
	# Presentation only: historical save/log bytes remain untouched.
	return value.replace("힐데가르트","힐데가").replace("베렝가","베렌가").replace("바르구트","바르굿")
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
		# A template made only of variables (e.g. {action}{cost}) cannot
		# identify a formatted UI string. Splitting arbitrary words corrupts fallback.
		if token.sub(src,"",true).strip_edges()=="":continue
		var expression="^";var pos=0;var keys=[]
		for m in matches:
			for ch in src.substr(pos,m.get_start()-pos):expression+=("\\" if ch in "\\.^$|?*+()[]{}" else "")+ch
			# Runtime formatted counts must not capture an entire Korean sentence.
			expression+="([+-]?[0-9]+(?:\\.[0-9]+)?)" if m.get_string(1) in ["n","exp","gold"] else "(.+?)";keys.append(m.get_string(1));pos=m.get_end()
		for ch in src.substr(pos):expression+=("\\" if ch in "\\.^$|?*+()[]{}" else "")+ch
		var re=RegEx.new();re.compile(expression+"$");patterns.append({"re":re,"src":src,"keys":keys})
static func render(value: String,lang="ko") -> String:
	value=canonical_names(value)
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

static func fit_box(node: Control) -> void:
	# Fixed artwork slots keep their geometry; wrap buttons before reducing type.
	if node is Button:node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var inset=Vector2.ZERO
	if node is Button:
		var style=node.get_theme_stylebox("normal")
		inset=Vector2(style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT),style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM))
	var available=node.size-inset
	var fs=node.get_theme_font_size("font_size")
	var minimum=mini(fs,10)
	while fs>minimum:
		var needed=node.get_theme_font("font").get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,available.x if node.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		if needed.x<=available.x+1 and needed.y<=available.y+1:break
		fs-=1
	node.add_theme_font_size_override("font_size",fs)
