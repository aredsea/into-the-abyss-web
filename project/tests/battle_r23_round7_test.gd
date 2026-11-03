extends "res://tests/battle_r23_round6_test.gd"
const SevenFixture=preload('res://tests/battle_r23_round7_fixture.gd')
const BF7={"atk":"attack_up","def":"defense_up","adn":"attack_down","ddn":"defense_down","spd":"haste","sdn":"slow","red20":"contract","red":"adeline_guard","psguard":"psguard","pscrit":"pscrit"}
var seven_data={}
func idx(b,u) -> int:return (b.data.allies+b.data.enemies).find(u)+1 if not u.is_empty() else 0
func rename(b,u,id: String) -> void:b.extra_state[id]=b.x(u);u.id=id
func setup_seven(c: Dictionary):
	if seven_data.is_empty():seven_data=personal_fixture().data.duplicate(true)
	var b=SevenFixture.new(seven_data);b.freeze_finish=true;b.extra_state={};b.gear_bridge=null
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
func project_seven(b,c: Dictionary,value: Variant=false):
	var us=[]
	for i in range(c.state.u.size()):
		var w=(b.data.allies+b.data.enemies)[i];var src=c.state.u[i];var x=b.x(w).duplicate(true)
		for key in ['source_rng','protect','hidden','counter_busy','cycle_a','cycle_b','cover']:x.erase(key)
		var bf={}
		for key in BF7:
			if w.effects.has(BF7[key]):var eff=w.effects[BF7[key]];bf[key]={"v":eff.amount,"n":eff.turns}
		var edot=[]
		for j in range(4):
			if w.effects.has('enemy_dot_'+str(j)):
				var dot=w.effects['enemy_dot_'+str(j)];edot.append({"d":dot.amount,"n":dot.turns,"by":idx(b,b.unit(dot.by))})
		var unit={"hp":w.hp,"mhp":w.mhp,"mp":w.get('mp',0),"sh":w.shield if i<4 else b.fx(w,'shield'),"shT":w.effects.get('shield',{}).get('turns',0),"g":w.remaining,"al":1 if w.hp>0 else 0,"df":1 if w.effects.has('guard') else 0,"am":1+b.fx(w,'enemy_attack_self'),"bt":w.effects.get('enemy_attack_self',{}).get('turns',0),"ay":w.get('gauge',0) if i>=4 else 0,"ym":w.get('max',0) if i>=4 else 0,"dr":1 if w.get('broken',false) else 0,"ia":int(w.act_index)+1 if i>=4 else 1,"it":idx(b,b.unit(w.target_id)) if i>=4 else 0,"tau":0,"oath":0,"oT":0,"mk":0,"chg":0,"bf":bf,"x":x}
		if src.has('edot') and not (c.op=='summon' and not w.empty and src.get('empty')==1):unit.edot=edot
		if i>=4:
			for key in ['cq','ph','rd','add','empty']:
				if src.has(key):unit[key]=src[key]
			if src.has('cq') or w.charged:unit.cq=1 if w.charged else 0
			if src.has('ph'):unit.ph=w.phase
			if w.foe_id=='':unit.empty=1
			elif src.get('empty')==1 or (c.op=='summon' and src.get('add')==1 and src.al==0 and w.hp>0):
				unit.erase('empty');unit.erase('cq');unit.erase('edot');unit.ph=1 if b.dungeon_enemy_r21.rules.foes[w.foe_id].has('phase2') else 0;unit.rd=1 if w.grade=='boss' else 0;unit.add=1
			if b.x(w).has('cycle_a'):unit.cwk=w.weak.duplicate()
			if b.x(w).has('cycle_a'):unit.x.cycle_a=b.x(w).cycle_a # removed below; native weakness is projected separately
			unit.x.erase('cycle_a')
		us.append(unit)
	var rec=b.combat_events.record;var ev=rec.get('ev')
	return {"units":us,"events":ev.list if ev is Dictionary else false,"h":ev.h if ev is Dictionary else false,"pre":ev.pre if ev is Dictionary else false,"q0":ev.q0 if ev is Dictionary else false,"log":rec.log,"T":b.combat_events.T if ev is Dictionary else false,"rng":b.x(b.data.enemies[0]).source_rng,"value":value if value!=null else false}
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round7-oracle.json'))
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for index in range(source.rows.size()):
			var row=source.rows[index];var c=row.input;c.op=row.op;var selected=OS.get_environment('R23_ROUND7_OPS')
			if not selected.is_empty() and not row.op in selected.split(','):continue
			var b=setup_seven(c);var e=b.data.enemies[0];var a=b.data.allies[0];var got='API unavailable';var value=false
			match row.op:
				'foe_line':value=b.dungeon_enemy_r21.foe_line(e,c.action,c.result,c.lang);got=project_seven(b,c,value)
				'counter':
					b.dungeon_enemy_r21.counter(e,a,c.counter,c.at);got=project_seven(b,c)
				'foe_hit_after':b.dungeon_enemy_r21.after_hit(a,e,c.element,c.at);got=project_seven(b,c)
				'edot_tick':
					if b.dungeon_enemy_r21.has_method('tick_dot'):value=b.dungeon_enemy_r21.tick_dot(a);got=project_seven(b,c,value)
				'e_dot':
					if b.dungeon_enemy_r21.has_method('dot_action'):b.dungeon_enemy_r21.dot_action(e,c.action);got=project_seven(b,c)
				'dispatch':
					if b.dungeon_enemy_r21.has_method('dispatch'):b.dungeon_enemy_r21.dispatch(e,c.action);got=project_seven(b,c)
				'charge_cancel':
					if b.dungeon_enemy_r21.has_method('cancel_charge'):b.dungeon_enemy_r21.cancel_charge(e);got=project_seven(b,c)
				'summon':b.dungeon_enemy_r21.summon(e,c.action);got=project_seven(b,c)
				'phase':value=b.dungeon_enemy_r21.phase_check();got=project_seven(b,c,value)
				'cutin':
					if b.combat_events.has_method('cutin'):b.combat_events.cutin(1,c.id,c.name);got=project_seven(b,c)
			check(same(got,row.expected),'round7/%s/%d'%[row.op,index],got,row.expected)
	var suffix=OS.get_environment('R23_ROUND7_OUTPUT');if suffix.is_empty():suffix='latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round7-'+suffix+'.json',FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND7 ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
