extends RefCounted
## 34-traits: global combat hooks, after every living personal hook.
const Passive=preload("res://game/combat_passives_r23.gd")
const Text=preload("res://game/combat_display_r22.gd")
const ORDER=["human","elf","demon","halfelf","nox","beast","seredia","karashin","solen","marento","naerin","morgas","kern","border"]
const TAGS={"인간":"human","엘프":"elf","악마":"demon","하프엘프":"halfelf","녹스":"nox","수인":"beast","신성 세레디아 제국":"seredia","대카라쉰":"karashin","솔렌 성왕국":"solen","마렌토 공화국":"marento","나에린":"naerin","모르가스 신관국":"morgas","케른 연방":"kern","경계도시":"border"}
static func passive_node(key: String) -> Dictionary:return Passive.PASSIVES.races.get(key,Passive.PASSIVES.nations.get(key,{}))
static func passive_text(value: Variant) -> String:
	var src=Text.lua_string(value);var regex=RegEx.new();regex.compile("\\{([A-Za-z0-9_]+)\\.([A-Za-z0-9_]+)(%?)\\}")
	var out="";var pos=0
	for m in regex.search_all(src):
		out+=src.substr(pos,m.get_start()-pos)
		var node=Passive.VAR if m.get_string(1)=="var" else Passive.TXN.get(m.get_string(1),Passive.PASS.get(m.get_string(1),{}))
		var v=node.get(m.get_string(2))
		if v is int or v is float:
			if m.get_string(3)=="%":v=floor(v*100+.5+1e-9)
			out+=Text.lua_string(v)
		else:out+=m.get_string()
		pos=m.get_end()
	return out+src.substr(pos)
static func counts(b) -> Dictionary:
	var out={}
	for u in b.data.allies:
		if u.hp<=0 or u.get("empty",false):continue
		for field in ["race","nation"]:
			var value=u.get(field,"")
			if value is String and not value.is_empty():
				var key=TAGS.get(value,value);out[key]=out.get(key,0)+1
	return out
static func refresh(b) -> void:
	var c=counts(b);var extended=level(c.get("halfelf",0))>=2
	for u in b.data.allies:u.buff_extension=1 if extended else 0
	var sy={}
	for key in ORDER:
		var n=level(c.get(key,0))
		if n>=2:sy[key]=n
	b.data.synergies=sy
static func synergies(b,lang: String="ko") -> Array:
	var out=int_synergy(b);var c=counts(b)
	for key in ORDER:
		var n=level(c.get(key,0))
		if n>=2:
			var node=passive_node(key)
			out.append({"t":node.short,"n":c[key],"fx":passive_text(Text.Locale.t(node.tier[n-2],lang))})
	return out
static func level(count: int) -> int:return 3 if count>=3 else 2 if count>=2 else 0
static func int_synergy(b) -> Array:
	var n=0
	for u in b.data.allies:
		if u.hp>0 and u.line=="int":n+=1
	return [{"t":"지능","n":n,"fx":"라운드마다 MP 4 회복"}] if n>=2 else []

static func dot_trim(b) -> void:
	var cap=6 if b.count_tag("nation","모르가스 신관국")>=3 else 5
	for e in b.living(false):
		if not e.effects.has("dot") or not e.effects.dot.has("stacks"):continue
		var eff=e.effects.dot
		while eff.stacks.size()>cap:
			eff.stacks.pop_front()
			for key in ["lifetimes","owners","bursts","initial_turns","orders"]:
				if eff.has(key):eff[key].pop_front()
		eff.amount=0.0
		for amount in eff.stacks:eff.amount+=amount
		b.x(e).dot_stacks=eff.stacks.size()
static func hit_after(b,h: Dictionary) -> void:
	var a=h.a; var e=h.e
	var shared=b.x(b.data.allies[0]); shared.last_target=e.id; shared.last_attacker=a.id
	if a.class_id=="sanctioned" and e.hp>0 and ((b.action_id=="attack" and not h.extra) or (h.volley and b.action_id!="personal")):
		b.gear_bridge.invoke("warp",[b.gear_bridge.slot(a),b.gear_bridge.slot(e),false,.5 if e.grade=="boss" else 1,800])
	if a.class_id=="unsanctioned" and b.action_id=="attack" and not h.extra and e.hp>0:
		b._push_class_dot(e,maxf(1,floor(a.base[a.line]*.24)),3,a.id)
	if h.killed: kill_credit(b,a)

