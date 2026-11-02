extends "res://tests/combat_a6_r22_test.gd"
const R23_RACES={"":"","elf":"엘프","beast":"수인"}
const FixedEnemy=preload("res://tests/battle_r23_random_fixture.gd")
var cached_data={}
func clean():
	if cached_data.is_empty(): cached_data=fixture().data.duplicate(true)
	var b=Battle.new(cached_data); b.freeze_finish=true; b.data.seed=12345; b.turn_count=1; b.dungeon_enemy_r21.begin_random(1)
	for u in b.data.allies+b.data.enemies:
		u.hp=1000;u.mhp=1000;u.shield=0;u.effects={};u.remaining=10000
		if u.has("base"):u.mp=0;u.mmp=100;u.base.spd=100;u.base.str=100;u.base.int=100;u.base.agi=0;u.base.crit=0
		else:u.speed=100;u.defense=0;u.weak=[]
	for i in range((b.data.allies+b.data.enemies).size()):
		var u=(b.data.allies+b.data.enemies)[i]
		u.row="전열" if i%2==0 else "후열"
		if u.has("base"):
			u.race=""; u.nation=""; u.lineage=""; u.class_id="warrior";u.line="str";u.base.def=0;u.gear_fx={};u.gear_special=[];u.element="none"
		else: u.gauge=10000;u.max=10000;u.rules={};u.grade="mob";u.phase=0
	return b
func rename(b,u,cid):
	b.extra_state[cid]=b.x(u);u.id=cid
func project(b):
	var us=[];var all=b.data.allies+b.data.enemies
	for u in all:
		var bf={}
		for key in ["attack_up","defense_up","attack_down","defense_down","haste","slow","contract","duty","adeline_guard","fortified_guard","backstep","blood","psguard","pscrit","zdn"]:
			if u.effects.has(key):bf[key]=[u.effects[key].amount,u.effects[key].turns,u.effects[key].get("doubled",false)]
		var dots=[]
		for key in ["dot","corrosion","bleed"]:
			if not u.effects.has(key):continue
			var eff=u.effects[key];var n=eff.get("stacks",[eff.amount]).size()
			for i in range(n):
				var by=eff.get("owners",[eff.get("by","")])[i] if eff.has("owners") else eff.get("by","")
				dots.append({"d":eff.get("stacks",[eff.amount])[i],"n":eff.get("lifetimes",[eff.turns])[i] if eff.has("lifetimes") else eff.turns,"by":all.find(b.unit(by))+1 if not by.is_empty() else 0,"k":1 if key=="dot" else 0,"c":1 if key=="corrosion" else 0,"bld":1 if key=="bleed" else 0})
		var cover=b.x(u).get("cover","")
		us.append({"hp":u.hp,"mp":u.get("mp",0),"sh":u.get("shield",b.fx(u,"shield")),"g":u.remaining,"ay":u.get("gauge",0),"broken":u.get("broken",false),"sp":u.base.spd if u.has("base") else u.speed,"buffs":bf,"dots":dots,"tau":u.effects.has("taunt"),"cover":all.find(b.unit(cover))+1 if not cover.is_empty() else 0,"charging":u.get("charging",false),"regen":[b.fx(u,"persona_regen"),u.effects.get("persona_regen",{}).get("turns",0)]})
	return {"units":us,"rng":b.x(b.data.enemies[0]).source_rng}
