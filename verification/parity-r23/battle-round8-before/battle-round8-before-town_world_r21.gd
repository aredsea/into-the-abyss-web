extends "res://game/dungeon_world_r21.gd"
## Additive town corrections. schema 1/2 and live battle snapshots stay intact.
const TOWN_RULES = preload("res://game/town_rules_r21.gd")
const Guild=preload("res://game/guild_rules_r21.gd")
const Commerce=preload("res://game/commerce_rules_r21.gd")
const PersonaResearch=preload("res://game/persona_research_r21.gd")
const Dialogue=preload("res://game/dialogue_player_r21.gd")
var dialogue=Dialogue.new()
var research_message=""

func _init():
	super()
	gear=Commerce.new()
	ensure_town_r21()

func ensure_town_r21() -> void:
	if s.get("schema")!=3 and not s.has("persona_progress_r21"):
		var p=s.get("persona",{});var level=clampi(int(p.get("lv",s.get("lv",1))),1,40)
		s.persona_progress_r21={"level":level,"xp":clampi(int(p.get("exp",0)),0,need(level)-1) if level<40 else 0}
	if not s.has("dialogue_r21"):s.dialogue_r21={"seen":{},"pending":{},"response":{},"queue":[],"bark_counts":{}}
	if not s.has("npc_aff_r21"):s.npc_aff_r21={}
	if not s.has("research_editor_r21"):s.research_editor_r21={}
	if not s.has("commerce_r21"):s.commerce_r21={"process_n":0,"sold_day":s.day,"bought":{}}
	if not s.has("town_r21"):
		var qn=0
		for q in s.board:
			if q.get("source_id","").begins_with("q"): qn=maxi(qn,int(q.id))
		s.town_r21={"seed":int(s.rng),"counter":qn,"qn":qn}

func fill_source_board() -> void:
	while s.board.size()<4:
		s.town_r21.counter+=1; s.town_r21.qn+=1
		s.board.append(Guild.quest(s.town_r21.seed,s.town_r21.counter,s.town_r21.qn,highest_level(),s.board))

func refill_board() -> void:
	ensure_town_r21()
	s.board=[]
	if not s.quest.is_empty(): s.board.append(s.quest.duplicate(true))
	fill_source_board()

func abandon_quest() -> bool:
	if active() or s.quest.is_empty(): return false
	var id=s.quest.id;s.quest={};s.board=s.board.filter(func(q):return q.id!=id)
	fill_source_board();return true

func quest_contract(q: Dictionary) -> Dictionary:
	if q.is_empty(): return {}
	if q.get("cmp",false): return q.duplicate(true)
	# Preserve previously accepted quests and their saved reward; do not reroll.
	var out=q.duplicate(true)
	out.difficulty={"하":"낮음","중":"중간","상":"높음","정예":"엘리트"}.get(q.difficulty,q.difficulty)
	out.lv=int(q.get("level",1)); out.cmp=true; out.stars=2 if q.rift=="남동 숲 균열" else 1
	out.kind="토벌" if "토벌" in q.name else "구조" if "구조" in q.name else "회수"
	out.title=q.rift+", "+q.name; out.migration_from="legacy-web"; out.source_id="legacy-"+str(q.id)
	return out

func depart_accepted_quest() -> bool:
	if active() or s.quest.is_empty(): return false
	return depart_rift_quest(quest_contract(s.quest))

