extends "res://tests/battle_r23_round5_test.gd"
const StateFile="res://game/battle_source_state_r23.gd"
func observe_six(api,op: String,c: Dictionary):
	api.lang=c.get("lang","ko")
	match op:
		"unit0":return api.unit0()
		"member_def":return api.member_definition(c.member)
		"member_skills":return api.member_skills(c.definition)
		"sk_slot":return {"value":api.skill_slot(c.skills,int(c.index),c.id)}
		"foe_def":api.lang=c.lang;return api.foe_definition(c.state,int(c.slot))
		"bind":
			var state=c.state.duplicate(true);state.pend=c.original_pend;api.lang="ko"
			api.bind(state);return {"state":state,"defs":api.definitions.duplicate(true),"skills":api.skills.duplicate(true)}
		"bind_legacy":
			api.lang="ko";api.definitions=[]
			for i in range(16):api.definitions.append({"stale":true})
			api.bind_foes(c.state);return api.definitions.duplicate(true)
		"migrate":return api.migrate(c.state.duplicate(true))
		"carry":var state=c.state.duplicate(true);api.apply_carry(state,c.carry);return state
		"result_context":api.definitions=c.defs;api.lang=c.lang;return {"value":api.result_context(c.state)}
		"dmg_line":api.definitions=c.defs;api.lang=c.lang;return api.damage_line(1,c.result,c.options)
	return "Unknown operation"
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/battle-round6-oracle.json"))
	var api=load(StateFile).new() if FileAccess.file_exists(StateFile) else null
	for index in range(source.rows.size()):
		var row=source.rows[index];var got="API unavailable"
		var selected=OS.get_environment('R23_ROUND6_OPS')
		if not selected.is_empty() and not row.op in selected.split(','):continue
		if row.op=='marceline_full':
			got=observe_marceline(row.input)
		elif row.op=='felice_full':
			got=observe_felice(row.input)
		elif api!=null:got=observe_six(api,row.op,row.input)
		check(same(got,row.expected),"round6/%s/%d"%[row.op,index],got,row.expected)
	var suffix=OS.get_environment("R23_ROUND6_OUTPUT")
	if suffix.is_empty():suffix="battle-round6-latest"
	var f=FileAccess.open("res://../verification/parity-r23/"+suffix+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 ROUND6 ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
func observe_felice(c: Dictionary):
	var b=personal_fixture();var state=c.state;var a=b.data.allies[0];a.id='felice';b.ctb_tick=int(state.tk)
	for i in range(4):
		var w=b.data.allies[i];var src=state.u[i];w.mhp=src.mhp;w.hp=src.hp;w.remaining=src.g;w.base.spd=src.sp;w.shield=src.sh;w.charging=src.chg==1
		w.effects={}
		if src.sh>0:w.effects.shield={"amount":0,"turns":src.shT}
		if src.tau>0:b._effect(w,'taunt',int(src.tau))
		if src.df>0:b._effect(w,'guard',1)
		if src.mk>0:b._effect(w,'mark',2)
		if src.bf.has('atk'):b._effect(w,'attack_up',int(src.bf.atk.n),src.bf.atk.v)
		if src.bf.has('pscrit'):b._effect(w,'pscrit',int(src.bf.pscrit.n),src.bf.pscrit.v)
		b.extra_state[w.id]=src.x.duplicate(true) if src.x is Dictionary else false
		if src.x is Dictionary and src.x.has('dtk'):b.x(w).death_tick=src.x.dtk;b.x(w).erase('dtk')
		if src.x is Dictionary and src.x.has('rv'):b.x(w).revive=src.x.rv>0;b.x(w).erase('rv')
		if src.has('dot'):w.effects.dot={"amount":3,"turns":2,"stacks":[3],"lifetimes":[2],"owners":[''],"bursts":[0],"initial_turns":[2],"orders":[0]}
	b.combat_events.record.log=state.log.duplicate(true);b.combat_events.begin_record(b)
	b._felice_scan()
	var units=[]
	for i in range(4):
		var w=b.data.allies[i];var xx=b.x(w).duplicate(true)
		if xx.has('death_tick'):xx.dtk=xx.death_tick;xx.erase('death_tick')
		if xx.has('revive'):xx.rv=1 if xx.revive else 0;xx.erase('revive')
		if xx.has('reviving'):xx.erase('reviving')
		var bf={}
		if w.effects.has('attack_up'):bf.atk={"v":w.effects.attack_up.amount,"n":w.effects.attack_up.turns}
		if w.effects.has('pscrit'):bf.pscrit={"v":w.effects.pscrit.amount,"n":w.effects.pscrit.turns}
		units.append({"hp":w.hp,"al":1 if w.hp>0 else 0,"g":w.remaining,"sh":w.shield,"shT":w.effects.get('shield',{}).get('turns',0),"tau":w.effects.get('taunt',{}).get('turns',0),"df":1 if w.effects.has('guard') else 0,"mk":1 if w.effects.has('mark') else 0,"chg":1 if w.charging else 0,"bf":bf,"x":xx,"dot":state.u[i].get('dot',[]) if w.effects.has('dot') else []})
	return {"units":units,"events":b.combat_events.record.ev.list,"h":b.combat_events.record.ev.h,"log":b.combat_events.record.log,"T":b.combat_events.T}

func observe_marceline(c: Dictionary):
	var b=personal_fixture();var a=b.data.allies[0];a.id='marceline';a.mhp=c.state.u[0].mhp;a.hp=0;b.x(a).saved=c.state.u[0].lf>0
	b.combat_events.record.log=c.state.log.duplicate(true);b.combat_events.begin_record(b)
	if not b.PersonalRules.new().has_method('marceline_save'):return 'API unavailable'
	var result=b.PersonalRules.marceline_save(b,a,b.data.allies[int(c.target)-1],.125)
	return {"value":result,"hp":a.hp,"sh":a.shield,"shT":a.effects.get('shield',{}).get('turns',0),"lf":1 if b.x(a).get('saved',false) else 0,"events":b.combat_events.record.ev.list,"h":b.combat_events.record.ev.h,"log":b.combat_events.record.log,"T":b.combat_events.T}
