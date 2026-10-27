extends "res://game/world_state.gd"
const ModernBattle=preload("res://game/battle_v3.gd")
const Gear=preload("res://game/gear_rules.gd")
var gear=Gear.new()
var research=JSON.parse_string(FileAccess.get_file_as_string("res://data/persona_skill.json"))

func _init() -> void:
	super()
	_upgrade()

func _upgrade() -> void:
	s.schema=2
	s.merge({"owned":IDS.duplicate(),"recruits":0,"rng":20261027,"equipment":{},"gear":[],"serial":0,"board":[],"quest":{},"refreshes":0,"quest_wins":0,"research":{}},false)
	for p in config.companions:
		if not s.members.has(p.id):
			var b=stats(p.id,1); s.members[p.id]={"level":1,"xp":0,"aff":0.0,"hp":int(b.hp),"mp":int(b.mp)}
		if not s.equipment.has(p.id): s.equipment[p.id]={}
		if not s.research.has(p.id): s.research[p.id]={"prefix":"","suffix":"","prefix_lv":{},"suffix_lv":{}}
	for item in config.items:
		if not s.items.has(item.id): s.items[item.id]=0
	if s.board.is_empty(): refill_board()

func next_random() -> float:
	s.rng=(int(s.rng)*48271)%2147483647
	return float(s.rng)/2147483647.0

func class_def(id: String) -> Dictionary:
	for c in config.classes:
		if c.name==person(id)["class"]: return c
	return {}

func stats(id: String,level: int) -> Dictionary:
	var b=super(id,level)
	if person(id).race=="엘프": b.mp+=6
	if person(id).nation=="신성 세레디아 제국": b.def*=1.04
	if s and s.has("party"):
		var humans=party_count("race","인간")
		if humans>=2: b.hp=int(round(b.hp*(1.07 if humans>=3 else 1.04)))
	if not s or not s.has("equipment"): return b
	var bonus=gear_bonus(id,level)
	var line={"힘":"str","민첩":"agi","지능":"int"}[class_def(id).line]
	for key in ["str","agi","int","def","hp","mp"]:
		b[key]*=1+bonus.get(key,0)/100.0+(bonus.get("stat",0)/100.0 if key==line else 0)
		if key in ["hp","mp"]: b[key]=int(round(b[key]))
	b.spd*=1+bonus.get("spd",0)/100.0
	return b

func party_count(key: String,value: String) -> int:
	var n=0
	for id in s.party:
		if person(id).get(key)==value: n+=1
	return n

func gear_bonus(id: String,level: int) -> Dictionary:
	var result={}
	for uid in s.equipment.get(id,{}).values():
		var entry=gear_entry(uid)
		if entry.is_empty(): continue
		var values=gear.roll(entry,level)
		for key in values: result[key]=result.get(key,0)+values[key]
	return result

func gear_special(id: String) -> Array:
	var out=[]
	for uid in s.equipment.get(id,{}).values():
		var e=gear_entry(uid)
		if e.is_empty(): continue
		var item=gear.by_id[e.id]
		if item.has("unique"): out.append(item.unique.duplicate(true))
		if item.has("sig"): out.append(item.sig.duplicate(true))
	return out

func recruit() -> bool:
	var price=100+20*s.recruits
	if active() or s.gold<price or s.owned.size()>=config.companions.size(): return false
	var available=config.companions.filter(func(p):return p.id not in s.owned)
	var p=available[int(next_random()*available.size())]
	s.gold-=price; s.recruits+=1; s.owned.append(p.id)
	var lv=1
	for id in s.party: lv=maxi(lv,s.members[id].level)
	s.members[p.id].level=lv; var b=stats(p.id,lv); s.members[p.id].hp=b.hp; s.members[p.id].mp=b.mp
	note("페넬라의 소개 · "+p.name+" 합류"); return true

func assign(id: String,slot: int) -> bool:
	if active() or id not in s.owned or slot<0 or slot>3: return false
	if person(id).row!=("전열" if slot<2 else "후열"): return false
	var previous=s.party.find(id)
	if previous>=0: return swap(previous,slot)
	s.party[slot]=id; _clamp_members(); note(person(id).name+" 편성"); return true