func settle(result: String) -> bool:
	var source_run=r21() and active()
	var before={}
	var amount_aff=0.0
	if source_run:
		for id in s.party:before[id]=s.members[id].aff
		if result!="defeat":amount_aff=2.0 if not s.run.rift_id.is_empty() and result=="clear" else s.run.wins+(3 if result=="clear" else 0)
	var quest_run=r21() and s.run.has("source_quest")
	var accepted=s.run.get("source_quest",{}).duplicate(true)
	if not super(result): return false
	if source_run:
		# Replace A's aggregate with the same source aggregate plus tx_aff synergy.
		for id in before:s.members[id].aff=before[id]
		if amount_aff>0:aff_party(amount_aff)
		if result!="defeat" and s.get("schema")!=3:
			var p=s.persona_progress_r21;p.xp+=int(floor(float(s.summary.xp)/2))
			while p.level<40 and p.xp>=need(p.level):p.xp-=need(p.level);p.level+=1
			if p.level==40:p.xp=0
		emit_bark("defeat" if result=="defeat" else "return")
	if quest_run and result in ["clear","defeat"]:
		if result=="clear":
			s.quest_wins+=1
			var adjusted=Guild.reward_gold(int(s.summary.gold),party_count("nation","마렌토 공화국"))
			s.gold+=adjusted-s.summary.gold;s.summary.gold=adjusted
			if dungeon_rules.quest_difficulty(accepted)=="엘리트":
				var qn=int(str(accepted.get("source_id",str(accepted.id))).trim_prefix("q").trim_prefix("legacy-"))
				for i in range(1,Guild.gear_count(s.town_r21.seed,qn)+1):
					var drop=Guild.elite_gear(dungeon_rules,s.town_r21.seed,qn,party_classes(),i)
					if not drop.is_empty() and gear.by_id.has(drop.id) and s.gear.size()<2000:
						s.serial+=1;s.gear.append({"uid":s.serial,"id":drop.id,"seed":drop.seed,"forge":0,"tries":0})
		if s.quest.get("id",-1)==accepted.get("id",-2): s.quest={}
		# A already pays quest_gold in finish_battle. Never pay it a second time.
		s.board=s.board.filter(func(q):return q.id!=accepted.get("id",-1))
		s.refreshes=0;fill_source_board()
	return true

func restore(value: Variant) -> bool:
	if not value is Dictionary: return false
	var previous=s.duplicate(true)
	if value.has("persona"):
		if not value.persona is Dictionary:return false
		for key in ["lv","exp"]:
			if value.persona.has(key) and not _num(value.persona[key]):return false
	if value.has("lv") and not _num(value.lv):return false
	if value.has("persona_progress_r21"):
		var p=value.persona_progress_r21
		if not _shape(p,{"level":0,"xp":0}) or p.level<1 or p.level>40 or p.level!=int(p.level) or p.xp<0 or p.xp!=int(p.xp) or p.xp>=need(p.level) or (p.level==40 and p.xp!=0):return false
	if value.has("dialogue_r21") and not valid_dialogue_save(value):return false
	if value.get("run",{}).has("dialogue_marks"):
		var marks=value.run.dialogue_marks
		if not marks is Dictionary:return false
		for key in marks:
			if not key is String or not marks[key] is bool:return false
	if value.has("npc_aff_r21"):
		if not value.npc_aff_r21 is Dictionary:return false
		for id in value.npc_aff_r21:
			var a=value.npc_aff_r21[id]
			if not id is String or not _num(a) or a<0 or a>200:return false
	if value.has("research_editor_r21"):
		var editors=value.research_editor_r21
		if not editors is Dictionary:return false
		for who in editors:
			if who not in value.get("owned",[]):return false
			var e=editors[who]
			if not e is Dictionary or not _shape(e,{"draft":{},"spent":0}):return false
			if e.spent<0 or e.spent!=int(e.spent) or e.spent>100000000:return false
			if not PersonaResearch.valid_saved(e.draft):return false
	if value.has("commerce_r21"):
		var c=value.commerce_r21
		if not c is Dictionary or not _shape(c,{"process_n":0,"sold_day":0,"bought":{}}):return false
		if c.process_n<0 or c.process_n!=int(c.process_n) or c.sold_day<1 or c.sold_day!=int(c.sold_day) or c.sold_day>value.get("day",0):return false
		for key in c.bought:
			if not key is String or not c.bought[key] is bool:return false
	for e in value.get("gear",[]):
		if e is Dictionary and e.has("source_r21") and not e.source_r21 is bool:return false
	if value.has("town_r21"):
		var t=value.town_r21
		if not t is Dictionary or not _shape(t,{"seed":0,"counter":0,"qn":0}) or t.seed<1 or t.seed>=2147483647 or t.seed!=int(t.seed) or t.counter<0 or t.qn<0 or t.counter!=int(t.counter) or t.qn!=int(t.qn): return false
	s.erase("town_r21")
	s.erase("commerce_r21")
	s.erase("research_editor_r21")
	s.erase("dialogue_r21")
	s.erase("npc_aff_r21")
	s.erase("persona_progress_r21")
	s.erase("persona")
	s.erase("lv")
	if not super(value): s=previous; return false
	ensure_town_r21()
	return true

func persona_level() -> int:
	return int(s.persona.lv) if s.get("schema")==3 else int(s.persona_progress_r21.level)

