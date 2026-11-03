extends RefCounted
## 30-engine / 32-personal-a/b canonical personal-skill eligibility.
const DOUBLE_KEYS=["attack_up","defense_up","contract","duty"]
const Definitions=preload('res://game/battle_source_data_r23.gd')
static func sorel_damage_aid(b,owner: Dictionary,target: Dictionary,at: Variant=null) -> void:
	if b.x(owner).get('rescue',0)>=2 or target.hp<=0 or target.hp>target.mhp*.25:return
	var clock=b.combat_events;clock.ensure_record(b);var T=clock.T if at==null or (at is bool and not at) else float(at)
	var h=heal_record(b,target,owner.base[owner.line]*2,T+.3)
	b.x(owner).rescue=b.x(owner).get('rescue',0)+1
	var count=str(int(b.x(owner).rescue));var name=target.name
	clock.trait_payload(clock.slot(b,owner),'골든타임: '+name+' +'+str(h)+' ('+count+'/2)',T)
	clock.push('trait',clock.slot(b,owner),T)
	clock.say('<b>'+owner.name+'</b>의 <b>골든타임</b>. HP가 바닥난 '+name+b.CombatDisplay.Josa.tail(name,'을를')+' 즉시 치료해 <em>'+str(h)+'</em> 회복 ('+count+'/2)',T+.4)
	clock.T=maxf(clock.T,T+.7);clock.record.ev.T=clock.T
static func damaged_dispatch(b,target: Dictionary,_damage: float,_source: Variant=null,at: Variant=null) -> void:
	for owner in b.data.allies:
		var character=owner.get('character_id',owner.id)
		if owner.hp<=0 or (not Definitions.CAST.has(character) and character!='persona'):continue
		if character=='sorel':sorel_damage_aid(b,owner,target,at)
		b.damaged_caster_cleanup(target)
static func has_magic(e: Dictionary) -> bool:
	if e.get("magic",false):return true
	for act in e.get("acts",[]):
		if act.get("magic",false) or act.get("ic","")=="spell":return true
	return false
static func casting(e: Dictionary) -> bool:
	var acts=e.get("acts",[]);var index=int(e.get("act_index",0))
	if index<0 or index>=acts.size():return false
	return acts[index].get("ic","") in ["spell","weaken","summon"] or acts[index].get("kind","") in ["spell","weaken","summon"]
static func felice_scan(b,owner: Dictionary) -> void:
	if not b.combat_events.record.has("ev"):b.combat_events.begin_record(b)
	if b.x(owner).get('revive',false):return
	var pick={};var earliest=INF
	for member in b.data.allies:
		if member.id==owner.id or member.hp>0 or member.get('empty',false):continue
		if not b.x(member).has('death_tick'):b.x(member).death_tick=b.ctb_tick
		var ready=b.x(member).death_tick+ceil(maxf(0,member.remaining)/member.base.spd)
		if b.ctb_tick>=ready and ready<earliest:pick=member;earliest=ready
	if pick.is_empty():return
	var T=b.combat_events.T
	# Source clears bf/tau/df/mk/chg only. Shield, DOT and x-owned effects
	# survive revival along with their existing lifetimes and provenance.
	for key in pick.effects.keys():
		if key in ['taunt','guard','mark','attack_up','defense_up','haste','attack_down','defense_down','zdn','slow','backstep','blood','fortified_guard','adeline_guard','contract','duty','psguard','bless','next_power','magic_amp','pscrit']:
			pick.effects.erase(key)
	pick.hp=maxi(1,int(floor(pick.mhp*.25+1e-9)));pick.charging=false;pick.remaining=0.0
	b.x(pick).erase('death_tick');b.x(owner).revive=true
	b.combat_events.field(b,pick,'hp',pick.hp,T+.4)
	var name=b.CombatDisplay.unit_name(pick);var who=b.CombatDisplay.unit_name(owner)
	b.combat_events.trait_payload(b.combat_events.slot(b,owner),'패자 부활전: '+name+' HP 25%로 일어났다',T)
	b.combat_events.say('<b>'+who+'</b>의 <b>패자 부활전</b>. 쓰러졌던 <b>'+name+'</b>'+b.CombatDisplay.Josa.tail(name,'이가')+' HP <em>'+str(pick.hp)+'</em> 상태로 일어났다',T+.5)
	b.combat_events.push('trait',b.combat_events.slot(b,owner),T)
	b.combat_events.T=T+.8
	b._event(pick.name+' · 펠리체 소생')
