extends RefCounted
## 30-engine / 32-personal-a/b canonical personal-skill eligibility.
const DOUBLE_KEYS=["attack_up","defense_up","contract","duty"]
static func best_double(u: Dictionary) -> String:
	var key=""; var amount=-INF
	for k in DOUBLE_KEYS:
		var effect=u.effects.get(k,{})
		if not effect.is_empty() and not effect.get("doubled",false) and effect.amount>amount:
			key=k; amount=effect.amount
	return key
static func can(b,a: Dictionary) -> bool:
	match a.id:
		"urda":
			for u in b.living(true):
				if u.id!=a.id and not best_double(u).is_empty(): return true
			return false
		"tika": return not b.x(a).get("inch",false) and a.hp>floor(a.mhp*.1)
		"levia": return a.hp>floor(a.mhp*.1)
		"teiris": return not a.once
		"colette":
			for e in b.living(false):
				if b.x(e).get("seal_until",0)>b.ctb_tick: continue
				if e.get("magic",false): return true
				for act in e.acts:
					if act.get("magic",false) or act.get("ic","")=="spell": return true
			return false
	return true

static func abyss(b,a,e,amount: float,element: String="") -> void:
	var value=amount*(1.5 if (a.element if element.is_empty() else element) in e.weak else 1)
	if a.id=="levia": value*=levia_mult(b)
	if b.gear_bridge!=null:
		var modified=b.gear_bridge.invoke("abyss_mul",[b.gear_bridge.slot(a),b.gear_bridge.slot(e),value]); value=modified if modified!=null else value
	value=floor(value+.5)
	var eligible=e.hp>0 and not e.broken
	b._break(e,value)
	if eligible and b.gear_bridge!=null: b.gear_bridge.invoke("abyss_after",[b.gear_bridge.slot(a),b.gear_bridge.slot(e),value,b.combat_events.T,[]])
	if eligible and a.id=="levia":
		for other in b.living(false):
			if other.id!=e.id: b._break(other,floor(value*.07+.5))

static func levia_mult(b) -> float:
	var n=b.data.encounter_r21.enc.fl.size(); var alive=b.living(false).size()
	return 1.3 if alive<=1 or n<=1 else 1+.3*float(n-alive)/(n-1)

static func corrode(b,a,e,add: int) -> void:
	var stacks=mini(3,int(b.x(e).get("cor",0) if e.effects.has("corrosion") else 0)+add)
	b.x(e).cor=stacks
	var n=int(b.data.encounter_r21.el)-1
	var k=40*(1+b.data.def_curve.a*n+b.data.def_curve.b*n*n)
	var dc=k/(k+e.defense*(1-b.fx(e,"defense_down")))
	b._effect(e,"corrosion",2,maxf(1,floor(a.base[a.line]*2*1.5*(1-(1-dc)/2)))*stacks)
	e.effects.corrosion.by=a.id
	e.effects.corrosion.order=b._next_dot_order()

