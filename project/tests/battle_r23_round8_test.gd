extends "res://tests/battle_r23_round7_test.gd"
func setup_eight(c):
	var b=setup_seven(c)
	for i in range(c.state.u.size()):
		var w=(b.data.allies+b.data.enemies)[i];var s=c.state.u[i]
		b.extra_state[w.id]=s.x.duplicate(true) if s.x is Dictionary else {};w.remaining=s.g
		if i<4:b.x(w).saved=s.lf==1
		if s.shT>0 and not w.effects.has('shield'):w.effects.shield={"amount":0,"turns":s.shT}
		if i<4:
			if c.defs[i].cid!='neutral':rename(b,w,c.defs[i].cid)
			w.class_id=c.defs[i].clsid
		else:w.speed=s.sp
		for key in s.bf:
			var eff=w.effects[BF7.get(key,key)]
			if s.bf[key].has('src'):eff.source=(b.data.allies+b.data.enemies)[int(s.bf[key].src)-1].id
			if s.bf[key].get('f',false):eff.fresh=true
		b.x(w).cover_turns=s.oT;b.x(w).cover=b.data.allies[int(s.oath)-1].id if s.oath>0 else ''
		if s.am!=1:w.effects.enemy_attack_self={"amount":s.am-1,"turns":s.bt}
		if s.get('sil','')!='':w.effects.silence={"amount":0,"turns":99};b.x(w).silenced_id=s.sil
		if s.has('dot'):
			var effect={"stacks":[],"lifetimes":[],"owners":[],"bursts":[],"initial_turns":[],"orders":[]}
			for order in range(s.dot.size()):
				var d=s.dot[order]
				if d.get('bld')==1:w.effects.bleed={"amount":d.d,"turns":d.n,"by":b.data.allies[int(d.by)-1].id,"order":order}
				elif d.get('c')==1:w.effects.corrosion={"amount":d.d,"turns":d.n,"by":b.data.allies[int(d.by)-1].id,"order":order}
				elif d.get('k')==1:
					effect.stacks.append(d.d);effect.lifetimes.append(d.n);effect.owners.append(b.data.allies[int(d.by)-1].id);effect.bursts.append(0);effect.initial_turns.append(d.n);effect.orders.append(order)
			if not effect.stacks.is_empty():b._store_class_dot(w,effect)
			b.x(b.data.allies[0]).dot_order=s.dot.size()
		if i<4 and s.na=='morgas':w.nation='모르가스 신관국'
		if i>=4:
			if s.x is Dictionary and s.x.has('slow'):b.x(w).judith_sp0=s.x.slow.sp0;b.x(w).judith_until=s.x.slow.rd;b.x(w).erase('slow')
			if s.x is Dictionary and s.x.has('bn'):b.x(w).bleed_stacks=s.x.bn;b.x(w).erase('bn')
	for i in range(c.state.u.size()):
		var w=(b.data.allies+b.data.enemies)[i];var src=c.state.u[i]
		for key in src.bf:
			if src.bf[key].has('src'):w.effects[BF7.get(key,key)].source=(b.data.allies+b.data.enemies)[int(src.bf[key].src)-1].id
		if i>=4:w.target_id=b.data.allies[int(src.it)-1].id if src.it>0 and src.it<=4 else ''
		b.x(w).cover=b.data.allies[int(src.oath)-1].id if src.oath>0 else ''
	b.x(b.data.enemies[0]).source_rng=c.state.rs
	b.ctb_round=c.state.rd;b.turn_count=c.state.n
	return b
