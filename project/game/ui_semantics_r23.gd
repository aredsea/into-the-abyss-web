extends RefCounted
## Observable presentation from 65/66. HTML tags and Risu host storage are not UI data.
const R=preload("res://game/panels_rules_r22.gd")
const L=preload("res://game/localization_r22.gd")
static var FX=JSON.parse_string(FileAccess.get_file_as_string("res://data/gear_effects.json"))
const RARITY={"common":"일반","fine":"고급","rare":"희귀","epic":"영웅","legend":"전설"}
const COLORS={"common":Color("#8D8A83"),"fine":Color("#5F8A6E"),"rare":Color("#4F74A3"),"epic":Color("#7B5A9C"),"legend":Color("#B08A3E")}
static var PASS=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui-passives-r23.json"))
static var template=preload("res://game/persona_rules.gd").new()
static var ICONS=JSON.parse_string(FileAccess.get_file_as_string("res://data/ui-gear-icons-r23.json"))
static func icon(item: Dictionary) -> String:return ICONS.get(item.get("id",""),"gear-"+str(item.get("shape","")).replace("_","-"))
static func icon_path(item: Dictionary) -> String:return "res://assets/ui-gear-r23/"+icon(item)+".webp"
static func tile(item: Dictionary,action: Variant=null,sub: Variant=null,lang="ko") -> Dictionary:
	var text=L.t(item.name,lang)+" Lv "+str(int(FX.equip_lv[item.rarity]))+(" · "+L.u(sub,{},lang) if sub is String else "")
	return {"text":text,"icon":icon(item),"rarity":item.rarity,"action":action if action is String else ""}
static func passive_block(title: String,node: Variant,lineage: String,lang="ko") -> Dictionary:
	if not node is Dictionary:return {}
	var result={"title":L.u(title,{},lang)+" "+L.t(node.name,lang),"entries":[],"tiers":[]}
	for e in node.get("own",[]):result.entries.append([L.t(e.name,lang),"",template.parameter_text(L.t(e.text,lang))])
	if node.has("lin"):
		for k in ([lineage] if lineage in ["dog","cat"] else ["dog","cat"]):
			var e=node.lin[k];result.entries.append([L.t(e.name,lang),"" if lineage in ["dog","cat"] else L.t("개과" if k=="dog" else "고양이과",lang),template.parameter_text(L.t(e.text,lang))])
	for i in mini(2,node.get("tier",[]).size()):result.tiers.append([L.u("{n}명",{"n":i+2},lang),template.parameter_text(L.t(node.tier[i],lang)),L.u("준비 중",{},lang) if node.get("wip",[]).size()>i and node.wip[i] else ""])
	return result
static func passive_groups(job: String,race: String,lineage: String,nation: String,lang="ko") -> Array:
	var c=PASS.classes.get(job,{});var result=[{"title":L.u("직업 패시브",{},lang),"entries":[[L.u("직업을 고르면 보입니다.",{},lang),"",""]] if c.is_empty() else [[L.t(c.name,lang),"",template.parameter_text(L.t(c.text,lang))]],"tiers":[]}]
	for e in [["종족 특성",PASS.races.get(race)],["출신 특성",PASS.nations.get(nation)]]:
		var b=passive_block(e[0],e[1],lineage if e[0]=="종족 특성" else "",lang)
		if not b.is_empty():result.append(b)
	return result
static func clean(s: String) -> String:
	return " ".join(s.split(" ",false)).replace("\n"," ").strip_edges()
static func button(action: String,label: String,cls="",sub="") -> Dictionary:
	return {"action":action,"text":clean(label+(" "+sub if sub!="" else "")),"selected":"on" in cls.split(" "),"disabled":"off" in cls.split(" ")}
static func bar(cur: float,maximum: float) -> float:
	return float("%.3f"%clampf(cur/maximum if maximum>0 else 0,0,1))
static func experience(level: int,xp: int,lang="ko") -> Dictionary:
	var k=.4 if level<10 else (.6+.4*(level-10)/20.0 if level<30 else 1.0)
	var need=int(floor((60*level+10*level*level)*k+.5))
	return {"text":L.u("경험치",{},lang)+" "+(L.u("최대 레벨",{},lang) if level>=40 else "%d / %d"%[maxi(0,xp),need]),"ratio":1.0 if level>=40 else bar(maxi(0,xp),need)}
static func kind(active: bool,lang="ko") -> String:return L.u("액티브" if active else "패시브",{},lang)
static func element(el: String,lang="ko") -> String:
	return L.t(R.DATA.els[el],lang) if el!="none" and R.DATA.els.has(el) else L.u("무속성",{},lang)
static func stats(st: Dictionary,lang="ko") -> Array:
	var out=[]
	for e in [["hp","HP"],["mp","MP"],["str","힘"],["agi","민첩"],["int","지능"],["def","방어"],["spd","속도"]]:out.append([L.t(e[1],lang),R.Value.text(st[e[0]]) if st.has(e[0]) else "-"])
	return out
