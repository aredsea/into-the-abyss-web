extends "res://tests/combat_a6_r22_test.gd"
func same(a,b) -> bool:
	if (a is Dictionary)!=(b is Dictionary) or (a is Array)!=(b is Array):return false
	if typeof(a)!=typeof(b) and not ((a is int or a is float) and (b is int or b is float)):return false
	return super.same(a,b)
func definitions() -> Array:
	var out=[]
	for i in range(1,7):out.append({"name":"unit"+str(i),"art":"art"+str(i),"clsid":"warrior","foe":"apprentice_doll"} if i>4 else {"name":"unit"+str(i),"art":"art"+str(i),"clsid":"warrior"})
	return out
class CountingRandom:
	extends "res://tests/battle_r23_random_fixture.gd"
	var calls=0
	func random() -> float:calls+=1;return forced
func personal_fixture():
	var b=fixture()
	for i in range(b.data.allies.size()):
		var w=b.data.allies[i];w.name='unit'+str(i+1);w.line='str';w.base.str=100;w.race='';w.nation='';w.trait={"p":{}}
	for i in range(b.data.enemies.size()):b.data.enemies[i].name='unit'+str(i+5)
	b.combat_events.T=.15;b.combat_events.record.log=[];b.combat_events.begin_record(b)
	return b
