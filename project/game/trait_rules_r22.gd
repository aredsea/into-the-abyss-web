extends RefCounted
## 34-traits: global combat hooks, after every living personal hook.
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

static func kill_credit(b,a) -> void:
	if a.is_empty() or a.hp<=0: return
	b._gear_kill(a)
	# 34-traits kill_credit clears SKON only after the gear kill hook.
	var old_skill=b.gear_bridge.hooks.skill if b.gear_bridge!=null else null
	if b.gear_bridge!=null: b.gear_bridge.hooks.skill=null
	if level(b.count_tag("race","악마"))>=2: b._receive_heal(a,a.mhp*.03)
	if level(b.count_tag("race","악마"))>=3:
		for u in b.living(true): u.mp=mini(u.mmp,u.mp+2)
	if b.gear_bridge!=null: b.gear_bridge.hooks.skill=old_skill

static func enemy_down(b,e) -> void:
	if level(b.count_tag("nation","대카라쉰"))>=3:
		var shared=b.x(b.data.allies[0]); shared.karashin_kills=mini(3,shared.get("karashin_kills",0)+1)

static func turn_end(b,u) -> void:
	if u.hp<=0 or not u.has("base"): return
	var x=b.x(u)
	if x.get("double_turn",false): x.double_turn=false; return
	if level(b.count_tag("race","수인"))>=3 and b._roll(.04):
		x.double_turn=true; u.remaining=maxf(0,u.remaining-10000); b._trait_event(u,"2회 행동",.6)

static func attacked(b,t,e) -> void:
	if t.hp<=0 or e.hp<=0 or b.count_tag("nation","케른 연방")<3: return
	if b._roll(.05):
		b._trait_event(t,"계약은 지킨다: 반격",0)
		b._damage(t,e,.7*1.1,0,true,-1,{"hit":.3,"duration":.9,"allow_extra":true})
