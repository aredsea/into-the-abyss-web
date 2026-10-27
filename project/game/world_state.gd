extends RefCounted

const Route = preload("res://game/route_v1.gd")
const Battle = preload("res://game/battle_state.gd")
const IDS = ["hildegard","bargut","teiris","berenga"]
var config: Dictionary
var template: Dictionary
var s: Dictionary

func _init() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	template=JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_scene.json"))
	s={"schema":1,"day":1,"gold":config.provisional.starting_gold,"party":IDS.duplicate(),"members":{},"items":config.provisional.starting_items.duplicate(),"hand":[],"acts":{},"run":{},"summary":{},"log":[],"runs":0}
	for id in IDS:
		var b=stats(id,1)
		s.members[id]={"level":1,"xp":0,"aff":0.0,"hp":int(b.hp),"mp":int(b.mp)}

func person(id: String) -> Dictionary:
	for c in config.companions:
		if c.id==id: return c
	return {}

func stats(id: String, level: int) -> Dictionary:
	var p=person(id)
	var cls={}
	for c in config.classes:
		if c.name==p["class"]: cls=c
	var out={}; var x=level-1
	for key in ["hp","mp","str","agi","int","def"]:
		var curve=config.curves[key if key in ["hp","mp","def"] else "atk"]
		var value=cls.base[key]*(1.0+p.mod.get(key,0)/100.0)*(1+cls.grow.get(key,1)*(curve.a*x+curve.b*x*x))
		out[key]=int(round(value)) if key in ["hp","mp"] else value
	out.spd=cls.base.spd+p.mod.get("spd",0)+config.curves.spd.add*x
	out.crit=cls.base.crit+p.mod.get("crit",0)
	return out

func need(level: int) -> int:
	var k=0.4 if level<10 else (0.6+0.4*(level-10)/20.0 if level<30 else 1.0)
	return int(round((60*level+10*level*level)*k))

func note(message: String) -> void:
	s.log.append(message)
	if s.log.size()>40: s.log.pop_front()

func active() -> bool:
	return not s.run.is_empty() and s.run.phase!="done"

func buy(id: String) -> bool:
	if active(): return false
	var item=item_def(id)
	if item.is_empty() or s.gold<item.price or s.items[id]>=99: return false
	s.gold-=item.price; s.items[id]+=1
	note(item.name+" 1개 구입")
	return true

func item_def(id: String) -> Dictionary:
	for i in config.items:
		if i.id==id: return i
	return {}

func use_item(id: String, who: String) -> bool:
	if who not in IDS or (active() and s.run.phase=="battle"): return false
	var item=item_def(id)
	if item.is_empty() or s.items[id]<1: return false
	var m=s.members[who]; var b=stats(who,m.level)
	if m.level<item.level: return false
	if item.kind=="revive":
		if m.hp>0: return false
		m.hp=maxi(1,int(b.hp*item.fraction))
	else:
		var k=item.kind
		if m.hp<=0 or m[k]>=b[k]: return false
		m[k]=mini(b[k],m[k]+maxi(1,int(round(b[k]*item.fraction))))
	s.items[id]-=1; note(person(who).name+": "+item.name+" 사용")
	return true

func inn(who: String, action: String) -> bool:
	if active() or who not in IDS or action not in ["talk","meal","gift","rest"]: return false
	var prices={"talk":0,"meal":25,"gift":30,"rest":20}
	var key=who+"_"+action
	if s.gold<prices[action] or (action!="rest" and s.acts.get(key,0)==s.day): return false
	s.gold-=prices[action]
	if action=="rest": s.day+=1
	else: s.acts[key]=s.day
	var a=s.members[who].aff
	s.members[who].aff=minf(200,a+1 if a<100 else a+0.4)
	note(person(who).name+"와 시간을 보냈다. 호감 "+str(s.members[who].aff))
	return true

func swap(a: int, b: int) -> bool:
	if active() or a<0 or a>3 or b<0 or b>3: return false
	# Native rows are preserved: only reorder within a row.
	if int(a/2)!=int(b/2): return false
	var old=s.party[a]; s.party[a]=s.party[b]; s.party[b]=old
	return true

func depart() -> bool:
	if active(): return false
	s.runs+=1
	s.run={"phase":"explore","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":false,"final":false,"battle":{},"rested":false,"id":s.runs}
	s.run.merge({"route_version":1,"route_seed":1,"node":"entry","path":["entry"]})
	s.run.event="entry"; s.run.resolved=true
	s.summary={}
	# Bot expeditions start with full HP/MP; resources carry between encounters.
	for id in IDS:
		var b=stats(id,s.members[id].level)
		s.members[id].hp=b.hp; s.members[id].mp=b.mp
	note("학술원 폐허 상층 2층 검수 원정 출발")
	return true

func mapped() -> bool:
	return not s.run.is_empty() and s.run.has("route_version")

func destinations() -> Array:
	if not active() or not mapped() or s.run.phase!="explore" or not s.run.resolved: return []
	return Route.NODES[s.run.node].next.duplicate()