func research_work(who: String) -> Dictionary:
	var e=s.research_editor_r21.get(who,{})
	return PersonaResearch.clean(e.get("draft",s.research.get(who,{})))

func research_dirty(who: String) -> bool:
	return s.research_editor_r21.has(who) and research_work(who)!=PersonaResearch.clean(s.research[who])

func research_action(who: String,arg: String) -> bool:
	if active() or who not in s.owned:return false
	var e=s.research_editor_r21.get(who,{"draft":{},"spent":0})
	var out=PersonaResearch.transition(s.research[who],e.draft,int(e.spent),int(s.gold),arg)
	research_message=out.message
	var changed=out.saved!=s.research[who] or out.draft!=e.draft or out.gold!=s.gold
	if not changed:return false
	s.research[who]=out.saved;s.gold=out.gold
	if out.draft.is_empty():s.research_editor_r21.erase(who)
	else:s.research_editor_r21[who]={"draft":out.draft,"spent":out.spent}
	return true

func train(who: String,kind: String) -> bool:
	# Compatibility shortcut still upgrades the equipped piece, using source cost.
	if active() or who not in s.owned or kind not in ["prefix","suffix"]:return false
	var r=s.research[who];var id=r[kind]
	if id.is_empty():return false
	var lv=PersonaResearch.level(r[kind+"_lv"],id);var amount=PersonaResearch.cost(lv+1)
	if lv>=10 or s.gold<amount:return false
	s.gold-=amount;r[kind+"_lv"][id]=lv+1;note("전술 조각 강화 +"+str(lv+1));return true

func shop_stock(who: String,slot: String) -> Array:
	if who not in s.owned or slot not in Gear.SLOT:return []
	var rows=gear.stock_source(s.town_r21.seed,int(s.day),class_def(who).id,slot)
	return rows.filter(func(e):return gear.rules.equip_lv[gear.by_id[e.id].rarity]<=highest_level())
func stock_sold(code: String) -> bool:return s.commerce_r21.sold_day==s.day and s.commerce_r21.bought.get(code,false)
func buy_gear(id: String,who: String) -> bool:
	if active() or who not in s.owned or s.gear.size()>=2000:return false
	var found={}
	for slot in Gear.SLOT:
		for row in shop_stock(who,slot):
			if id in [row.id,row.code]:found=row;break
	if found.is_empty() or stock_sold(found.code):return false
	var amount=price({"price":found.price})
	if s.gold<amount:return false
	npc_like("pietro")
	s.gold-=amount;s.serial+=1;s.gear.append({"uid":s.serial,"id":found.id,"seed":found.seed,"forge":0,"tries":0,"source_r21":true})
	if s.commerce_r21.sold_day!=s.day:s.commerce_r21.sold_day=s.day;s.commerce_r21.bought={}
	s.commerce_r21.bought[found.code]=true;note(gear.by_id[found.id].name+" 구입");return true
func process_gear(_who: String) -> bool:
	if active() or s.gear.size()>=2000:return false
	var amount=gear.band(highest_level()).price
	if s.gold<amount:return false
	var classes=s.owned.map(func(id):return class_def(id).id)
	var result=gear.process_source(s.town_r21.seed,int(s.commerce_r21.process_n)+1,classes,highest_level())
	if result.is_empty():return false
	npc_like("hanna")
	s.gold-=amount;s.commerce_r21.process_n+=1;s.serial+=1
	s.gear.append({"uid":s.serial,"id":result.id,"seed":result.seed,"forge":0,"tries":0,"source_r21":true})
	note("한나의 가공 · "+gear.by_id[result.id].name);return true
func forge(uid: int) -> bool:
	var e=gear_entry(uid)
	if active() or e.is_empty() or e.forge>=10:return false
	var amount=gear.forge_cost(e)
	if s.gold<amount:return false
	var success=gear.forge_result(s.town_r21.seed,e)
	npc_like("hanna")
	s.gold-=amount;e.tries+=1
	if success:e.forge+=1
	note(gear.by_id[e.id].name+(" 강화 성공 +%d"%e.forge if success else " 강화 실패 · 장비 보존"));return true

func need(level: int) -> int: return TOWN_RULES.need(level)

func recruit_fee() -> int: return TOWN_RULES.recruit_cost(s.recruits)

