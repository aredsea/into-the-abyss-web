extends RefCounted
## P1 pure source contracts: 60-create / 74-level / 75-sortie / 26-start.
const KEYS=["str","agi","int","def","spd"]
var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/persona-r22.json"))

func by(list: Array,key: String,value: Variant) -> Dictionary:
	for entry in list:
		if entry.get(key)==value:return entry
	return {}

func cls(name: String) -> Dictionary:return by(data.classes,"name",name)
func total(p: Dictionary) -> int:return clampi(int(floor(float(p.get("bonus_total",5)))),0,99)
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
func prepare(p: Dictionary) -> void:
	p.merge({"race":"","lineage":"","nation":"","cls":"","fight":1,"stats":{},"bonus_total":5,"bonus_custom":0},false)
	if not p.get("bonus") is Dictionary or not p.bonus.has("str"):p.bonus={"str":0,"agi":0,"int":0,"def":0,"spd":0}
	p.bonus_total=total(p)
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
func ok(p: Dictionary,page: int) -> bool:
	match page:
		1:return p.race!="" and (p.race!="수인" or p.lineage!="")
		2:return p.nation!="" and blocked(p.race,nation_id(p.nation)).is_empty()
		3:return not cls(p.cls).is_empty()
		4:return left(p)==0
	return true
func reach(p: Dictionary,page: int) -> bool:
	for n in range(1,page):
		if not ok(p,n):return false
	return true
func calc(p: Dictionary) -> Dictionary:
	var c=cls(p.cls)
	if c.is_empty():return {}
	var out={"hp":c.hp,"mp":c.mp}
	for key in KEYS:out[key]=c[key]+p.get("bonus",{}).get(key,0)*(2 if key=="spd" else 1)
	return out

func create_action(g: Dictionary,arg: String,kind="cr") -> void:
	if kind=="sc":
		if g.scene!="scenario" or g.scenario!="":return
		if arg.begins_with("pick_"):
			if not by(data.scenarios,"id",arg.substr(5)).is_empty():g.ui.sel=arg.substr(5)
		elif arg=="back":g.scene="create";g.ui.page=5;g.ui.sel=""
		elif arg=="go":
			var sc=by(data.scenarios,"id",g.ui.sel)
			if sc.is_empty():g.ui.msg="먼저 만남을 골라 주세요.";return
			g.scenario=sc.id;g.roster=[sc.companion];g.party=[sc.companion];g.gold=300;g.scene="town";g.ui.page=1;g.ui.sel=""
		return
	if g.scene!="create":return
	var p=g.persona;prepare(p)
	var parts=arg.split("_",true,1);var cmd=parts[0];var rest=parts[1] if parts.size()>1 else ""
	match cmd:
		"race":
			var r=by(data.races,"id",rest)
			if r.is_empty():return
			p.race=r.name
			if r.id!="beast":p.lineage=""
			var bl=blocked(p.race,nation_id(p.nation))
			if not bl.is_empty():g.ui.msg="「%s」 출신은 이 종족과 맞지 않아 비웠습니다. %s 출신을 다시 골라 주세요."%[p.nation,bl.m];p.nation=""
		"lin":
			var l=by(data.lineages,"id",rest)
			if not l.is_empty() and p.race=="수인":p.lineage=l.name
		"nat":
			var n=by(data.nations,"id",rest)
			if n.is_empty():return
			var bl=blocked(p.race,n.id)
			if not bl.is_empty():g.ui.msg=bl.m;return
			p.nation=n.name
		"cls":
			var c=by(data.classes,"id",rest)
			if not c.is_empty():p.cls=c.name
		"up","dn":
			if rest not in KEYS:return
			var cur=p.bonus.get(rest,0)
			if cmd=="up":
				if left(p)<=0:g.ui.msg="남은 점수가 없습니다.";return
				if cur>=cap(total(p)):g.ui.msg="한 능력치에는 최대 %d점까지만 줄 수 있습니다."%cap(total(p));return
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
			elif rest in ["5","10","20"]:n=int(rest)
			else:return
			var cut=set_total(p,n,custom)
			if cut>0:g.ui.msg="총량이 %d점으로 바뀌어 나눠 둔 점수 %d점을 줄였습니다. 남은 점수를 다시 나눠 주세요."%[total(p),cut]
		"next":
			if not ok(p,int(g.ui.page)):g.ui.msg="이 단계부터 채워 주세요.";return
			g.ui.page=mini(5,int(g.ui.page)+1)
		"back":g.ui.page=maxi(1,int(g.ui.page)-1)
		"go":
			var n=int(rest)
			if n>=1 and n<=5 and reach(p,n):g.ui.page=n
		"done":
			if not reach(p,5):g.ui.msg="아직 비어 있는 단계가 있습니다.";return
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
func award(g: Dictionary,st: Dictionary) -> Dictionary:
	var gains={};var xp=int(floor(float(st.get("exp",0))))
	if xp<=0:return gains
	var key=st.get("sid",g.get("town",{}).get("bn",st.get("bn")))
	if key!=null and g.town.get("xp_bn")==key:return gains
	var ids=[]
	if not st.get("pm",[]).is_empty():
		for m in st.pm:
			var id=m.id if m is Dictionary else m
			if id!="" and id not in ids:ids.append(id)
	else:
		if g.persona.fight==1:ids.append("persona")
		for id in g.party:
			if id not in ids:ids.append(id)
	if "persona" not in ids:gains.persona=int(xp/2)
	for id in ids:
		if id=="persona" or id in g.roster:gains[id]=xp
	for id in gains:
		var p=g.persona if id=="persona" else {"lv":g.lvl.get(id,g.persona.lv),"exp":g.exp.get(id,0)}
		var result=give(int(p.lv),int(p.exp),gains[id])
		if id=="persona":g.persona.lv=result.level;g.persona.exp=result.xp;g.lv=result.level
		else:g.lvl[id]=result.level;g.exp[id]=result.xp
	if key!=null:g.town.xp_bn=key
	return gains
