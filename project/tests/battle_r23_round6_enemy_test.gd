extends "res://tests/battle_r23_round6_test.gd"
func observe_enemy(c: Dictionary,op: String):
	var b=personal_fixture();var s=c.state
	if OS.get_environment('R23_ROUND6_ENEMY_BEFORE')=='1':b.dungeon_enemy_r21=load('res://../verification/parity-r23/battle-round6-before-enemy.gd').new(b)
	for i in range(6):
		var w=(b.data.allies+b.data.enemies)[i];var src=s.u[i]
		w.hp=src.hp if src.al==1 else 0;w.mhp=src.mhp;w.remaining=src.g;w.effects={};b.extra_state[w.id]={}
		if i<4:
			w.class_id='missing';w.skills={"attack":{"name":"attack"},"defend":{"name":"defend"}}
			if src.tau>0:b._effect(w,'taunt',int(src.tau))
		else:
			w.row='후열' if i==5 else '전열';w.charged=src.get('cq',0)==1;w.target_id=b.data.allies[0].id;w.rules=c.get('rules',{})
			b.x(w).foe_turns=src.get('tn',0)
	b.combat_events.record.log=s.log.duplicate(true);b.combat_events.begin_record(b)
	if c.has('forced_roll'):
		b.dungeon_enemy_r21=CountingRandom.new(b);b.dungeon_enemy_r21.forced=c.forced_roll
	var enemy=b.data.enemies[0];b.x(enemy).source_rng=s.rs
	if c.has('skill_lists'):
		for i in range(4):
			var w=b.data.allies[i];w.class_id=c.class_id;w.skills={}
			for sk in c.skill_lists[i]:
				var id=source_alias(c.class_id,sk)
				w.skills[id]={"name":sk.name}

	if OS.get_environment('R23_ROUND6_ENEMY_BEFORE')=='1' and c.action.kind=='buff' and c.action.stat in ['shield','pull'] and not c.action.has('amount'):return 'missing amount would raise'
	if op=='turn_end':b.dungeon_enemy_r21.turn_end(enemy,c.action)
	else:b.dungeon_enemy_r21.support_action(enemy,c.action)
	var units=[]
	for i in range(6):
		var w=(b.data.allies+b.data.enemies)[i];var bf={}
		for pair in [['attack_up','atk'],['defense_up','def'],['haste','spd'],['attack_down','adn'],['defense_down','ddn'],['slow','sdn']]:
			if w.effects.has(pair[0]):
				var eff=w.effects[pair[0]];bf[pair[1]]={"v":eff.amount,"n":eff.turns}
				if eff.has('source'):bf[pair[1]].src=b.combat_events.slot(b,b.unit(eff.source));bf[pair[1]].au=1
		var target=b.x(w).get('protect','');var x={};var sil=b.x(w).get('silenced_id','')
		if c.has('skill_lists'):
			for sk in c.skill_lists[i] if i<4 else []:
				if source_alias(c.class_id,sk)==sil:sil=sk.id;break
		units.append({"hp":w.hp,"df":1 if w.effects.has("guard") else 0,"sh":b.fx(w,'shield'),"shT":w.effects.get('shield',{}).get('turns',0),"g":w.remaining,"am":1+b.fx(w,'enemy_attack_self'),"bt":w.effects.get('enemy_attack_self',{}).get('turns',0),"bf":bf,"pt":b.combat_events.slot(b,b.unit(target)) if target!='' else false,"cq":1 if w.get('charged',false) else 0,"sil":sil,"hid":1 if b.x(w).get('hidden',false) else 0,"x":x})
	return {"units":units,"events":b.combat_events.record.ev.list,"h":b.combat_events.record.ev.h,"log":b.combat_events.record.log,"T":b.combat_events.T,"rng":b.x(enemy).get('source_rng',s.rs)}
func source_alias(cls: String,sk: Dictionary) -> String:
	if sk.get('pv',false):return 'personal'
	return {"atk":"attack","df":"defend","guard2":"guard","shield":"pshield","taunt":"ptaunt" if cls=='paladin' else 'taunt',"pshield":"hshield","defdn":"acid","wave":"chaoswave"}.get(sk.id,sk.id)
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round6-enemy-oracle.json'))
	for index in range(source.rows.size()):
		var row=source.rows[index];var got=observe_enemy(row.input,row.op)
		check(same(got,row.expected),'round6/%s/%d'%[row.op,index],got,row.expected)
	var suffix='before' if OS.get_environment('R23_ROUND6_ENEMY_BEFORE')=='1' else 'latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round6-enemy-'+suffix+'.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},'\t'));f.close()
	print('R23 ROUND6 ENEMY ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
