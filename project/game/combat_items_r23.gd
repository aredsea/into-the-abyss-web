extends RefCounted
## Canonical battle-item rules, shared by canvas controls and source observations.
const Text=preload('res://game/combat_source_text_r23.gd')
const Stats=preload('res://game/battle_stats_r23.gd')
const ItemData=preload('res://game/combat_item_data_r23.gd')
static func u(text: String,vars: Dictionary={},lang: String='ko') -> String:
	var translated=vars.duplicate()
	if lang=='en':
		for key in translated:
			if translated[key] is String:translated[key]=ItemData.ENGLISH.get(translated[key],translated[key])
	return Text.u(ItemData.ENGLISH.get(text,text) if lang=='en' else text,translated,lang)
static func t(text: String,lang: String='ko') -> String:return ItemData.ENGLISH.get(text,Text.t(text,lang)) if lang=='en' else text
static func current_actor(state: Dictionary) -> Variant:return state.get('cur')
static func native_id(id: String) -> String:return {'sh_s':'shield_s','sh_m':'shield_m','sh_l':'shield_l'}.get(id,id)
static func source_id(id: String) -> String:return {'shield_s':'sh_s','shield_m':'sh_m','shield_l':'sh_l'}.get(id,id)
static func item_name(id: String) -> String:return ItemData.NAMES.get(id,id)
static func amount(id: String,target: Dictionary,mul: float=1) -> int:
	var d=ItemData.ITEMS.get(source_id(id),{})
	return int(floor((target.mmp if d.get('kind')=='mp' else target.mhp)*d.get('fraction',0)*mul+.5))
static func has_dot(target: Dictionary) -> bool:
	for key in target.effects:
		if key=='foxflame':
			if target.effects[key].get('amount',0)>0:return true
		elif key in ['bleed','corrosion'] or key.begins_with('enemy_dot_'):return true
		elif key=='dot' and (target.effects.dot.get('stacks',[]).size()>0 or target.effects.dot.get('amount',0)>0):return true
	return false
static func state_ok(b,id: String,target: Dictionary) -> bool:
	id=source_id(id)
	if target.is_empty() or target not in b.data.allies or b.data.allies.find(target)>=4 or target.get('empty',false):return false
	if id=='bandage':return target.hp<=0
	if target.hp<=0:return false
	match ItemData.ITEMS.get(id,{}).get('kind'):
		'hp':return target.hp<target.mhp
		'mp':return target.mmp>0 and target.mp<target.mmp
		'sh':return target.shield<amount(id,target)
	if id=='antidote':return has_dot(target)
	return false
static func target_ok(b,id: String,target: Dictionary) -> bool:
	return state_ok(b,id,target) and Stats.number(target.get('level'),1)>=ItemData.ITEMS.get(source_id(id),{}).get('lv',0)
static func any_target(b,id: String) -> bool:
	return b.data.allies.any(func(target):return target_ok(b,id,target))
static func blocked(b,id: String) -> bool:
	return b.data.allies.any(func(target):return state_ok(b,id,target) and not target_ok(b,id,target))
static func button(bag: Variant,lang: String='ko') -> Dictionary:
	var view={"heading":"","hint":"","buttons":[]}
	if not bag is Dictionary:return view
	var total=0.0
	for id in ItemData.ORDER:total+=Stats.number(bag.get(id),0)
	view.buttons.append({"action":"it_open" if total>0 else '',"enabled":total>0,"label":u('물약',{},lang),"description":u('아이템 {n}개, 쓰면 이번 차례를 씁니다',{"n":total},lang) if total>0 else u('남은 아이템이 없다',{},lang)})
	return view