static func marceline_save(b,owner: Dictionary,target: Dictionary,at: float) -> bool:
	if not b.combat_events.record.has("ev"):b.combat_events.begin_record(b)
	if target.id!=owner.id or b.x(owner).get('saved',false):return false
	b.x(owner).saved=true
	var h=mini(owner.mhp,1+int(floor(owner.mhp*.25+1e-9)))
	owner.hp=1;b.combat_events.field(b,owner,'hp',1,at)
	owner.hp=h;b.combat_events.field(b,owner,'hp',h,at+.4)
	# This personal save writes a fixed shield, independent of shield multipliers.
	owner.shield=int(floor(owner.mhp*.15+1e-9));owner.effects.shield={"amount":0,"turns":3}
	b.combat_events.field(b,owner,'sh',owner.shield,at+.4)
	b.combat_events.trait_payload(b.combat_events.slot(b,owner),'9회말 2아웃: HP 1로 버티고 회복, 보호막',at)
	b.combat_events.say('<b>'+b.CombatDisplay.unit_name(owner)+'</b>의 <b>9회말 2아웃</b>. HP 1로 버티고 <em>'+str(h-1)+'</em> 회복, 보호막 '+str(owner.shield),at+.5)
	b.combat_events.push('trait',b.combat_events.slot(b,owner),at)
	return true
static func isweak(e: Dictionary,element: Variant) -> bool:
	return element is String and element in e.get("weak",[])
static func best_double(u: Dictionary) -> String:
	var key=""; var amount=-INF
	for k in DOUBLE_KEYS:
		var effect=u.effects.get(k,{})
		if not effect.is_empty() and not effect.get("doubled",false) and effect.amount>amount:
			key=k; amount=effect.amount
	return key
static func can(b,a: Dictionary) -> bool:
	match a.id:
		"urda":
			for u in b.living(true):
				if u.id!=a.id and not best_double(u).is_empty(): return true
			return false
		"tika": return not b.x(a).get("inch",false) and a.hp>floor(a.mhp*.1)
		"levia": return a.hp>floor(a.mhp*.1)
		"teiris": return not a.once
		"colette":
			for e in b.living(false):
				if b.x(e).get("seal_until",0)>b.ctb_tick: continue
				if has_magic(e):return true
			return false
	return true

static func abyss(b,a,e,amount: float,element: String="") -> void:
	if b.dungeon_enemy_r21==null:legacy_abyss(b,a,e,amount,element);return
	abyss_result(b,a,e,amount,element,b.combat_events.abyss_time()-.2)

static func legacy_abyss(b,a,e,amount: float,element: String="") -> void:
	var value=amount*(1.5 if isweak(e,a.element if element.is_empty() else element) else 1)
	if a.id=="levia": value*=levia_mult(b)
	if b.gear_bridge!=null:
		var modified=b.gear_bridge.invoke("abyss_mul",[b.gear_bridge.slot(a),b.gear_bridge.slot(e),value]); value=modified if modified!=null else value
	value=floor(value+.5)
	var eligible=e.hp>0 and not e.broken
	b._break(e,value)
	if eligible and b.gear_bridge!=null: b.gear_bridge.invoke("abyss_after",[b.gear_bridge.slot(a),b.gear_bridge.slot(e),value,b.combat_events.T,[]])
	if eligible and a.id=="levia":
		for other in b.living(false):
			if other.id!=e.id: b._break(other,floor(value*.07+.5))

static func abyss_result(b,a,e,amount: float,element: String="",at: float=0) -> Dictionary:
	if amount<=0 or e.hp<=0 or e.broken:return {"n":0,"list":false}
	var value=amount*(1.5 if isweak(e,a.element if element.is_empty() else element) else 1)
	if a.id=="levia": value*=levia_mult(b)
	if b.gear_bridge!=null:
		var modified=b.gear_bridge.invoke("abyss_mul",[b.gear_bridge.slot(a),b.gear_bridge.slot(e),value]); value=modified if modified!=null else value
	value=maxf(1,floor(value+.5))
	var list=[]
	b._break_at(e,value,at)
	if a.id=="levia" and a.hp>0:
		var c=floor(value*.07+.5)
		for other in b.living(false):
			if other.id!=e.id and not other.broken and c>=1:
				b._break_at(other,c,at+.5);list.append({"i":b.combat_events.slot(b,other),"n":c})
		if not list.is_empty():b.combat_events.trait_payload(b.combat_events.slot(b,a),'깨진 유리창 이론: 다른 적 심연 −'+str(int(c)),at+.4,1)
	if b.gear_bridge!=null:b.gear_bridge.invoke('abyss_after',[b.gear_bridge.slot(a),b.gear_bridge.slot(e),value,at,list])
	return {"n":value,"list":list}