func run():
	var input=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/inputs.json"))
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/oracle.json"))
	for c in input:
		var b=clean();var a=b.data.allies[0];var e=b.data.enemies[0];var got
		match c.op:
			"speed":
				for i in range(4):b.data.allies[i].race=R23_RACES[c.race] if i<c.n else ""
				if not c.alive:b.data.allies[3].hp=0
				a.base.spd=100.137;a.hp=333;a.class_id=c.cls;b.data.allies[1].nation="대카라쉰";b.data.allies[1].class_id="alchemist"
				b._effect(a,"haste" if c.buff>=0 else "slow",3,absf(c.buff));got={"speed":b.speed(a),"other":b.speed(b.data.allies[1])}
			"target":
				for i in range(4):b.data.allies[i].hp=200 if i<c.alive else 0
				e.acts=[{"kind":c.kind,"low":c.low}];e.act_index=0
				if c.get("native_alias",false):e.acts[0].erase("low")
				if c.has("force_random"):b.dungeon_enemy_r21=FixedEnemy.new(b);b.dungeon_enemy_r21.forced=c.force_random
				got={"target":(b.data.allies+b.data.enemies).find(b.dungeon_enemy_r21.pick_target(e))+1,"rng":b.x(e).source_rng}
			"defense":
				a.line="str" if c.melee else "int";b.x(e).hidden=c.hidden
				if not c.other:b.data.enemies[1].hp=0
				var r={}
				if c.rule in ["melee","all"]:r.melee_dr=.2
				if c.rule in ["ranged","all"]:r.ranged_dr=.3
				if c.rule in ["ally","all"]:r.dr_while_ally={"enemy":"apprentice_doll","mult":.5}
				e.rules=r;got={"mult":b.dungeon_enemy_r21.defense(a,e)}
			"kill":
				for i in range(4):b.data.allies[i].race="악마" if i<c.n else "";b.data.allies[i].mp=99
				a.hp=(1000 if c.full else 500) if c.alive else 0
				b.TraitRules.kill_credit(b,a);got=project(b)
			"double":
				b.data.seed=int(c.seed);b.dungeon_enemy_r21.begin_random(1)
				for i in range(4):b.data.allies[i].race="수인" if i<c.n else ""
				if not c.alive:a.hp=0
				b.x(a).double_turn=c.double;b.TraitRules.turn_end(b,a);got={"g":a.remaining,"double":b.x(a).double_turn,"rng":b.x(e).source_rng}
			"personal","can":
				rename(b,a,c.cid);b.action_id="personal";var v=int(c.variant)
				if c.cid=="bargut":a.trait.p.crit=30
				for u in b.data.allies:u.hp=1000 if v==1 else 500;u.mp=100
				for u in b.data.enemies:u.hp=10000;u.mhp=10000
				e.acts=[{"kind":"atk","ic":"spell" if v==7 else "attack"}]
				if v==2:b.data.enemies[1].hp=0
				if v==3:
					for i in range(1,4):b.data.allies[i].row="후열"
				if v==4:e.grade="boss";e.phase=0
				if v==5:e.hp=1;b.data.enemies[1].hp=1
				if v==6:b._effect(b.data.allies[1],"attack_up",2,.2);b._effect(b.data.allies[1],"contract",2,.4)
				if v==8:b._effect(b.data.allies[1],"attack_down",2,.2);b._effect(b.data.allies[1],"defense_down",2,.1)
				if v==9:a.base.spd=99;b.data.allies[1].base.spd=101
				if v==10:a.hp=100;a.once=true;b.x(a).inch=true
				if v==11:a.mp=0;b._effect(a,"silence",1);b.x(a).silenced_id="personal"
				if c.op=="personal":
					b._personal(a,e,b.data.allies[1],{"name":"test","brk":15});got=project(b)
				else:got={"can":b.PersonalRules.can(b,a) and not (a.effects.has("silence") and b.x(a).get("silenced_id","")=="personal")}
			"strike":
				a.hp=c.hp;a.shield=c.shield
				if c.guard:b._effect(a,"guard",1,.4)
				if c.priest:b.data.allies[1].class_id="priest"
				b._incoming_strike(a,100,e,{"name":"test"},false,c.fixed);got=project(b)
			"atk_mult":
				e.grade=c.grade;e.rules={"hp_atk":{"thr":.3,"amount":.2}};b.data.encounter_r21.enc.raid=true;b.ctb_round=int(c.rd);e.hp=c.hp
				b._effect(e,"attack_up",2,c.buff);got={"mult":b.dungeon_enemy_r21.attack_mult(e)}
			"persona":
				rename(b,a,"persona");b.action_id="personal"
				for u in b.data.allies:u.hp=500
				if c.variant==1:b.data.allies[1].hp=0
				if c.variant==2:b.x(b.data.enemies[1]).protect=e.id
				if c.variant==3:
					for u in b.data.enemies:u.hp=1
				if c.variant==4:b._effect(e,"attack_down",2,.2)
				if c.variant==5:b.data.allies[1].shield=9999
				b.PersonaCombat.run(b,a,e,b.data.allies[1],{"persona_skill":c.raw});got=project(b)
			"persona_meta":
				var r=b.PersonaCombat.Research;var raw=c.raw.duplicate(true) if c.raw is Dictionary or c.raw is Array else c.raw
				if c.get("level_case","")=="nan":raw.prefix_lv.strike=NAN;raw.suffix_lv.bane=NAN
				var p=r.part("prefixes",r.clean(raw).prefix);var q=r.part("suffixes",r.clean(raw).suffix)
				got={"value":r.clean(raw),"parts":[p if not p.is_empty() else false,q if not q.is_empty() else false],"ready":r.ready(raw),"name":r.skill_name(raw),"desc":r.description(raw),"name_en":r.skill_name(raw,true),"desc_en":r.description(raw,true),"skill":r.skill(raw) if r.ready(raw) else false}
			"enemy_speed":
				e.hp=c.hp;e.speed=c.base;e.rules={"hp_spd":{"thr":.3,"amount":.2}} if c.rule else {}
				b._effect(e,"haste" if c.buff>=0 else "slow",3,absf(c.buff));got={"speed":b.speed(e)}
			"pack_speed":
				for i in range(4):b.data.allies[i].nation="대카라쉰" if i<c.n else ""
				b.x(a).karashin_kills=c.kills
				if not c.alive:b.data.allies[3].hp=0
				got={"speed":b.speed(a)}
			"debuff":
				if int(c.bits)%2==1:b._effect(e,"attack_down",2,.2)
				if (int(c.bits)/2)%2==1:b._effect(e,"defense_down",2,.2)
				if (int(c.bits)/4)%2==1:b._effect(e,"foxflame",2,.6)
				if c.dot!="none":b._effect(e,{"class":"dot","corrosion":"corrosion","bleed":"bleed"}[c.dot],2,10)
				got={"debuff":b.PersonaCombat.debuffed(e)}
			"counter":
				var v=int(c.variant);e.rules={"counter_when_guard":{"m":.6}};b._effect(e,"guard",2,.4);e.attack=100
				if v==1:a.gear_fx={"evade":100}
				if v==2:b._effect(e,"attack_up",3,.5)
				if v==3:e.rules.hp_atk={"thr":1,"amount":.2}
				if v==4:e.grade="chief";e.hp=299
				if v==5:rename(b,b.data.allies[1],"marceline");b.x(b.data.allies[1]).cover=a.id
				if v==6:rename(b,a,"saya");b.data.seed=1;b.dungeon_enemy_r21.begin_random(1)
				if v==7:b.x(e).counter_busy=true
				if v==8:b._effect(e,"enemy_attack_self",3,.2)
				if v==9:b._effect(e,"attack_down",3,.2)
				if v==10:b._effect(a,"guard",2,.4)
				if v==11:a.shield=30
				if v==12:e.grade="boss";b.data.encounter_r21.enc.raid=true;b.ctb_round=40
				if v==13:b._effect(e,"enemy_attack_self",3,.2);b._effect(e,"attack_up",3,.5);b._effect(e,"attack_down",3,.2)
				if v==14:e.attack=0
				if v==15:a.hp=0
				if v==16:e.hp=0
				b.dungeon_enemy_r21.after_hit(a,e);got=project(b)
			"element_delay":
				a.element=c.actor;e.rules={"weak_hit_delay":c.rule}
				if c.boss:e.grade="boss"
				if c.lethal:e.hp=1
				b._damage(a,e,1,0,false,-1,{"element":c.element});got=project(b)
		var want=oracle.rows[int(c.case)-1].expected
		check(same(got,want),"r23/%s/%d"%[c.op,c.case],got,want)
	var f=FileAccess.open("res://../verification/parity-r23/latest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