func travel(id: String) -> bool:
	if id not in destinations(): return false
	var r=s.run
	r.node=id; r.path.append(id); r.step=r.path.size()-1
	r.event=Route.NODES[id].kind; r.resolved=true
	note(Route.NODES[id].name+" 도착")
	match r.event:
		"find_card": s.hand.append("key")
		"supplies": s.hand.append("camp")
		"coins": r.gold+=config.provisional.cache_gold
		"sealed", "rest": r.resolved=false
		"battle":
			r.phase="battle"; r.resolved=false; r.final=id=="gate"; r.battle={}
	return true

func skip_rest() -> bool:
	if not active() or not mapped() or s.run.phase!="explore" or s.run.node!="rest" or s.run.resolved: return false
	s.run.resolved=true; note("휴게실에서 쉬지 않고 이동을 준비했다.")
	return true

func advance() -> bool:
	if mapped(): return false
	if not active() or s.run.phase!="explore" or (not s.run.event.is_empty() and not s.run.resolved): return false
	var r=s.run
	if r.step==5:
		r.phase="rest"; return true
	r.step+=1; r.resolved=false
	match int(r.step):
		1:
			r.event="find_card"; s.hand.append("key"); r.resolved=true
			note("쓰러진 서가에서 봉인 해제 카드를 얻었다.")
		2:
			r.event="battle"; r.phase="battle"
		3: r.event="sealed"
		4:
			r.event="supplies"; s.hand.append("camp"); r.resolved=true
			note("버려진 야영지에서 안전한 야영 카드를 얻었다.")
		5:
			r.event="coins"; r.gold+=20; r.resolved=true
			note("붕괴한 복도에서 금화 20을 모았다.")
	return true

func card_def(id: String) -> Dictionary:
	for c in config.cards:
		if c.id==id: return c
	return {}

func card_reason(id: String) -> String:
	if not active() or s.run.phase!="explore": return "탐색 중에 사용할 수 있습니다."
	if id not in s.hand: return "보유한 카드가 없습니다."
	if id=="key" and (s.run.event!="sealed" or s.run.resolved): return "봉인된 보관함에서 사용합니다."
	if id=="camp":
		var hurt=false
		for who in IDS:
			if s.members[who].hp>0 and s.members[who].hp<stats(who,s.members[who].level).hp: hurt=true
		if not hurt: return "회복할 동료가 없습니다."
	return ""

func use_card(id: String) -> bool:
	if not card_reason(id).is_empty(): return false
	if id=="key":
		s.items.hp_s+=1; s.run.resolved=true
	else:
		for who in IDS:
			var m=s.members[who]; var b=stats(who,m.level)
			if m.hp>0: m.hp=mini(b.hp,m.hp+int(round(b.hp*0.2)))
	s.hand.erase(id); note(card_def(id).name+" 사용 · 카드 1장 소모")
	return true

func leave_cache() -> bool:
	if not active() or s.run.phase!="explore" or s.run.event!="sealed" or s.run.resolved: return false
	s.run.resolved=true; note("봉인된 보관함을 지나쳤다.")
	return true

func rest() -> bool:
	if not active() or s.run.rested: return false
	if mapped():
		if s.run.phase!="explore" or s.run.node!="rest": return false
	else:
		if s.run.phase!="rest": return false
	for id in IDS:
		var m=s.members[id]; var b=stats(id,m.level)
		m.hp=mini(b.hp,m.hp+int(round(b.hp*0.3)))
		m.mp=mini(b.mp,m.mp+int(round(b.mp*0.6)))
	s.run.rested=true
	if mapped(): s.run.resolved=true
	note("휴식: 파티 HP 30%, MP 60% 회복")
	return true

func final_battle() -> bool:
	if mapped(): return false
	if not active() or s.run.phase!="rest" or not s.run.rested: return false
	s.run.phase="battle"; s.run.final=true; s.run.battle={}
	return true

func battle_data() -> Dictionary:
	var d=template.duplicate(true)
	d.build=config.build+"-run-"+str(int(s.run.id))+("-final" if s.run.final else "-explore")
	var members=[]
	for id in s.party:
		for a in d.allies:
			if a.id!=id: continue
			var m=s.members[id]; var b=stats(id,m.level)
			a.name=person(id).name; a.cls=person(id)["class"]
			a.base=b; a.mhp=b.hp; a.mmp=b.mp; a.hp=m.hp; a.mp=m.mp; a.level=m.level
			members.append(a)
	d.allies=members
	if not s.run.battle.is_empty() and s.run.battle.get("build") is String:
		d.build=s.run.battle.build
	return d

func record_battle(snapshot: Dictionary) -> void:
	if active() and s.run.phase=="battle": s.run.battle=snapshot.duplicate(true)

