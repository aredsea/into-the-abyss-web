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