func observe(api,op: String,c: Dictionary):
	var hud=load("res://game/combat_hud_r23.gd").new();hud.lang=c.get("lang","ko");hud.definitions=definitions();hud.profile=c.get('image');hud.profile_available=c.get('vid',false)
	api.lang=c.get("lang","ko");api.definitions=definitions();api.profile=null;api.profile_available=false
	var L=api.layers(c.get("cuts",true))
	match op:
		"sv":return api.style(c.t,c.x if not c.x is bool else null)
		"fx_dn":return api.number(c.txt,c.t,c.cls,c.left,c.top)
		"fx_cn":return api.critical(c.txt,c.t)
		"fx_plaque":return api.plaque(c.txt,c.t,c.cls)
		"fx_put":api.put(L,int(c.slot),'first');api.put(L,int(c.slot),'');api.put(L,int(c.slot),'<b>next</b>');return L
		"bz_add":api.camera_add(L,'z6',.125,c.k if not c.k is bool else null,c.rank);return L
		"fx_hit":
			var hs=api.hit(L,int(c.slot),.5,c.o)
			if c.repeat_hit:api.hit(L,int(c.slot),.8,{"tier":2,"k":3})
			return {"L":L,"hs":hs}
		"fx_abyss":api.abyss(L,c.r,.125);return L
		"fx_result":api.result(L,c.r,.5,c.o);return L
		"fx_cutin":api.cutin(L,2,'스킬',c.line,.125);return L
		"fx_pcutin":api.profile=c.image;api.profile_available=c.vid;api.persona_cutin(L,1,'스킬',.125);return L
		"fx_event":api.event(c.state,c.e,L);return L
		"fx_sequence":return api.render_events(c.state,c.events)
		"numspan":return hud.numspan(c.v,c.k)
		"chip":return hud.chip(c.c,c.txt)
		"chip_tn":return hud.chip_turns(c.v)
		"chip_dotn":return hud.dot_turns(c.v)
		"icn":return hud.icon(c.ic)
		"sn":
			while hud.definitions.size()<int(c.i):hud.definitions.append(null)
			if c.mode=='missing':hud.definitions[int(c.i)-1]=null
			elif c.mode=='legacy' and c.i>4:hud.definitions[int(c.i)-1]={"name":"legacy"}
			elif c.mode=='foe':hud.definitions[int(c.i)-1]={"foe":"x","name":"적 이름"}
			return hud.short_name(int(c.i))
		"hp_stat":
			var unit={"hp":100,"mhp":100,"mp":100,"mmp":100,"ay":100,"ym":100,"sh":100};unit[c.f]=c.v;var K=[{}];var flags=int(c.flags)
			if flags&1:K[0][c.f]='k3u1'+c.f
			return hud.hp_stat('label','ab' if c.f=='ay' else c.f,unit,c.f,100,K,1,bool(flags&2),bool(flags&4),50 if flags>=8 else null)
		"dyn":return hud.dyn(c.state,c.D)
		"printf":
			var formatter=load('res://../verification/parity-r23/round5-before-display.gd').new() if OS.get_environment('R23_FORMAT_BEFORE')=='1' else api.Text.new()
			return {"one":formatter.fixed_decimal(c.v,1),"two":formatter.fixed_decimal(c.v,2)}
		"kchip":return hud.kind_chip(c.act)
		"log":return hud.log_html(c.state)
		"pbadges":return hud.passive_badges(c.state.u[0],c.cls)
		"pips":return hud.phase_pips(c.foe,int(c.ph))
		"chips":return hud.chips(c.state,int(c.slot))
		"intent":return hud.intent(c.state,5,c.act,{"taunt":.125})
		"camera_compare":return hud.camera_before(c.p,c.q)
		"bzo":return hud.camera_wrapper('bpi',c.x)
		"tile":hud.definitions=c.defs;return hud.tile(c.state,int(c.idx),int(c.pos),c.mark,c.lost)
		"rail":hud.definitions=c.defs;return hud.rail(c.state)
		"head":hud.definitions=c.defs;return hud.head(c.state)
		"frame":return fixture().combat_display_frame(c.state,c.defs,c.lang)
		"fx_optional":
			var o={"tier":false,"el":false,"arc":0,"r":false,"k":false,"crit":false,"abfx":false}
			if c.kind=='hit':return {"L":L,"hs":api.hit(L,5,.5,o)}
			if c.kind=='result':api.result(L,{"i":5,"d":1,"sh":0,"c":0,"tags":false,"ab":false,"list":false},.5,o)
			if c.kind=='event':api.event({}, {"k":"atk","a":1,"t":.125,"ht":false,"nm":"일반 공격","tg":[{"i":5,"d":1,"sh":0,"c":0}]}, L)
			return L
		"miko_full":
			var b=personal_fixture();var a=b.data.allies[0];var target=b.data.allies[int(c.target)-1];a.id='miko';a.trait.p.variant=c.variant;a.trait.p.bonus=.6
			target.hp=int(c.hp);target.remaining=c.g;b.combat_events.begin_record(b)
			b.PersonalRules.run(b,a,b.data.enemies[0],target,{"name":"test (memo)"})
			return {"hp":target.hp,"g":target.remaining,"mk":b.x(target).get('mk',false),"events":b.combat_events.record.ev.list,"h":b.combat_events.record.ev.h,"log":b.combat_events.record.log,"T":b.combat_events.T}
		"urda_round_full":
			var b=personal_fixture();var a=b.data.allies[0]
			for i in range(4):
				var w=b.data.allies[i];w.hp=int(c.hp) if int(c.bits)&(1<<i) else 0
				if int(c.mode)&1:b._effect(w,'attack_down',2,.2)
				if int(c.mode)>=2:b._effect(w,'defense_down',3,.3)
			b.combat_events.begin_record(b)
			if not b.PersonalRules.new().has_method('urda_round'):return 'API unavailable'
			b.PersonalRules.urda_round(b,a);var units=[]
			for i in range(4):
				var w=b.data.allies[i];var bf={}
				for pair in [['attack_down','adn'],['defense_down','ddn']]:
					if w.effects.has(pair[0]):bf[pair[1]]={"v":w.effects[pair[0]].amount,"n":w.effects[pair[0]].turns}
				units.append({"hp":w.hp,"bf":bf})
			return {"units":units,"events":b.combat_events.record.ev.list,"h":b.combat_events.record.ev.h,"log":b.combat_events.record.log,"T":b.combat_events.T}
		"hildegard_full":
			var b=personal_fixture();var a=b.data.allies[0];a.id='hildegard'
			if c.kind=='missing' and not b.PersonalRules.new().has_method('hildegard_scan'):return 'API unavailable'
			if c.taunt:b._effect(a,'taunt',1)
			for e in b.data.enemies:
				e.act_index=0;e.target_id=b.data.allies[int(c.target)-1].id;e.acts=[] if c.kind=='missing' else [{"kind":c.kind}];e.redirected=true;b.extra_state[e.id]={"keep":7,"hg_index":0 if c.cached else -1} if c.xmap else false
			b.dungeon_enemy_r21=CountingRandom.new(b);b.dungeon_enemy_r21.forced=c.roll
			b._hg_scan();var es=[]
			for e in b.data.enemies:
				var x={"hgk":b.x(e).hg_index+1,"hg":1 if e.redirected else 0}
				if c.xmap:x.keep=7
				es.append({"it":b.data.allies.find(b.ally(e.target_id))+1,"x":x})
			return {"enemies":es,"events":b.combat_events.record.ev.list,"log":b.combat_events.record.log,"T":b.combat_events.T,"calls":b.dungeon_enemy_r21.calls}
	return 'Unknown operation'
func run():
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/round5-oracle.json"))
	var file="res://game/combat_fx_r23.gd"
	var api=load(file).new() if FileAccess.file_exists(file) else null
	for index in range(source.rows.size()):
		var row=source.rows[index];var got="API unavailable"
		var selected=OS.get_environment('R23_ROUND5_OPS')
		if not selected.is_empty() and not row.op in selected.split(','):continue
		if api!=null:got=observe(api,row.op,row.input)
		check(same(got,row.expected),"round5/%s/%d"%[row.op,index],got,row.expected)
	var suffix=OS.get_environment("R23_ROUND5_OUTPUT")
	if suffix.is_empty():suffix="round5-latest"
	var f=FileAccess.open("res://../verification/parity-r23/"+suffix+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"rows":rows},"\t"));f.close()
	print("R23 ROUND5 ",checks," checks / failures ",failures.size());quit(0 if failures.is_empty() else 1)