static func judith(b,a,e,sk: Dictionary) -> void:
	var clock=b.combat_events;var T=clock.T
	b._effect(e,'defense_down',3,.2);b._effect(e,'haste',3,.15);b._effect(e,'attack_down',3,.15)
	if not b.x(e).has('judith_sp0'):b.x(e).judith_sp0=e.speed;e.speed=floor(e.speed*.85+.5)
	b.x(e).judith_until=b.ctb_round+3
	var result=abyss_result(b,a,e,3,a.element,T+.8);var c=corrode(b,a,e,1)[0]
	var target={"i":clock.slot(b,e),"ab":result.n}
	if result.list is Array:target.list=result.list
	var skill_name=sk.get('name',a.get('skills',{}).get('personal',{}).get('name',''))
	clock.Record.push(clock.record,{"k":"mark","a":clock.slot(b,a),"t":T,"tg":[target],"nm":skill_name})
	var text=preload('res://game/combat_source_text_r23.gd')
	clock.say(text.u('<b>{who}</b>{particle} {skill:을를} 펼쳤다. {target} 방어 <em>−{def}%</em>, 속도 <em>−{speed}%</em>, 공격 <em>−{attack}%</em> ({turns}턴), 부식 {stacks}중첩{abyss}',{"who":a.name,"particle":b.CombatDisplay.Josa.tail(a.name,'이가'),"skill":skill_name,"target":e.name,"def":b.CombatDisplay.percent(.2*(.5 if e.grade=='boss' else 1)),"speed":15,"attack":b.CombatDisplay.percent(.15*(.5 if e.grade=='boss' else 1)),"turns":3,"stacks":c,"abyss":text.u('. <i>심연 −{n}</i>',{"n":result.n}) if result.n>0 else ''}),T+.8)
	finish_payload(b,1.7)

static func levia_mult(b) -> float:
	var n=b.initial_enemy_count(); var alive=b.living(false).size()
	return 1.3 if alive<=1 or n<=1 else 1+.3*float(n-alive)/(n-1)

static func cor_live(b,e) -> int:
	var state=b.extra_state.get(e.id)
	if not state is Dictionary:return 0
	if e.effects.has("corrosion"):return int(state.get("cor",0))
	state.cor=0
	return 0
static func defense_constant(b) -> float:
	return b.data.get("combat_K",b.BattleStats.K_of(b.data.encounter_r21.get("el",40),b.data.formula,b.data.def_curve))
static func corrode(b,a,e,add: int=1) -> Array:
	var stacks=mini(3,cor_live(b,e)+add)
	b.x(e).cor=stacks
	var k=defense_constant(b)
	var dc=k/(k+e.defense*(1-b.fx(e,"defense_down")))
	var per=maxf(1,floor(a.base[a.line]*2*1.5*(1-(1-dc)/2)+1e-9))
	b._effect(e,"corrosion",2,per*stacks)
	e.effects.corrosion.by=a.id
	e.effects.corrosion.order=b._next_dot_order()
	return [stacks,per]

static func gunhild_deal(b,owner,a,e,m: float,tags: Array):
	if a.id!=owner.id:return null
	var x=b.x(owner)
	if x.get("streak_action",-1)!=b.turn_count+1:
		x.streak_action=b.turn_count+1;x.streak=x.get("streak",0)+1 if x.get("target")==e.id else 0;x.target=e.id
	if x.get("target")!=e.id:return null
	var bonus=minf(.5,.05*x.get("streak",0))
	if bonus<=0:return null
	tags.append("선택과 집중 +%d%%"%b.CombatDisplay.percent(bonus))
	return m*(1+bonus)

static func bargut_turn_end(b,owner,a) -> void:
	if owner.id!=a.id:return
	var p=b.x(owner).get("personal_pull",0)
	if p<=0:return
	b.x(owner).personal_pull=0;owner.remaining=maxf(0,owner.remaining-10000*p)

static func felice_save(b,owner,target):
	if owner.id!=target.id:b.x(target).death_tick=b.ctb_tick
	return null

static func drop_caster_buffs(b,caster) -> void:
	for u in b.data.allies:
		for key in ["contract","adeline_guard"]:
			if u.effects.get(key,{}).get("source","")==caster.id:u.effects.erase(key)

