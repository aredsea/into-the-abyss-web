extends SceneTree
const Screen=preload('res://ui/battle_screen.gd')
const World=preload('res://game/settings_world_r22.gd')
var checks=0
var failures=[]
var captures=[]
func _initialize():call_deferred('run')
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures.append(label);push_error(label)
func fixture(lang: String):
	var world=World.new();world.s.scene='town';world.s.creation_r22={"complete":true,"legacy":true}
	var c=world.config.classes[0];world.s.persona.cls=c.name;world.s.persona.stats=c.base.duplicate(true);world.s.persona.lv=10;world.s.members.persona.level=10
	world.s.owned=['felice','naran','sorel'];world.s.party=world.s.owned.duplicate();world.s.settings.lang=lang
	for id in world.s.owned:world.s.members[id].level=10
	world.depart_dungeon(1,12345);world.s.run.phase='battle'
	var screen=Screen.new();screen.session_data=world.battle_data();screen.session_save=func(_v):return OK
	screen.size=root.size;root.add_child(screen);screen.motion_reduced=true;screen.busy=false
	screen.state.current_id='persona';screen.state.last_ally='persona';screen.state.selected_ally='persona'
	for id in screen.state.inventory:screen.state.inventory[id]=0
	screen.state.inventory.merge({"hp_s":2,"mp_m":1,"bandage":1,"shield_l":1},true)
	return screen
func capture(screen,tag: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	for metric in screen.text_metrics:
		check(metric.missing_glyphs.is_empty(),'glyph '+tag+' '+metric.text)
		check(metric.needed<=metric.available+.6,'width '+tag+' '+metric.text)
	var path='res://../verification/parity-r23/battle-round9-ui-'+tag+'.png'
	check(root.get_texture().get_image().save_png(path)==OK,'capture '+tag);captures.append(path)
func run():
	preload('res://ui/persona_visual_adapter.gd').prepare()
	for dim in [Vector2i(360,780),Vector2i(390,844),Vector2i(390,664),Vector2i(430,932),Vector2i(1280,800)]:
		root.content_scale_size=dim;root.size=dim
		for lang in ['ko','en']:
			var s=fixture(lang);var tag='%s-%dx%d'%[lang,dim.x,dim.y]
			s._rebuild();s._toggle_supplies();await process_frame
			var ids=s.state.actions().keys().filter(func(id):return id.begins_with('item:') and s.state.inventory.get(id.substr(5),0)>0)
			check(ids==['item:hp_s','item:mp_m','item:shield_l','item:bandage'],'source order '+tag)
			for id in ids:
				var button=s.find_child(id.replace(':','_'),true,false)
				check(is_instance_valid(button),'item control '+id)
				if is_instance_valid(button):check(button.disabled,'unusable target disabled '+id)
			await capture(s,tag+'-blocked')
			var reopened=Screen.new();reopened.session_data=s.scene_data;reopened.session_snapshot=s.state.snapshot();reopened.session_save=func(_v):return OK
			reopened.size=root.size;root.add_child(reopened);reopened.motion_reduced=true;reopened.busy=false
			check(reopened.items_open and reopened.pending_action.is_empty(),'item menu resume '+tag)
			reopened.queue_free();await process_frame
			var a=s.state.ally('persona');a.hp=maxi(1,int(a.mhp*.5));s._rebuild()
			s._select_supply('item:hp_s');s.supply_target_set=true
			check(s._supply_reason().is_empty(),'valid selection '+tag)
			reopened=Screen.new();reopened.session_data=s.scene_data;reopened.session_snapshot=s.state.snapshot();reopened.session_save=func(_v):return OK
			reopened.size=root.size;root.add_child(reopened);reopened.motion_reduced=true;reopened.busy=false
			check(reopened.items_open and reopened.pending_action=='item:hp_s','picked item resume '+tag)
			reopened._close_sheets();check(reopened.state.selected_action=='attack','cancel resume '+tag)
			reopened.queue_free();await process_frame
			await capture(s,tag+'-target')
			s._close_sheets();s.state.inventory={};s._rebuild()
			var root_button=s.find_child('supplies',true,false);check(is_instance_valid(root_button) and root_button.disabled,'empty inventory disabled '+tag)
			s.queue_free();await process_frame
	var f=FileAccess.open('res://../verification/parity-r23/battle-round9-ui-latest.json',FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures}));f.close()
	print('R23 ROUND9 UI ',checks,' checks / failures ',failures.size());quit(0 if failures.is_empty() else 1)
