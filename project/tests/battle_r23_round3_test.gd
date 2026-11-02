extends "res://tests/battle_r23_batch_test.gd"
class CycleForced:
	extends "res://tests/battle_r23_random_fixture.gd"
	var calls=0
	func random() -> float:calls+=1;return forced
func same(a,b) -> bool:
	if (a is String)!=(b is String):return false
	return super(a,b)
func run():
	var stats=Stats.new();var traits=Traits.new();var personal=preload("res://game/personal_rules_r22.gd").new();var display=preload("res://game/combat_display_r22.gd").new()
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/round3-oracle.json"))
	for index in range(source.rows.size()):
		var row=source.rows[index];var c=row.input;var got="API unavailable"
		match row.op:
			"pct":
				if display.has_method("percent"):
					var v=display.call("percent",c.value);got={"a":v,"b":v,"foes":v}
			"short":
				if display.has_method("short_name"):
					var v=display.call("short_name",c.value);got={"a":v,"b":v}
			"names":
				if display.has_method("unit_name"):
					var u={"name":c.name};var v=display.call("unit_name",u,c.lang)
					got={"engine":v,"foes":v,"personal":v,"sub":display.call("subject",u,c.lang)}
			"bp":
				if display.has_method("bold_particle"):got=display.call("bold_particle",c.name,c.key,c.lang)
			"vconn":
				if display.has_method("verb_connection"):got=display.call("verb_connection",c.value)
			"exp_mult":got=preload("res://game/expedition_rules_r22.gd").new().modifiers(c.pm,Stats.world.companions).exp
			"legacy_stats":
				if stats.has_method("enemy_stats"):
					var method=stats.get_method_list().filter(func(m):return m.name=="enemy_stats")[0]
					if method.args[0].type!=TYPE_STRING or c.kind is String:got=stats.call("enemy_stats",c.kind,c.lv,c.star)
			"legacy_foes":
				if native_rules.has_method("foes_for"):got=native_rules.foes_for(c.pm)
			"rift":
				if native_rules.has_method("rift_id_of"):got=native_rules.rift_id_of(c.value)
			"floor_plan":
				if native_rules.has_method("floor_plan"):got=native_rules.floor_plan(int(c.f),c.avg,int(c.n),int(c.stage),int(c.seed))
			"front":
				if native_rules.has_method("front_before"):got=native_rules.front_before(c.fl,int(c.a)-1,int(c.b)-1)
			_:
				var b=clean();var a=b.data.allies[0];var e=b.data.enemies[0]
				match row.op:
					"foe_start":
						for j in range(2):
							b.data.enemies[j].remaining=(j+5)*7;b.data.enemies[j].hp=1000 if int(c.bits)&(1<<j) else 0;b.data.enemies[j].rules={"first_move":bool(int(c.bits)&(1<<(j+2)))}
						if not c.fl:b.data.erase("encounter_r21")
						if b.dungeon_enemy_r21.has_method("start"):
							b.dungeon_enemy_r21.start();got=[b.data.enemies[0].remaining,b.data.enemies[1].remaining]
					"foe_turn_start","foe_turn_bound":
						var boundary=row.op=="foe_turn_bound"
						if boundary:b.dungeon_enemy_r21=CycleForced.new(b);b.dungeon_enemy_r21.forced=c.roll
						b.x(e).source_rng=12345 if boundary else c.seed;b.x(e).protect=b.data.enemies[1].id;b.x(e).hidden=true;e.phase=2 if boundary else c.phase;e.weak=["keep"]
						if boundary:b.x(e).foe_turns=1
						elif not c.turns is bool:b.x(e).foe_turns=c.turns
						else:b.x(e).erase("foe_turns")
						b.dungeon_enemy_r21.rules.foes[e.foe_id].phase2={"weak_cycle":true if boundary else c.cycle}
						if b.dungeon_enemy_r21.has_method("turn_start"):
							b.dungeon_enemy_r21.turn_start(e)
							got={"pt":idx(b,b.unit(b.x(e).protect)),"hid":1 if b.x(e).hidden else 0,"tn":b.x(e).foe_turns,"cwk":e.weak,"weak":e.weak,"rs":b.x(e).source_rng}
							if boundary:got.calls=b.dungeon_enemy_r21.calls
					"broken_level":
						for j in range(4):b.data.allies[j].race="엘프" if j<2 else ""
						b.data.allies[2].race="엘프" if c.value is String and c.value=="elf" else c.value;b.data.allies[2].empty=c.empty
						got=traits.level(b.count_tag("race","엘프"))
					"Kc":
						if not c.K is bool:b.data.combat_K=c.K
						if c.el is bool:b.data.encounter_r21.erase("el")
						else:b.data.encounter_r21.el=c.el
						got=personal.defense_constant(b)
					"live_level":
						for j in range(4):
							b.data.allies[j].hp=1000 if int(c.bits)&(1<<j) else 0
							b.data.allies[j].race="엘프" if j<int(c.n) else "";b.data.allies[j].nation="경계도시" if j<int(c.n) else ""
						got=traits.level(b.count_tag("race","엘프") if c.kind=="race" else b.count_tag("nation","경계도시") if c.kind=="nation" else 0)
					"syn":
						for j in range(4):b.data.allies[j].hp=1000 if int(c.bits)&(1<<j) else 0;b.data.allies[j].line="int"
						if traits.has_method("int_synergy"):got=traits.call("int_synergy",b)
					"boss_half":
						for j in range(2):b.data.enemies[j].hp=1000 if int(c.bits)&(1<<j) else 0;b.data.enemies[j].grade="boss" if int(c.bits)&(1<<(j+2)) else "mob"
						if display.has_method("boss_half"):got=display.call("boss_half",b)
					"corrode":
						b.data.combat_K=47;e.defense=c.def;a.base.str=c.cs
						b.extra_state[e.id]=c.value.duplicate(true) if c.value is Dictionary or c.value is Array else c.value
						b._effect(e,"dot",7,3);e.effects.dot.by=b.data.allies[1].id;e.effects.dot.order=1
						b._effect(e,"bleed",4,2);e.effects.bleed.by=b.data.allies[2].id;e.effects.bleed.order=3
						if c.live:b._effect(e,"corrosion",1,100);e.effects.corrosion.by=b.data.allies[3].id;e.effects.corrosion.order=2
						b.x(b.data.allies[0]).dot_order=3
						var result=personal.call("corrode",b,a,e,int(c.stack))
						var dot=[]
						for pair in [["dot","k"],["bleed","bld"],["corrosion","c"]]:
							var eff=e.effects[pair[0]];var d={"d":eff.amount,"n":eff.turns,"by":idx(b,b.unit(eff.by))};d[pair[1]]=1;dot.append(d)
						got={"n":b.x(e).get("cor",0),"per":e.effects.corrosion.amount/b.x(e).cor if b.x(e).cor!=0 else maxf(1,floor(c.cs*2*1.5*(1-(1-47.0/(47+c.def))/2))),"x":b.x(e).duplicate(true),"dot":dot}
						if result is Array:got.n=result[0];got.per=result[1]
					"gunhild":
						rename(b,a,"gunhild");b.turn_count=3;b.x(a).streak_action=c.action;b.x(a).target=e.id;b.x(a).streak=c.stacks
						var tags=["keep"]
						if personal.has_method("gunhild_deal"):
							var v=personal.call("gunhild_deal",b,a,b.data.allies[1] if c.other else a,b.data.enemies[int(c.target)-5],2,tags)
							got={"value":v if v!=null else false,"x":{"gn":b.x(a).streak_action,"gt":idx(b,b.unit(b.x(a).target)),"gs":b.x(a).streak},"tags":tags}
					"bargut_end":
						rename(b,a,"bargut");a.remaining=c.g
						if not c.pull is bool:b.x(a).personal_pull=c.pull
						if personal.has_method("bargut_turn_end"):
							personal.call("bargut_turn_end",b,a,b.data.allies[1] if c.other else a)
							got={"g":a.remaining,"pull":b.x(a).get("personal_pull",false)}
					"felice_save":
						var t=b.data.allies[1];b.ctb_tick=321;b.extra_state[t.id]=c.value.duplicate(true) if c.value is Dictionary or c.value is Array else c.value
						if personal.has_method("felice_save"):
							var v=personal.call("felice_save",b,a,a if c.self else t)
							var x=b.extra_state[t.id];got={"value":v if v!=null else false,"x":x.duplicate(true) if x is Dictionary else x}
							if got.x is Dictionary and got.x.has("death_tick"):got.x.dtk=got.x.death_tick;got.x.erase("death_tick")
					"drop":
						var keys=["contract","adeline_guard","attack_up","duty"]
						for j in range(3):
							var u=b.data.allies[j];u.effects.keep={"amount":.7,"turns":9,"source":(b.data.allies+b.data.enemies)[int(c.source)-1].id}
							for k in range(4):
								if int(c.bits)&(1<<k):u.effects[keys[k]]={"amount":.2,"turns":3,"source":(b.data.allies+b.data.enemies)[int(c.source)-1].id if int(c.bits)&16 else u.id,"keep":"ok"}
						if personal.has_method("drop_caster_buffs"):
							personal.call("drop_caster_buffs",b,(b.data.allies+b.data.enemies)[int(c.source)-1]);got=[]
							for j in range(4):
								var bf={}
								for key in b.data.allies[j].effects:
									var eff=b.data.allies[j].effects[key];var k=["red20","red","atk","red25"][keys.find(key)] if key!="keep" else "keep"
									bf[k]={"v":eff.amount,"n":eff.turns,"src":idx(b,b.unit(eff.source))}
									if eff.has("keep"):bf[k].keep=eff.keep
								got.append({"bf":bf if j<3 else false})
					"trim":
						for j in range(4):b.data.allies[j].nation="모르가스 신관국" if j<int(c.morgas) else ""
						e.hp=1000 if c.live else 0
						# Native groups class lines, while source interleaves nonclass rows.
						e.effects.dot={"amount":0,"turns":99,"stacks":[],"lifetimes":[],"owners":[],"orders":[]};e.effects.corrosion={"amount":0,"turns":2,"preserved":[]}
						for j in range(int(c.count)):
							var eff=e.effects.dot;eff.stacks.append(j+1);eff.lifetimes.append(j+2);eff.owners.append(a.id);eff.orders.append(j*2)
							e.effects.corrosion.preserved.append({"d":j+1,"n":2,"c":1,"by":2})
						if traits.has_method("dot_trim"):
							traits.call("dot_trim",b);got=[];var eff=e.effects.dot
							for j in range(int(c.count)):
								if j+1 in eff.stacks:got.append({"d":j+1,"n":j+2,"k":1,"by":1})
								got.append(e.effects.corrosion.preserved[j])
					"defense_tags":
						a.line="str" if c.melee else "int";e.rules={};var bits=int(c.bits);b.data.enemies[1].name="인형"
						if bits&1:e.rules.melee_dr=.2
						if bits&2:e.rules.ranged_dr=.3
						if bits&4:e.rules.dr_while_ally={"enemy":"apprentice_doll","mult":.5}
						b.x(e).hidden=bool(bits&8);b.data.enemies[1].hp=1000 if bits&16 else 0
						var tags=["keep"]
						if b.dungeon_enemy_r21.has_method("defense_tags"):got={"value":b.dungeon_enemy_r21.defense_tags(a,e,tags),"tags":tags}
					"attack_tags":
						e.grade=c.grade;e.hp=c.hp;e.rules={"hp_atk":{"thr":.3,"amount":.2}};b.ctb_round=int(c.rd);b.data.encounter_r21.enc.raid=c.raid;b._effect(e,"attack_up",2,.1)
						if b.dungeon_enemy_r21.has_method("attack_multiplier"):got=b.dungeon_enemy_r21.attack_multiplier(e)
		check(same(got,row.expected),"round3/%s/%d"%[row.op,index],got,row.expected)
	var output=OS.get_environment("R23_ROUND3_OUTPUT")
	if output.is_empty():output="round3-latest.json"
	var f=FileAccess.open("res://../verification/parity-r23/"+output,FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 ROUND3 ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