func finish_battle() -> bool:
	if not active() or s.run.phase!="battle" or s.run.battle.is_empty(): return false
	var battle=Battle.new(battle_data())
	if not battle.restore(s.run.battle) or battle.result.is_empty(): return false
	for id in IDS:
		s.members[id].hp=battle.ally(id).hp; s.members[id].mp=battle.ally(id).mp
	if battle.result=="defeat": return settle("defeat")
	s.run.gold+=40; s.run.xp+=14; s.run.wins+=1
	s.hand.append("camp"); note("인형의 짐에서 안전한 야영 카드 1장을 얻었다.")
	for id in IDS:
		var m=s.members[id]
		m.aff=minf(200,m.aff+1 if m.aff<100 else m.aff+0.4)
		if m.hp==0: m.hp=maxi(1,int(stats(id,m.level).hp*0.2))
	if s.run.final: return settle("clear")
	s.run.phase="explore"; s.run.resolved=true; s.run.battle={}
	return true

func settle(result: String) -> bool:
	if not active() or result not in ["retreat","clear","defeat"]: return false
	if result=="retreat" and s.run.phase not in ["explore","rest"]: return false
	var gold=0 if result=="defeat" else int(s.run.gold)
	var xp=0 if result=="defeat" else int(s.run.xp)
	s.gold+=gold; var gains=[]
	for id in IDS:
		var m=s.members[id]; var before=m.level
		m.xp+=xp
		while m.level<40 and m.xp>=need(m.level):
			m.xp-=need(m.level); m.level+=1
		if m.level==40: m.xp=0
		gains.append({"id":id,"before":before,"level":m.level,"xp":m.xp})
	s.summary={"result":result,"gold":gold,"xp":xp,"wins":s.run.wins,"lost":s.run.gold if result=="defeat" else 0,"gains":gains}
	s.day+=1; s.run.phase="done"; s.run.battle={}
	note("원정 정산: 금화 %d, 경험치 %d" % [gold,xp])
	return true

func restore(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema")!=1: return false
	if not _shape(value,{"schema":1,"day":1,"gold":0,"party":[],"members":{},"items":{},"hand":[],"acts":{},"run":{},"summary":{},"log":[],"runs":0}): return false
	if value.day<1 or value.day>1000000 or value.gold<0 or value.gold>100000000 or value.runs<0: return false
	if value.party.size()!=4 or value.members.size()!=4: return false
	var sorted=value.party.duplicate(); sorted.sort(); var expected=IDS.duplicate(); expected.sort()
	if sorted!=expected or value.party[0] not in IDS.slice(0,2) or value.party[1] not in IDS.slice(0,2): return false
	for id in IDS:
		var m=value.members.get(id)
		if not m is Dictionary or not _shape(m,s.members[id]): return false
		if m.level<1 or m.level>40 or m.level!=int(m.level) or m.xp<0 or m.xp>=need(m.level) or m.aff < -100 or m.aff>200: return false
		var b=stats(id,m.level)
		if m.hp<0 or m.hp>b.hp or m.mp<0 or m.mp>b.mp: return false
	for id in s.items:
		if not _num(value.items.get(id)) or value.items[id]<0 or value.items[id]>10000: return false
	for card in value.hand:
		if card not in ["key","camp"]: return false
	if value.hand.size()>10000 or value.log.size()>40: return false
	for line in value.log:
		if not line is String or line.length()>300: return false
	for key in value.acts:
		if not key is String or not _num(value.acts[key]) or value.acts[key]<1: return false
	var r=value.run
	if not r.is_empty():
		var sample={"phase":"","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":false,"final":false,"battle":{},"rested":false,"id":0}
		if not _shape(r,sample) or r.phase not in ["explore","battle","rest","done"] or r.step<0 or r.step>5 or r.step!=int(r.step) or r.gold<0 or r.xp<0 or r.wins<0 or r.wins>2: return false
		if r.has("route_version"):
			if not Route.valid(r): return false
		else:
			if r.event not in ["","find_card","battle","sealed","supplies","coins"]: return false
		if r.id<1 or r.id!=value.runs or r.gold>1000000 or r.xp>1000000: return false
	var result=value.summary
	if not result.is_empty():
		if not _shape(result,{"result":"","gold":0,"xp":0,"wins":0,"lost":0,"gains":[]}): return false
		if result.result not in ["clear","retreat","defeat"] or result.gains.size()!=4: return false
		for gain in result.gains:
			if not _shape(gain,{"id":"","before":0,"level":0,"xp":0}) or gain.id not in IDS: return false
	var prev=s; s=value.duplicate(true)
	if active() and s.run.phase=="battle" and not s.run.battle.is_empty():
		var b=Battle.new(battle_data())
		if not b.restore(s.run.battle): s=prev; return false
	return true

func _num(v: Variant) -> bool:
	return (v is float or v is int) and is_finite(float(v))

func _shape(v: Variant, sample: Variant) -> bool:
	if sample is Dictionary:
		if not v is Dictionary: return false
		for k in sample:
			if not v.has(k) or not _shape(v[k],sample[k]): return false
		return true
	if sample is Array: return v is Array
	if _num(sample): return _num(v)
	return typeof(v)==typeof(sample)