static func miko_deal(b,owner,a,m: float,tags: Array,opt: Variant=null):
	if owner.trait.p.get("variant",2)!=1:return null
	var x=b.x(a);var v=opt.get("mkv") if opt is Dictionary else null
	if v==null:
		v=x.get("mk",0);x.mk=0
		if opt is Dictionary:opt.mkv=v
	if v<=0:return null
	tags.append("약발 받는 한 방 +%d%%"%b.CombatDisplay.percent(v))
	return m*(1+v)

static func miko_round(b,owner) -> void:
	if owner.trait.p.get("variant",2)!=2:return
	var pick={};var late=-1.0
	for a in b.living(true):
		if a.id==owner.id:continue
		var wait=float(a.remaining)/b.speed(a)
		if wait>late:pick=a;late=wait
	if pick.is_empty():return
	var pull=owner.trait.p.get("pull",.4);pick.remaining=maxf(0,pick.remaining-10000*pull)
	var t=b.combat_events.T;var name=b.CombatDisplay.unit_name(pick)
	var text="러버밴드 효과: "+name+" 차례 %d%% 당김"%b.CombatDisplay.percent(pull)
	b.combat_events.trait_payload(b.combat_events.slot(b,owner),text,t+.3)
	b.combat_events.push("trait",b.combat_events.slot(b,owner),t+.3)
	b.combat_events.say("<b>"+b.CombatDisplay.unit_name(owner)+"</b>의 <b>러버밴드 효과</b>. "+name+"의 다음 차례가 <em>%d%% 당겨졌다</em>"%b.CombatDisplay.percent(pull),t+.4)
	b.combat_events.T=t+.6

static func finish_payload(b,duration: float) -> void:
	# PRUN owns its duration; the native visual finish still starts at the
	# original body time, and reaches the same end time without adding twice.
	if not b.combat_events.context.is_empty():b.combat_events.context.body_start=b.combat_events.T
	b.combat_events.T+=duration
	b.combat_events.record.ev.T=b.combat_events.T
static func heal_record(b,target: Dictionary,amount: float,at: float,actor: Dictionary={}) -> int:
	var h=b._receive_heal(target,amount,actor)
	if h>0:b.combat_events.field(b,target,'hp',target.hp,at)
	return h
static func urda_round(b,owner: Dictionary) -> void:
	var target={};var ratio=2.0
	for w in b.living(true):
		var r=float(w.hp)/w.mhp
		if r<ratio:ratio=r;target=w
	if target.is_empty():return
	var clock=b.combat_events;var T=clock.T
	if not clock.record.has('ev'):clock.begin_record(b)
	var text=preload("res://game/combat_source_text_r23.gd")
	var h=heal_record(b,target,owner.base[owner.line]*2*owner.trait.p.get('k',.35),T+.3)
	var cleansed=''
	for pair in [['attack_down','공격 약화'],['defense_down','방어 약화']]:
		if target.effects.has(pair[0]):target.effects.erase(pair[0]);cleansed=pair[1];break
	if h<=0 and cleansed.is_empty():return
	var name=target.name
	var label=text.u('소울푸드: {target}{heal}{cleanse}',{"target":name,"heal":text.u(' +{n}',{"n":h}) if h>0 else '',"cleanse":text.u(', {debuff} 해제',{"debuff":cleansed}) if not cleansed.is_empty() else ''})
	clock.trait_payload(clock.slot(b,owner),label,T);clock.push('trait',clock.slot(b,owner),T)
	clock.say(text.u('<b>{owner}</b>의 <b>소울푸드</b>. {target}{heal}{cleanse}',{"owner":owner.name,"target":name,"heal":text.u(' HP <em>{n}</em> 회복',{"n":h}) if h>0 else '',"cleanse":text.u('{sep}{debuff} 해제',{"sep":', ' if h>0 else ' ',"debuff":cleansed}) if not cleansed.is_empty() else ''}),T+.4)
	clock.T=T+.6;clock.record.ev.T=clock.T
