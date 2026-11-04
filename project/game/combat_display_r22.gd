extends RefCounted
const Locale=preload("res://game/localization_r22.gd")
const Josa=preload("res://game/josa_r22.gd")
static func fixed_decimal(value: float,digits: int) -> String:
	# C printf rounds the stored binary64 value, not value*100 (which may
	# round a nearby binary value onto a decimal half). Keep the significand
	# exact through integer arithmetic, including signed zero and ties to even.
	if digits<0 or digits>3 or not is_finite(value) or absf(value)>=1e14:return ("%."+str(digits)+"f")%value
	var bytes=PackedFloat64Array([value]).to_byte_array();var negative=(bytes[7]&128)!=0
	var bits=PackedFloat64Array([absf(value)]).to_byte_array().decode_s64(0)
	var exponent=(bits>>52)&2047;var mantissa=bits&0xfffffffffffff
	if exponent!=0:mantissa|=1<<52
	var power=(int(exponent)-1023-52 if exponent!=0 else -1074)+digits
	var numerator=mantissa*([1,5,25,125][digits]);var rounded=0
	if power>=0:rounded=numerator<<power
	elif -power<63:
		var shift=-power;rounded=numerator>>shift
		var remainder=numerator-(rounded<<shift);var half=1<<(shift-1)
		if remainder>half or (remainder==half and rounded%2==1):rounded+=1
	var scale=[1,10,100,1000][digits]
	@warning_ignore("integer_division")
	var whole=rounded/scale
	return ('-' if negative else '')+str(whole)+('.'+str(rounded%scale).pad_zeros(digits) if digits>0 else '')
static func fixed_two(value: float) -> String:return fixed_decimal(value,2)
static func ratio_text(value: float,maximum: float):
	return 0 if maximum<=0 else fixed_decimal(clampf(value/maximum*100,0,100),1)
static func tag_class(value: String) -> String:
	for pair in [["약점","w"],["고갈","a"],["여우불","f"]]:
		if pair[0] in value:return pair[1]
	return ""
static func scale_style(value: Variant) -> String:
	return ";--k:"+lua_string(value) if (value is float or value is int) and value>1 else ""
static func percent(value: float) -> int:return int(floor(value*100+.5+1e-9))
static func lua_string(value: Variant) -> String:
	if value==null:return "nil"
	if value is bool:return "true" if value else "false"
	if (value is int or value is float) and value==floor(value):return str(int(value))
	return str(value)
static func unit_name(u: Dictionary,lang: String="ko") -> String:return Locale.t(u.name,lang)
static func subject(u: Dictionary,lang: String="ko") -> String:
	var name=unit_name(u,lang)
	return "<b>"+name+"</b>"+Josa.tail(name,"이가",lang)
static func bold_particle(word: String,key: String,lang: String="ko") -> String:
	return "<b>"+word+"</b>"+Josa.tail(word,key,lang)
static func short_name(value: Variant) -> String:
	var s=lua_string(value);var out="";var pos=0
	while pos<s.length():
		if s[pos]!="(":out+=s[pos];pos+=1;continue
		var depth=1;var end=pos+1
		while end<s.length() and depth>0:
			if s[end]=="(":depth+=1
			elif s[end]==")":depth-=1
			end+=1
		if depth!=0:out+=s[pos];pos+=1;continue
		while not out.is_empty() and out[-1] in [" ","\t","\r","\n","\u000b","\u000c"]:out=out.left(-1)
		pos=end
	return out
static func verb_connection(value: Variant):
	var s=lua_string(value) if value!=null and not (value is bool and not value) else ""
	if not s.ends_with("다") or s.length()<2:return false
	var body=s.left(-1);var cp=body.unicode_at(body.length()-1)
	if cp<0xac00 or cp>0xd7a3 or (cp-0xac00)%28!=20:return false
	return body.left(-1)+("베어" if cp==0xbcb4 else String.chr(cp-20))
static func boss_half(b) -> String:
	for e in b.living(false):
		if e.get("grade","")=="boss":return " (보스는 절반)"
	return ""
## Exact source-record fragments for replay/inspection. This is independent of
## the native scene layout, and does not mutate a saved state or its event list.
static func source_frame(state: Dictionary,definitions: Array,lang: String="ko",profile: Variant=null,profile_available: bool=false) -> Dictionary:
	var fx=load("res://game/combat_fx_r23.gd").new();fx.definitions=definitions;fx.lang=lang;fx.profile=profile;fx.profile_available=profile_available
	var hud=load("res://game/combat_hud_r23.gd").new();hud.definitions=definitions;hud.lang=lang
	var events=state.get('ev',{}).get('list',[]) if state.get('ev') is Dictionary else []
	var D=state.ev.T+.8 if state.get('ev') is Dictionary else 0
	return {"layers":fx.render_events(state,events),"dynamic":hud.dyn(state,D),"log":hud.log_html(state)}