static func run(b,a,e,t,sk) -> void:
	match a.id:
		"marceline": b.x(a).cover=t.id; b.x(a).cover_turns=4
		"naran": b._effect(e,"mark",99,1); abyss(b,a,e,3)
		"teiris":
			a.once=true; b._volley(a,1.9,0)
		"haldric":
			for u in b.living(true):
				if u.row==a.row: b._source_effect(u,"contract",3,.2,a.id)
		"erdene":
			b._effect(a,"taunt",3); b._receive_heal(a,b.x(a).get("prevented",0)*.25); b.x(a).prevented=0
			for foe in b.living(false): b._effect(foe,"attack_down",2,.15); abyss(b,a,foe,20)
		"bianca": b._damage(a,e,1.4,0)
		"saya": e.remaining+=4000*(.5 if e.grade=="boss" else 1); abyss(b,a,e,3)
		"gerda":
			var behind=b._behind(e); b.x(a).penetrating=true; b._damage(a,e,1.3,3)
			if not behind.is_empty() and behind.hp>0: b._damage(a,behind,1.3,3,true,-1,{"hit":.5,"duration":1.5})
			b.x(a).penetrating=false
		"judith":
			b._effect(e,"defense_down",3,.2); b._effect(e,"haste",3,.15); b._effect(e,"attack_down",3,.15)
			if not b.x(e).has("judith_sp0"): b.x(e).judith_sp0=e.speed; e.speed=floor(e.speed*.85+.5)
			b.x(e).judith_until=b.ctb_round+3
			abyss(b,a,e,3); corrode(b,a,e,1)
		"levia": a.hp-=int(floor(a.mhp*.1)) if a.get("nation")!="모르가스 신관국" else maxi(1,int(floor(floor(a.mhp*.1)*.7))); b._effect(a,"rift_charge",99,1); b._sorel_aid(a)
		"urda":
			var key=best_double(t)
			if not key.is_empty():
				t.effects[key].amount=minf(.7,t.effects[key].amount*2) if key in ["contract","duty"] else t.effects[key].amount*2
				t.effects[key].doubled=true
		"lynette":
			for u in b.living(true): b._receive_heal(u,floor(a.base[a.line]),a); b._shield(u,floor(a.base[a.line]),3,false)
		"felice","berenga": b._heal(a,t,.4 if a.id=="felice" else 1,true); cleanse(t)
		"sorel":
			for u in b.living(true): b._heal(a,u,1,true); b._effect(u,"sorel_regen",2,floor(a.base[a.line]*.6))
		"tika":
			a.hp-=int(floor(a.mhp*.1)); b.x(a).free=b.x(a).get("free",0)+2; b.x(a).inch=true; b._sorel_aid(a)
		"hedwig": b._damage(a,e,1.2,15); b.x(a).mamp=.1
		"hildegard":
			b._effect(a,"taunt",2); b._effect(a,"duty",2,.25)
			var target={}
			for foe in b.living(false):
				if target.is_empty() or foe.hp<target.hp: target=foe
			if not target.is_empty(): abyss(b,a,target,15)
		"altan":
			var atk=false; var defense=false
			for u in b.living(true): atk=atk or u.effects.has("attack_up"); defense=defense or u.effects.has("defense_up")
			for u in b.living(true): b._effect(u,"defense_up" if atk and not defense else "attack_up",2,.15)
		"colette":
			var magic=e.get("magic",false)
			for act in e.acts: magic=magic or act.get("magic",false) or act.get("ic","")=="spell"
			abyss(b,a,e,15)
			if magic and (e.grade!="boss" or b._roll(.5)): b.x(e).seal_until=b.ctb_tick+200
			weaken_all(b)
		"zahar": b._volley(a,1.2,15); b._effect(a,"zdn",2,.2)
		"tove": b._effect(a,"taunt",2); abyss(b,a,e,40)
		"miko": b._heal(a,t,1,true); t.remaining=maxf(0,t.remaining-3000)
		"adeline":
			for u in b.living(true):
				b._heal(a,u,.4,true); b._source_effect(u,"adeline_guard",2,.1,a.id); b._add_adeline_regen(u,a.base[a.line]*.16,2,a.id)
		"jorund":
			# PRUN reads the selected target's contract before B.attack redirects.
			var marked=b.x(e).get("jm",false)
			var options={"jmk":marked,"capture_result":true}
			b._damage(a,e,1.2,15,false,-1,options)
			if not marked and not options.get("primary_kill",true): b.x(e).jm=true
		_:
			b._damage(a,e,1.2,15)
			if a.id=="ornel" and e.hp>0: weaken(b,e,.2)

static func cleanse(t) -> void:
	for key in ["attack_down","defense_down","zdn"]:
		if t.effects.has(key): t.effects.erase(key); return
static func weaken(b,e,amount: float) -> void:
	var cur=e.effects.get("attack_down",{})
	if not cur.is_empty() and (cur.amount>amount or (cur.amount==amount and cur.turns>=2)): return
	b._effect(e,"attack_down",2,amount)
static func weaken_all(b) -> void:
	for foe in b.living(false): weaken(b,foe,.15)