static func menu(b,bag: Variant,picked: String='',lang: String='ko') -> Dictionary:
	var name=b.ally(b.current_id).get('name','');var controls=[]
	if picked!='':
		return {"heading":u('{name} / {item}',{"name":name,"item":item_name(picked)},lang),"hint":u('쓰러진 아군을 누르세요' if picked=='bandage' else '대상 아군을 누르세요',{},lang),"buttons":[{"action":"it_cancel","enabled":true,"label":u('취소',{},lang),"description":u('다른 행동을 고릅니다',{},lang)}]}
	for id in ItemData.ORDER:
		var n=Stats.number(bag.get(id) if bag is Dictionary else null,0)
		if n<=0:continue
		var def=ItemData.ITEMS[id];var usable=any_target(b,id)
		var desc=u('{description} (보유 {n})',{"description":t(def.d,lang),"n":n},lang)
		if not usable:desc=u('<b>Lv {lv}부터 쓸 수 있습니다</b>. {description}',{"lv":def.get('lv',0),"description":def.d},lang) if blocked(b,id) else u('<b>쓸 대상이 없습니다</b>. {description}',{"description":def.d},lang)
		controls.append({"action":'it_pick_'+id if usable else '',"enabled":usable,"label":t(def.name,lang),"description":plain(desc)})
	controls.append({"action":"it_cancel","enabled":true,"label":u('취소',{},lang),"description":u('행동 고르기로 돌아간다',{},lang)})
	return {"heading":u('{name} / 아이템',{"name":name},lang),"hint":u('무엇을 쓸까요? 쓰면 이번 차례를 씁니다',{},lang),"buttons":controls}
static func plain(text: String) -> String:
	var regex=RegEx.new();regex.compile('<[^>]*>');return regex.sub(text,'',true)
static func apply(b,id: String,target: Dictionary) -> int:
	id=source_id(id)
	var d=ItemData.ITEMS[id];var actor=b.ally(b.current_id);var clock=b.combat_events;var T=clock.T
	var mul=1.1 if b.count_tag('nation','마렌토 공화국')>=2 else 1.0
	var value=0;var field='hp'
	match d.get('kind',''):
		'hp':value=b.PersonalRules.heal_record(b,target,amount(id,target,mul),T+.8)
		'mp':
			value=mini(target.mmp,target.mp+amount(id,target,mul))-target.mp;target.mp+=value;field='mp'
			if value>0:clock.field(b,target,'mp',target.mp,T+.8)
		'sh':
			value=amount(id,target,mul)
			if b.count_tag('nation','솔렌 성왕국')>=2:value=int(floor(value*1.03))
			if b.gear_bridge!=null:
				var modified=b.gear_bridge.invoke('shield',[current_actor({"cur":clock.slot(b,actor)}),value]);value=int(floor(modified)) if modified!=null else value
			target.shield=maxi(target.shield,value);target.effects.shield={"amount":0,"turns":3};clock.field(b,target,'sh',target.shield,T+.8);field='sh'
	if id=='antidote':
		for key in target.effects.keys():
			if key=='dot':value+=target.effects.dot.get('stacks',[0]).size()
			elif key in ['corrosion','bleed'] or key.begins_with('enemy_dot_'):value+=1
			elif key=='foxflame' and target.effects[key].get('amount',0)>0:value+=1
			if key in ['dot','corrosion','bleed','foxflame'] or key.begins_with('enemy_dot_'):target.effects.erase(key)
		b.x(target).erase('dot_stacks');field='cure'
	elif id=='bandage':
		value=maxi(1,int(floor(target.mhp*.25)));target.hp=value;target.remaining=10000;target.charging=false;target.broken=false
		for key in target.effects.keys():
			# Source clears bf/DOT/fx and stance fields, preserving sh, sil,
			# x-owned regeneration and the party's global wall.
			if key not in ['shield','silence','persona_regen','sorel_regen','regen','wall_party','enemy_attack_self']:target.effects.erase(key)
		b.x(target).erase('dot_stacks')
		clock.field(b,target,'hp',target.hp,T+.8);field='up'
	clock.Record.push(clock.record,{"k":"item","a":clock.slot(b,actor),"t":T,"nm":d.name,"tg":[{"i":clock.slot(b,target),"d":value,"f":field}]})
	var effect='HP <em>+'+str(int(value))+'</em>'
	if field=='mp':effect='MP <em>+'+str(int(value))+'</em>'
	elif field=='sh':effect=Text.u('보호막 <em>{n}</em>',{"n":value})
	elif field=='cure':effect=Text.u('지속 상태 해제')
	elif field=='up':effect=Text.u('쓰러진 몸을 일으켰다. HP <em>{n}</em>',{"n":value})
	clock.say(Text.u('<b>{who}</b>{suffix} {item:을를} 썼다. <b>{target}</b> {effect}',{"who":actor.name,"suffix":b.CombatDisplay.Josa.tail(actor.name,'이가'),"item":d.name,"target":target.name,"effect":effect}),T+.9)
	clock.push('item',clock.slot(b,actor),T,[clock.slot(b,target)]);clock.T=T+1.4;clock.record.ev.T=clock.T
	return value