func price(item: Dictionary) -> int:
	var count=0
	for id in s.party:
		if person(id).nation=="마렌토 공화국": count+=1
	return int(floor(item.price*(.88 if count>=3 else .94 if count>=2 else 1)))

func buy(id: String) -> bool:
	var item=item_def(id)
	if active() or item.is_empty() or s.gold<price(item) or s.items[id]>=99: return false
	s.gold-=price(item); s.items[id]+=1; note(item.name+" 구입"); return true

func use_item(id: String,who: String) -> bool:
	if who not in s.owned or (active() and s.run.phase=="battle"): return false
	var item=item_def(id)
	if item.is_empty() or s.items[id]<=0: return false
	var m=s.members[who]; var b=stats(who,m.level)
	if m.level<item.level: return false
	match item.kind:
		"level":
			if active() or m.level>=40: return false
			m.level+=1; m.xp=0
		"return":
			if not active() or not settle("retreat"): return false
		"revive":
			if m.hp>0: return false
			m.hp=maxi(1,int(b.hp*item.fraction))
		"hp","mp":
			if m.hp<=0 or m[item.kind]>=b[item.kind]: return false
			m[item.kind]=mini(b[item.kind],m[item.kind]+int(round(b[item.kind]*item.fraction)))
		_: return false # Shield / cleanse are combat supplies.
	s.items[id]-=1; note(item.name+" 사용"); return true

func inn(who: String,action: String) -> bool:
	if active() or who not in s.owned or action not in ["talk","meal","gift","rest"]: return false
	var prices={"talk":0,"meal":25,"gift":30,"rest":20}; var key=who+"_"+action
	if s.gold<prices[action] or (action!="rest" and s.acts.get(key,0)==s.day): return false
	s.gold-=prices[action]
	if action=="rest": s.day+=1; s.refreshes=0
	else: s.acts[key]=s.day
	var a=s.members[who].aff; s.members[who].aff=minf(200,a+(1 if a<100 else .4))
	note(person(who).name+"와 교류 · 호감 "+str(s.members[who].aff)); return true

func gear_entry(uid: int) -> Dictionary:
	for e in s.get("gear",[]):
		if e.uid==uid: return e
	return {}

func add_gear(id: String) -> void:
	s.serial+=1; next_random()
	s.gear.append({"id":id,"uid":s.serial,"seed":s.rng,"forge":0,"tries":0})

func buy_gear(id: String,who: String) -> bool:
	if active() or id not in gear.stock(class_def(who).id,s.day) or s.gear.size()>=2000: return false
	var amount=price({"price":gear.price(id)})
	if s.gold<amount: return false
	s.gold-=amount; add_gear(id); note(gear.by_id[id].name+" 구입"); return true

func wearer(uid: int) -> String:
	for id in s.equipment:
		if uid in s.equipment[id].values(): return id
	return ""

func equip(who: String,uid: int) -> bool:
	var entry=gear_entry(uid)
	if active() or who not in s.owned or entry.is_empty(): return false
	var item=gear.by_id[entry.id]
	if item.cls!=class_def(who).id or s.members[who].level<gear.rules.equip_lv[item.rarity]: return false
	var old=wearer(uid)
	if not old.is_empty(): s.equipment[old].erase(item.slot)
	s.equipment[who][item.slot]=uid; _clamp_members(); note(person(who).name+" · "+item.name+" 장착"); return true

func unequip(who: String,slot: String) -> bool:
	if active() or who not in s.owned or not s.equipment[who].has(slot): return false
	s.equipment[who].erase(slot); _clamp_members(); return true

func _clamp_members() -> void:
	for id in s.members:
		var m=s.members[id]; var b=stats(id,m.level); m.hp=mini(m.hp,b.hp); m.mp=mini(m.mp,b.mp)

func sell_gear(uid: int) -> bool:
	var e=gear_entry(uid)
	if active() or e.is_empty() or not wearer(uid).is_empty(): return false
	s.gold+=gear.sell_price(e); s.gear.erase(e); note("장비 판매"); return true

func forge(uid: int) -> bool:
	var e=gear_entry(uid)
	if active() or e.is_empty() or e.forge>=10: return false
	var amount=gear.forge_cost(e)
	if s.gold<amount: return false
	s.gold-=amount; e.tries+=1
	var success=next_random()*100<gear.rules.forge.success[int(e.forge)]
	if success: e.forge+=1
	note(gear.by_id[e.id].name+(" 강화 성공 +"+str(e.forge) if success else " 강화 실패 · 장비 보존")); return true

