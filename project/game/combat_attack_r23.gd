extends RefCounted
## An attack body owns its source record before hit-after/counter re-entry.
const State=preload('res://game/battle_source_state_r23.gd')
static func attack(b,a: Dictionary,target: Dictionary,opt: Dictionary) -> Dictionary:
	var clock=b.combat_events;clock.ensure_record(b);var T=clock.T
	var targets=b.living(false) if opt.get('volley',false) else [b.dungeon_enemy_r21.protector(target)]
	var old_context=clock.context;var old_volley=b.volley_active;var old_hooks=b.pending_hit_hooks
	b.volley_active=true;b.pending_hit_hooks=[]
	var results=[];var rank=0
	for e in targets:
		var at=T+opt.get('hit',.4)+rank*.07;rank+=1
		clock.context={"id":"source_attack","owner":a.id,"actor":clock.slot(b,a),"enemy":clock.slot(b,e),"ally":0,"friends":[],"foes":[],"source_spec":[opt.get('k','atk'),at-T,opt.get('dur',1.3),'enemy']}
		var options={"redirected":true,"capture_result":true,"element":opt.get('el',a.element),"source_at":at,"source_opt":opt}
		b._damage(a,e,opt.get('m',1),opt.get('brk',0),opt.get('extra',false),-1,options)
		results.append(options.result)
	var event={"k":opt.get('k','atk'),"a":clock.slot(b,a),"t":T,"ht":T+opt.get('hit',.4),"tg":results,"nm":opt.get('name',''),"el":opt.get('el',a.element)}
	if opt.has('big'):event.big=opt.big
	clock.Record.push(clock.record,event)
	if opt.get('volley',false):
		var parts=[]
		for r in results:
			var e=(b.data.allies+b.data.enemies)[int(r.i)-1]
			parts.append(e.name+' <em>'+str(int(r.d))+'</em>'+('(치명타)' if r.c==1 else '')+('(약점)' if not r.tags.is_empty() and '약점' in r.tags[0] else '')+('(쓰러짐)' if r.kill==1 else '')+(' <i>심연 −'+str(int(r.ab))+'</i>' if r.ab>0 else ''))
		clock.say(b.CombatDisplay.Locale.u('<b>{who}</b>{particle} {skill:으로} {action}. {targets}',{"who":a.name,"particle":b.CombatDisplay.Josa.tail(a.name,'이가'),"skill":opt.get('name',''),"action":opt.get('line','적 전체를 휩쓸었다'),"targets":', '.join(parts)}),T+opt.get('hit',.5)+.2)
	elif not results.is_empty():
		var api=State.new();api.definitions=(b.data.allies+b.data.enemies).map(func(w):return {"name":w.name})
		clock.say(api.damage_line(clock.slot(b,a),results[0],{"sk":opt.get('sk'),"vb":opt.get('vb','때렸다')}),T+opt.get('hit',.4)+.1)
	clock.push(event.k,event.a,T,results.map(func(r):return r.i),event.ht)
	clock.T=T+opt.get('dur',1.3);clock.record.ev.T=clock.T;clock.context={}
	var hooks=b.pending_hit_hooks;b.pending_hit_hooks=old_hooks;b.volley_active=old_volley
	for h in hooks:
		h.volley=opt.get('volley',false);b._personal_hit_after(h)
	if not old_context.is_empty():old_context.body_recorded=true
	clock.context=old_context
	return results[0] if not results.is_empty() else {}
