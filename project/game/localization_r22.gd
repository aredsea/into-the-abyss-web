extends RefCounted
## One source-backed dictionary for P1/P7/P10/settings. Never translate save values.
const DATA=preload("res://data/localization-r22.json").data
const SOURCE=preload("res://data/ui-source-locale-r23.json").data
const Josa=preload("res://game/josa_r22.gd")
const Pack=preload("res://game/locale_pack_r23.gd")
const Value=preload("res://game/ui_value_r23.gd")
const NATIVE=preload("res://data/native-locale-r24.json").data
static var packs=Pack.new({"en":JSON.stringify(SOURCE.ui)},JSON.stringify(SOURCE.words))
static var patterns=[]
static var cache={}
static func persona_name(s: Dictionary) -> String:
	var name=str(s.get("persona",{}).get("name",""))
	return ("You" if language(s)=="en" else "당신") if name in ["","{{user}}"] else name
static func display(value: String,s: Dictionary) -> String:
	var korean=RegEx.new();korean.compile("[가-힣]")
	# Already translated English (including authored dialogue) is final copy.
	var translated=render(value,language(s)) if language(s)!="en" or korean.search(value)!=null else value
	return translated.replace("{{user}}",persona_name(s))
static func authored_display(value: String,s: Dictionary) -> String:
	# Prose needs a complete translation, never generic UI-template substitution.
	return value.replace("{{user}}",persona_name(s))
static func configure_packs(raw: Variant=null,words: Variant=null) -> void:
	packs=Pack.new({"en":JSON.stringify(SOURCE.ui)} if raw==null else raw,JSON.stringify(SOURCE.words) if words==null else words)
	patterns=[];cache={}
static func change_raw_pack(lang: String,raw: String,words: String) -> void:
	packs.raw[lang]=raw;packs.words_raw=words
static func ui_pack(lang: String) -> Variant:return packs.pack(lang)
static func en_dict() -> Variant:return packs.dictionary()
static func _lookup(table: Variant,key: Variant,fallback: Variant) -> Variant:
	var v=table.get(key) if table is Dictionary else null
	if table is Array and (key is int or key is float) and key==floor(key) and key>=1 and key<=table.size():v=table[int(key)-1]
	return v if Value.truth(v) else fallback
static func canonical_names(value: String) -> String:
	# Presentation only: historical save/log bytes remain untouched.
	return value.replace("힐데가르트","힐데가").replace("베렝가","베렌가").replace("바르구트","바르굿")
static func language(s: Dictionary) -> String:return "en" if s.get("settings",{}).get("lang","")=="en" else "ko"
static func t(value: Variant,lang="ko") -> Variant:return _lookup(en_dict(),value,value) if lang=="en" and value is String else value
static func c1_en(value: Variant=null) -> Variant:return _lookup(en_dict(),value,value) if Value.truth(value) else ""
static func u(src: String,vars: Variant=null,lang="ko") -> String:
	var tpl=_lookup(ui_pack(lang),src,src) if lang!="ko" else src
	if vars==null or not tpl.contains("{"):return tpl
	var re=RegEx.new();re.compile("\\{([A-Za-z0-9_]+):?([^{}]*)\\}")
	var out="";var pos=0
	for m in re.search_all(tpl):
		out+=tpl.substr(pos,m.get_start()-pos);var key=m.get_string(1)
		if not vars.has(key) or vars[key]==null:out+=m.get_string()
		else:
			var v=t(vars[key],lang) if vars[key] is String else str(int(vars[key])) if (vars[key] is float or vars[key] is int) and vars[key]==floor(vars[key]) else str(vars[key]);out+=v
			if m.get_string(2)!="" and lang=="ko":out+=Josa.tail(v,m.get_string(2),lang)
		pos=m.get_end()
	return out+tpl.substr(pos)
