extends "res://tests/battle_r23_round7_test.gd"
const BeforeFixture=preload('res://../verification/parity-r23/battle-round7-before-fixture.gd')
func setup_seven(c: Dictionary):
	if seven_data.is_empty():seven_data=personal_fixture().data.duplicate(true)
	var b=BeforeFixture.new(seven_data);b.freeze_finish=true;b.extra_state={};b.gear_bridge=null
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

func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round7-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for index in range(source.rows.size()):
			var row=source.rows[index]
			if not row.op in ['counter','foe_hit_after','summon','phase']:continue
			var c=row.input;c.op=row.op;var b=setup_seven(c)
			b.dungeon_enemy_r21=load('res://../verification/parity-r23/battle-round7-before-dungeon_enemy_r21.gd').new(b)
			var e=b.data.enemies[0];var a=b.data.allies[0];var value=false
			match row.op:
				'counter':b._enemy_hit(e,a,{"kind":"atk","name":"test","m":c.counter.get('m',.6),"counter":true})
				'foe_hit_after':b.dungeon_enemy_r21.after_hit(a,e,c.element)
				'summon':b.dungeon_enemy_r21.summon(e,c.action)
				'phase':value=b.dungeon_enemy_r21.phase_check()
			var got=project_seven(b,c,value)
			check(same(got,row.expected),'round7/before/%s/%d'%[row.op,index],got,row.expected)
	var f=FileAccess.open('res://../verification/parity-r23/battle-round7-before-replay.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND7 BEFORE ',checks,' checks / differences ',failures.size());quit(0)
