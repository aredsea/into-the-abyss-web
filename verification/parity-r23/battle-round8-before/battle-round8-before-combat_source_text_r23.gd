extends RefCounted
const Lex=preload("res://game/combat_text_r23.gd")
const Josa=preload("res://game/josa_r22.gd")
const Text=preload("res://game/combat_display_r22.gd")
static func t(value: String,lang: String="ko") -> String:return Lex.WORDS.get(value,value) if lang=="en" else value
static func u(src: String,vars: Dictionary={},lang: String="ko") -> String:
	var tpl=Lex.UI.get(src,src) if lang=="en" else src
	var re=RegEx.new();re.compile("\\{([A-Za-z0-9_]+):?([^{}]*)\\}")
	var out="";var pos=0
	for m in re.search_all(tpl):
		out+=tpl.substr(pos,m.get_start()-pos);var key=m.get_string(1)
		if not vars.has(key):out+=m.get_string()
		else:
			var v=t(vars[key],lang) if vars[key] is String else Text.lua_string(vars[key]);out+=v
			if m.get_string(2)!="" and lang=="ko":out+=Josa.tail(v,m.get_string(2),lang)
		pos=m.get_end()
	return out+tpl.substr(pos)