func highest_level() -> int:
	var n=1
	for id in s.owned: n=maxi(n,s.members[id].level)
	return n

func process_gear(who: String) -> bool:
	if active() or who not in s.owned or s.gear.size()>=2000: return false
	var band=gear.band(highest_level())
	if s.gold<band.price: return false
	s.gold-=band.price; var roll=next_random()*100; var rarity="common"
	for key in band.w:
		roll-=band.w[key]
		if roll<0: rarity=key; break
	var pool=gear.catalog.items.filter(func(i):return i.cls==class_def(who).id and i.rarity==rarity)
	var item=pool[int(next_random()*pool.size())]; add_gear(item.id)
	note("한나의 가공 · "+Gear.RARITY[rarity]+" "+item.name); return true

func refill_board() -> void:
	s.board=[]
	for i in range(4):
		var lv=clampi(highest_level()+[-3,0,3,0][i],1,40)
		s.board.append({"id":s.day*1000+s.refreshes*4+i,"name":["고립된 탐사대 구조","잃어버린 유품 회수","균열 핵 토벌","균열 핵 토벌"][i],"rift":"남서 설산 균열" if i%2==0 else "남동 숲 균열","difficulty":["하","중","상","정예"][i],"level":lv,"gold":int(round(100*reward_mult(mini(40,lv+3) if i==3 else lv)*[.7,1,1.6,4][i])),"elite":i==3})

func reward_mult(level: int) -> float:
	var points=[[1,1],[5,2],[10,4],[17,5],[20,7],[30,13],[40,25]]
	var floor_value=25.0
	for i in range(points.size()-1):
		if level<=points[i+1][0]:
			floor_value=lerpf(points[i][1],points[i+1][1],float(level-points[i][0])/(points[i+1][0]-points[i][0])); break
	var stars=[1.0,1.6,2.5,4.0,6.0,8.0,10.0,13.0,16.0]
	var zone=mini(7,int((floor_value-1)/3)); var fraction=(floor_value-1-zone*3)/3
	return stars[zone]*pow(stars[zone+1]/stars[zone],fraction)

func research_parts(kind: String,id: String) -> Dictionary:
	for part in research[kind]:
		if part.id==id: return part
	return {}

func compatible(prefix: String,suffix: String) -> bool:
	var p=research_parts("prefixes",prefix); var q=research_parts("suffixes",suffix)
	return not p.is_empty() and not q.is_empty() and (p.kind in ["attack","volley"])!=(q.kind in ["regen","guard","crit"])

func compose(who: String,prefix: String,suffix: String) -> bool:
	if active() or who not in s.owned or not compatible(prefix,suffix): return false
	s.research[who].prefix=prefix; s.research[who].suffix=suffix; note(person(who).name+" · 전술 조합 변경"); return true

func train(who: String,kind: String) -> bool:
	if active() or who not in s.owned or kind not in ["prefix","suffix"]: return false
	var r=s.research[who]; var id=r[kind]
	if id.is_empty(): return false
	var lv=r[kind+"_lv"].get(id,0); var amount=40+20*lv*lv
	if lv>=10 or s.gold<amount: return false
	s.gold-=amount; r[kind+"_lv"][id]=lv+1; note("전술 조각 강화 +"+str(lv+1)); return true

func tactic(who: String) -> Dictionary:
	var r=s.research[who]
	if not compatible(r.prefix,r.suffix): return {}
	var p=research_parts("prefixes",r.prefix).duplicate(true); var q=research_parts("suffixes",r.suffix).duplicate(true)
	p.power+=p.step*r.prefix_lv.get(p.id,0); q.value+=q.step*r.suffix_lv.get(q.id,0)
	return {"name":p.name+" "+q.name,"mp":p.mp,"target":"적 전체" if p.kind=="volley" else "적 1" if p.kind=="attack" else "아군 전체" if p.kind.ends_with("_all") else "아군 1","power":p.power,"brk":p.brk,"turns":2,"note":p.note+" / "+q.note,"prefix":p,"suffix":q}

func refresh_board() -> bool:
	var amount=10*int(pow(2,mini(s.refreshes,4)))
	if active() or s.gold<amount: return false
	s.gold-=amount; s.refreshes+=1; refill_board(); return true