func observe_eight(b,c,value=false):
	var got=project_seven(b,c,value);got.erase('pre');got.erase('q0');got.nd=b.data.get('depletions',c.state.nd);got.kill=b.data.get('last_kill',c.state.kill)
	for i in range(c.state.u.size()):
		var w=(b.data.allies+b.data.enemies)[i];var src=c.state.u[i];var u=got.units[i]
		for key in ['edot','rd','ph','add','cq','empty']:u.erase(key)
		u.sp=w.base.spd if i<4 else w.speed
		u.lf=1 if b.x(w).get('saved',false) else 0
		u.x.erase('saved')
		u.edot=[]
		for j in range(4):
			if w.effects.has('enemy_dot_'+str(j)):
				var d=w.effects['enemy_dot_'+str(j)];u.edot.append({"d":d.amount,"n":d.turns,"by":idx(b,b.unit(d.by))})
		u.oath=idx(b,b.unit(b.x(w).get('cover','')));u.oT=b.x(w).get('cover_turns',0)
		if src.has('sil'):u.sil=b.x(w).get('silenced_id','') if w.effects.has('silence') else ''
		for key in src.bf:
			var e=w.effects.get(BF7.get(key,key),{})
			if not e.is_empty():
				if e.get('fresh',false):u.bf[key].f=true
				if e.has('source'):u.bf[key].src=idx(b,b.unit(e.source))
		if u.x.has('judith_sp0'):u.x.slow={"sp0":u.x.judith_sp0,"rd":u.x.judith_until}
		if u.x.has('bleed_stacks'):u.x.bn=u.x.bleed_stacks
		for key in ['judith_sp0','judith_until','bleed_stacks','dot_stacks','dot_owner','dot_order','silenced_id','cover_turns']:u.x.erase(key)
		if src.has('dot') or w.effects.has('dot') or w.effects.has('bleed') or w.effects.has('corrosion'):
			var dot=[];var eff=w.effects.get('dot',{})
			for j in range(eff.get('stacks',[]).size()):
				var d={"d":eff.stacks[j],"n":eff.lifetimes[j],"k":1};var by=idx(b,b.unit(eff.owners[j]))
				if by>0:d.by=by
				dot.append({"order":eff.orders[j],"d":d})
			if w.effects.has('bleed'):dot.append({"order":w.effects.bleed.order,"d":{"d":w.effects.bleed.amount,"n":w.effects.bleed.turns,"bld":1,"by":idx(b,b.unit(w.effects.bleed.by))}})
			if w.effects.has('corrosion'):dot.append({"order":w.effects.corrosion.order,"d":{"d":w.effects.corrosion.amount,"n":w.effects.corrosion.turns,"c":1,"by":idx(b,b.unit(w.effects.corrosion.by))}})
			dot.sort_custom(func(x,y):return x.order<y.order)
			u.dot=dot.map(func(x):return x.d)
	return got
func run():
	var manifest=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/battle-round8-oracle.json'))
	var can_battle=null
	for part in manifest.parts:
		var source=JSON.parse_string(FileAccess.get_file_as_string('res://../verification/parity-r23/'+part.file))
		for i in range(source.rows.size()):
			var row=source.rows[i];var c=row.input;c.op=row.op
			var selected=OS.get_environment('R23_ROUND8_OPS')
			if not selected.is_empty() and not row.op in selected.split(','):continue
			var b
			if row.op=='can_use':
				if can_battle==null:can_battle=setup_eight(c)
				b=can_battle;b.extra_state={};b.result=''
				for j in range(4):b.data.allies[j].hp=c.state.u[j].hp;b.data.allies[j].effects={};b.data.allies[j].empty=false
				b.data.allies[0].id=c.who
				if c.state.u[0].get('sil','')!='':b.data.allies[0].effects.silence={"amount":0,"turns":1};b.x(b.data.allies[0]).silenced_id=c.state.u[0].sil
			else:b=setup_eight(c)
			var a=b.data.allies[0];var e=b.data.enemies[0];var value=false
			match row.op:
				'abyss':
					if b.PersonalRules.new().has_method('abyss_result'):value=b.PersonalRules.abyss_result(b,a,e,c.brk,'fire',c.at)
				'end_turn':
					if b.has_method('end_turn_state'):b.end_turn_state((b.data.allies+b.data.enemies)[int(c.slot)-1],c.cost)
				'dot_push':b._push_class_dot(e,c.amount,c.turns,b.data.allies[int(c.by)-1].id if c.by else '')
				'judith':b.PersonalRules.run(b,a,e,b.data.allies[1],{"name":"test"});b.ctb_round=c.round;b._round_tick()
				'jorund':b.PersonalRules.hit_after(b,{"a":a,"e":e,"killed":c.killed==1,"power":1,"dealt":0,"before":e.hp,"critical":false,"hit_at":.125})
				'damaged_cleanup':
					if b.living(true).any(func(w):return w.id in ['hildegard','judith','haldric','felice','adeline']) and b.has_method('damaged_caster_cleanup'):b.damaged_caster_cleanup(b.data.allies[1])
				'enemy_attack':
					if b.dungeon_enemy_r21.has_method('attack_action'):b.dungeon_enemy_r21.attack_action(e,c.action)
				'can_use':
					b.current_id=a.id;a.class_id=c.cls;a.once=c.state.u[0].seal==1;a.hp=c.state.u[0].hp;a.mp=c.state.u[0].mp;b.action_id=''
					var id='missing'
					if c.skill is Dictionary:
						id=c.skill.id;a.skills[id]={"id":id,"name":"test","mp":c.skill.mp,"target":"자신","power":0,"brk":0}
					if c.state.u[0].x.has('inch'):b.x(a).inch=true
					value={"value":b.unavailable(id).is_empty()}
			var got=value if row.op=='can_use' else observe_eight(b,c,value)
			check(same(got,row.expected),'round8/%s/%s/%d'%[row.op,part.file,i],got,row.expected)
	var suffix=OS.get_environment('R23_ROUND8_OUTPUT');if suffix.is_empty():suffix='latest'
	var f=FileAccess.open('res://../verification/parity-r23/battle-round8-'+suffix+'.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows}));f.close()
	print('R23 ROUND8 ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
