extends SceneTree
const World=preload('res://game/settings_world_r22.gd')
const Battle=preload('res://game/battle_v3.gd')
const Cloud=preload('res://game/cloud_store_r22.gd')
var checks=0
var failures=[]
var responses=[]
func same(a,b) -> bool:
	if a is Dictionary:
		if not b is Dictionary or a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]):return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size():return false
		for i in range(a.size()):
			if not same(a[i],b[i]):return false
		return true
	if a is int or a is float:return (b is int or b is float) and absf(a-b)<.0000001
	return typeof(a)==typeof(b) and a==b
func _initialize():create_timer(60).timeout.connect(func():quit(98));call_deferred('run')
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func run():
	var w=World.new();w.s.scene='town';w.s.creation_r22={"complete":true,"legacy":true}
	var c=w.config.classes[0];w.s.persona.cls=c.name;w.s.persona.stats=c.base.duplicate(true);w.s.persona.lv=1
	w.s.persona.stats.erase('crit')
	w.s.owned=['hildegard','felice','naran'];w.s.party=w.s.owned.duplicate()
	for id in ['persona']+w.s.owned:
		w.s.members[id].level=1;w.s.members[id].xp=0;var stats=w.stats(id,1);w.s.members[id].hp=stats.hp;w.s.members[id].mp=stats.mp
	check(w.depart_dungeon(1,12345),'prepare source battle');w.s.run.phase='battle'
	var data=w.battle_data();var b=Battle.new(data);b.current_id=b.data.allies[0].id;b.last_ally=b.current_id;b.selected_ally=b.current_id
	b.set_persona_regen(b.data.allies[0],7,2)
	var client=Cloud.new();root.add_child(client);client.model=w;client.config.server_url=OS.get_environment('ABYSS_TEST_SERVER')
	for selected in ['supply_menu','item:hp_s','attack']:
		b.selected_action=selected;w.s.run.battle=b.snapshot()
		var restored=World.new();check(restored.restore(w.s),'native save '+selected)
		var response=await client._request(HTTPClient.METHOD_POST,'/v1/account',{"save":w.s});responses.append({"selected":selected,"response":response})
		check(response.status==201,'local server accepts '+selected+' '+JSON.stringify(response))
		if response.status==201:
			var downloaded=await client._request(HTTPClient.METHOD_GET,'/v1/save/'+response.code)
			check(downloaded.status==200 and same(downloaded.save.run.battle,w.s.run.battle) and World.new().restore(downloaded.save),'cloud menu/effect round trip '+selected)
	client.queue_free()
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-cloud-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"responses":responses}));f.close()
	print('R23 ROUND9 CLOUD ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