static func _patterns() -> void:
	if not patterns.is_empty():return
	var token=RegEx.new();token.compile("\\{([A-Za-z0-9_]+):?([^{}]*)\\}")
	var all=NATIVE.duplicate();all.merge(DATA.ui,false)
	for src in all:
		var matches=token.search_all(src)
		if matches.is_empty():continue
		# Already formatted Latin/numeric text has no language to infer. Generic
		# placeholder templates can otherwise consume punctuation in HP/MP values.
		var korean=RegEx.new();korean.compile("[가-힣]")
		if korean.search(token.sub(src,"",true))==null and not NATIVE.has(src):continue
		# Variable-only templates cannot identify formatted text safely.
		if token.sub(src,"",true).strip_edges()=="":continue
		var expression="^";var pos=0;var keys=[]
		for m in matches:
			for ch in src.substr(pos,m.get_start()-pos):expression+=("\\" if ch in "\\.^$|?*+()[]{}" else "")+ch
			# Runtime formatted counts must not capture an entire Korean sentence.
			expression+="([+-]?[0-9]+(?:\\.[0-9]+)?)" if m.get_string(1) in ["n","exp","gold","floor","turns"] else "(.+?)";keys.append(m.get_string(1));pos=m.get_end()
		for ch in src.substr(pos):expression+=("\\" if ch in "\\.^$|?*+()[]{}" else "")+ch
		var re=RegEx.new();re.compile(expression+"$");patterns.append({"re":re,"src":src,"keys":keys})
static func render(value: String,lang="ko") -> String:
	value=canonical_names(value)
	if lang!="en":return value
	if NATIVE.has(value):return NATIVE[value]
	if DATA.ui.has(value) and DATA.ui[value]!=value:return DATA.ui[value]
	if SOURCE.words.has(value):return c1_en(value)
	if DATA.words.has(value):return DATA.words[value]
	if cache.has(value):return cache[value]
	_patterns()
	# Native templates can span separators (counts, potion effects and headings).
	for item in patterns:
		if not NATIVE.has(item.src):continue
		var m=item.re.search(value)
		if m:
			var result=NATIVE[item.src]
			for i in item.keys.size():result=result.replace("{"+item.keys[i]+"}",render(m.get_string(i+1),lang))
			cache[value]=result;return result
	# Join fields before generic templates; a {name} template must not swallow metadata.
	for separator in ["\n"," · "," / "]:
		if value.contains(separator):
			var pieces=[]
			for part in value.split(separator):pieces.append(render(part,lang))
			return separator.join(pieces)
	_patterns()
	for item in patterns:
		var m=item.re.search(value)
		if m:
			var vars={}
			for i in item.keys.size():vars[item.keys[i]]=render(m.get_string(i+1),lang)
			var result=u(item.src,vars,lang)
			if NATIVE.has(item.src):
				result=NATIVE[item.src]
				for key in vars:result=result.replace("{"+key+"}",vars[key])
			cache[value]=result;return result
	return value
static func profile(id: String,fallback: Dictionary,lang="ko") -> Dictionary:return DATA.profiles.get(id,fallback) if lang=="en" else fallback
static func fit_title(label: Label,maximum: int) -> void:
	var width=label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,maximum).x
	label.add_theme_font_size_override("font_size",mini(maximum,maxi(18,int(floor(maximum*label.size.x/maxf(1,width))))))

static func fit_box(node: Control) -> void:
	# Fixed artwork slots keep their geometry; wrap buttons before reducing type.
	if node is Button and not str(node.get_meta("source_action","")).begins_with("p7_filter_"):node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	var inset=Vector2.ZERO
	if node is Button:
		var style=node.get_theme_stylebox("normal")
		inset=Vector2(style.get_content_margin(SIDE_LEFT)+style.get_content_margin(SIDE_RIGHT),style.get_content_margin(SIDE_TOP)+style.get_content_margin(SIDE_BOTTOM))
	var available=node.size-inset
	# Label text can temporarily expand its minimum size before clip_text/layout
	# settles. Existing canvas metrics retain the authored slot width.
	if node.has_meta("metric_index"):
		var ancestor=node.get_parent();var index=int(node.get_meta("metric_index"))
		while ancestor!=null:
			if ancestor.has_method("localized"):
				var measures=ancestor.get("metrics")
				if measures is Array and index>=0 and index<measures.size() and measures[index] is Dictionary and measures[index].has("available"):
					available.x=minf(available.x,float(measures[index].available)-inset.x);break
			ancestor=ancestor.get_parent()
	var fs=node.get_theme_font_size("font_size")
	var minimum=mini(fs,10)
	while fs>minimum:
		var needed=node.get_theme_font("font").get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,available.x if node.autowrap_mode!=TextServer.AUTOWRAP_OFF else -1,fs)
		if needed.x<=available.x+1 and needed.y<=available.y+1:break
		fs-=1
	node.add_theme_font_size_override("font_size",fs)