## 40-fx callback schedule; native art and animation assets are unchanged.
static func schedule(e: Dictionary) -> Array:
	var out=[]; var t=float(e.t); var k=e.k; var tg=e.get("tg",[])
	var add=func(kind,at): out.append({"kind":kind,"t":at})
	var result=func(r,at,tier):
		add.call("hit",at)
		if r.get("c",0)==1 or not r.get("tags",[]).filter(func(tag):return "약점" in tag).is_empty(): tier=maxi(tier,1)
		if e.get("last",false) and k in ["atk","snipe","wave","burst"]: tier=2
		var delay=[0,.1,.15][tier]
		add.call("critical" if r.get("c",0)==1 else "number",at+delay)
		if r.get("sh",0)>0 and r.sh<r.d: add.call("number",at+delay+.25)
	match k:
		"atk","snipe":
			if e.get("nm","")!="일반 공격": add.call("plaque",t+.1)
			result.call(tg[0],e.get("ht",t+.4),0 if e.get("nm","")=="일반 공격" else 1)
		"wave","burst":
			add.call("plaque",t+(.1 if k=="wave" else 1.2))
			for n in range(tg.size()): result.call(tg[n],e.ht+(.05 if k=="burst" else 0)+n*.07,1)
		"eatk": result.call(tg[0],t+(.62 if e.get("shoot",0)==1 else .52),1 if e.get("big",0)==1 else 0)
		"shield":
			add.call("plaque",t+1.0)
			for n in range(tg.size()): add.call("number",t+1.5+(n+1)*.1)
		"taunt","oath","mark": add.call("plaque",t+.1)
		"def": add.call("plaque",t+.05)
		"rev": add.call("plaque",t+.1); add.call("number",t+.3)
		"chg": add.call("plaque",t+.1); add.call("number",t+.8)
		"cut": add.call("cut",t)
		"recover": add.call("number",t+.5)
		"eall":
			for n in range(tg.size()): result.call(tg[n],t+.62+n*.07,1 if e.get("big",0)==1 else 0)
		"edeb","eheal","item":
			if k=="item": add.call("plaque",t+.1)
			for r in tg: add.call("number",t+(.6 if k=="edeb" else .7))
		"ecut": add.call("number",t+.3)
		"adot": result.call(tg[0],t+.3,0)
	return out

static func chips(b,u: Dictionary) -> Array:
	if u.hp<=0: return ["부상 이탈" if u.has("base") else "쓰러짐"]
	var out=[]; var shield=u.get("shield",b.fx(u,"shield")); var x=b.x(u); var effects=u.effects
	if shield>0: out.append("보호막 %d"%shield)
	if effects.has("taunt"): out.append("도발")
	if effects.has("guard"): out.append("방어")
	if u.get("charging",false) or u.get("charged",false): out.append("충전 (다음 차례 발동)")
	if not x.get("protect","").is_empty(): out.append("보호 → "+b.unit(x.protect).name)
	if x.get("hidden",false): out.append("은신")
	if effects.has("silence"): out.append("침묵")
	if not x.get("cover","").is_empty(): out.append("서약 → "+b.unit(x.cover).name)
	if effects.has("rift_charge"): out.append("심연 깎기 ×1.5")
	for pair in [["psguard","전술 피해 감소"],["pscrit","치명"],["persona_regen","재생"]]:
		if effects.has(pair[0]):out.append(pair[1]+" (%d턴)"%effects[pair[0]].turns)
	if effects.has("mark"): out.append("표식")
	if effects.has("foxflame"): out.append("여우불 %d턴"%effects.foxflame.turns)
	for entry in [["attack_up","공격 +"],["defense_up","방어 +"],["attack_down","공격 −"],["defense_down","방어 −"],["haste","속도 +"],["slow","속도 −"]]:
		if effects.has(entry[0]): out.append(entry[1]+"%d%% (%d턴)"%[floor(b.fx(u,entry[0])*100),effects[entry[0]].turns])
	for entry in [["blood","피의 갈증"],["fortified_guard","굳건한 방어"],["backstep","백스텝"]]:
		if effects.has(entry[0]): out.append(entry[1]+" (%d턴)"%effects[entry[0]].turns)
	var n=0; var turns=0
	for key in ["dot","corrosion","bleed"]:
		if effects.has(key): n+=effects[key].get("stacks",[0]).size(); turns=maxi(turns,int(effects[key].turns))
	if n>0: out.append("지속 피해 ×%d (%d턴)"%[n,turns])
	n=0; turns=0
	for i in range(4):
		if effects.has("enemy_dot_%d"%i): n+=1; turns=maxi(turns,effects["enemy_dot_%d"%i].turns)
	if n>0: out.append("지속 피해 ×%d (%d턴)"%[n,turns])
	if effects.has("enemy_attack_self"): out.append("강화")
	if u.get("once",false): out.append("노트 사용")
	if x.get("saved",false): out.append("판결 사용")
	return out

## Full source-record tiles for imported/replayed battle records. Native scene
## layout and user save serialization remain owned by the existing renderer.
static func source_tiles(context: Dictionary) -> String:
	var tiles=load('res://game/combat_tiles_r23.gd').new()
	tiles.definitions=context.defs;tiles.skills=context.skills;tiles.lang=context.get('lang','ko')
	tiles.profile=context.get('profile');tiles.profile_available=context.get('profile_available',false)
	match context.kind:
		'ally':return tiles.ally_tile(context.state,int(context.slot),context.L,context.K,context.get('item_ok',false))
		'raid':return tiles.raid_field(context.state,context.L,context.K,context.visible,context.get('target',false))
	return tiles.enemy_tile(context.state,int(context.slot),context.L,context.K,context.visible,context.kind=='boss')