static func miko(b,a: Dictionary,target: Dictionary,sk: Dictionary) -> void:
	var clock=b.combat_events;var T=clock.T
	if not clock.record.has('ev'):clock.begin_record(b)
	var text=preload("res://game/combat_source_text_r23.gd")
	var h=heal_record(b,target,a.base[a.line]*2,T+1,a)
	b._event('%s → %s · HP +%d'%[a.name,target.name,h])
	target.remaining=maxf(0,target.remaining-3000)
	var boost=a.trait.p.get('variant',2)==1;var bonus=a.trait.p.get('bonus',.6)
	if boost:b.x(target).mk=bonus
	var name=b.CombatDisplay.short_name(sk.name)
	clock.Record.push(clock.record,{"k":"shield","a":clock.slot(b,a),"t":T,"tg":[{"i":clock.slot(b,target),"d":h}],"nm":name})
	clock.say(text.u('{who} 「{skill}」 하며 약을 건넸다. {target} HP <em>+{heal}</em>, 다음 차례가 <em>당겨졌다</em>',{"who":b.CombatDisplay.subject(a),"skill":name,"target":target.name,"heal":h}),T+1.1)
	if boost:
		clock.trait_payload(clock.slot(b,a),'약발 받는 한 방: '+target.name+' 다음 공격 피해 +%d%%'%b.CombatDisplay.percent(bonus),T+1.2)
		clock.say('<b>'+a.name+'</b>의 <b>약발 받는 한 방</b>. '+target.name+b.CombatDisplay.Josa.tail(target.name,'은는')+' 약발이 올라 다음 공격 피해 <em>+%d%%</em>'%b.CombatDisplay.percent(bonus),T+1.3)
	finish_payload(b,1.8)
static func hildegard_scan(b,owner: Dictionary) -> void:
	var taunted=false
	for a in b.living(true):
		if b.fx(a,'taunt')>0 or a.effects.get('taunt',{}).get('turns',0)>0:taunted=true
	for e in b.living(false):
		var x=b.x(e);var index=int(e.act_index)
		if x.get('hg_index',-1)==index:continue
		x.hg_index=index;e.redirected=false
		var act=e.acts[index] if index>=0 and index<e.acts.size() else {}
		if act.get('kind') in ['atk','shoot','aimed','spell','big_one','big_all'] and not taunted:
			var roll=b.dungeon_enemy_r21.random()
			if e.target_id!=owner.id and roll<owner.trait.p.get('pull',.35):
				e.target_id=owner.id;e.redirected=true
				if not b.combat_events.record.has('ev'):b.combat_events.begin_record(b)
				b._trait_event(owner,'첫 번째 펭귄: '+e.name+'의 공격이 쏠린다')

static func haldric(b,a,sk: Dictionary) -> void:
	var clock=b.combat_events;var T=clock.T;var names=[];var first={}
	if not clock.record.has("ev"):clock.begin_record(b)
	b._source_effect(a,"contract",3,.2,a.id)
	for u in b.living(true):
		if u.id==a.id or u.row!=a.row:continue
		b._source_effect(u,"contract",3,.2,a.id);names.append(b.CombatDisplay.unit_name(u))
		if first.is_empty():first=u
	var event={"k":"def" if first.is_empty() else "oath","a":clock.slot(b,a),"t":T}
	if sk.get("name")!=null:event.nm=sk.name
	if not first.is_empty():event.tg=[{"i":clock.slot(b,first)}]
	clock.Record.push(clock.record,event)
	var who="자신" if names.is_empty() else "자신과 "+", ".join(names)
	var name=b.CombatDisplay.unit_name(a)
	var vars={"who":name,"particle":b.CombatDisplay.Josa.tail(name,"이가"),"allies":who,"allies_particle":b.CombatDisplay.Josa.tail(who,"이가"),"red":20,"turns":3}
	if sk.get("name")!=null:vars.skill=sk.name
	clock.say(b.CombatDisplay.Locale.u("<b>{who}</b>{particle} {skill:을를} 읊었다. {allies}{allies_particle} 받는 피해 <em>−{red}%</em> ({turns}턴)",vars),T+.6)
	finish_payload(b,1.4)

static func urda(b,a,t,sk: Dictionary) -> void:
	var clock=b.combat_events;var T=clock.T;var key=best_double(t)
	if not clock.record.has("ev"):clock.begin_record(b)
	clock.Record.push(clock.record,{"k":"oath","a":clock.slot(b,a),"t":T,"tg":[{"i":clock.slot(b,t)}],"nm":sk.name})
	var name=b.CombatDisplay.unit_name(a);var target=b.CombatDisplay.unit_name(t)
	if not key.is_empty():
		var effect=t.effects[key];var old=effect.amount
		effect.amount=minf(.7,old*2) if key in ["contract","duty"] else old*2;effect.doubled=true
		clock.say("<b>"+name+"</b>"+b.CombatDisplay.Josa.tail(name,"이가")+" "+sk.name+b.CombatDisplay.Josa.tail(sk.name,"을를")+" 내렸다. "+target+"의 버프가 <em>%d%% → %d%%</em> (남은 %d턴 그대로)"%[b.CombatDisplay.percent(old),b.CombatDisplay.percent(effect.amount),effect.turns],T+.7)
	else:
		clock.say(b.CombatDisplay.Locale.u("<b>{who}</b>{particle} {skill:을를} 내렸지만 {target}에게는 두 배로 만들 버프가 없었다",{"who":name,"particle":b.CombatDisplay.Josa.tail(name,"이가"),"skill":sk.name,"target":target}),T+.7)
	finish_payload(b,1.6)