func accept_quest(id: int) -> bool:
	if active() or not s.quest.is_empty(): return false
	for q in s.board:
		if q.id==id: s.quest=q.duplicate(true); return true
	return false

func abandon_quest() -> bool:
	if active() or s.quest.is_empty(): return false
	s.quest={}; return true

func depart() -> bool:
	if not super(): return false
	s.run.rules_version=3
	if not s.quest.is_empty():
		s.run.quest=s.quest.duplicate(true)
		s.run.quest_strength=1.5+.1*int(next_random()*6) if s.quest.elite else 1.0
	for id in s.party:
		var b=stats(id,s.members[id].level); s.members[id].hp=b.hp; s.members[id].mp=b.mp
	return true

func battle_data() -> Dictionary:
	if s.run.get("rules_version",2)!=3: return super()
	var d=template.duplicate(true); d.rules_version=3; d.build=config.build+"-"+str(int(s.run.id))+str(s.run.final)
	var members=[]
	for i in range(s.party.size()):
		var id=s.party[i]; var p=person(id); var c=class_def(id); var m=s.members[id]; var b=stats(id,m.level); var skills={}
		for sk in c.skills:
			if sk.kind in ["기본","능동"]: skills["attack" if sk.id=="atk" else sk.id]=sk.duplicate(true)
		skills.personal=p.skill.duplicate(true)
		if not skills.has("guard"): skills.guard={"name":"방어","mp":0,"target":"자신","power":.4,"turns":1,"brk":0,"note":"다음 자기 차례까지 피해 -40% · 웹판 비용 0"}
		var custom=tactic(id)
		if not custom.is_empty(): skills.erase("guard"); skills.tactic=custom
		members.append({"id":id,"name":p.name,"row":p.row,"hp":m.hp,"mhp":b.hp,"mp":m.mp,"mmp":b.mp,"base":b,"cls":c.name,"class_id":c.id,"line":{"힘":"str","민첩":"agi","지능":"int"}[c.line],"element":p.element,"passive":c.get("passive",{}),"trait":p.trait,"skills":skills,"remaining":float(i*900),"level":m.level,"sprite_row":{"teiris":0,"hildegard":1,"bargut":2,"berenga":3}.get(id,-1),"gear_fx":gear_bonus(id,m.level),"delay":.25})
	d.allies=members
	for a in d.allies:
		a.gear_special=gear_special(a.id); a.race=person(a.id).race; a.nation=person(a.id).nation; a.lineage=person(a.id).get("lineage","")
	var lv=0.0
	for id in s.party: lv+=s.members[id].level/4.0
	lv=clampi(int(round(lv))+1,2,40)
	if s.run.has("quest"): lv=s.run.quest.level
	for e in d.enemies:
		var n=lv-1; var ac=config.curves.atk; var dc=config.curves.def
		var am=(1+ac.a*n+ac.b*n*n)/(1+ac.a+ac.b)
		e.level=lv; e.mhp=int(round(e.mhp*am)); e.hp=e.mhp; e.attack*=am
		e.defense*=(1+dc.a*n+dc.b*n*n)/(1+dc.a+dc.b)
		e.speed+=(lv-2)*.25
		if s.run.has("quest"):
			e.mhp=int(round(e.mhp*s.run.quest_strength)); e.hp=e.mhp; e.attack*=s.run.quest_strength
	d.inventory=s.items.duplicate(true); d.item_defs=config.items.duplicate(true)
	if not s.run.battle.is_empty(): d.build=s.run.battle.build
	return d

func record_battle(snapshot: Dictionary) -> void:
	super(snapshot)
	if snapshot.get("schema_version")==3 and snapshot.has("inventory"): s.items=snapshot.inventory.duplicate(true)

func finish_battle() -> bool:
	if s.run.get("rules_version",2)!=3: return super()
	if not active() or s.run.phase!="battle" or s.run.battle.is_empty(): return false
	var battle=ModernBattle.new(battle_data())
	if not battle.restore(s.run.battle) or battle.result.is_empty(): return false
	for id in s.party:
		s.members[id].hp=battle.ally(id).hp; s.members[id].mp=battle.ally(id).mp
	if battle.result=="defeat": return settle("defeat")
	s.run.gold+=40; s.run.xp+=14; s.run.wins+=1; s.hand.append("camp")
	for id in s.party:
		var m=s.members[id]; m.aff=minf(200,m.aff+(1 if m.aff<100 else .4))
		if m.hp==0: m.hp=maxi(1,int(stats(id,m.level).hp*.2))
	if s.run.final: return settle("clear")
	s.run.phase="explore"; s.run.resolved=true; s.run.battle={}; return true

