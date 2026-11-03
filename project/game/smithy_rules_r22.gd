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

# 82-smithy.fx_clear. Keep source field names at this transient boundary; the
# native screen uses a computed view of these two mutually exclusive effects.
func fx_clear(g: Dictionary) -> Variant:
	g.erase("forge_fx");g.erase("proc_fx");return null

func _decimal_multiply(s: String,factor: int) -> String:
	var out="";var carry=0
	for i in range(s.length()-1,-1,-1):
		var v=(s.unicode_at(i)-48)*factor+carry
		out=String.chr(48+v%10)+out;carry=v/10
	return (str(carry) if carry else "")+out

# Lua/C %g: six significant decimal digits, ties to even, exponent outside
# [-4,5]. Convert the exact IEEE double to decimal before rounding so values
# next to a decimal half do not suffer a second floating-point rounding.
func pct(value: Variant) -> String:
	var v=0.0 if value==null or (value is bool and not value) else float(value)
	var bits=PackedFloat64Array([v]).to_byte_array().decode_u64(0)
	var negative=(bits & (-9223372036854775807-1))!=0
	var sign_text="-" if negative else ""
	if is_nan(v):return sign_text+"nan"
	if is_inf(v):return sign_text+"inf"
	if v==0:return sign_text+"0"
	var exponent=int((bits>>52)&2047);var mantissa=bits&4503599627370495
	var binary_exp=-1074
	if exponent!=0:mantissa+=4503599627370496;binary_exp=exponent-1075
	var exact=str(mantissa);var scale=0
	if binary_exp>=0:
		while binary_exp>=29:exact=_decimal_multiply(exact,536870912);binary_exp-=29
		if binary_exp>0:exact=_decimal_multiply(exact,1<<binary_exp)
	else:
		scale=-binary_exp;var remaining=scale
		while remaining>=12:exact=_decimal_multiply(exact,244140625);remaining-=12
		var factor=1
		for i in range(remaining):factor*=5
		if remaining>0:exact=_decimal_multiply(exact,factor)
	var decimal_exp=exact.length()-scale-1
	var digits=exact.substr(0,6).rpad(6,"0")
	if exact.length()>6:
		var next_digit=exact.unicode_at(6)-48
		var rest=exact.substr(7).replace("0","")
		if next_digit>5 or (next_digit==5 and (not rest.is_empty() or int(digits)%2==1)):
			digits=str(int(digits)+1)
			if digits.length()>6:digits="100000";decimal_exp+=1
	if decimal_exp< -4 or decimal_exp>=6:
		var tail=digits.substr(1)
		while tail.ends_with("0"):tail=tail.left(-1)
		return sign_text+digits[0]+("."+tail if not tail.is_empty() else "")+"e"+("-" if decimal_exp<0 else "+")+str(absi(decimal_exp)).pad_zeros(2)
	var point=decimal_exp+1;var text=""
	if point<=0:text="0."+"".rpad(-point,"0")+digits
	elif point>=6:text=digits+"".rpad(point-6,"0")
	else:text=digits.substr(0,point)+"."+digits.substr(point)
	if "." in text:
		while text.ends_with("0"):text=text.left(-1)
		if text.ends_with("."):text=text.left(-1)
	return sign_text+text

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