func recruit() -> bool:
	if active() or not s.dialogue_r21.pending.is_empty() or not s.dialogue_r21.response.is_empty():return false
	var candidates=config.companions.filter(func(p):return p.id not in s.owned)
	var cost=recruit_fee()
	if candidates.is_empty() or s.gold<cost:return false
	s.town_r21.counter+=1
	var index=mini(candidates.size()-1,int(floor(Guild.random(s.town_r21.seed,s.town_r21.counter)*candidates.size())))
	var who=candidates[index].id
	s.gold-=cost;s.recruits+=1;s.owned.append(who)
	var m=s.members[who];m.aff=0;m.level=persona_level();m.xp=0
	var b=stats(who,m.level);m.hp=b.hp;m.mp=b.mp
	s.town_r21.meet=who;npc_like("fenella")
	note("페넬라의 소개 · "+person(who).name+" 합류");return true
func refresh_fee() -> int: return TOWN_RULES.refresh_cost(s.refreshes)

func price(item: Dictionary) -> int:
	var count=0
	for id in s.party:
		if person(id).nation=="마렌토 공화국": count+=1
	return TOWN_RULES.shop_price(float(item.price),count)

func buy(id: String) -> bool:
	var item=item_def(id)
	if active() or item.is_empty() or s.gold<price(item) or s.items[id]>=10000: return false
	npc_like("pietro")
	s.gold-=price(item); s.items[id]+=1; note(item.name+" 구입"); return true

func inn(id: String,action: String) -> bool:
	var acts=TOWN_RULES.DATA.inn
	if active() or id not in s.owned or not acts.has(action) or not s.dialogue_r21.pending.is_empty(): return false
	if not TOWN_RULES.inn_act_visible(s,action,id):return false
	var def=acts[action]; var key=id+"_"+action
	if s.gold<def.cost or (not def.day and s.acts.get(key,0)==s.day): return false
	s.gold-=def.cost
	if def.day: s.day+=1
	else: s.acts[key]=s.day
	aff_add(id,def.aff)
	if action in ["meal","rest"]:npc_like("dorothea")
	note(person(id).name+" · "+def.name); return true

func dungeon_catalog() -> Array:
	var out=[]
	for id in dungeon_rules.config.zone_order:
		var z=dungeon_rules.zones[id]
		out.append({"id":id,"name":z.name,"floor":int(z.floors[0]),"last_floor":int(z.floors[1]),"unlocked":z.floors[0]<=dungeon_max(),"image":"res://assets/src/academy.png","route":"탐색 5회 → 휴식 → 층 보스","provisional":false})
	return out

func item_preview(id: String,who: String) -> Dictionary:
	var it=item_def(id)
	if it.is_empty() or who not in s.owned: return {"usable":false,"reason":"보유한 동료와 보급품을 선택하세요."}
	var m=s.members[who]; var b=stats(who,m.level); var out={"usable":false,"before":m.hp,"after":m.hp,"maximum":b.hp,"resource":"HP","reason":""}
	if s.items.get(id,0)<1: out.reason="보유한 보급품이 없습니다."; return out
	if m.level<it.level: out.reason="Lv.%d부터 사용합니다." % it.level; return out
	if active() and s.run.phase=="battle": out.reason="전투의 보급품 메뉴에서 사용하세요."; return out
	match it.kind:
		"hp","mp":
			var k=it.kind; out.before=m[k]; out.maximum=b[k]; out.resource=k.to_upper()
			out.after=mini(b[k],m[k]+int(round(b[k]*it.fraction)))
			out.usable=m.hp>0 and m[k]<b[k]
			if not out.usable: out.reason="쓰러진 동료에게는 붕대를 사용하세요." if m.hp<=0 else "이미 가득 찼습니다."
		"revive":
			out.after=maxi(1,int(b.hp*it.fraction)); out.usable=m.hp==0
			if not out.usable: out.reason="쓰러진 동료에게 사용합니다."
		"level":
			out.before=m.level; out.after=mini(40,m.level+1); out.maximum=40; out.resource="Lv."
			out.usable=not active() and m.level<40
			if not out.usable: out.reason="마을에서 Lv.40 미만의 동료에게 사용합니다."
		"return":
			out.usable=active() and s.run.phase in ["explore","rest"]
			if not out.usable: out.reason="원정 탐색 중 사용합니다."
		_: out.reason="전투의 보급품 메뉴에서 사용하세요."
	return out

