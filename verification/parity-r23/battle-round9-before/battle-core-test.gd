extends "res://tests/battle_r23_round8_test.gd"
func setup_nine(c):
	var b=setup_eight(c)
	for i in range(4):
		var w=b.data.allies[i];var s=c.state.u[i]
		if s.tau>0:b._effect(w,'taunt',int(s.tau))
		w.element=c.defs[i].get('el','none');w.base.agi=s.ag;w.passive={}
		w.skills.attack={"name":"일반 공격","power":1,"mp":0,"brk":0,"target":"적 1"}
		if s.has('gu'):w.gear_special=s.gu.duplicate(true)
		if c.defs[i].get('cid')=='bargut':w.trait.p.crit=30
		w.class_id=c.defs[i].get('clsid','warrior')
	b.current_id=b.data.allies[0].id;b.r21_action_actor=b.current_id
	return b
func project_nine(b,c,value=false):
	var got=observe_eight(b,c,value)
	for i in range(4):
		var w=b.data.allies[i];got.units[i].tau=w.effects.get('taunt',{}).get('turns',0)
		if got.units[i].x.has('personal_pull'):got.units[i].x.pull=got.units[i].x.personal_pull;got.units[i].x.erase('personal_pull')
		# Native aliases for source top-level tl/tla and zeroed gear caches.
		for key in ['last_target','last_attacker','scar','charge_damage']:got.units[i].x.erase(key)
		if w.effects.has('persona_regen'):
			var effect=w.effects.persona_regen;got.units[i].x.psrg={"d":effect.amount,"n":effect.turns,"s":effect.get('order',0)}
	return got
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round9-core-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;c.op=row.op
			var selected=OS.get_environment('R23_ROUND9_OPS')
			if not selected.is_empty() and not row.op in selected.split(','):continue
			var b=setup_nine(c);var a=b.data.allies[0];var e=b.data.enemies[0];var value=false
			match row.op:
				'bargut':b.action_id='personal';b.PersonalRules.run(b,a,e,b.data.allies[1],{"name":c.name,"brk":15})
				'persona':
					var action=b.PersonaCombat.action(c.raw);action.name=c.name;a.skills.personal=action
					if not c.get('lower_level_owner',false):b.combat_events.begin(b,'personal',a,e,b.data.allies[int(c.target)-1])
					b.action_id='personal';b.PersonaCombat.run(b,a,e,b.data.allies[int(c.target)-1],action)
				'extra_hit':
					var calls=[]
					if b.TraitRules.new().has_method('extra_hit'):
						b.TraitRules.extra_hit(b,(b.data.allies+b.data.enemies)[int(c.actor)-1],b.data.enemies[1],{"extra":c.extra,"el":"fire"},{"kill":c.killed},.5,func(actor,target,opt):calls.append({"i":idx(b,actor),"t":idx(b,target),"opt":opt}))
						value={"calls":calls}
					else:value='API unavailable'
				'enemy_attack':b.dungeon_enemy_r21.attack_action(e,c.action)
			var got=project_nine(b,c,value)
			check(same(got,row.expected),'round9/%s/%s/%d'%[row.op,part.file,i],got,row.expected)
	var suffix=OS.get_environment('R23_ROUND9_OUTPUT');if suffix.is_empty():suffix='latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-core-'+suffix+'.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND9 CORE ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)

func setup_seven(c: Dictionary):
	if seven_data.is_empty():seven_data=personal_fixture().data.duplicate(true)
	var b=load("res://../verification/parity-r23/battle-round9-before/replay/battle-fixture.gd").new(seven_data);b.freeze_finish=true;b.extra_state={};b.gear_bridge=null
	var s=c.state
	while b.data.enemies.size()<s.u.size()-4:
		var e=b.data.enemies[1].duplicate(true);e.id='reserve'+str(b.data.enemies.size());b.data.enemies.append(e)
	b.data.encounter_r21.enc={"fl":s.fl.duplicate(),"fg":s.fg.duplicate(),"ne":s.get('ne',2),"raid":s.get('raid',0)==1,"star":s.star,"dk":s.get('dk',0),"dc":s.get('dc',0),"zk":s.get('zk','')};b.data.encounter_r21.el=s.el
	for i in range(s.u.size()):
		var w=(b.data.allies+b.data.enemies)[i];var src=s.u[i];w.name=c.defs[i].name;w.hp=src.hp;w.mhp=src.mhp;w.remaining=src.g;w.effects={};w.shield=src.sh;w.empty=src.get('empty',0)==1;b.extra_state[w.id]={}
		if src.sh>0:w.effects.shield={"amount":0 if i<4 else src.sh,"turns":src.shT}
		if src.df==1:b._effect(w,'guard',2,.4)
		for key in src.bf:
			var eff=src.bf[key];w.effects[BF7.get(key,key)]={"amount":eff.v,"turns":eff.n}
		for j in range(src.get('edot',[]).size()):
			var d=src.edot[j];w.effects['enemy_dot_'+str(j)]={"amount":d.d,"turns":d.n,"by":b.data.enemies[int(d.by)-5].id}
		if i<4:
			rename(b,w,'neutral'+str(i));w.class_id='warrior';w.race='';w.nation='';w.line='str';w.trait={"p":{}};w.base.def=src.de;w.base.str=src.cs;w.base.agi=src.ag;w.base.crit=src.cr;w.base.spd=src.sp;w.mp=src.mp;w.gear_fx={};w.gear_special=[]
		else:
			w.foe_id=s.fl[i-4];w.grade=s.fg[i-4] if s.fg[i-4]!='' else 'mob';w.gauge=src.ay;w.max=src.ym;w.broken=src.dr==1;w.charged=src.get('cq',0)==1;w.phase=src.get('ph',0);w.act_index=int(src.ia)-1;w.target_id=b.data.allies[int(src.it)-1].id if src.it>0 and src.it<=4 else '';w.level=s.el;w.attack=src.cs;w.defense=src.de;w.speed=src.sp;w.rules=c.defs[i].get('rules',{})
			if src.get('rd',0)==1:w.grade='boss'
			elif src.get('add',0)==1:w.grade='minion'
			if w.foe_id!='':w.acts=b.dungeon_enemy_r21.rules.foes[w.foe_id].acts.duplicate(true)
			if src.am!=1:w.effects.enemy_attack_self={"amount":src.am-1,"turns":src.bt}
			b.x(w).protect='';b.x(w).hidden=false
	b.x(b.data.enemies[0]).source_rng=s.rs;b.combat_events.T=s.ev.T if s.get('ev') is Dictionary else .15;b.combat_events.record={"u":[],"log":s.log.duplicate(true),"q":s.q.duplicate()}
	b.combat_events.begin_record(b)
	if s.get('ev') is Dictionary:b.combat_events.record.ev=s.ev.duplicate(true)
	else:b.combat_events.record.erase('ev')
	if s.get('ev') is Dictionary:
		for i in range(s.ev.h.size()):
			if not s.ev.h[i].is_empty():b.combat_events.changed_slots[i+1]=true
	if c.has('miss'):b.forced_evade=c.miss
	return b