static func run(b,a,e,t,sk) -> void:
	match a.id:
		'bargut':
			var fastest=true
			for w in b.living(true)+b.living(false):
				if (w.base.spd if w.has('base') else w.speed)>a.base.spd:fastest=false
			b.SourceAttack.attack(b,a,e,{"m":1.2,"brk":15,"name":b.CombatDisplay.short_name(sk.name),"sk":b.CombatDisplay.short_name(sk.name),"vb":"먼저 찔렀다","hit":.45,"dur":1.4})
			if not fastest:b.combat_events.say('<b>'+a.name+'</b>보다 빠른 자가 있어 기습 보너스는 받지 못했다',b.combat_events.T)
		"marceline": b.x(a).cover=t.id; b.x(a).cover_turns=4
		"naran": b._effect(e,"mark",99,1); abyss(b,a,e,3)
		"teiris":
			a.once=true; b._volley(a,1.9,0)
		"haldric":
			haldric(b,a,sk)
		"erdene":
			b._effect(a,"taunt",3); b._receive_heal(a,b.x(a).get("prevented",0)*.25); b.x(a).prevented=0
			for foe in b.living(false): b._effect(foe,"attack_down",2,.15); abyss(b,a,foe,20)
		"bianca": b._damage(a,e,1.4,0)
		"saya": e.remaining+=4000*(.5 if e.grade=="boss" else 1); abyss(b,a,e,3)
		"gerda":
			var behind=b._behind(e); b.x(a).penetrating=true; b._damage(a,e,1.3,3)
			if not behind.is_empty() and behind.hp>0: b._damage(a,behind,1.3,3,true,-1,{"hit":.5,"duration":1.5})
			b.x(a).penetrating=false
		"judith":
			judith(b,a,e,sk)
		"levia": a.hp-=int(floor(a.mhp*.1)) if a.get("nation")!="모르가스 신관국" else maxi(1,int(floor(floor(a.mhp*.1)*.7))); b._effect(a,"rift_charge",99,1); b._sorel_aid(a)
		"urda":
			urda(b,a,t,sk)
		"lynette":
			for u in b.living(true): b._receive_heal(u,floor(a.base[a.line]),a); b._shield(u,floor(a.base[a.line]),3,false)
		"felice","berenga": b._heal(a,t,.4 if a.id=="felice" else 1,true); cleanse(t)
		"sorel":
			for u in b.living(true): b._heal(a,u,1,true); b._effect(u,"sorel_regen",2,floor(a.base[a.line]*.6))
		"tika":
			a.hp-=int(floor(a.mhp*.1)); b.x(a).free=b.x(a).get("free",0)+2; b.x(a).inch=true; b._sorel_aid(a)
		"hedwig": b._damage(a,e,1.2,15); b.x(a).mamp=.1
		"hildegard":
			b._effect(a,"taunt",2); b._effect(a,"duty",2,.25)
			var target={}
			for foe in b.living(false):
				if target.is_empty() or foe.hp<target.hp: target=foe
			if not target.is_empty(): abyss(b,a,target,15)
		"altan":
			var atk=false; var defense=false
			for u in b.living(true): atk=atk or u.effects.has("attack_up"); defense=defense or u.effects.has("defense_up")
			for u in b.living(true): b._effect(u,"defense_up" if atk and not defense else "attack_up",2,.15)
		"colette":
			var magic=has_magic(e)
			abyss(b,a,e,15)
			if magic and (e.grade!="boss" or b._roll(.5)): b.x(e).seal_until=b.ctb_tick+200
			weaken_all(b)
		"zahar": b._volley(a,1.2,15); b._effect(a,"zdn",2,.2)
		"tove": b._effect(a,"taunt",2); abyss(b,a,e,40)
		"miko":
			miko(b,a,t,sk)
		"adeline":
			for u in b.living(true):
				b._heal(a,u,.4,true); b._source_effect(u,"adeline_guard",2,.1,a.id); b._add_adeline_regen(u,a.base[a.line]*.16,2,a.id)
		"jorund":
			# PRUN reads the selected target's contract before B.attack redirects.
			var marked=b.x(e).get("jm",false)
			var options={"jmk":marked,"capture_result":true}
			b._damage(a,e,1.2,15,false,-1,options)
			if not marked and not options.get("primary_kill",true): b.x(e).jm=true
		_:
			b._damage(a,e,1.2,15)
			if a.id=="ornel" and e.hp>0: weaken(b,e,.2)