func gear_comparison(id: String,uid: int) -> Dictionary:
	var entry=gear_entry(uid)
	if entry.is_empty() or id not in s.owned: return {}
	var item=gear.by_id[entry.id]; var level=s.members[id].level
	if item.cls!=class_def(id).id: return {}
	var old=s.equipment[id].get(item.slot,0); var before={}
	if old: before=gear.roll(gear_entry(old),level)
	var after=gear.roll(entry,level); var delta={}
	for key in before: delta[key]=after.get(key,0)-before[key]
	for key in after: delta[key]=after[key]-before.get(key,0)
	return {"before":before,"after":after,"delta":delta,"slot":item.slot,"can_equip":level>=gear.rules.equip_lv[item.rarity] and not active(),"roll_authority":"legacy-web-rng"}

func npc_like(id: String) -> void:
	if id not in ["fenella","loredana","oswald","pietro","dorothea","knut","hanna","isolde","sven","agnes","noel","muriel","vittoria"]:return
	var a=float(s.npc_aff_r21.get(id,0))
	if a<100:s.npc_aff_r21[id]=minf(100,floor((a+1)*100+.5)/100)

func aff_add(id: String,amount: float) -> float:
	if id not in s.owned:return 0
	var before=float(s.members[id].aff)
	var source_state={"aff":{id:before}}
	var gained=TOWN_RULES.aff_add_source(source_state,id,amount)
	var after=source_state.aff[id];s.members[id].aff=after
	var t=dialogue.transition(id,before,after)
	if not t.is_empty():
		t.who=id;t.kind="transition";s.dialogue_r21.queue.append(t)
		note(person(id).name+" · "+TOWN_RULES.aff_stage(before)+" → "+TOWN_RULES.aff_stage(after))
	return gained

func aff_party(amount: float) -> Dictionary:
	var multiplier=1.2 if party_count("nation","솔렌 성왕국")>=3 else 1.0
	var gained={}
	for id in s.party:
		if id!="persona" and id!="" and id in s.owned and not gained.has(id):gained[id]=aff_add(id,amount*multiplier)
	return gained

func begin_dialogue(id: String) -> bool:
	if active() or id not in s.owned:return false
	var state=s.dialogue_r21
	if not state.pending.is_empty():return state.pending.who==id
	if s.acts.get(id+"_talk",0)==s.day:return false
	var row=dialogue.select_scene(id,s.members[id].aff,state.seen)
	if row.is_empty():return inn(id,"talk")
	state.response={};state.pending={"who":id,"scene":row.id,"day":s.day}
	return true

func choose_dialogue(choice_id: String) -> bool:
	var state=s.dialogue_r21;var p=state.pending
	if active() or p.is_empty() or p.who not in s.owned or p.day!=s.day or s.acts.get(p.who+"_talk",0)==s.day:return false
	var row=dialogue.scene(p.who,p.scene);var choice={}
	for c in row.get("choices",[]):
		if c.id==choice_id:choice=c;break
	if choice.is_empty():return false
	var before=float(s.members[p.who].aff)
	var qsize=state.queue.size();var gained=aff_add(p.who,float(choice.aff))
	var transition={}
	if state.queue.size()>qsize:transition=state.queue.pop_back()
	s.acts[p.who+"_talk"]=s.day;state.seen[p.scene]=int(state.seen.get(p.scene,0))+1
	state.response={"who":p.who,"scene":p.scene,"choice":choice_id,"text":choice.text,"lines":choice.response.duplicate(),"gained":gained,"before":before,"after":s.members[p.who].aff,"transition":transition}
	state.pending={};note(person(p.who).name+" · 대화하기")
	return true

func close_dialogue() -> bool:
	if s.dialogue_r21.response.is_empty():return false
	s.dialogue_r21.response={};return true

func emit_bark(event: String,only: String="") -> void:
	var state=s.dialogue_r21;var count=int(state.bark_counts.get(event,0))
	var ids=s.party.filter(func(id):return (only.is_empty() or id==only) and not dialogue.data(id).is_empty())
	if ids.is_empty():return
	var who=ids[posmod(count,ids.size())];var line=dialogue.bark(who,s.members[who].aff,event,int(count/ids.size()))
	if line.is_empty():return
	state.bark_counts[event]=count+1
	state.queue.append({"who":who,"kind":"bark","event":event,"lines":[line]})
	# Bound persistent presentation history; never affect game RNG or rewards.
	if state.queue.size()>32:state.queue.pop_front()

