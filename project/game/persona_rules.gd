extends RefCounted
## P1 pure source contracts: 60-create / 74-level / 75-sortie / 26-start.
const KEYS=["str","agi","int","def","spd"]
const Value=preload("res://game/ui_value_r23.gd")
const Locale=preload("res://game/localization_r22.gd")
const TextValues=preload("res://data/persona-text-r23.json").data
var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/persona-r22.json"))
func parameter_text(value: Variant) -> String:
	var s="nil" if value==null else str(value);var re=RegEx.new();re.compile("\\{([A-Za-z0-9_]+)\\.([A-Za-z0-9_]+)(%?)\\}")
	var out="";var pos=0
	for m in re.search_all(s):
		out+=s.substr(pos,m.get_start()-pos)
		var a=m.get_string(1);var b=m.get_string(2)
		var table=TextValues.get("VAR",{}) if a=="var" else TextValues.get("X",{}).get(a,TextValues.get("P",{}).get(a,{}))
		var v=table.get(b)
		if v is int or v is float:
			if m.get_string(3)=="%":v=floor(v*100+.5)
			out+=Value.text(v)
		else:out+=m.get_string()
		pos=m.get_end()
	return out+s.substr(pos)
func syn_text(entry: Dictionary,lang="ko") -> Variant:
	if lang=="ko" or not Value.truth(entry.get("syn2_raw")):return entry.get("syn")
	return Locale.u("{two}, 3명이면 {three}",{"two":parameter_text(Locale.t(entry.syn2_raw,lang)),"three":parameter_text(Locale.t(entry.get("syn3_raw"),lang))},lang)

func by(list: Array,key: String,value: Variant) -> Dictionary:
	for entry in list:
		if entry.get(key)==value:return entry
	return {}

func cls(name: String) -> Dictionary:return by(data.classes,"name",name)
func new_seed(seconds: int,microseconds: int,random_value: int) -> int:
	return posmod(seconds*1000003+microseconds*7919+random_value,2147483646)+1
func total(p: Dictionary) -> int:return clampi(Value.integer(p.get("bonus_total"),5),0,99)
func cap(n: int) -> int:return maxi(3,int((n*3+4)/5))
func spent(p: Dictionary) -> int:
	var n=0
	for k in KEYS:n+=int(p.get("bonus",{}).get(k,0))
	return n
func left(p: Dictionary) -> int:return total(p)-spent(p)
func blocked(race: String,nid: String) -> Dictionary:
	return data.blocked.get(nid,{}).get(by(data.races,"name",race).get("id",""),{})
func nation_id(name: String) -> String:return by(data.nations,"name",name).get("id","")
func note(p: Dictionary,nid: String) -> String:
	var r=by(data.races,"name",p.race).get("id","");var notes=data.notes.get(nid,{})
	if r=="beast":
		var lin=by(data.lineages,"name",p.lineage).get("id","")
		if notes.has(lin):return notes[lin]
	return notes.get(r,"")
func prepare(p: Dictionary) -> Dictionary:
	p.merge({"race":"","lineage":"","nation":"","cls":"","fight":1,"stats":{},"bonus_total":5,"bonus_custom":0},false)
	for key in ["race","lineage","nation","cls"]:
		if not Value.truth(p.get(key)):p[key]=""
	if p.get("fight")==null:p.fight=1
	if not p.get("stats") is Dictionary:p.stats={}
	if not p.get("bonus") is Dictionary or not p.bonus.has("str"):p.bonus={"str":0,"agi":0,"int":0,"def":0,"spd":0}
	p.bonus_total=total(p)
	p.bonus_custom=1 if Value.equal_number(p.get("bonus_custom"),1) else 0
	return p
func view(g: Dictionary) -> Dictionary:
	var p=g.get("persona",{});var b=p.get("bonus",{}) if p is Dictionary else {}
	if not b is Dictionary:b={}
	var out={}
	for key in ["race","lineage","nation","cls"]:out[key]=p.get(key,"") if Value.truth(p.get(key)) else ""
	out.fight=0 if Value.equal_number(p.get("fight"),0) else 1
	if p.get("bonus_total")!=null:out.bonus_total=p.bonus_total
	out.bonus_custom=1 if Value.equal_number(p.get("bonus_custom"),1) else 0
	out.bonus={}
	for key in KEYS:out.bonus[key]=b.get(key,0) if Value.truth(b.get(key)) else 0
	return out
func scenarios(raw: Variant) -> Array:
	# Generated scenarios can be an array or an id-keyed table in old bundles.
	if raw is Array:return raw.duplicate(true)
	if not raw is Dictionary:return []
	var out=raw.values();out.sort_custom(func(a,b):return Value.text(a.get("id"))<Value.text(b.get("id")))
	return out