func settle(result: String) -> bool:
	var accepted=s.quest.duplicate(true)
	if not super(result): return false
	if result=="clear" and not accepted.is_empty():
		s.gold+=accepted.gold; s.summary.gold+=accepted.gold; s.quest_wins+=1; s.quest={}; note("의뢰 보수 · 금화 "+str(accepted.gold))
		if accepted.elite:
			for i in range(1+int(next_random()*2)):
				var roll=next_random()*100; var rarity="rare" if roll<78 else "epic" if roll<99 else "legend"
				var cls=class_def(s.party[int(next_random()*4)]).id
				var pool=gear.catalog.items.filter(func(item):return item.cls==cls and item.rarity==rarity)
				var item=pool[int(next_random()*pool.size())]; add_gear(item.id); note("정예 의뢰 장비 · "+item.name)
		refill_board()
	s.refreshes=0
	return true

func restore(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.get("schema")==1:
		# Validate old saves with their original three-item configuration.
		var legacy=load("res://game/world_state.gd").new()
		legacy.config.items=legacy.config.items.filter(func(i):return i.id in ["hp_s","mp_s","bandage"])
		if not legacy.restore(value): return false
		s=legacy.s; _upgrade(); return true
	if value.get("schema")!=2 or not _shape(value,s): return false
	if value.party.size()!=4 or value.owned.size()<4 or value.owned.size()>30 or value.members.size()!=30: return false
	if value.gold<0 or value.gold>100000000 or value.day<1 or value.rng<1 or value.rng>=2147483647: return false
	var seen=[]
	for id in value.owned:
		if not id is String or person(id).is_empty() or id in seen: return false
		seen.append(id)
	seen=[]
	for i in range(4):
		var id=value.party[i]
		if id not in value.owned or id in seen or person(id).row!=("전열" if i<2 else "후열"): return false
		seen.append(id)
	for p in config.companions:
		var m=value.members.get(p.id)
		if not m is Dictionary or not _shape(m,s.members[p.id]) or m.level<1 or m.level>40 or m.level!=int(m.level) or m.hp<0 or m.mp<0 or m.xp<0 or m.xp>=need(m.level) or m.aff>200 or m.aff< -100: return false
	for item in config.items:
		if not _num(value.items.get(item.id)) or value.items[item.id]<0 or value.items[item.id]>10000: return false
	var uids=[]
	for entry in value.gear:
		if not _shape(entry,{"id":"","uid":0,"seed":0,"forge":0,"tries":0}) or not gear.by_id.has(entry.id) or entry.uid in uids or entry.forge<0 or entry.forge>10: return false
		uids.append(entry.uid)
	for id in value.equipment:
		if person(id).is_empty() or not value.equipment[id] is Dictionary: return false
		for slot in value.equipment[id]:
			if slot not in Gear.SLOT or value.equipment[id][slot] not in uids: return false
	var run=value.run
	if not run.is_empty():
		if not _shape(run,{"phase":"","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":false,"final":false,"battle":{},"rested":false,"id":0}): return false
		if run.phase not in ["explore","battle","rest","done"] or run.gold<0 or run.xp<0 or run.wins<0 or run.wins>2 or run.id!=value.runs: return false
	var prev=s; s=value.duplicate(true)
	for id in s.members:
		var b=stats(id,s.members[id].level)
		if s.members[id].hp>b.hp or s.members[id].mp>b.mp: s=prev; return false
	if active():
		if not s.run.has("phase") or s.run.phase not in ["explore","battle","rest"]: s=prev; return false
		if s.run.has("route_version") and not Route.valid(s.run): s=prev; return false
		if s.run.phase=="battle" and not s.run.battle.is_empty():
			var b=ModernBattle.new(battle_data()) if s.run.get("rules_version",2)==3 else Battle.new(battle_data())
			if not b.restore(s.run.battle): s=prev; return false
	return true
