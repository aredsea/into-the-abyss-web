extends "res://tests/battle_r23_test.gd"
const Rules=preload("res://game/dungeon_rules_r21.gd")
const Stats=preload("res://game/battle_stats_r23.gd")
const Traits=preload("res://game/trait_rules_r22.gd")
var native_rules=Rules.new()
func same(a,b) -> bool:
	if (a is bool)!=(b is bool):return false
	return super(a,b)
class Forced:
	extends RefCounted
	var roll=0.0
	var calls=0
	func next(): calls+=1;return roll
class ForcedPM:
	extends Rules.PM
	var roll=0.0
	var calls=0
	func next() -> float:calls+=1;return roll
func idx(b,u):return (b.data.allies+b.data.enemies).find(u)+1 if not u.is_empty() else 0
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/batch-oracle.json"))
	for index in range(source.rows.size()):
		var row=source.rows[index];var c=row.input;var got
		match row.op:
			"rng":
				var seed=c.get("seed")
				var rng=Rules.PM.new(seed);got=[]
				for j in range(12):rng.next();got.append(rng.s)
			"pick":
				var rng=Forced.new();rng.roll=c.roll
				var value=native_rules.pick_value(rng,c.list)
				got={"value":value if value!=null else false,"calls":rng.calls}
			"party_target":
				var rng=Forced.new();rng.roll=c.roll
				var v=native_rules.party_target(int(c.n),int(c.order),rng,c.override)
				got={"value":v,"calls":rng.calls}
			"compose":got=native_rules.compose(int(c.seed),c.ctx)
			"slots":got=native_rules.build_slots(c.template,int(c.tc),c.elite)
			"shuffle":
				var rng=Rules.PM.new(int(c.seed));var list=c.list.duplicate();rng.shuffle(list);rng.next()
				got={"list":list,"next":rng.s}
			"shuffle_roll":
				var rng=ForcedPM.new(1);rng.roll=c.roll;var list=c.list.duplicate();rng.shuffle(list)
				got={"list":list,"calls":rng.calls}
			"dfs":
				var rng=Rules.PM.new(int(c.seed));var fl=c.fl.duplicate();var fg=c.fg.duplicate();var budget=[c.budget];var args=c.opts.duplicate(true);args.rng=rng
				var ok=native_rules.dfs(c.slots,int(c.k)-1,fl,fg,budget,args);rng.next()
				got={"ok":ok,"fl":fl,"fg":fg,"budget":budget[0],"next":rng.s}
			"result":
				var base=c.base.duplicate(true)
				for key in ["fl","fg","tmpl","raid","n","ne"]:base.erase(key)
				got=native_rules._composition(base,c.fl,c.fg,"probe",c.raid)
			"sy_level":got=Traits.level(int(c.n))
			"class":
				got=Stats.cls_of(c.id)
				if got.is_empty():got=false
			"class_ref":got=is_same(Stats.cls_of(c.id),Stats.cls_of(c.canonical))
			"stats":
				got=Stats.party_stats(c.cls,c.L,c.cid)
				if got.is_empty():got=false
			"stat":
				var cls=Stats.cls_of(c.cls);var mod={};var level=clampf(Stats.number(c.L),1,40);got=[]
				for p in Stats.world.companions:
					if p.id==c.cid:mod=p.mod;break
				for pair in [["str","atk"],["agi","atk"],["int","atk"],["hp","hp"],["mp","mp"],["def","def"]]:got.append(Stats.stat(cls,mod,pair[0],pair[1],level))
			"K":got=Stats.K_of(c.get("L"))
			"reset":
				native_rules.floor_final_reset();var first=native_rules.floor_final(12,c.kind).duplicate(true)
				var curve=native_rules.catalog.tune.curve.get(c.kind,native_rules.catalog.tune.curve.normal);var old=curve.pts[0][1];curve.pts[0][1]=old*2
				var cached=native_rules.floor_final(12,c.kind).duplicate(true);native_rules.floor_final_reset();var changed=native_rules.floor_final(12,c.kind).duplicate(true)
				curve.pts[0][1]=old;native_rules.floor_final_reset();got={"first":first,"cached":cached,"changed":changed}
			_:
				var b=clean();var a=b.data.allies[0];var e=b.data.enemies[0]
				match row.op:
					"cid","slot_of":
						for j in range(4):b.data.allies[j].id=c.ids[j]
						got=b.companion_id(int(c.i)) if row.op=="cid" else b.slot_of(c.id)
					"enemy0":
						if c.foe is bool:b.data.erase("encounter_r21")
						else:
							b.data.encounter_r21.enc.fl=[]
							for j in range(c.foe.size()):b.data.encounter_r21.enc.fl.append("apprentice_doll")
						got=b.initial_enemy_count()
					"foes","behind":
						for j in range(6):(b.data.allies+b.data.enemies)[j].hp=1000 if int(c.bits)&(1<<j) else 0
						if row.op=="foes":
							got=[]
							for u in b.living(false):got.append(idx(b,u))
						else:
							e=b.data.enemies[int(c.t)-5];e.row=c.row;got=idx(b,b._behind(e))
					"xs","tr_xs":
						b.extra_state[a.id]=c.value.duplicate(true) if c.value is Dictionary or c.value is Array else c.value
						var x=b.x(a);var ref=is_same(x,b.extra_state[a.id]);x.changed=7
						got={"same":ref,"value":x,"again":is_same(b.x(a),x)}
					"cor_live":
						b.extra_state[e.id]=c.value.duplicate(true) if c.value is Dictionary or c.value is Array else c.value
						if b.extra_state[e.id] is Dictionary:b.extra_state[e.id].cor=2
						if c.live:e.effects.corrosion={"amount":2,"turns":1}
						var n=b.PersonalRules.cor_live(b,e)
						got={"value":n,"cor":b.extra_state[e.id].get("cor",false) if b.extra_state[e.id] is Dictionary else false}
					"magic":
						e.magic=c.magic;e.acts=c.acts
						got=b.PersonalRules.has_magic(e)
					"casting":
						e.acts=c.acts;e.act_index=int(c.ia)-1
						got=b.PersonalRules.casting(e)
					"btick":
						var keys=["attack_up","defense_down","contract","psguard"];var source_keys=["atk","ddn","red20","psguard"]
						for j in range(4):
							if int(c.bits)&(1<<j):
								a.effects[keys[j]]={"amount":.2,"turns":c.n,"source":b.data.allies[1].id,"doubled":true,"keep":"value"}
								if c.fresh:a.effects[keys[j]].fresh=true
						b.dungeon_enemy_r21.end_effects(a);got={}
						for j in range(4):
							if a.effects.has(keys[j]):
								var eff=a.effects[keys[j]]
								got[source_keys[j]]={"v":eff.amount,"n":eff.turns,"src":2,"db":eff.doubled,"keep":eff.keep}
					"edot":
						for j in range(int(c.count)):b.dungeon_enemy_r21.add_dot(a,e,j+1,j+1)
						b.dungeon_enemy_r21.add_dot(a,b.data.enemies[1],int(c.per),int(c.n));got=[]
						for j in range(4):
							var eff=a.effects.get("enemy_dot_%d"%j,{})
							if not eff.is_empty():got.append({"d":eff.amount,"n":eff.turns,"by":idx(b,b.unit(eff.by))})
					"weak":
						if c.wk is Array:e.weak=c.wk
						else:e.erase("weak")
						got=b.PersonalRules.isweak(e,c.el)
		check(same(got,row.expected),"batch/%s/%d"%[row.op,index],got,row.expected)
	var out=FileAccess.open("res://../verification/parity-r23/batch-latest.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));out.close()
	print("R23 BATCH ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)