func set_total(p: Dictionary,n: int,custom: bool) -> int:
	n=clampi(n,0,99);p.bonus_total=n;p.bonus_custom=1 if custom else 0
	var before=spent(p)
	for k in KEYS:p.bonus[k]=mini(int(p.bonus.get(k,0)),cap(n))
	while spent(p)>n:
		var top="";var v=0
		for k in KEYS:
			if p.bonus.get(k,0)>v:top=k;v=p.bonus[k]
		if top.is_empty():break
		p.bonus[top]=v-1
	return before-spent(p)
func ok(p: Dictionary,page) -> bool:
	# Lua numeric equality treats 1 and 1.0 equally; GDScript match is typed.
	if page==1:return p.race!="" and (p.race!="수인" or p.lineage!="")
	if page==2:return p.nation!="" and blocked(p.race,nation_id(p.nation)).is_empty()
	if page==3:return not cls(p.cls).is_empty()
	if page==4:return left(p)==0
	return true
func reach(p: Dictionary,page) -> bool:
	for n in range(1,int(floor(page-1))+1):
		if not ok(p,n):return false
	return true
func calc(p: Dictionary) -> Dictionary:
	var c=cls(p.cls)
	if c.is_empty():return {}
	var out={"hp":c.hp,"mp":c.mp}
	for key in KEYS:out[key]=c[key]+p.get("bonus",{}).get(key,0)*(2 if key=="spd" else 1)
	return out

func create_action(g: Dictionary,arg: String,kind="cr",language: Variant=null) -> void:
	var lang=Locale.language(g) if language==null else language
	if kind=="sc":
		if g.scene!="scenario" or g.scenario!="":return
		if arg.begins_with("pick_"):
			if not by(data.scenarios,"id",arg.substr(5)).is_empty():g.ui.sel=arg.substr(5)
		elif arg=="back":g.scene="create";g.ui.page=5;g.ui.sel=""
		elif arg=="go":
			var sc=by(data.scenarios,"id",g.ui.sel)
			if sc.is_empty():g.ui.msg=Locale.u("먼저 만남을 골라 주세요.",{},lang);return
			g.scenario=sc.id;g.roster=[sc.companion];g.party=[sc.companion];g.gold=300;g.scene="town";g.ui.page=1;g.ui.sel=""
		return
	if g.scene!="create":return
	var p=g.persona;prepare(p)
	var re=RegEx.new();re.compile("^([a-z]+)_?(.*)$");var m=re.search(arg)
	if m==null:return
	var cmd=m.get_string(1);var rest=m.get_string(2)
	match cmd:
		"race":
			var r=by(data.races,"id",rest)
			if r.is_empty():return
			p.race=r.name
			if r.id!="beast":p.lineage=""
			var bl=blocked(p.race,nation_id(p.nation))
			if not bl.is_empty():g.ui.msg=Locale.u("「{nation}」 출신은 이 종족과 맞지 않아 비웠습니다. {reason} 출신을 다시 골라 주세요.",{"nation":p.nation,"reason":bl.m},lang);p.nation=""
		"lin":
			var l=by(data.lineages,"id",rest)
			if not l.is_empty() and p.race=="수인":p.lineage=l.name
		"nat":
			var n=by(data.nations,"id",rest)
			if n.is_empty():return
			var bl=blocked(p.race,n.id)
			if not bl.is_empty():g.ui.msg=Locale.t(bl.m,lang);return
			p.nation=n.name
		"cls":
			var c=by(data.classes,"id",rest)
			if not c.is_empty():p.cls=c.name
		"up","dn":
			if rest not in KEYS:return
			var cur=p.bonus.get(rest,0)
			if cmd=="up":
				if left(p)<=0:g.ui.msg=Locale.u("남은 점수가 없습니다.",{},lang);return
				if cur>=cap(total(p)):g.ui.msg=Locale.u("한 능력치에는 최대 {cap}점까지만 줄 수 있습니다.",{"cap":cap(total(p))},lang);return
				p.bonus[rest]=cur+1
			elif cur>0:p.bonus[rest]=cur-1
		"clear":p.bonus={"str":0,"agi":0,"int":0,"def":0,"spd":0}
		"auto":
			var c=cls(p.cls)
			if c.is_empty():return
			p.bonus={"str":0,"agi":0,"int":0,"def":0,"spd":0}
			var main={"힘":"str","민첩":"agi","지능":"int"}.get(c.line,"str")
			var a=mini(cap(total(p)),total(p));p.bonus[main]=a;p.bonus.def=mini(cap(total(p)),total(p)-a)
			var remain=total(p)-a-p.bonus.def
			if remain>0:p.bonus.spd=mini(cap(total(p)),remain)
		"tot":
			if rest=="free":p.bonus_custom=1;return
			var n=0;var custom=rest in ["m5","m1","p1","p5"]
			if custom:n=total(p)+int(rest.substr(1))*(-1 if rest.begins_with("m") else 1)
			else:
				var value=Value.number(rest,NAN)
				if value!=5 and value!=10 and value!=20:return
				n=int(value)
			var cut=set_total(p,n,custom)
			if cut>0:g.ui.msg=Locale.u("총량이 {n}점으로 바뀌어 나눠 둔 점수 {cut}점을 줄였습니다. 남은 점수를 다시 나눠 주세요.",{"n":n,"cut":cut},lang)
		"next":
			var page=Value.number(g.ui.page,1)
			if not ok(p,page):g.ui.msg=Locale.u("이 단계부터 채워 주세요.",{},lang);return
			g.ui.page=min(5,page+1)
		"back":g.ui.page=max(1,Value.number(g.ui.page,1)-1)
		"go":
			var n=Value.number(rest,NAN)
			if n>=1 and n<=5 and reach(p,n):g.ui.page=n
		"done":
			if not reach(p,5):g.ui.msg=Locale.u("아직 비어 있는 단계가 있습니다.",{},lang);return
			p.stats=calc(p);p.name="{{user}}";g.scene="scenario";g.ui.page=1;g.ui.sel=""