func dismiss_dialogue_queue() -> bool:
	if s.dialogue_r21.queue.is_empty():return false
	s.dialogue_r21.queue=[];return true

func depart_dungeon(f: int,seed: int=0,rift_id: String="",stars: int=1) -> bool:
	if not s.dialogue_r21.pending.is_empty() or not s.dialogue_r21.response.is_empty():return false
	if not super(f,seed,rift_id,stars):return false
	emit_bark("departure");emit_bark("floor_entry")
	if s.run.phase=="battle":emit_bark("elite_boss_before");emit_bark("battle_start")
	return true

func advance() -> bool:
	if not super():return false
	if r21():
		if s.run.phase=="battle":
			if s.run.kind=="elite":emit_bark("elite_boss_before")
			emit_bark("battle_start")
		else:emit_bark("discovery")
	elif s.run.event=="sealed":emit_bark("sealed_cache")
	return true

func travel(id: String) -> bool:
	if not super(id):return false
	if s.run.event=="sealed":emit_bark("sealed_cache")
	return true

func use_card(id: String) -> bool:
	if not super(id):return false
	emit_bark("rest" if id=="camp" else "discovery")
	return true

func enter_dungeon_rest():
	var was_rested=s.run.rested
	super()
	if not was_rested:emit_bark("rest")

func final_battle() -> bool:
	if not super():return false
	if r21():emit_bark("elite_boss_before");emit_bark("battle_start")
	return true

func record_battle(snapshot: Dictionary) -> void:
	# Observe saved engine events outside battle UI; each threshold fires once/run fight.
	if r21() and active() and s.run.phase=="battle":
		var marks=s.run.get("dialogue_marks",{})
		for id in s.party:
			var a=snapshot.get("units",{}).get(id,{})
			if a.is_empty():continue
			var key=str(s.run.step)+":"+str(s.run.final)+":"+id
			var hp=float(a.get("hp",1));var maximum=float(stats(id,s.members[id].level).hp)
			if hp<=0 and not marks.has(key+":down"):
				marks[key+":down"]=true;emit_bark("ally_down")
			elif hp>0 and hp<=maximum*.25 and not marks.has(key+":low"):
				marks[key+":low"]=true;emit_bark("self_wounded",id);emit_bark("ally_low_hp")
		s.run.dialogue_marks=marks
	super(snapshot)

func finish_battle() -> bool:
	var source=r21();var final=source and s.run.final
	var won=source and s.run.battle.get("result","")=="victory"
	if not super():return false
	if source and (won or (active() and s.run.phase!="battle") or s.summary.get("result","")=="clear"):
		emit_bark("boss_defeat" if final else "victory")
	return true

func valid_dialogue_save(value: Dictionary) -> bool:
	var d=value.dialogue_r21
	if not _shape(d,{"seen":{},"pending":{},"response":{},"queue":[],"bark_counts":{}}):return false
	for counts in [d.seen,d.bark_counts]:
		for key in counts:
			if not key is String or not _num(counts[key]) or counts[key]<0 or counts[key]!=int(counts[key]):return false
	if d.queue.size()>32:return false
	for row in d.queue:
		if not _shape(row,{"who":"","kind":"","lines":[]}) or row.who not in value.get("owned",[]):return false
		if row.kind not in ["transition","bark"]:return false
		if row.kind=="transition" and not _shape(row,{"from":"","to":"","situation":""}):return false
		for line in row.lines:
			if not line is String:return false
	if not d.pending.is_empty():
		var p=d.pending
		if not _shape(p,{"who":"","scene":"","day":0}) or p.who not in value.get("owned",[]) or p.day!=value.day:return false
		if value.acts.get(p.who+"_talk",0)==value.day:return false
		# Missing future content cancels presentation during migration, not the save.
	if not d.response.is_empty():
		var p=d.response
		if not _shape(p,{"who":"","scene":"","choice":"","text":"","lines":[],"gained":0,"before":0,"after":0,"transition":{}}) or p.who not in value.get("owned",[]):return false
		for line in p.lines:
			if not line is String:return false
		if not p.transition.is_empty():
			if not _shape(p.transition,{"from":"","to":"","situation":"","lines":[]}):return false
			for line in p.transition.lines:
				if not line is String:return false
	return true

func accept_quest(id: int) -> bool:
	if not super(id):return false
	npc_like("fenella");return true