static func hit_after(b,h: Dictionary) -> void:
	var a=h.a; var e=h.e
	for owner in b.data.allies:
		if owner.hp<=0: continue
		match owner.id:
			"hildegard": b._hg_scan()
			"bargut":
				if a.id==owner.id and h.critical: b.x(a).personal_pull=maxf(b.x(a).get("personal_pull",0),.3)
			"bianca":
				if a.id==owner.id and not h.killed and e.hp>0 and e.hp<=e.mhp*.25 and e.grade not in ["boss","chief","core"]:
					var before=e.hp; b._flat_enemy(e,before*2+1); b._record_hit(a.id,e.id,before,0); a.remaining-=5000
			"gerda":
				if a.id!=owner.id or b.x(a).get("penetrating",false): continue
				var behind=b._behind(e); var mult=.6
				if behind.is_empty() and e.hp>0: behind=e; mult=.3
				if not behind.is_empty():
					b.x(a).penetrating=true; b._trait_event(a,"도미노 이론",0); b._damage(a,behind,h.power*mult,0,true,-1,{"hit":.4,"duration":1.0}); b.x(a).penetrating=false
			"naran":
				if a.id==owner.id and not h.killed: b._effect(e,"foxflame",3,.6)
			"judith":
				if a.id==owner.id and not h.killed and e.hp>0: corrode(b,a,e,1)
			"colette":
				if a.id==owner.id: weaken_all(b)
			"selva":
				if a.id!=owner.id: continue
				var carry=int(floor(b.x(a).get("overheal",0)))
				if carry>0:
					b.x(a).overheal=0
					if not h.killed and e.hp>0: b._flat_enemy(e,carry,a,true,true,false)
				var leech=.3*minf(h.dealt,h.before+h.get("shield_before",0)); var got=minf(leech,a.mhp-a.hp)
				if got>0: b._receive_heal(a,got)
				b.x(a).overheal=b.x(a).get("overheal",0)+maxf(0,leech-got)
			"jorund":
				if a.id!=owner.id or h.killed or e.hp<=0: continue
				var stacks=mini(3,int(b.x(e).get("bleed_stacks",0) if e.effects.has("bleed") else 0)+1)
				var n=int(b.data.encounter_r21.el)-1; var k=40*(1+b.data.def_curve.a*n+b.data.def_curve.b*n*n)
				var dc=k/(k+e.defense*(1-b.fx(e,"defense_down"))); var per=a.base[a.line]*2*.2*(1-(1-dc)/2)
				e.effects.erase("bleed")
				var want=.05
				if stacks==3:
					b.x(e).bleed_stacks=0; b._flat_enemy(e,maxf(1,floor(9*per*1.5)),a,false,false); want=.18
				else:
					b.x(e).bleed_stacks=stacks; b._effect(e,"bleed",3,maxf(1,floor(stacks*per))); e.effects.bleed.by=a.id; e.effects.bleed.order=b._next_dot_order()
				var cur=b.x(e).get("jd",0)
				if e.hp>0 and want>cur: e.remaining+=10000*(want-cur)*(.5 if e.grade=="boss" else 1); b.x(e).jd=want
			"lavinia":
				if a.id!=owner.id or h.killed or b.x(a).get("echoing",false): continue
				if b.x(a).get("echo_action",-1)!=b.turn_count+1:
					b.x(a).echo_action=b.turn_count+1; b.x(a).echo=b._roll(.5)
				if b.x(a).echo and e.hp>0:
					b.x(a).echoing=true; b._trait_event(a,"에코 챔버",0); b._damage(a,e,h.power*.7,0,true,-1,{"hit":.4,"duration":1.0}); b.x(a).echoing=false
			"tika":
				if a.id!=owner.id: continue
				var roll=b.dungeon_enemy_r21.random()
				if b.x(a).get("enc",0)<2 and roll<.3:
					b.x(a).enc=b.x(a).get("enc",0)+1; b.x(a).free=b.x(a).get("free",0)+1; b._trait_event(a,"앙코르 요청 쇄도",0)

static func enemy_down(b,e) -> void:
	for owner in b.living(true):
		if owner.id=="gunhild" and b.x(owner).get("target")==e.id: b.x(owner).erase("target"); b.x(owner).streak=0
		if owner.id=="judith" and e.effects.has("corrosion"):
			for other in b.living(false):
				if other.id!=e.id: corrode(b,owner,other,int(b.x(e).get("cor",0))); break

static func turn_end(b,a) -> void:
	if a.hp<=0 or not a.has("base"): return
	match a.id:
		"tika":
			if b.x(a).get("free",0)>0: b.x(a).free-=1; a.remaining-=10000
			else: b.x(a).enc=0; b.x(a).inch=false
		"hedwig":
			if b.x(a).get("decl",false) and b.x(a).get("dset",0)<a.actions: b.x(a).decl=false
			if int(a.actions)%3==0: b.x(a).decl=true; b.x(a).dset=a.actions; b._trait_event(a,"삼세번의 법칙",.5)

static func damage_mult(b,a) -> float:
	var mult=1.0
	for owner in b.living(true):
		if owner.id!="hedwig": continue
		if a.id==owner.id and b.x(owner).get("decl",false): mult*=1.6
		if a.line=="int" and b.x(owner).get("mamp",0)>0: mult*=1+b.x(owner).mamp; b.x(owner).mamp=0
	return mult

static func take(b,a,hit: float,e: Dictionary) -> float:
	for owner in b.living(true):
		match owner.id:
			"haldric":
				if a.id==owner.id or owner.effects.has("taunt"): hit*=.85
				hit*=1-b.fx(a,"contract")
			"erdene":
				if a.id==owner.id and owner.effects.has("taunt"): b.x(owner).prevented=b.x(owner).get("prevented",0)+hit*.15; hit*=.85
			"hildegard":
				if a.id!=owner.id: continue
				hit*=.85*(1-b.fx(owner,"duty"))
				if not e.is_empty() and e.get("redirected",false): e.redirected=false; b._receive_heal(owner,owner.mhp*.04)
			"adeline": hit*=1-b.fx(a,"adeline_guard")
			"zahar":
				if a.id!=owner.id: continue
				hit*=.62
				if b.fx(a,"zdn")>0:
					var n=int(b.data.encounter_r21.el)-1; var k=40*(1+b.data.def_curve.a*n+b.data.def_curve.b*n*n)
					var d0=a.base.def*(1+b.fx(a,"defense_up")); var d1=d0-a.base.def*b.fx(a,"zdn")
					hit*=(k+d0)/(k+d1)
	return hit