func clean(party: Array,roster: Array,fight: int,valid: Array) -> Array:
	var out=[]
	for id in party:
		if id in valid and id in roster and id not in out:out.append(id)
	return out.slice(0,3 if fight==1 else 4)
func need(level: int) -> int:
	var l=clampi(level,1,40);var k=.4 if l<10 else .6+.4*(l-10)/20.0 if l<30 else 1.0
	return int(floor((60*l+10*l*l)*k+.5))
func give(level: int,xp: int,amount: int) -> Dictionary:
	level=clampi(level,1,40);xp=maxi(0,xp)+amount
	while level<40 and xp>=need(level):xp-=need(level);level+=1
	return {"level":level,"xp":0 if level==40 else xp}
func award(g: Dictionary,st: Variant) -> Dictionary:
	return award_result(g,st).gains

func award_result(g: Dictionary,st: Variant,lang: String="ko",names: Dictionary={}) -> Dictionary:
	var out={"gains":{},"lines":[],"chron":[]};var gains=out.gains
	if not st is Dictionary:return out
	var xp=Value.integer(st.get("exp"))
	if xp<=0 or not g.get("persona") is Dictionary:return out
	var town=preload("res://game/town_rules_r21.gd").source_town(g)
	var key=st.get("sid")
	if not Value.truth(key):key=town.bn if town.bn is int or town.bn is float else st.get("bn")
	var numbered=key is int or key is float
	# Lua compares numeric keys only. A string sid never suppresses an award.
	if numbered and (town.get("xp_bn") is int or town.get("xp_bn") is float) and town.xp_bn==key:return out
	var ids=[];var pm=st.get("pm")
	if pm is Array and not pm.is_empty():
		for m in pm:
			var id=m.get("id") if m is Dictionary else m
			if Value.truth(id) and id!="" and id not in ids:ids.append(id)
	else:
		if Value.equal_number(g.persona.get("fight"),1):ids.append("persona")
		for id in g.get("party",[]):
			if Value.truth(id) and id!="" and id not in ids:ids.append(id)
	if "persona" not in ids:gains.persona=int(xp/2)
	for id in ids:
		if id=="persona" or id in g.get("roster",[]):gains[id]=xp
	var order=["persona"]
	for id in ids:
		if id!="persona":order.append(id)
	for id in order:
		if not gains.has(id):continue
		# Missing companion levels inherit the persona's level at the instant
		# give() runs, after the persona has received this battle's XP.
		var raw=g.persona.get("lv")
		if not Value.truth(raw):raw=g.get("lv")
		var pl=clampi(Value.integer(raw,1),1,40)
		var levels=g.get("lvl",{})
		var l=pl if id=="persona" else clampi(Value.integer(levels.get(id) if levels is Dictionary else null,pl),1,40)
		var x=Value.integer(g.persona.get("exp")) if id=="persona" else Value.integer(g.get("exp",{}).get(id))
		var result=give(l,x,gains[id])
		if id=="persona":g.persona.lv=result.level;g.persona.exp=result.xp;g.lv=result.level
		else:
			if not g.get("lvl") is Dictionary:g.lvl={}
			if not g.get("exp") is Dictionary:g.exp={}
			g.lvl[id]=result.level;g.exp[id]=result.xp
		if result.level>l:
			var name=g.persona.get("name","") if id=="persona" else names.get(id,id)
			if name=="":name="당신"
			out.lines.append(Locale.u("{name} Lv {before} → {after}",{"name":name,"before":l,"after":result.level},lang))
	if numbered:town.xp_bn=key
	if not out.lines.is_empty():out.chron.append("Leveled up: "+", ".join(out.lines) if lang=="en" else Locale.u("레벨이 올랐다: {lines}",{"lines":", ".join(out.lines)},lang))
	return out