static func cleanse(t) -> void:
	for key in ["attack_down","defense_down","zdn"]:
		if t.effects.has(key): t.effects.erase(key); return
static func weaken(b,e,amount: float) -> void:
	var cur=e.effects.get("attack_down",{})
	if not cur.is_empty() and (cur.amount>amount or (cur.amount==amount and cur.turns>=2)): return
	b._effect(e,"attack_down",2,amount)
static func weaken_all(b) -> void:
	for foe in b.living(false): weaken(b,foe,.15)

static func hit_after(b,h: Dictionary) -> void:
	var a=h.a; var e=h.e
	for owner in b.data.allies:
		if owner.hp<=0: continue
		match owner.id:
			"hildegard": b._hg_scan()
			"bargut":
				if a.id==owner.id and h.critical:
					b.x(a).personal_pull=maxf(b.x(a).get("personal_pull",0),.3)
					b.combat_events.trait_payload(b.combat_events.slot(b,owner),'스노우볼 효과: 다음 차례 30% 당김',h.get('hit_at',b.combat_events.T)+.2)
			"bianca":
				if a.id==owner.id and not h.killed and e.hp>0 and e.hp<=e.mhp*.25 and e.grade not in ["boss","chief","core"]:
					var before=e.hp; b._flat_enemy(e,before*2+1); b._record_hit(a.id,e.id,before,0); a.remaining-=5000
			"gerda":
				if a.id!=owner.id or b.x(a).get("penetrating",false): continue
				var behind=b._behind(e); var mult=.6
				if behind.is_empty() and e.hp>0: behind=e; mult=.3
				if not behind.is_empty():
					b.x(a).penetrating=true; b._trait_event(a,"도미노 이론",0); b._damage(a,behind,h.power*mult,0,true,-1,{"hit":.4,"duration":1.0}); b.x(a).penetrating=false
			"naran":
				if a.id==owner.id and not h.killed: b._effect(e,"foxflame",3,.6)
			"judith":
				if a.id==owner.id and not h.killed and e.hp>0: corrode(b,a,e,1)
			"colette":
				if a.id==owner.id: weaken_all(b)
			"selva":
				if a.id!=owner.id: continue
				var carry=int(floor(b.x(a).get("overheal",0)))
				if carry>0:
					b.x(a).overheal=0
					if not h.killed and e.hp>0: b._flat_enemy(e,carry,a,true,true,false)
				var leech=.3*minf(h.dealt,h.before+h.get("shield_before",0)); var got=minf(leech,a.mhp-a.hp)
				if got>0: b._receive_heal(a,got)
				b.x(a).overheal=b.x(a).get("overheal",0)+maxf(0,leech-got)
			"jorund":
				if a.id!=owner.id or h.killed or e.hp<=0: continue
				var stacks=mini(3,int(b.x(e).get("bleed_stacks",0) if e.effects.has("bleed") else 0)+1)
				var n=int(b.data.encounter_r21.el)-1; var k=40*(1+b.data.def_curve.a*n+b.data.def_curve.b*n*n)
				var dc=k/(k+e.defense*(1-b.fx(e,"defense_down"))); var per=a.base[a.line]*2*.2*(1-(1-dc)/2)
				e.effects.erase("bleed")
				var want=.05
				var at=h.get('hit_at',b.combat_events.T);var slot=b.combat_events.slot(b,a)
				if stacks==3:
					b.x(e).bleed_stacks=0
					var amount=maxf(1,floor(9*per*1.5));var shield_before=b.fx(e,'shield');var damage=maxi(1,int(floor(amount*.6))) if e.effects.has('guard') else int(amount)
					b._flat_enemy(e,amount,a,false,false,false);want=.18
					if shield_before>0:b.combat_events.field(b,e,'sh',b.fx(e,'shield'),at+.3)
					b.combat_events.field(b,e,'hp',e.hp,at+.3)
					b.combat_events.trait_payload(slot,'티핑 포인트: 출혈 3중첩 폭발 '+str(damage),at+.3)
					b.combat_events.say('<b>'+a.name+'</b>의 <b>티핑 포인트</b>. '+e.name+'의 출혈이 한꺼번에 터졌다. <em>'+str(damage)+'</em> 피해를 입혔다'+('. 쓰러졌다' if e.hp<=0 else ''),at+.4)
					if e.hp<=0:b.data.last_kill=a.name+'의 티핑 포인트';b.TraitRules.kill_credit(b,a,at+.3)
				else:
					b.x(e).bleed_stacks=stacks; b._effect(e,"bleed",3,maxf(1,floor(stacks*per))); e.effects.bleed.by=a.id; e.effects.bleed.order=b._next_dot_order()
					b.combat_events.trait_payload(slot,'티핑 포인트: 출혈 '+str(stacks)+'중첩',at+.3)
				var cur=b.x(e).get("jd",0)
				if e.hp>0 and want>cur: e.remaining+=10000*(want-cur)*(.5 if e.grade=="boss" else 1); b.x(e).jd=want
			"lavinia":
				if a.id!=owner.id or h.killed or b.x(a).get("echoing",false): continue
				if b.x(a).get("echo_action",-1)!=b.turn_count+1:
					b.x(a).echo_action=b.turn_count+1; b.x(a).echo=b._roll(.5)
				if b.x(a).echo and e.hp>0:
					b.x(a).echoing=true; b._trait_event(a,"에코 챔버",0); b._damage(a,e,h.power*.7,0,true,-1,{"hit":.4,"duration":1.0}); b.x(a).echoing=false
			"tika":
				if a.id!=owner.id: continue
				var roll=b.dungeon_enemy_r21.random()
				if b.x(a).get("enc",0)<2 and roll<.3:
					b.x(a).enc=b.x(a).get("enc",0)+1; b.x(a).free=b.x(a).get("free",0)+1; b._trait_event(a,"앙코르 요청 쇄도",0)