static func tabs(tab: String,lang="ko") -> Array:
	var pattern=RegEx.new();pattern.compile("^[A-Za-z]+");var prefix=pattern.search(tab)
	var grp=prefix.get_string() if prefix!=null else ""
	if grp not in ["el","cls"]:grp=""
	var out=[]
	for e in [["all","전체",tab==""],["rec","영입",tab=="rec"],["el","속성",grp=="el"],["cls","직업",grp=="cls"]]:out.append(button("cx_f_"+e[0],L.u(e[1],{},lang),"on" if e[2] else ""))
	if grp!="":
		out.append(button("cx_f_"+grp,L.u("모두",{},lang),"on" if tab==grp else ""))
		var entries=[]
		if grp=="el":
			for el in R.DATA.el_order:entries.append([el,R.DATA.els[el]])
		else:
			for c in R.DATA.classes:entries.append([c.id,c.name])
		for e in entries:out.append(button("cx_f_"+grp+"_"+e[0],L.u(e[1],{},lang),"on" if tab==grp+"_"+e[0] else ""))
	return out
static func chip(key: String,value: String,label: String,current: String,lang="ko") -> Dictionary:
	return button("bg_f_"+key+"_"+("all" if value=="" else value),L.u(label,{},lang),"on" if value==current else "")
static func fxline(key: String,value: float,job: String,lang="ko") -> String:
	var d=FX.base.get(key,FX.affix.get(key,{}));var name=R.cls(job).get("line",d.get("name",key)) if key=="stat" else d.get("name",key)
	return L.t(name,lang)+" "+("+" if value>=0 else "")+R.fnum(value)+d.get("unit","")
static func gear_groups(rolled: Dictionary,lang="ko") -> Array:
	var groups=[];var lines=[]
	for key in R.DATA.fx_order:
		if rolled.item.base.has(key):lines.append(fxline(key,rolled.fx.get(key,rolled.item.base[key]),rolled.item.cls,lang))
	if not lines.is_empty():groups.append({"title":L.u("기본 효과",{},lang),"lines":lines})
	lines=[]
	for a in rolled.affix:lines.append(fxline(a[0],a[1],rolled.item.cls,lang))
	if not lines.is_empty():groups.append({"title":L.u("무작위 옵션",{},lang),"lines":lines})
	if rolled.get("unique") is Dictionary and not rolled.unique.is_empty():groups.append({"title":L.u("고유 효과",{},lang),"lines":[L.t(rolled.unique.name,lang),L.t(rolled.unique.text,lang)]})
	return groups
static func observe(fn: String,args: Array,lang="ko") -> Dictionary:
	var out={"text":"","buttons":[],"bars":[]};var words=[]
	match fn:
		"element":out.text=element(args[0],lang)
		"kind":out.text=kind(args[0],lang)
		"pass_block","passives":
			var blocks=[passive_block(args[0],args[1],args[2],lang)] if fn=="pass_block" else passive_groups(args[0],args[1],args[2],args[3],lang)
			for b in blocks:
				if b.is_empty():continue
				words.append(b.title)
				for e in b.entries:words.append_array(e)
				for t in b.tiers:words.append_array(t)
		"stats":
			for e in stats(args[0] if args[0] is Dictionary else {},lang):words.append_array(e)
		"notice":out.text=args[0]
		"bar":out.bars=[bar(args[1],args[2])]
		"expbar":
			var g=args[0];var cid=args[1];var xp=g.persona.exp if cid=="persona" else g.exp.get(cid,0)
			var e=experience(R.level(g,cid),R.Value.integer(xp),lang);out.text=e.text;out.bars=[e.ratio]
		"tabs":out.buttons=tabs(args[0],lang)
		"button":out.buttons=[button(args[0],args[1],args[2],args[3])]
		"chip":out.buttons=[chip(args[0],args[1],args[2],args[3],lang)]
		"fxline":out.text=fxline(args[0],args[1],args[2],lang)
		"gear_fx","gear_card":
			var r=args[0]
			if fn=="gear_card":words.append_array([L.t(r.item.name,lang),L.t(RARITY.get(r.item.rarity,r.item.rarity),lang),"· Lv",str(int(r.lv))]);out.icons=[icon(r.item)];out.rarity=r.item.rarity
			for g in gear_groups(r,lang):words.append(g.title);words.append_array(g.lines)
		"gear_icon":out.icons=[icon(args[0])]
		"gear_tile":
			var t=tile(args[0],args[1],args[2],lang);out.icons=[t.icon];out.rarity=t.rarity
			if t.action!="":out.buttons=[button(t.action,t.text)]
			else:out.text=t.text
	for b in out.buttons:words.append(b.text)
	if not words.is_empty():out.text=clean(" ".join(words))
	return out
