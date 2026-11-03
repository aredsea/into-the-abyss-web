extends "res://tests/battle_r23_round3_test.gd"
const Research=preload("res://game/persona_research_r21.gd")
const Personal=preload("res://game/personal_rules_r22.gd")
const Display=preload("res://game/combat_display_r22.gd")
const Record=preload("res://game/combat_record_r23.gd")
class CountingRandom:
	extends "res://tests/battle_r23_random_fixture.gd"
	var calls=0
	func random() -> float:calls+=1;return forced
const RACE_NAMES={"human":"인간","elf":"엘프","demon":"악마","halfelf":"하프엘프","nox":"녹스","beast":"수인"}
const NATION_NAMES={"seredia":"신성 세레디아 제국","karashin":"대카라쉰","solen":"솔렌 성왕국","marento":"마렌토 공화국","naerin":"나에린","morgas":"모르가스 신관국","kern":"케른 연방","border":"경계도시"}
func party(c):
	var b=clean()
	for j in range(4):
		var u=b.data.allies[j];u.line="str";u.hp=1000 if int(c.bits)&(1<<j) else 0;u.race=RACE_NAMES.get(c.key,c.key) if j<int(c.n) else "";u.nation=""
	return b
func clean():
	var sample=super.clean()
	if OS.get_environment("R23_RECONSTRUCT_BEFORE")=="1":
		var b=load("res://../verification/parity-r23/round4-before-miko-fixture.gd").new(sample.data)
		b.data=sample.data.duplicate(true);b.extra_state=sample.extra_state.duplicate(true);b.ctb_tick=sample.ctb_tick;b.ctb_round=sample.ctb_round;b.turn_count=sample.turn_count;b.freeze_finish=true
		return b
	return sample
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/round4-oracle.json"))
	var traits=Traits.new();var display=Display.new();var persona=PersonaCombatScript.new()
	for index in range(source.rows.size()):
		var row=source.rows[index];var c=row.input;var got="API unavailable"
		var selected=OS.get_environment("R23_ROUND4_OPS")
		if not selected.is_empty() and not row.op in selected.split(","):continue
		match row.op:
			"ps_level":got=Research.level({"strike":c.value},"strike")
			"ps_clean":got=Research.clean(c.raw)
			"ps_parts":
				var v=Research.clean(c.raw);var p=Research.part("prefixes",v.prefix);var s=Research.part("suffixes",v.suffix);got={"p":p if not p.is_empty() else false,"s":s if not s.is_empty() else false,"v":v}
			"ps_meta":
				var research=Research.new()
				# Before the fix, exercise existing APIs with their existing arguments.
				var methods=Research.new().get_method_list().filter(func(m):return m.name=="skill_name")
				var lang_supported=methods[0].args.size()>=3
				got={"name":research.call("skill_name",c.raw,c.force,c.lang) if lang_supported else Research.skill_name(c.raw,c.force),"desc":research.call("description",c.raw,c.force,c.lang) if lang_supported else Research.description(c.raw,c.force),"skill":research.call("skill",c.raw,c.lang) if lang_supported else Research.skill(c.raw)}
				if got.skill.is_empty():got.skill=false
			"ps_label":
				if persona.has_method("part_label"):got=persona.call("part_label",c.node,c.lang)
			"pnode":
				if traits.has_method("passive_node"):got=traits.call("passive_node",c.key);got=got if not got.is_empty() else false
			"ptx":
				if traits.has_method("passive_text"):got=traits.call("passive_text",c.value)
			"refresh":
				var b=party(c)
				if traits.has_method("refresh"):
					traits.call("refresh",b);var bx=[]
					for u in b.data.allies:bx.append(u.buff_extension)
					got={"sy":b.data.synergies,"bx":bx}
			"syn_full":
				var b=party(c)
				if traits.has_method("synergies"):got=traits.call("synergies",b,c.lang)
			"tick":
				var b=clean();var e=b.data.enemies[0];var keys=["attack_up","defense_up","attack_down","contract"]
				for j in range(4):
					if int(c.bits)&(1<<j):
						e.effects[keys[j]]={"amount":.1*(j+1),"turns":c.n,"doubled":true,"keep":"yes"}
						if not c.src is bool:e.effects[keys[j]].source="missing" if c.src==0 else (b.data.allies+b.data.enemies)[int(c.src)-1].id
						if int(c.bits)>=16:e.effects[keys[j]].fresh=true
				b.dungeon_enemy_r21.tick_buffs(e);got={}
				for j in range(4):
					if e.effects.has(keys[j]):
						var eff=e.effects[keys[j]];var x={"v":eff.amount,"n":eff.turns,"d":1,"keep":"yes"}
						if eff.has("source"):x.src=c.src
						if eff.has("fresh"):x.f=eff.fresh
						got[["atk","def","adn","red20"][j]]=x
				if c.bits==0:got=false
			"attack_split":
				var b=clean();var e=b.data.enemies[0];e.hp=c.hp;e.grade=c.grade;e.rules={"hp_atk":{"thr":.3,"amount":.2}};b.ctb_round=int(c.rd);b.data.encounter_r21.enc.raid=c.raid
				b._effect(e,"attack_up",2,.1);b._effect(e,"enemy_attack_self",2,c.am-1)
				if b.dungeon_enemy_r21.has_method("attack_bonus"):
					got=b.dungeon_enemy_r21.call("attack_bonus",e);got.combined=b.dungeon_enemy_r21.attack_mult(e)
			"f2":
				if display.has_method("fixed_two"):var s=display.call("fixed_two",c.value);got={"fx":s,"hud":s,"raid":s}
			"ratio":
				if display.has_method("ratio_text"):got=display.call("ratio_text",c.v,c.m)
			"tagcls":
				if display.has_method("tag_class"):got=display.call("tag_class",c.value)
			"kx":
				if display.has_method("scale_style"):got=display.call("scale_style",c.value)
			"record":
				var st=c.initial.duplicate(true)
				st.log=[]
				for j in range(int(c.logged)):Record.say(st,"log "+str(j+1),(j+1)/10.0)
				if c.active:Record.begin(st)
				for step in c.steps:Record.set_field(st,int(step.i),step.f,step.v,step.at)
				for payload in c.payloads:
					var e=payload.duplicate(true);e.erase("after");var r=Record.push(st,e);r.after="same"
				got=st
			"record_edge":
				var q={"false":false,"zero":0,"string":"","map":{"keep":7},"array":[1,3]}
				var values={"false":false,"number":5,"string":"","map":{"keep":7},"true":true}
				var ats={"false":false,"zero":0,"true":true}
				var st={"u":[{"hp":5,"keep":7}],"log":[],"ev":false}
				if c.qkind!="missing":st.q=q[c.qkind]
				var recorder=load("res://../verification/parity-r23/round4-before-record.gd").new() if OS.get_environment("R23_RECORD_BEFORE")=="1" else Record.new()
				recorder.set_field(st,1,"hp",7,0);recorder.say(st,values.get(c.kind),ats.get(c.atkind));recorder.begin(st);recorder.set_field(st,1,"hp",null,0)
				var nilret=recorder.push(st,null)==null
				for v in [false,true,5,{"keep":7}]:recorder.push(st,v)
				got={"state":st,"nilret":nilret}
			"trait_payload":
				var st={"u":[],"log":[],"q":[]};Record.begin(st);Record.trait_line(st,2,c.text,c.at,c.ab)
				var direct=st.ev.list.duplicate(true);st.ev.list=[];Record.trait_line(st,2,c.text,c.at)
				got={"direct":direct,"wrapper":st.ev.list}
			"miko_deal":
				var b=clean();var a=b.data.allies[1];var owner=b.data.allies[0];owner.trait.p.variant=c.variant
				b.extra_state[a.id]={"keep":7}
				if not c.boost is bool:b.x(a).mk=c.boost
				var opt={} if c.hasopt else null
				if opt!=null and not c.cached is bool:opt.mkv=c.cached
				var tags=["keep"]
				if Personal.new().has_method("miko_deal"):
					var v=Personal.new().call("miko_deal",b,owner,a,2,tags,opt)
					got={"value":v if v!=null else false,"x":b.x(a),"opt":opt if opt!=null else false,"tags":tags}
			"miko_round":
				var b=clean();var owner=b.data.allies[0];owner.trait.p.variant=c.variant;owner.trait.p.pull=.4
				for j in range(4):
					var u=b.data.allies[j];u.hp=1000 if int(c.bits)&(1<<j) else 0;u.name="unit"+str(j+1)
					u.remaining=10000 if c.mode==0 else (j+1)*500 if c.mode==1 else -2000 if c.mode==2 else 0;u.base.spd=(j+1)*100 if c.mode==3 else 100
				b.combat_events=b.CombatEvents.new();b.combat_events.begin_record(b)
				if Personal.new().has_method("miko_round"):
					Personal.new().call("miko_round",b,owner);var gs=[]
					for u in b.data.allies:gs.append(u.remaining)
					got={"g":gs,"events":b.combat_events.record.ev.list,"log":b.combat_events.record.log,"T":b.combat_events.T}
			"miko_attack":
				var b=clean()
				for j in range(4):rename(b,b.data.allies[j],"neutral"+str(j));b.extra_state[b.data.allies[j].id]={}
				var a=b.data.allies[0];rename(b,b.data.allies[1],"miko");b.data.allies[1].trait.p.variant=c.variant;b.x(a).mk=c.boost;b.x(b.data.enemies[0]).source_rng=12345;b.action_id="test"
				if c.volley:b._volley(a,1,0)
				else:b._damage(a,b.data.enemies[0],1,0)
				got={"hp":[b.data.enemies[0].hp,b.data.enemies[1].hp],"rs":b.x(b.data.enemies[0]).source_rng}
				if b.x(a).has("mk"):got.mk=b.x(a).mk
			"miko_run":
				var b=clean();var a=b.data.allies[0];rename(b,a,"miko");a.trait.p.variant=c.variant;a.trait.p.bonus=.6
				var t=b.data.allies[int(c.target)-1];t.hp=c.hp;t.remaining=c.g
				b._personal(a,b.data.enemies[0],t,{"name":"test"});got={"hp":t.hp,"g":t.remaining,"mk":b.x(t).get("mk",false)}
			"haldric","urda":
				var b=clean();var a=b.data.allies[0];var target=b.data.allies[1]
				for j in range(4):b.data.allies[j].name="unit"+str(j+1)
				b.combat_events=b.CombatEvents.new();b.combat_events.begin_record(b)
				if row.op=="haldric":
					b._begin_effect_action(a.id)
					for j in range(4):
						var u=b.data.allies[j];u.hp=1000 if int(c.bits)&(1<<j) else 0;u.row="전열" if j==0 or int(c.rows)&(1<<(j-1)) else "후열"
					Personal.haldric(b,a,{"name":"test"} if c.named else {});var buffs=[]
					for u in b.data.allies:
						var bf={}
						if u.effects.has("contract"):
							var eff=u.effects.contract;bf.red20={"v":eff.amount,"n":eff.turns,"src":idx(b,b.unit(eff.source))}
							if eff.get("fresh",false):bf.red20.f=true
						buffs.append(bf)
					got={"buffs":buffs}
				else:
					var keys=["attack_up","defense_up","contract","duty"]
					for j in range(4):
						if int(c.bits)&(1<<j):
							target.effects[keys[j]]={"amount":.4 if j<=1 else .6,"turns":3,"source":b.data.allies[3].id,"keep":"yes"}
							if int(c.bits)&(1<<(j+4)):target.effects[keys[j]].doubled=true
					Personal.urda(b,a,target,{"name":"test"});var buffs={}
					for j in range(4):
						if target.effects.has(keys[j]):
							var eff=target.effects[keys[j]];var bf={"v":eff.amount,"n":eff.turns,"src":4,"keep":"yes"}
							if eff.get("doubled",false):bf.d=1
							buffs[["atk","def","red20","red25"][j]]=bf
					got={"buffs":buffs}
				got.events=b.combat_events.record.ev.list;got.log=b.combat_events.record.log;got.T=b.combat_events.T
			"kill_full","double_full":
				var b=clean();var actor=int(c.actor) if not c.actor is bool else 0
				for j in range(4):
					var u=b.data.allies[j];u.name="unit"+str(j+1);u.race=("악마" if row.op=="kill_full" else "수인") if j<c.n else "";u.hp=(1000 if c.get("full",false) else 500) if int(c.bits)&(1<<j) else 0;u.mp=100 if c.get("full",false) else 99
				b.combat_events=b.CombatEvents.new();b.combat_events.begin_record(b)
				if row.op=="kill_full":
					b.gear_bridge.hooks.skill=true
					var a={} if actor<=0 or actor>6 else (b.data.allies+b.data.enemies)[actor-1]
					Traits.kill_credit(b,a,.4);var us=[]
					for j in range(4):us.append({"hp":b.data.allies[j].hp,"mp":b.data.allies[j].mp})
					got={"units":us,"h":b.combat_events.record.ev.h,"events":b.combat_events.record.ev.list,"T":b.combat_events.T,"skill_restored":b.gear_bridge.hooks.skill==true}
				else:
					b.data.synergies={"keep":7}
					for u in b.data.allies:u.buff_extension=99
					b.dungeon_enemy_r21=CountingRandom.new(b);b.dungeon_enemy_r21.forced=c.roll
					var a=(b.data.allies+b.data.enemies)[actor-1];b.x(a).double_turn=c.dbl
					Traits.turn_end(b,a);var bx=[]
					for u in b.data.allies:bx.append(u.get("buff_extension",0))
					got={"g":a.remaining,"dbl":1 if b.x(a).double_turn else 0,"sy":b.data.get("synergies",false),"bx":bx,"events":b.combat_events.record.ev.list,"log":b.combat_events.record.log,"T":b.combat_events.T,"calls":b.dungeon_enemy_r21.calls}
		check(same(got,row.expected),"round4/%s/%d"%[row.op,index],got,row.expected)
	var output=OS.get_environment("R23_ROUND4_OUTPUT")
	if output.is_empty():output="round4-latest.json"
	var f=FileAccess.open("res://../verification/parity-r23/"+output,FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 ROUND4 ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
const PersonaCombatScript=preload("res://game/persona_combat_r22.gd")