static func enemy_down(b,e) -> void:
	for owner in b.living(true):
		if owner.id=="gunhild" and b.x(owner).get("target")==e.id: b.x(owner).erase("target"); b.x(owner).streak=0
		if owner.id=="judith" and e.effects.has("corrosion"):
			for other in b.living(false):
				if other.id!=e.id: corrode(b,owner,other,int(b.x(e).get("cor",0))); break

static func turn_end(b,a) -> void:
	if a.hp<=0 or not a.has("base"): return
	match a.id:
		"tika":
			if b.x(a).get("free",0)>0: b.x(a).free-=1; a.remaining-=10000
			else: b.x(a).enc=0; b.x(a).inch=false
		"hedwig":
			if b.x(a).get("decl",false) and b.x(a).get("dset",0)<a.actions: b.x(a).decl=false
			if int(a.actions)%3==0: b.x(a).decl=true; b.x(a).dset=a.actions; b._trait_event(a,"삼세번의 법칙",.5)

static func damage_mult(b,a) -> float:
	var mult=1.0
	for owner in b.living(true):
		if owner.id!="hedwig": continue
		if a.id==owner.id and b.x(owner).get("decl",false): mult*=1.6
		if a.line=="int" and b.x(owner).get("mamp",0)>0: mult*=1+b.x(owner).mamp; b.x(owner).mamp=0
	return mult

static func take(b,a,hit: float,e: Dictionary) -> float:
	for owner in b.living(true):
		match owner.id:
			"haldric":
				if a.id==owner.id or owner.effects.has("taunt"): hit*=.85
				hit*=1-b.fx(a,"contract")
			"erdene":
				if a.id==owner.id and owner.effects.has("taunt"): b.x(owner).prevented=b.x(owner).get("prevented",0)+hit*.15; hit*=.85
			"hildegard":
				if a.id!=owner.id: continue
				hit*=.85*(1-b.fx(owner,"duty"))
				if not e.is_empty() and e.get("redirected",false): e.redirected=false; b._receive_heal(owner,owner.mhp*.04)
			"adeline": hit*=1-b.fx(a,"adeline_guard")
			"zahar":
				if a.id!=owner.id: continue
				hit*=.62
				if b.fx(a,"zdn")>0:
					var n=int(b.data.encounter_r21.el)-1; var k=40*(1+b.data.def_curve.a*n+b.data.def_curve.b*n*n)
					var d0=a.base.def*(1+b.fx(a,"defense_up")); var d1=d0-a.base.def*b.fx(a,"zdn")
					hit*=(k+d0)/(k+d1)
	return hit