static func kill_credit(b,a,at: Variant=null) -> void:
	if a.is_empty() or not a in b.data.allies or a.hp<=0:return
	if at==null:at=b.combat_events.T
	if not b.combat_events.record.has("ev"):b.combat_events.begin_record(b)
	b._gear_kill(a)
	# 34-traits kill_credit clears SKON only after the gear kill hook.
	var old_skill=b.gear_bridge.hooks.skill if b.gear_bridge!=null else null
	if b.gear_bridge!=null: b.gear_bridge.hooks.skill=null
	if level(b.count_tag("race","악마"))>=2:
		var h=b._receive_heal(a,a.mhp*.03)
		if h>0:
			b.combat_events.field(b,a,"hp",a.hp,at+.3)
			b.combat_events.trait_payload(b.combat_events.slot(b,a),"피의 대가: 처치로 HP +"+str(h),at+.3)
	if level(b.count_tag("race","악마"))>=3:
		var any=false
		for u in b.living(true):
			if u.mp>=u.mmp:continue
			u.mp=mini(u.mmp,u.mp+2);b.combat_events.field(b,u,"mp",u.mp,at+.3);any=true
		if any:b.combat_events.trait_payload(b.combat_events.slot(b,a),"피의 대가: 처치로 파티 MP +2",at+.3)
	if b.gear_bridge!=null: b.gear_bridge.hooks.skill=old_skill

static func enemy_down(b,e) -> void:
	if level(b.count_tag("nation","대카라쉰"))>=3:
		var shared=b.x(b.data.allies[0]); shared.karashin_kills=mini(3,shared.get("karashin_kills",0)+1)

static func turn_end(b,u) -> void:
	if not u in b.data.allies:return
	refresh(b)
	if u.hp<=0:return
	var x=b.x(u)
	if x.get("double_turn",false): x.double_turn=false; return
	if level(b.count_tag("race","수인"))>=3 and b._roll(.04):
		x.double_turn=true;u.remaining=maxf(0,u.remaining-10000)
		if not b.combat_events.record.has("ev"):b.combat_events.begin_record(b)
		b._trait_event(u,"2회 행동: 바로 한 번 더")
		var name=Text.unit_name(u)
		b.combat_events.say("<b>"+name+"</b>"+Text.Josa.tail(name,"은는")+" 틈을 놓치지 않는다. <em>2회 행동</em>, 바로 한 번 더 움직인다",b.combat_events.T+.2)
		b.combat_events.T+=.6

static func attacked(b,t,e) -> void:
	if t.hp<=0 or e.hp<=0 or b.count_tag("nation","케른 연방")<3: return
	if b._roll(.05):
		b._trait_event(t,"계약은 지킨다: 반격",0)
		b._damage(t,e,.7*1.1,0,true,-1,{"hit":.3,"duration":.9,"allow_extra":true})

static func extra_hit(b,a: Dictionary,target: Dictionary,opt: Dictionary,res: Dictionary,at: float,attack_callback: Callable=Callable()) -> void:
	if a.hp<=0 or opt.get('extra',false) or not a in b.data.allies or a.class_id!='assassin':return
	if target.hp<=0 or res.get('kill',0)==1:return
	var chance=.2
	for entry in a.get('gear_special',[]):
		if entry.key=='as_shadow':chance=entry.v[0]/100.0;break
	if not b._roll(chance):return
	b.combat_events.trait_payload(b.combat_events.slot(b,a),'추가 공격')
	var atk=StateAttack.get(a.class_id,StateAttack.warrior)
	var options={"m":atk.m,"brk":0,"extra":true,"name":"추가 공격","sk":"추가 공격","vb":atk.vb,"hit":.25,"dur":.8}
	if opt.has('el'):options.el=opt.el
	if attack_callback.is_valid():attack_callback.call(a,target,options)
	else:b.SourceAttack.attack(b,a,target,options)

const StateAttack=preload('res://game/battle_source_data_r23.gd').ATTACK
