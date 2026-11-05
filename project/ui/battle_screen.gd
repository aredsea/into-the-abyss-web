extends Control
signal session_finished
var session_data: Dictionary={}
var session_snapshot: Dictionary={}
var session_save: Callable

const ResourceGauge=preload("res://ui/resource_gauge_r24.gd")
const BattleState = preload("res://game/battle_state.gd")
const ModernBattle=preload("res://game/battle_v3.gd")
const CharacterSprite=preload("res://ui/battle_body_r18.gd")
const SignatureSequence=preload("res://ui/signature_sequence.gd")
const ForgedButton=preload("res://ui/forged_button.gd")
const CombatFX=preload("res://ui/combat_fx.gd")
const CombatPresentation=preload("res://ui/combat_presentation.gd")
const SaveStore = preload("res://game/save_store.gd")
const UI=preload("res://ui/fantasy_theme.gd")
const L=preload("res://game/localization_r22.gd")
const INK = Color("111715")
const GOLD = Color("d83219")
const LINE = Color("b8b8ab")
const PAPER = Color("f4efe3")
const RED = Color("d83219")
const DISPLAY = preload("res://assets/fonts/AbyssDisplayR19.ttf")
const DISPLAY_PLAIN = preload("res://assets/fonts/AbyssNotoBlackCondensed.ttf")
const BODY = preload("res://assets/fonts/AbyssNotoText500.ttf")
const BODY_BOLD = preload("res://assets/fonts/AbyssNotoText800.ttf")
const W750 = preload("res://assets/fonts/AbyssTextR19W750.ttf")
const W850 = preload("res://assets/fonts/AbyssTextR19W850.ttf")
const TIGHT = preload("res://assets/fonts/AbyssTextR19Tight.ttf")
const InkR17 = preload("res://ui/battle_ink_r17.gd")
const FaceR17 = preload("res://ui/battle_face_r17.gd")
var state
var storage = SaveStore.new()
var font: Font = BODY
var textures = {}
var frame = Rect2()
var controls = {}
var text_metrics = []
var skills_open = false
var items_open=false
var supply_target_set=false # an ally card was tapped in this supplies sheet
var ally_open = ""
var actor: Control
var preview_tween: Tween
var storage_error = OK
var motion_reduced = false
var pending_action = ""
var busy = false
var log_open = false
var log_title = "전투 기록"
var sheet_kind = ""
var notice = ""
var scene_data: Dictionary
var animation_ally = ""
var playback_generation = 0
var motion: Node2D
var motion_serial = 0
var enemy_visuals: Dictionary = {}
var field_visual: Control
var field_home = Vector2.ZERO
var field_back: Control
var motion_hurt_ids: Array = []
static var enemy_pixels: Dictionary = {}
var shown_hp: Dictionary = {}
var resource_history: Dictionary = {}
var presenting_source = ""
# Presentation-only journal. Old saved prose remains readable and is never parsed.
var display_history: Array=[]
var history_origin=0
var legacy_history: Array=[]
var session_context: Dictionary={}
var layout_boxes: Dictionary={}
var battle_window: Window
var previous_content_size=Vector2i.ZERO

func _language() -> String:
	return state.data.get("language_r22","ko") if state!=null else session_data.get("language_r22","ko")

func _tr(value: String) -> String:
	if _language()!="en":return value
	for a in state.data.allies:
		var signature=a.skills.get("personal",{})
		if a.id=="persona" and signature.has("persona_skill"):
			if value==signature.name:return ModernBattle.PersonaCombat.Research.skill_name(signature.persona_skill,true)
			if value==signature.note:return ModernBattle.PersonaCombat.Research.description(signature.persona_skill,true)
	return L.render(value,_language())

func _sync_battle_viewport() -> void:
	if not is_instance_valid(battle_window): return
	var logical=Vector2i(int(JavaScriptBridge.eval("window.innerWidth",true)),int(JavaScriptBridge.eval("window.innerHeight",true)))
	# Only portrait phone-width pages get 1:1 CSS pixels; desktop and tablet
	# windows keep the project's scaled canvas so battle matches the town.
	var phone=logical.x>0 and logical.x<=480 and logical.y>logical.x
	# Never go below the 360x780 design minimum: short browser viewports
	# (toolbars shown) scale down instead of squeezing the battlefield.
	var k=maxf(1.0,maxf(780.0/maxf(1,logical.y),360.0/maxf(1,logical.x)))
	var target=Vector2i(ceili(logical.x*k),ceili(logical.y*k)) if phone else previous_content_size
	if target.x>0 and target.y>0 and battle_window.content_scale_size!=target:
		battle_window.content_scale_size=target

func _exit_tree() -> void:
	if resized.is_connected(_rebuild): resized.disconnect(_rebuild)
	if is_instance_valid(battle_window) and previous_content_size!=Vector2i.ZERO:
		if battle_window.size_changed.is_connected(_sync_battle_viewport): battle_window.size_changed.disconnect(_sync_battle_viewport)
		# The world is still inside remove_child() here. Restore next frame so
		# its resize-driven redraw runs after the battle has been detached.
		battle_window.set_deferred("content_scale_size",previous_content_size)

func _mark(key: String, node: Control) -> Control:
	node.set_meta("r19_box",key)
	return node

func _outline(b: Button) -> void:
	b.add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,Color("888d81")))

func _location() -> String:
	var context=session_context
	if context.is_empty() and get_parent()!=null and get_parent().get("model")!=null:
		context=get_parent().model.s.get("run",{})
	var place=str(state.data.get("location","학술원 폐허"))
	var floor_value=context.get("floor",context.get("layer",state.data.get("floor",0)))
	return place+(" · %d층"%int(floor_value) if int(floor_value)>0 else "")

func _journal(source: String, action_id: String, turn: int) -> void:
	var unit=state.unit(source)
	var action_name=unit.get("skills",{}).get(action_id,{}).get("name","")
	if action_name.is_empty(): action_name="적 행동" if action_id=="enemy" else action_id
	if action_id.begins_with("item:"):
		for item in state.data.get("item_defs",[]):
			if item.id==action_id.substr(5): action_name=item.name
	display_history.append({"turn":turn+1,"actor":source,"name":unit.get("name",source),"action":action_name.split("(")[0].strip_edges()})
	if display_history.size()>100: display_history.pop_front()


func _ready() -> void:
	if OS.has_feature("web"):
		battle_window=get_window(); previous_content_size=battle_window.content_scale_size
		_sync_battle_viewport(); battle_window.size_changed.connect(_sync_battle_viewport)
	theme=UI.make_theme()
	motion_reduced=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	scene_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_scene.json"))
	assert(scene_data is Dictionary)
	state = BattleState.new(scene_data)
	if not session_data.is_empty():
		scene_data=session_data
		state=ModernBattle.new(scene_data) if scene_data.get("rules_version",2)==3 else BattleState.new(scene_data)
		state.restore(session_snapshot)
		_persist()
	else:
		state.restore(storage.read_snapshot())
	history_origin=state.history.size()
	legacy_history=state.history.duplicate()
	if state is ModernBattle and state.dungeon_enemy_r21!=null:
		if state.selected_action=='supply_menu':items_open=true
		elif state.selected_action.begins_with('item:') and state.actions().has(state.selected_action):
			items_open=true;pending_action=state.selected_action;supply_target_set=false
	resized.connect(_rebuild)
	busy=state.result.is_empty() and (not state.player_turn() or state.ally(state.current_id).charging)
	_rebuild()
	if busy: call_deferred("_resume_automatic")

func _texture(path: String) -> Texture2D:
	if not textures.has(path):
		textures[path] = load(path)
	return textures[path]

func _put(node: Control, rect: Rect2, parent: Control = self) -> Control:
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size
	if not node is Button:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _color(rect: Rect2, color: Color, parent: Control = self) -> ColorRect:
	var node = ColorRect.new()
	node.color = color
	return _put(node, rect, parent)

func _picture(path: String, rect: Rect2, parent: Control = self, pixel = false) -> TextureRect:
	var node = TextureRect.new()
	node.texture = _texture(path)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if pixel else CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return _put(node, rect, parent)

func _companion_picture(id: String, rect: Rect2, parent: Control=self) -> Control:
	var pic=CharacterSprite.new(); pic.portrait_mode=true; pic.configure(id)
	return _put(pic,rect,parent)

func _label(text: String, rect: Rect2, fs = 12, color = INK, parent: Control = self, align = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return _type(text,rect,fs,color,parent,align,font)

func _strong(text: String, rect: Rect2, fs=12, color=INK, parent: Control=self, align=HORIZONTAL_ALIGNMENT_LEFT, face: Font=W750) -> Label:
	return _type(text,rect,fs,color,parent,align,face)

func _style(bg: Color, line: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = line
	style.set_border_width_all(1)
	return style

func _button(id: String, rect: Rect2, callback: Callable, active = false, parent: Control = self, bare = false) -> Button:
	var b=Button.new(); b.name=id.replace(":","_")
	b.add_theme_stylebox_override("normal",StyleBoxEmpty.new() if bare else _style(RED if active else Color("e8e6dd"),RED if active else LINE))
	b.add_theme_stylebox_override("hover",StyleBoxEmpty.new() if bare else _style(Color("ddd7c8"),INK))
	b.add_theme_stylebox_override("pressed",_style(RED,RED))
	b.add_theme_stylebox_override("disabled",_style(Color("e1e0d8"),Color("bfc0b7")))
	var focus=_style(Color.TRANSPARENT,RED); focus.set_border_width_all(2)
	b.add_theme_stylebox_override("focus",focus)
	b.pressed.connect(callback); _put(b,rect,parent)
	var p=b.global_position
	controls[id]={"rect":[p.x,p.y,rect.size.x,rect.size.y]}
	return b

func _panel(rect: Rect2, parent: Control = self) -> Panel:
	var panel=Panel.new(); panel.add_theme_stylebox_override("panel",_style(PAPER,LINE))
	_put(panel,rect,parent); return panel

func _resource(unit: Dictionary,rect: Rect2,parent: Control,hp=true) -> Control:
	var entry=ResourceGauge.observe(resource_history,str(unit.id),unit.hp,motion_reduced) if hp else {}
	return ResourceGauge.attach(parent,rect,unit.hp if hp else unit.mp,unit.mhp if hp else unit.mmp,hp,_resource_shield(unit) if hp else 0,entry,motion_reduced,_phase_thresholds(unit) if hp else [])

func _phase_thresholds(unit: Dictionary) -> Array:
	if state is ModernBattle and state.dungeon_enemy_r21!=null:
		var rules=state.dungeon_enemy_r21.rules
		if rules.foes.get(unit.get("foe_id",""),{}).has("phase2"):return [rules.catalog.tune.boss.phase_hp]
	return []

func _resource_shield(unit: Dictionary) -> float:
	return float(unit.get("shield",unit.get("effects",{}).get("shield",{}).get("amount",0)))

func _resource_numbers(unit: Dictionary,rect: Rect2,parent: Control,hp=true,large=20) -> Control:
	return preload("res://ui/reskin_components_r24.gd").readable_resource(ResourceGauge.numbers(parent,rect,unit.hp if hp else unit.mp,unit.mhp if hp else unit.mmp,hp,_resource_shield(unit) if hp else 0,large))

func _knockout(face: Control,parent: Control,rect: Rect2) -> void:
	var material=ShaderMaterial.new();material.shader=preload("res://ui/resource_ko_r24.gdshader");face.material=material
	if face.has_method("knockout"):face.knockout()
	var stamp=Control.new();_put(stamp,rect,parent);stamp.pivot_offset=rect.size/2;stamp.rotation=deg_to_rad(-8)
	var panel=_panel(Rect2(Vector2.ZERO,rect.size),stamp);var sb=_style(Color(.96,.94,.89,.9),ResourceGauge.RED);sb.set_border_width_all(2);panel.add_theme_stylebox_override("panel",sb)
	_strong("전투 불능",Rect2(2,0,rect.size.x-4,rect.size.y),12,ResourceGauge.RED,stamp,HORIZONTAL_ALIGNMENT_CENTER,DISPLAY_PLAIN)

func _rebuild() -> void:
	if state==null or not is_inside_tree(): return
	if preview_tween: preview_tween.kill()
	for child in get_children():
		if child.has_meta("combat_sequence"): continue
		remove_child(child); child.queue_free()
	controls.clear(); text_metrics.clear(); enemy_visuals.clear(); shown_hp.clear(); layout_boxes.clear()
	var view=get_viewport_rect().size; var w=minf(view.x,430); var h=view.y
	frame=Rect2((view-Vector2(w,h))/2,Vector2(w,h))
	var x=frame.position.x; var y=frame.position.y; var delta=h-844
	_color(frame,PAPER)
	var back=_button("back",Rect2(x,y,44,41),func(): pass,false,self,true)
	back.disabled=true; back.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
	var arrow=_picture("res://assets/ui-r17/back.svg",Rect2(12,8.5,24,24),back); arrow.modulate=Color(1,1,1,.45); _mark("back",arrow)
	back.tooltip_text=_tr("전투 중에는 귀환할 수 없습니다")
	var place=_strong(_location(),Rect2(x+44,y+8.5,w-120 if _language()=="en" else minf(w-120,TIGHT.get_string_size(_location(),HORIZONTAL_ALIGNMENT_LEFT,-1,16).x),24),16,INK,self,HORIZONTAL_ALIGNMENT_LEFT,TIGHT)
	# Same font's measured 16px advance: Chromium 114.15625 / Godot 111.
	# Compensate the native shaper horizontally, including the visible glyphs.
	place.scale.x=1.0 if _language()=="en" else 114.15625/111.0; _mark("place",place)
	_label("턴",Rect2(x+w-73,y+18,46,18) if _language()=="en" else Rect2(x+w-40,y+18,15,18),12)
	_mark("turn-number",_type(str(state.turn_count),Rect2(x+w-24.2,y+2.5,12.2,36),25,INK,self,HORIZONTAL_ALIGNMENT_RIGHT,preload("res://assets/fonts/AbyssNotoBlackCondensed.ttf")))
	_queue(Rect2(x+12,y+43,w-24,44))
	_battlefield(Rect2(x,y+94,w,288+delta))
	var mode=ink_mode()
	# Wider-than-comp pages would let the edge strokes spill past the paper frame.
	var edge_clip=Control.new(); edge_clip.clip_contents=true; edge_clip.mouse_filter=Control.MOUSE_FILTER_IGNORE; _put(edge_clip,frame,self)
	# Comp strokes are drawn for a 390px frame; follow the real frame width.
	_ink(Rect2(0,352+delta,w,76),"edge-"+mode,PAPER,edge_clip)
	if mode=="base": _ink(Rect2(0,351+delta,w*264.0/390.0,69),"base",INK,edge_clip)
	var a=state.ally(state.current_id)
	var title=a.name+"의 차례" if not a.is_empty() else state.enemy(state.current_id).name+" 행동 중"
	var heading_width=minf(w-24,DISPLAY.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,38).x+4)
	var heading_paper=_color(Rect2(x+12,y+382.046875+delta,heading_width,46.890625),PAPER); heading_paper.z_index=3
	var heading=_display(title,Rect2(x+12,y+382+delta,heading_width,47),38); heading.z_index=3; _mark("actor-heading",heading)
	_color(Rect2(x+12,y+427+delta,49,3),RED)
	if not items_open and not skills_open and not log_open and ally_open.is_empty():
		_detail(Rect2(x+12,y+438+delta,w-24,59))
		_commands(Rect2(x+12,y+506+delta,w-24,170))
	var sheet=Rect2(x,y+430+delta,w,245)
	if items_open: _supplies(sheet)
	if skills_open: _skills(sheet)
	if not ally_open.is_empty(): _ally_sheet(sheet)
	if log_open: _log_sheet(sheet)
	if not items_open and not skills_open and not log_open and ally_open.is_empty(): sheet_kind=""
	_party(Rect2(x+12,y+h-159,w-24,150))
	if not pending_action.is_empty() and not state is ModernBattle: _confirm_sheet(Rect2(x+12,y+430+delta,w-24,245))
	if not state.result.is_empty() and not busy: _result_sheet(Rect2(x+12,y+200,w-24,245))
	call_deferred("_publish_metrics")
	call_deferred("_refresh_ink")

func _queue(rect: Rect2) -> void:
	var col=(rect.size.x-35)/8
	for i in range(8):
		var pos=rect.position+Vector2(i*(col+5),0)
		var slot=_panel(Rect2(pos,Vector2(col,42)))
		slot.add_theme_stylebox_override("panel",_style(Color("f7f1e6") if i==0 else Color("e7e2d6"),RED if i==0 else LINE))
		if i!=0:
			var sb=slot.get_theme_stylebox("panel").duplicate(); sb.set_border_width_all(0); sb.border_width_bottom=1; slot.add_theme_stylebox_override("panel",sb)
		if i==0:
			var sb=slot.get_theme_stylebox("panel").duplicate(); sb.set_border_width_all(2); slot.add_theme_stylebox_override("panel",sb)
		if i<state.data.queue.size():
			var id=state.data.queue[i]; var a=state.ally(id)
			if not a.is_empty():
				var pic=CharacterSprite.new(); pic.configure(id); _put(pic,Rect2(3,2,col-6,34),slot)
			else:
				var e=state.enemy(id)
				if not e.is_empty(): _enemy_art(e,Rect2(3,2,col-6,35),slot)
		var number_width=9.2 if i==0 else 8.84
		_color(Rect2(col-number_width-1,28,number_width,14),PAPER,slot)
		_mark("queue-number:"+str(i),_label(str(i+1),Rect2(col-number_width-1,28,number_width,14),12,RED if i==0 else Color("303a34"),slot,HORIZONTAL_ALIGNMENT_CENTER))
		_mark("queue-slot:"+str(i),slot)

func _battlefield(rect: Rect2) -> void:
	var field=Control.new(); field.clip_contents=true; _put(field,rect); _mark("battle",field)
	field_visual=field; field_home=field.position
	var back=_picture("res://assets/src/academy.png",Rect2(Vector2.ZERO,rect.size),field); field_back=back
	var material=ShaderMaterial.new(); material.shader=preload("res://assets/ui-r17/print.gdshader"); back.material=material
	# Only the bottom ~23px of the 288px mask is cut; keep its height and anchor it
	# to the field bottom so short fields do not squash the torn edge.
	_ink(Rect2(0,rect.size.y-288,rect.size.x,288),"mask-"+ink_mode(),PAPER,field)
	var enemies=state.data.enemies.filter(func(e): return e.hp>0)
	var small=enemies.filter(func(e): return e.id!="executor")
	var order={"lantern":0,"apprentice":1,"orb":2}
	small.sort_custom(func(a,b): return order.get(a.id,3)<order.get(b.id,3))
	var sx=rect.size.x/390.0; var sy=rect.size.y/288.0
	# The number font needs its full line box; the old 13px row was painted over.
	var hud_h=48.0
	var has_big=enemies.any(func(e):return e.id=="executor")
	# On shorter fields the top row ends before the boss sprite starts.
	var small_h=clampf(49*sy-1,38,hud_h) if has_big and not small.is_empty() else hud_h
	var targeting=not pending_action.is_empty() and state.actions().has(pending_action) and state.actions()[pending_action].target=="적 1"
	if targeting:
		_ink(Rect2(240*sx,175*sy,150*sx,71*sy),"target-bloom",RED,field)
	var positions={"lantern":Rect2(45,14,46,72),"apprentice":Rect2(167,13,52,75),"orb":Rect2(309,20,43,69),"executor":Rect2(270,141,98,103)}
	for e in enemies:
		var big=e.id=="executor"; var index=small.find(e)
		var hud_w=119.0*sx if big else minf(112.0*sx,rect.size.x/maxi(1,small.size())-10)
		var left=259*sx if big else ([9.0,139.0,270.0][index]*sx if small.size()==3 else (index+.5)*rect.size.x/small.size()-hud_w/2)
		var hit_w=hud_w
		var hud_y=92*sy
		var plate_h=hud_h if big else small_h
		var hud_x=0.0
		if big:
			if small.is_empty():
				# Above the lone boss, including the short 390x664 battlefield.
				hud_y=maxf(0,141*sy-hud_h-4)
			else:
				# The gap between the actor and boss leaves both sprites unobscured.
				hit_w+=(259-169)*sx
				left=169*sx
				hud_w=95*sx
				hud_y=maxf(141*sy,92*sy+small_h+4)
		var hit_top=128*sy if big else 0.0
		if big and not small.is_empty(): hit_top=maxf(hit_top,92*sy+small_h)
		# Include a raised plate in the same enemy selection target.
		if big:hit_top=minf(hit_top,hud_y)
		var hit_h=rect.size.y-hit_top if big else maxf(44,hud_y+plate_h)
		# Source encounters have up to seven distinct enemies, not the old
		# three back-row roles. Keep every plate above its own visible sprite.
		var source_grid=state.data.has("encounter_r21")
		var source_body=Rect2()
		if source_grid:
			var count=enemies.size();var at=enemies.find(e);var top_count=mini(count,4 if count>=6 else 3)
			var lower=at>=top_count;var row_count=count-top_count if lower else top_count
			var j=at-top_count if lower else at
			var area_x=180.0*sx if lower else 4.0*sx
			var area_w=rect.size.x-area_x-4*sx
			hud_w=minf(112*sx,area_w/row_count-5*sx);hit_w=hud_w
			left=area_x+(j+.5)*area_w/row_count-hud_w/2
			hud_y=maxf(124*sy,64+75*sy) if lower else 3.0
			plate_h=48;hit_top=hud_y
			var art_y=hud_y+plate_h+5
			var art_h=minf(75*sy,rect.size.y-art_y-24)
			source_body=Rect2(0,art_y-hit_top,hud_w,art_h)
			hit_h=art_y+art_h-hit_top;hud_x=0
		var hit=_button("enemy:"+e.id,Rect2(left,hit_top,hit_w,hit_h),_enemy_pressed.bind(e.id),false,field,true)
		var body: Rect2=positions.get(e.id,Rect2(45,14,46,72))
		body=Rect2(body.position*Vector2(sx,sy)-Vector2(left,hit_top),body.size*Vector2(sx,sy))
		if not big and small.size()!=3: body.position.x=(hud_w-body.size.x)/2
		if source_grid:body=source_body
		if targeting and state.selected_enemy==e.id:
			var target_rect=Rect2(-6,141*sy-hit_top,hit_w+12,111*sy) if big else Rect2(body.position-Vector2(6,0),body.size+Vector2(12,8))
			var outline_rect=Rect2(253*sx-left,141*sy-hit_top,126,110) if big else target_rect
			if source_grid:outline_rect=Rect2(body.position-Vector2(3,3),body.size+Vector2(6,6))
			var outline=_picture("res://assets/ui-r20/target-outline.svg",outline_rect,hit)
			outline.z_as_relative=false; outline.z_index=4
		var art=_enemy_art(e,body,hit,false); art.z_as_relative=false; art.z_index=3; _mark("enemy-art:"+e.id,art)
		enemy_visuals[e.id]={"node":art,"home":art.position}; shown_hp[e.id]=e.hp
		var hud=_color(Rect2(hud_x,hud_y-hit_top,hud_w,plate_h),PAPER,hit); _mark("enemy-hud:"+e.id,hud)
		hud.z_as_relative=false; hud.z_index=25; enemy_visuals[e.id]["hud"]=hud
		var phased=not _phase_thresholds(e).is_empty()
		_enemy_name(e.name,Rect2(3,0,hud_w-6-(30 if phased else 0),13),hud)
		if phased:_strong("%d단계"%int(e.get("phase",1)),Rect2(hud_w-32,0,29,13),10,ResourceGauge.RED,hud,HORIZONTAL_ALIGNMENT_RIGHT)
		var compact=plate_h<hud_h
		var number_y=25.0 if compact else 27.0
		_resource(e,Rect2(3,14 if compact else 16,hud_w-6,9),hud)
		var numbers=_resource_numbers(e,Rect2(3,number_y,hud_w-6,plate_h-number_y),hud,true,mini(16,int(plate_h-number_y)))
		if compact:
			# Match _type's tight line box without clipping or vertically scaling glyphs.
			for label in numbers.get_children():
				var face=label.get_theme_font("font");var fs=label.get_theme_font_size("font_size")
				var excess=maxi(0,ceili(face.get_height(fs)-numbers.size.y))
				if excess>0:
					var tight=FontVariation.new();tight.base_font=face;tight.spacing_top=-ceili(excess/2.0);tight.spacing_bottom=-floori(excess/2.0)
					label.add_theme_font_override("font",tight);label.size.y=numbers.size.y
		if big:
			var diamond=Polygon2D.new(); diamond.polygon=PackedVector2Array([Vector2(0,-5.66),Vector2(5.66,0),Vector2(0,5.66),Vector2(-5.66,0)])
			diamond.color=RED if targeting else PAPER; hit.add_child(diamond); diamond.position=Vector2(317*sx-left,132*sy-hit_top); diamond.z_index=26
			if targeting:
				# Keep the whole marker 4px clear of the expanded HP plate.
				# A plate at the field's top has no room above; use its left margin.
				diamond.position=Vector2(hud_x+hud_w/2,hud_y-hit_top-9.66) if small.is_empty() and hud_y>=15.32 else Vector2(hud_x-9.66,hud_y-hit_top+plate_h/2)
			if source_grid:diamond.position=Vector2(hud_w-8,plate_h+10)
	if not pending_action.is_empty() and state.actions().has(pending_action) and state.actions()[pending_action].target=="적 1":
		var caption_y=maxf(131*sy,92*sy+small_h+4)
		if has_big and not small.is_empty():caption_y=maxf(141*sy,92*sy+small_h+4)+hud_h+4
		if state.data.has("encounter_r21"):caption_y=rect.size.y-23
		var caption=_color(Rect2(136*sx,minf(caption_y,rect.size.y-23),130,23),PAPER,field); caption.z_index=26
		_mark("target-instruction",_label("공격할 적을 선택하세요",Rect2(6,3,118,17),12,INK,caption))
	actor=CharacterSprite.new(); actor.battle_pixels=false; actor.idle_enabled=false; _actor_texture(false)
	var teiris=actor.character_id=="teiris"
	var actor_rect=Rect2(27 if teiris else 37,137 if teiris else 138,145 if teiris else 127,146 if teiris else 145)
	actor_rect=Rect2(actor_rect.position*Vector2(sx,sy),actor_rect.size*Vector2(sx,sy))
	_put(actor,actor_rect,field); actor.z_as_relative=false; actor.z_index=3; _mark("actor",actor)
	controls["field"]={"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}

func _actor_texture(attack: bool) -> void:
	var id=animation_ally if not animation_ally.is_empty() else state.current_id if state.player_turn() else state.last_ally
	var a=state.ally(id)
	if not a.is_empty(): actor.configure(a.id,attack)

func _party(rect: Rect2) -> void:
	_color(Rect2(rect.position,Vector2(rect.size.x,2)),INK)
	var col=(rect.size.x-18)/4
	for i in range(state.data.allies.size()):
		var a=state.data.allies[i]; shown_hp[a.id]=a.hp
		var b=_button("ally:"+a.id,Rect2(rect.position+Vector2(i*(col+6),9),Vector2(col,141)),_ally_pressed.bind(a.id),false,self,true); _mark("party-card:"+a.id,b)
		var face=preload("res://ui/portrait_slot_r24.gd").make(a.id,"battle-party",Vector2(col,51)); _put(face,Rect2(0,0,col,51),b); _mark("face:"+a.id,face)
		
		if a.id==state.current_id or a.id==ally_open or (items_open and supply_target_set and a.id==state.selected_ally):
			var border=_panel(Rect2(0,0,col,51),b); var sb=_style(Color.TRANSPARENT,RED); sb.set_border_width_all(2); border.add_theme_stylebox_override("panel",sb)
		_strong(a.name,Rect2(0,51,col-(28 if a.id==state.current_id else 0),17),12,INK,b,HORIZONTAL_ALIGNMENT_LEFT,TIGHT)
		if a.id==state.current_id:_strong("차례",Rect2(col-28,51,28,17),12,ResourceGauge.RED,b,HORIZONTAL_ALIGNMENT_RIGHT,W850)
		_label(a.row,Rect2(0,68,col*.5,17),12,Color("575f55"),b)
		_strong("선택" if a.id==ally_open or (items_open and supply_target_set and a.id==state.selected_ally) else "",Rect2(col*.5,68,col*.5,17),12,Color("b52816"),b,HORIZONTAL_ALIGNMENT_RIGHT,W850)
		if a.hp<=0:_knockout(face,b,Rect2(4,17,col-8,22))
		_resource_numbers(a,Rect2(0,85,col,22),b)
		_resource(a,Rect2(0,107,col,9),b)
		_resource(a,Rect2(0,119,col,3),b,false)
		_resource_numbers(a,Rect2(0,123,col,17),b,false,15)

func _detail(rect: Rect2) -> void:
	var e=state.enemy(state.selected_enemy)
	if e.is_empty(): return
	_color(Rect2(rect.position,Vector2(rect.size.x,1)),LINE)
	if state.data.has("encounter_r21"):
		_enemy_name(e.name+" · "+e.role,Rect2(rect.position+Vector2(0,6),Vector2(rect.size.x-100,17)),self,HORIZONTAL_ALIGNMENT_LEFT)
	else: _strong(e.name,Rect2(rect.position+Vector2(0,6),Vector2(rect.size.x-100,17)),12)
	_resource_numbers(e,Rect2(rect.position+Vector2(rect.size.x-100,2),Vector2(100,21)),self)
	_resource(e,Rect2(rect.position+Vector2(rect.size.x-100,25),Vector2(100,9)),self)
	var weak=[]
	for element in e.get("weak",[]): weak.append(state.data.elements.get(element,element))
	if not weak.is_empty(): _label("약점 "+" · ".join(weak),Rect2(rect.position+Vector2(0,22),Vector2(rect.size.x-112,17)),12)
	if e.has("gauge"): _label("심연 %s/%d" % [str(int(e.gauge)),e.max],Rect2(rect.position+Vector2(rect.size.x-112,36),Vector2(112,17)),12,INK,self,HORIZONTAL_ALIGNMENT_RIGHT)
	var intent=state.intent(e).split(" / ")[0].split(" · 심연")[0]
	_label(intent,Rect2(rect.position+Vector2(0,40),Vector2(rect.size.x-115 if e.has("gauge") else rect.size.x,17)),12)

func _commands(rect: Rect2) -> void:
	var ready=state.player_turn() and not busy
	var ids=state.actions().keys().filter(func(id): return not id.begins_with("item:")) if ready else []
	# Keep the source's visual ordering without mutating model action dictionaries.
	if "taunt" in ids and "guard" in ids:
		ids.erase("taunt"); ids.insert(1,"taunt")
	var col=(rect.size.x-7)/2
	for i in range(mini(ids.size(),4)):
		var id=ids[i]; var sk=state.actions()[id]; var reason=_reason(id)
		var overflow=i==3 and ids.size()>4
		if overflow: reason="" # Navigation stays available when that skill is unavailable.
		var active=(pending_action==id or (pending_action.is_empty() and id=="attack")) and reason.is_empty()
		var b=_button("action:"+id,Rect2(rect.position+Vector2((i%2)*(col+7),int(i/2)*63),Vector2(col,56)),_toggle_skills if overflow else _action_pressed.bind(id),active); _mark("action:"+str(i),b)
		for key in ["normal","disabled"]:
			var style=b.get_theme_stylebox(key).duplicate(); style.set_border_width_all(0); style.border_width_bottom=1; b.add_theme_stylebox_override(key,style)
		# An unaffordable card remains tappable to explain the reason in the sheet.
		b.disabled=(not reason.is_empty() and reason.begins_with("마나")==false) or (not pending_action.is_empty() and pending_action!=id)
		if not reason.is_empty() and not b.disabled: b.add_theme_stylebox_override("normal",_style(Color("e1e0d8"),Color("bfc0b7")))
		var color=Color.WHITE if active else Color("686d65") if b.disabled or not reason.is_empty() else INK
		var title=_tr(sk.name.split("(")[0].strip_edges())
		if overflow: title="기술 선택"
		var icon="sword" if id=="attack" else "shield" if id in ["taunt","guard"] else "snow" if state.ally(state.current_id).element=="ice" else "element-"+state.ally(state.current_id).element
		var pic=_picture("res://assets/ui-r17/"+icon+".svg",Rect2(9,15,22,25),b); pic.modulate=color
		var fs=19 if DISPLAY.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x>col-50 else 22
		_display(title,Rect2(41,0 if fs==22 else 2.5,col-47,32 if fs==22 else 27),fs,color,b)
		var mp=state.cost(id) if state is ModernBattle else sk.mp
		var cost_text="MP %d" % mp; var a=state.ally(state.current_id)
		if state is ModernBattle and (id=="blood" or (id=="personal" and a.id in ["tika","levia"])): cost_text="HP %d" % state.hp_cost(a,id)
		_label("기술 %d개"%_skill_ids().size() if overflow else cost_text+" · "+sk.target,Rect2(41,31 if fs==22 else 29.5,col-47,19),12,color,b)
		b.tooltip_text=_tr(reason if not reason.is_empty() else sk.note)
	if busy:
		var skip=_button("skip-motion",Rect2(rect.position,Vector2(rect.size.x,56)),_skip_motion)
		_label("연출 건너뛰기",Rect2(10,0,rect.size.x-20,56),14,INK,skip,HORIZONTAL_ALIGNMENT_CENTER)
	var pos=rect.position+Vector2(0,126)
	if not pending_action.is_empty():
		var action_name=state.actions().get(pending_action,{}).get("name","").split("(")[0].strip_edges()
		var target_text=state.actions().get(pending_action,{}).get("target","")
		_strong(action_name+" · "+target_text.replace("적 1","적 1명").replace("아군 1","아군 1명")+" 선택",Rect2(pos,Vector2(rect.size.x-128,44)),12)
		var cancel=_button("cancel-action",Rect2(pos+Vector2(rect.size.x-120,0),Vector2(120,44)),_close_sheets); _outline(cancel)
		_strong("취소",Rect2(0,0,120,44),14,INK,cancel,HORIZONTAL_ALIGNMENT_CENTER,BODY_BOLD)
	else:
		var utility_col=(rect.size.x-8)/2
		for i in range(2):
			var id="supplies" if i==0 else "log"
			var b=_button(id,Rect2(pos+Vector2(i*(utility_col+8),0),Vector2(utility_col,44)),_toggle_supplies if i==0 else _toggle_log); _outline(b); _mark(id,b)
			b.disabled=not ready or (i==0 and not state is ModernBattle)
			var source_label=''
			if i==0 and state is ModernBattle and state.dungeon_enemy_r21!=null:
				var view=state.CombatItems.button(state.source_item_bag(),_language()).buttons[0]
				b.disabled=b.disabled or not view.enabled;b.tooltip_text=view.description;source_label=view.label
			var text=source_label if not source_label.is_empty() else _tr("보급품" if i==0 else "전투 기록"); var tw=BODY_BOLD.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
			var left=(utility_col-tw-29)/2
			_picture("res://assets/ui-r17/"+("bag" if i==0 else "log")+".svg",Rect2(left,11,19,22),b)
			_strong(text,Rect2(left+29,0,tw+1,44),14,INK,b,HORIZONTAL_ALIGNMENT_LEFT,BODY_BOLD)

func _skill_ids() -> Array:
	var ids=state.actions().keys().filter(func(id): return not id.begins_with("item:"))
	return ids.filter(func(id): return id!="attack" and (id!="guard" or ids.size()>4))

func _skills(rect: Rect2) -> void:
	var p=_sheet(rect,"기술 선택","skills"); var a=state.ally(state.current_id)
	_strong("MP %d/%d" % [a.mp,a.mmp],Rect2(rect.size.x-104,0,92,49),14,INK,p,HORIZONTAL_ALIGNMENT_RIGHT,W850)
	var scroll=ScrollContainer.new(); _put(scroll,Rect2(12,49,rect.size.x-24,145),p); scroll.mouse_filter=Control.MOUSE_FILTER_STOP
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list=VBoxContainer.new(); list.add_theme_constant_override("separation",7); scroll.add_child(list); list.size_flags_horizontal=SIZE_EXPAND_FILL
	for id in _skill_ids():
		var sk=state.actions()[id]; var reason=_reason(id); var width=rect.size.x-24
		var b=_button("skill:"+id,Rect2(0,0,width,69),_action_pressed.bind(id),false,list)
		b.custom_minimum_size=Vector2(width,69); b.disabled=not reason.is_empty()
		var tint=Color("596057") if b.disabled else INK
		_display(sk.name.split("(")[0].strip_edges(),Rect2(10,7,width-20,23),21,tint,b)
		var suffix=" · %d턴 충전"%int(sk.get("turns",0)) if id=="burst" else " · 전투당 1회" if id=="personal" and a.id=="teiris" else ""
		_label("MP %d · %s%s" % [state.cost(id) if state is ModernBattle else sk.mp,sk.target,suffix],Rect2(10,30,width-20,17),12,tint,b)
		_label(reason,Rect2(10,47,width-20,16),12,tint,b)
	var cancel=_button("cancel-action",Rect2(12,203,rect.size.x-24,44),_close_sheets,false,p); _outline(cancel)
	_strong("취소",Rect2(0,0,rect.size.x-24,44),14,INK,cancel,HORIZONTAL_ALIGNMENT_CENTER,BODY_BOLD)

func _summary(id: String) -> String:
	var summaries={"attack":"선택한 적 1명에게 일반 공격","guard":"자신 · 피해 -40%% · %d턴" % state.actions().guard.turns,"taunt":"자신 · 도발 2턴 · 위압으로 심연 20","duty":"자신 도발·피해 -25% · HP 최저 적 심연 15","burst":"적 전체 ×1.9 · 충전 · 행동 간격 2배","hshield":"아군 전체 · 보호막 18 · 2턴","bless":"아군 전체 · 공격·방어 +15% · 3턴","personal":"적 전체 ×1.9 · 즉시 · 전투당 1회"}
	return summaries.get(id,"")

func _wrap(message: String,width: float,fs: int) -> String:
	message=_tr(message)
	var lines=[]; var line=""
	for word in message.split(" "):
		if font.get_string_size(line+" "+word,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>width and not line.is_empty():
			lines.append(line); line=word
		else: line=word if line.is_empty() else line+" "+word
	if not line.is_empty(): lines.append(line)
	return "\n".join(lines)

func _confirm_sheet(rect: Rect2) -> void:
	var skill=state.actions()[pending_action]
	var panel=_panel(rect)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	_label("%s · MP %d" % [skill.name,skill.mp],Rect2(10,6,rect.size.x-20,26),15,GOLD,panel)
	_label(_wrap(_summary(pending_action),rect.size.x-20,12),Rect2(10,34,rect.size.x-20,38),12,INK,panel)
	var target=state.enemy(state.selected_enemy).name if skill.target=="적 1" else skill.target
	if pending_action in ["taunt","duty"]: target="자신 / 위압: "+state.intimidation_target(pending_action).short
	_label("대상: "+target,Rect2(10,75,rect.size.x-20,24),13,GOLD,panel)
	var col=(rect.size.x-26)/2
	for i in range(2):
		var id="confirm" if i==1 else "cancel"
		var button=_button(id,Rect2(8+i*(col+10),106,col,48),_commit if i==1 else _close_sheets,i==1,panel)
		_label("실행" if i==1 else "취소",Rect2(0,0,col,48),15,INK,button,HORIZONTAL_ALIGNMENT_CENTER)
		controls[id].rect=[rect.position.x+8+i*(col+10),rect.position.y+106,col,48]

func _toggle_log() -> void:
	if busy: return
	log_open=not log_open; skills_open=false; items_open=false; ally_open=""; pending_action=""; _rebuild()

func _log_sheet(rect: Rect2) -> void:
	var p=_sheet(rect,log_title,"log")
	var scroll=ScrollContainer.new(); _put(scroll,Rect2(12,51,rect.size.x-24,183),p)
	scroll.mouse_filter=Control.MOUSE_FILTER_STOP; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list=VBoxContainer.new(); list.add_theme_constant_override("separation",0); scroll.add_child(list); list.size_flags_horizontal=SIZE_EXPAND_FILL
	var width=rect.size.x-24
	# The model has prose events only. Keep restored old events, then show new
	# UI journal entries with their original turn and actor, in chronological order.
	for i in range(legacy_history.size()):
		var row=Control.new(); row.custom_minimum_size=Vector2(width,61); list.add_child(row)
		_label(_wrap(legacy_history[i],width-8,12),Rect2(0,0,width,60),12,INK,row)
		_color(Rect2(0,60,width,1),LINE,row)
	for entry in display_history:
		var row=Control.new(); row.custom_minimum_size=Vector2(width,61); list.add_child(row)
		_label("턴 "+str(entry.turn),Rect2(0,0,35,60),12,INK,row)
		_color(Rect2(44,8,39,45),Color("e4dfd1"),row)
		if not state.ally(entry.actor).is_empty():
			var face=preload("res://ui/portrait_slot_r24.gd").make(entry.actor,"battle-log",Vector2(39,45)); _put(face,Rect2(44,8,39,45),row)
		elif not state.enemy(entry.actor).is_empty(): _enemy_art(state.enemy(entry.actor),Rect2(44,8,39,45),row)
		_strong(_tr(entry.name),Rect2(94,10,width-100,18),12,INK,row,HORIZONTAL_ALIGNMENT_LEFT,W850)
		_label(_tr(entry.action),Rect2(94,28,width-100,22),14,INK,row)
		_color(Rect2(0,60,width,1),LINE,row)
	if history_origin==0 and display_history.is_empty(): _label("아직 실행한 행동이 없습니다.",Rect2(12,51,width,44),12,INK,p)
	scroll.get_v_scroll_bar().value_changed.connect(func(_value): _refresh_ink())

func _result_sheet(rect: Rect2) -> void:
	var panel=_panel(rect)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	_label("전투 승리" if state.result=="victory" else "전투 패배",Rect2(8,15,rect.size.x-16,42),24,GOLD,panel,HORIZONTAL_ALIGNMENT_CENTER)
	_label("적을 모두 쓰러뜨렸습니다." if state.result=="victory" else "부상으로 전투에서 이탈했습니다.",Rect2(8,64,rect.size.x-16,32),13,INK,panel,HORIZONTAL_ALIGNMENT_CENTER)
	var button=_button("retry",Rect2(14,152,rect.size.x-28,52),_retry,true,panel)
	_label(("원정으로" if state.result=="victory" else "정산으로") if session_save.is_valid() else "다시 전투",Rect2(0,0,rect.size.x-28,52),16,INK,button,HORIZONTAL_ALIGNMENT_CENTER)
	controls.retry.rect=[rect.position.x+14,rect.position.y+152,rect.size.x-28,52]

func _close_button(rect: Rect2, parent: Control) -> void:
	var b=_button("close",rect,_close_sheets,false,parent,true)
	_strong("닫기",Rect2(0,0,32,44),12,INK,b,HORIZONTAL_ALIGNMENT_LEFT,BODY_BOLD)
	_picture("res://assets/ui-r17/close.svg",Rect2(40,14,16,16),b)

func _ally_sheet(rect: Rect2) -> void:
	var a=state.ally(ally_open); var p=_sheet(rect,a.name,"status")
	var status_portrait=preload("res://ui/portrait_slot_r24.gd").make(a.id,"battle-status",Vector2(153,192))
	_put(status_portrait,Rect2(7,52,153,192),p);_mark("status-portrait",status_portrait)
	if a.hp<=0:_knockout(status_portrait,p,Rect2(24,119,117,27))

	var x=174.0; var width=rect.size.x-x-12
	_label(a.row+" · "+a.cls,Rect2(x,57,width,20),14,INK,p)
	for j in range(2):
		var yy=93+j*53
		var value=_resource_numbers(a,Rect2(x,yy,width,31),p,j==0,28)
		_mark("status-value:"+str(j),value)
		_resource(a,Rect2(x,yy+34,width,9 if j==0 else 3),p,j==0)

	_color(Rect2(x,199,width,1),LINE,p)
	var effects=state.effects_text(a)
	_label("상태 효과 없음" if a.effects.is_empty() else _wrap(effects,width,12),Rect2(x,210,width,20),13,INK,p)

func _enemy_pressed(id: String) -> void:
	if busy: return
	state.choose_enemy(id)
	if state is ModernBattle and not pending_action.is_empty() and state.actions()[pending_action].target=="적 1": _commit(); return
	_persist(); _rebuild()

func _ally_pressed(id: String) -> void:
	if busy: return
	if items_open:
		if state is ModernBattle and state.choose_ally(id): supply_target_set=true
		_rebuild(); return
	if state is ModernBattle and not pending_action.is_empty() and state.actions()[pending_action].target=="아군 1":
		if state.choose_ally(id): _commit()
		return
	ally_open=id; skills_open=false; log_open=false; _rebuild()

func _action_pressed(id: String) -> void:
	if busy or not state.player_turn(): return
	if not state.unavailable(id).is_empty():
		if _reason(id).begins_with("마나"): skills_open=true; items_open=false; log_open=false; ally_open=""; pending_action=""; _rebuild()
		return
	state.choose_action(id); pending_action=id; skills_open=false; ally_open=""
	if state is ModernBattle and (state.actions()[id].target not in ["적 1","아군 1"]): _commit()
	else: _rebuild()

func _close_sheets() -> void:
	if busy: return
	if items_open and state is ModernBattle:state.selected_action='attack'
	skills_open=false; items_open=false; ally_open=""; pending_action=""; log_open=false; _rebuild()
	_persist()

func _capture_visual_before() -> Dictionary:
	var before={}
	for unit in state.data.allies+state.data.enemies:
		before[unit.id]={"hp":unit.hp,"shield":unit.get("shield",0),"gauge":unit.get("gauge",0),"effects":unit.effects.duplicate(true)}
	return before

func _commit() -> void:
	if busy or pending_action.is_empty(): return
	var id=pending_action
	var before=_capture_visual_before()
	var journal_turn=state.turn_count
	animation_ally=state.current_id
	presenting_source=animation_ally
	# Build the old visual state before resolving once. No post-action HP leak.
	pending_action=""; skills_open=false; items_open=false; ally_open=""; busy=true
	_rebuild()
	if not state.act(id):
		busy=false; _rebuild(); return
	_journal(animation_ally,id,journal_turn)
	_persist()
	await _present_action(before,animation_ally,id)
	_resume_automatic(0.08)

func _present_action(before: Dictionary, source: String, action_id: String) -> void:
	motion_serial+=1
	var current=CombatPresentation.new()
	motion=current
	current.sequence_id=motion_serial
	current.character_id=source
	current.action=action_id
	current.language_r22=_language()
	if source=="persona":
		current.signature_art={"name":state.ally(source).name,"skill":_tr(state.ally(source).skills.get(action_id,{}).get("name","")),"element":"none"}
	current.reduced=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	motion_reduced=current.reduced
	current.enemy_action=state.ally(source).is_empty()
	var r=controls.field.rect
	current.field=Rect2(r[0],r[1],r[2],r[3])
	if current.enemy_action:
		var enemy=state.enemy(source)
		if enemy_visuals.has(source):
			var visual=enemy_visuals[source].node
			current.source_rect=Rect2(visual.global_position,visual.size)
			current.source_image=visual.texture
		else: current.source_rect=current.field
	else:
		current.source_rect=Rect2(actor.global_position,actor.size)
		current.element=state.ally(source).element
		current.tint=CombatFX.color_for(current.element)
	motion_hurt_ids=[]
	var source_ally=state.ally(source)
	var target_friendly=current.enemy_action or not source_ally.get("skills",{}).get(action_id,{}).get("target","적").begins_with("적")
	for unit in state.data.allies+state.data.enemies:
		var old=before[unit.id]
		var hurt=unit.hp<old.hp or unit.get("shield",0)<old.shield
		var changed=hurt or unit.hp!=old.hp or unit.effects!=old.effects or unit.get("gauge",0)!=old.gauge or unit.get("shield",0)!=old.shield
		var ally_unit=not state.ally(unit.id).is_empty()
		var key=("ally:" if ally_unit else "enemy:")+unit.id
		if not changed or not controls.has(key): continue
		var rect=controls[key].rect
		var target=Rect2(actor.global_position,actor.size) if ally_unit else Rect2(enemy_visuals[unit.id].node.global_position,enemy_visuals[unit.id].node.size)
		# Secondary intimidation/passive changes must not put an ally's shield
		# on an enemy. All visible allies share the one foreground body.
		if ally_unit==target_friendly and target not in current.targets: current.targets.append(target)
		if hurt and ally_unit==current.enemy_action:
			current.hurt_targets.append(target)
			motion_hurt_ids.append(unit.id)
	current.damaging=not current.hurt_targets.is_empty()
	current.impact.connect(_motion_impact.bind(before,source,action_id))
	current.on_visual_update=_motion_visuals
	add_child(current)
	_motion_visuals(current)
	call_deferred("_publish_metrics")
	await current.finished
	motion=null
	_rebuild()

func _motion_impact(before: Dictionary, source: String, action_id: String) -> void:
	_rebuild()
	_effect_feedback(before,source,action_id)
	if is_instance_valid(motion): _motion_visuals(motion)

func _motion_visuals(current) -> void:
	if is_instance_valid(actor): actor.visible=current==null or current.enemy_action
	if is_instance_valid(actor): actor.material=current.hit_material if current!=null and current.enemy_action and current.hit_flash() else null
	if is_instance_valid(field_back): field_back.position=current.shake_offset() if current!=null else Vector2.ZERO
	for id in enemy_visuals:
		var visual=enemy_visuals[id].node
		if not is_instance_valid(visual): continue
		enemy_visuals[id].hud.visible=current==null or not is_instance_valid(current.signature) or current.clock.elapsed>=current.clip_start or current.reduced
		visual.visible=current==null or not (current.enemy_action and current.character_id==id)
		visual.position=enemy_visuals[id].home
		if current!=null: visual.position+=current.shake_offset()
		visual.modulate=Color.WHITE
		if current!=null and id in motion_hurt_ids and current.clock.impacted:
			visual.position+=current.reaction_offset()
			visual.material=current.hit_material if current.hit_flash() else null
		else: visual.material=null

func _skip_motion() -> void:
	if is_instance_valid(motion): motion.skip()

func _resume_automatic(initial_delay=0.08) -> void:
	busy=true; playback_generation+=1
	call_deferred("_publish_metrics")
	var generation=playback_generation
	await get_tree().create_timer(initial_delay).timeout
	if generation!=playback_generation: return
	animation_ally=""
	while state.result.is_empty() and (not state.player_turn() or state.ally(state.current_id).charging):
		var before=_capture_visual_before()
		var source=state.current_id
		presenting_source=source
		_rebuild()
		var journal_turn=state.turn_count
		var enemy=state.enemy(source)
		var action_name=state.intent(enemy).split(" / ")[0] if not enemy.is_empty() else "마력 폭발"
		state.automatic_turn(); _journal(source,"enemy" if not enemy.is_empty() else "burst",journal_turn)
		display_history[-1].action=action_name
		_persist()
		await _present_action(before,source,"enemy" if state.ally(source).is_empty() else "burst")
		if generation!=playback_generation: return
	busy=false; _rebuild()

func _retry() -> void:
	if session_save.is_valid():
		session_finished.emit()
		return
	playback_generation+=1; state=ModernBattle.new(scene_data) if scene_data.get("rules_version",2)==3 else BattleState.new(scene_data)
	busy=false; pending_action=""; animation_ally=""; skills_open=false; ally_open=""; log_open=false
	resource_history.clear(); display_history.clear(); legacy_history.clear(); history_origin=0
	_persist(); _rebuild()

func _preview(id: String) -> void:
	var initial = actor.position
	preview_tween=create_tween()
	motion_reduced=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true))
	if motion_reduced:
		if id!="guard":
			_actor_texture(true)
		preview_tween.tween_interval(0.72)
		preview_tween.tween_callback(_actor_texture.bind(false))
		call_deferred("_publish_metrics")
		return
	if id!="guard":
		_actor_texture(true)
		var step = Vector2(34,-8) if id=="attack" else Vector2(16,-4)
		preview_tween.tween_property(actor,"position",initial+step,0.2)
		preview_tween.tween_interval(0.26)
		preview_tween.tween_property(actor,"position",initial,0.26)
	else:
		preview_tween.tween_property(actor,"position",initial+Vector2(0,4),0.2)
		preview_tween.tween_property(actor,"position",initial,0.34)
	preview_tween.tween_callback(_actor_texture.bind(false))
	call_deferred("_publish_metrics")

func _persist() -> void:
	storage_error=session_save.call(state.snapshot()) if session_save.is_valid() else storage.write_snapshot(state.snapshot())

func _publish_metrics() -> void:
	if not is_inside_tree(): return
	for key in controls:
		var node=find_child(str(key).replace(":","_"),true,false)
		if node is Button: controls[key].rect=[node.global_position.x,node.global_position.y,node.size.x,node.size.y]
	if not OS.has_feature("web"):
		return
	var report={"ui_build":"r21-a-data-20261031" if state.data.has("encounter_r21") else "battle-r20b-20261031","items_open":items_open,"log_open":log_open,"build":state.data.build,"busy":busy,"pending_action":pending_action,"result":state.result,"current_id":state.current_id,"events":state.events,"engine":Engine.get_version_info().string,"state":state.snapshot(),"controls":controls,"text":text_metrics,"skills_open":skills_open,"ally_open":ally_open,"motion_reduced":motion_reduced,"storage_persistent":OS.is_userfs_persistent(),"storage_error":storage_error,"frame":[frame.position.x,frame.position.y,frame.size.x,frame.size.y],"viewport":[get_viewport_rect().size.x,get_viewport_rect().size.y],"shown_hp":shown_hp,"motion_serial":motion_serial,"actor_art":CharacterSprite.info(animation_ally if not animation_ally.is_empty() else state.last_ally).get("path",""),"enemy_hp":state.data.enemies.map(func(e):return {"id":e.id,"hp":e.hp,"mhp":e.mhp})}
	JavaScriptBridge.eval("window.__abyssPreview = "+JSON.stringify(report)+";",true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_sheets()

func _effect_feedback(before: Dictionary,source: String,action: String) -> void:
	var a=state.ally(source); var element=a.element if not a.is_empty() else "fire"
	if action=="tactic" and not a.is_empty():
		var field=controls.field.rect
		var banner=_panel(Rect2(field[0]+5,field[1]+field[3]-62,field[2]-10,58))
		_companion_picture(a.id,Rect2(3,3,48,52),banner)
		_label(a.name,Rect2(59,4,field[2]-78,20),12,INK,banner)
		_label(a.skills[action].name.split("(")[0].strip_edges(),Rect2(59,24,field[2]-78,29),14,GOLD,banner)
	for u in state.data.allies+state.data.enemies:
		var previous=before[u.id]; var delta=int(u.hp)-int(previous.hp)
		var text_value=("+" if delta>0 else "-")+str(absi(delta))
		var healing=delta>0; var fs=24
		if delta==0:
			var shield=int(u.get("shield",0))-int(previous.shield); var abyss=int(previous.gauge)-int(u.get("gauge",0))
			if shield>0: text_value="보호막 +"+str(shield); healing=true
			elif abyss>0: text_value="심연 -"+str(abyss)
			elif u.effects!=previous.effects: text_value="효과 적용"; healing=u.has("base")
			else: continue
			fs=14
		var key=("ally:" if u.has("base") else "enemy:")+u.id
		if not controls.has(key): continue
		var r=controls[key].rect; var center=Vector2(r[0]+r[2]/2,r[1]+r[3]*.4)
		if not is_instance_valid(motion):
			var fx=CombatFX.new(); fx.position=center; fx.element=element; fx.healing=healing; fx.reduced=motion_reduced; add_child(fx)
		var label=_label(text_value,Rect2(center-Vector2(53,10),Vector2(106,32)),fs,Color("9bd9b0") if healing else UI.PAPER,self,HORIZONTAL_ALIGNMENT_CENTER)
		var tween=create_tween()
		if not motion_reduced: tween.tween_property(label,"position:y",label.position.y-24,.48)
		else: tween.tween_interval(.18)
		tween.tween_property(label,"modulate:a",0,.18)

func _supplies(rect: Rect2) -> void:
	var canonical=state is ModernBattle and state.dungeon_enemy_r21!=null
	var picked=state.CombatItems.source_id(pending_action.substr(5)) if canonical and pending_action.begins_with('item:') else ''
	var menu=state.supply_menu(_language(),picked) if canonical else {}
	var p=_sheet(rect,menu.get('heading','전투 보급품'),"supplies")
	var scroll=ScrollContainer.new(); _put(scroll,Rect2(12,44,rect.size.x-24,132),p); scroll.mouse_filter=Control.MOUSE_FILTER_STOP
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list=VBoxContainer.new(); list.add_theme_constant_override("separation",0); scroll.add_child(list); list.size_flags_horizontal=SIZE_EXPAND_FILL
	var count=0
	for id in state.actions():
		if not id.begins_with("item:"): continue
		var sk=state.actions()[id]; var amount=state.inventory.get(id.substr(5),0)
		if amount<=0: continue
		count+=1; var width=rect.size.x-24
		var source_view={}
		if canonical:
			var source_id=state.CombatItems.source_id(sk.item.id)
			for control in state.supply_menu(_language()).buttons:
				if control.label==state.CombatItems.t(state.CombatItems.item_name(source_id),_language()):source_view=control;break
		var row_height=80 if canonical else 44
		var b=_button(id,Rect2(0,0,width,row_height),_select_supply.bind(id),pending_action==id,list)
		b.custom_minimum_size=Vector2(width,row_height)
		if canonical and not source_view.is_empty():b.disabled=not source_view.enabled;b.tooltip_text=source_view.description
		var style=_style(RED if pending_action==id else Color.TRANSPARENT,RED if pending_action==id else LINE); style.set_border_width_all(0); style.border_width_bottom=1; b.add_theme_stylebox_override("normal",style)
		var tint=Color.WHITE if pending_action==id else INK
		var icon_id="hp" if sk.item.kind=="hp" else "mp" if sk.item.kind=="mp" else "band" if sk.item.kind=="revive" else "scroll"
		var icon=_picture("res://assets/ic_it_"+icon_id+".webp",Rect2(6,7.5,24,29),b,true); icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_type(source_view.get('label',sk.name).replace(" · ","·"),Rect2(43,2,width-85,25) if canonical else Rect2(43,2,width-197,44),16 if canonical else 19,tint,b,HORIZONTAL_ALIGNMENT_LEFT,DISPLAY_PLAIN)
		var item=sk.item
		var description="Lv.%d" % item.level
		if item.kind in ["hp","mp","shield"]: description=("HP" if item.kind=="hp" else "MP" if item.kind=="mp" else "보호막")+" %d%%" % int(item.fraction*100)+(" 회복" if item.kind in ["hp","mp"] else "")
		elif item.kind=="revive": description="소생 HP 25%"
		elif item.kind=="cleanse": description="해로운 효과 해제"
		if canonical:_label(_wrap(source_view.get('description',description),width-58,11),Rect2(43,29,width-58,48),11,tint,b)
		else:_label(description,Rect2(width-146,2.5,108,44),12,tint,b)
		_strong("×"+str(int(amount)),Rect2(width-31,2,25,44),14,Color.WHITE if pending_action==id else INK,b,HORIZONTAL_ALIGNMENT_RIGHT,BODY_BOLD)
	if count==0: _label("사용할 보급품이 없습니다.",Rect2(12,80,rect.size.x-24,44),14,INK,p)
	var a=state.ally(state.selected_ally)
	if pending_action.is_empty() or not supply_target_set:
		_label(menu.get('hint','아군 카드를 눌러 대상 선택'),Rect2(12,181,rect.size.x-24,22),12,INK,p)
	else:
		_label("대상 "+a.name,Rect2(12,181,110,22),14,INK,p)
		var width=(rect.size.x-140)/2
		_resource_numbers(a,Rect2(122,177,width,17),p,true,16)
		_resource(a,Rect2(122,194,width,9),p)
		_resource_numbers(a,Rect2(128+width,177,width,17),p,false,16)
		_resource(a,Rect2(128+width,194,width,3),p,false)
	var col=(rect.size.x-32)/2
	var cancel=_button("cancel-action",Rect2(12,203,col,44),_close_sheets,false,p); _outline(cancel)
	_strong("취소",Rect2(0,0,col,44),14,INK,cancel,HORIZONTAL_ALIGNMENT_CENTER,BODY_BOLD)
	var use=_button("use-supply",Rect2(20+col,203,col,44),_commit,true,p); use.disabled=not _supply_reason().is_empty()
	_strong("사용하기" if not use.disabled else _supply_reason(),Rect2(0,0,col,44),12 if use.disabled else 14,Color.WHITE if not use.disabled else INK,use,HORIZONTAL_ALIGNMENT_CENTER,BODY_BOLD)

func _type(text: String, rect: Rect2, fs: int, color: Color, parent: Control, align: int, face: Font) -> Label:
	text=_tr(text)
	text=text.replace("−","-")
	while fs>(8 if _language()=="en" else 12) and face.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>rect.size.x: fs-=1
	# CSS line-height may be smaller than the font's natural line box. Match
	# it explicitly, rather than letting Label enlarge the requested bounds.
	if not text.contains("\n") and face.get_height(fs)>rect.size.y:
		var variation=FontVariation.new(); variation.base_font=face
		var excess=ceili(face.get_height(fs)-rect.size.y)
		variation.spacing_top=-ceili(excess/2.0); variation.spacing_bottom=-floori(excess/2.0)
		face=variation
	var node=Label.new(); node.text=text
	node.add_theme_font_override("font",face); node.add_theme_font_size_override("font_size",fs)
	node.add_theme_color_override("font_color",color)
	node.horizontal_alignment=align; node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	_put(node,rect,parent)
	var needed=0.0; var missing=[]
	for line in text.split("\n"): needed=maxf(needed,face.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)
	for i in range(text.length()):
		var cp=text.unicode_at(i)
		if cp not in [9,10,13] and not face.has_char(cp): missing.append(cp)
	text_metrics.append({"text":text,"font":fs,"available":rect.size.x,"needed":needed,"missing_glyphs":missing})
	return node


func _display(text: String, rect: Rect2, fs=31, color=INK, parent: Control=self) -> Label:
	return _type(text,rect,fs,color,parent,HORIZONTAL_ALIGNMENT_LEFT,DISPLAY)


func ink_mode() -> String:
	return "status" if not ally_open.is_empty() else "skills" if skills_open else "supplies" if items_open else "log" if log_open else "target" if not pending_action.is_empty() else "base"

func _ink(rect: Rect2, kind: String, tint: Color, parent: Control=self) -> void:
	var ink=InkR17.new(); ink.kind=kind; ink.tint=tint; ink.text_source=self; _put(ink,rect,parent)
	if kind.begins_with("edge") or kind=="base" or kind=="target-bloom": ink.z_index=2

func _refresh_ink() -> void:
	for ink in find_children("*","Control",true,false):
		if ink is InkR17: ink.queue_redraw()

func text_regions(clearance=0.0) -> Array:
	# Full Label rectangles, conservatively larger than glyph outlines.
	# Include dynamic log rows and honor viewport/scroll clipping.
	var regions=[]
	for node in find_children("*","Label",true,false):
		if not node.is_visible_in_tree() or node.text.is_empty(): continue
		var r=node.get_global_rect().intersection(get_viewport_rect())
		var ancestor=node.get_parent()
		while ancestor is Control:
			if ancestor.clip_contents: r=r.intersection(ancestor.get_global_rect())
			ancestor=ancestor.get_parent()
		if r.has_area(): regions.append({"text":node.text,"rect":r.grow(clearance)})
	return regions

func field_text_regions() -> Array:
	var regions=[]
	if is_instance_valid(field_visual):
		for node in field_visual.find_children("*","Label",true,false):
			regions.append({"rect":node.get_global_rect()})
	return regions


func _enemy_art(e: Dictionary, rect: Rect2, parent: Control, pixel=false) -> TextureRect:
	var atlas=AtlasTexture.new(); atlas.atlas=_texture(e.art); var b=e.bbox
	atlas.region=Rect2(b[0],b[1],b[2]-b[0],b[3]-b[1])
	var art=TextureRect.new(); art.texture=atlas; art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	if pixel:
		var source_size=atlas.region.size
		var ratio=minf(rect.size.x/source_size.x,rect.size.y/source_size.y)
		var dimensions=Vector2i(maxi(1,roundi(source_size.x*ratio/2)),maxi(1,roundi(source_size.y*ratio/2)))
		# Rebuilds happen every action; resample each enemy raster once per size.
		var key="%s|%s|%s" % [e.art,str(b),str(dimensions)]
		if not enemy_pixels.has(key):
			var image=atlas.get_image()
			image.resize(dimensions.x,dimensions.y,Image.INTERPOLATE_NEAREST)
			enemy_pixels[key]=ImageTexture.create_from_image(image)
		art.texture=enemy_pixels[key]
		var extent=Vector2(dimensions)*2
		rect=Rect2((rect.position+Vector2((rect.size.x-extent.x)/2,rect.size.y-extent.y)).round(),extent)
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_put(art,rect,parent); return art

func _enemy_name(value: String,rect: Rect2,parent: Control,align=HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	# Preserve full canonical text in the model and tooltip. Fit the fixed r20 HUD.
	var text=_tr(value)
	if state.data.has("encounter_r21"):
		while text.length()>1 and W750.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>rect.size.x:
			text=text.left(text.length()-2)+"…"
	var label=_strong(text,rect,12,INK,parent,align)
	label.tooltip_text=_tr(value)
	return label

func _enemy_hp(value: String,rect: Rect2,parent: Control,align: int) -> Label:
	var label=_strong(value,rect,12,INK,parent,align)
	if state.data.has("encounter_r21"):
		# Source encounters can have 7 live enemies or much larger deep-floor HP.
		# Fit the exact numbers inside the unchanged r20 label rectangle.
		var needed=float(text_metrics[-1].needed)
		if needed>rect.size.x:
			label.size.x=needed; label.scale.x=rect.size.x/needed
			text_metrics[-1].needed=rect.size.x
		label.tooltip_text=value
	return label


func _reason(id: String) -> String:
	var reason=state.unavailable(id)
	if reason=="MP 부족": return "마나 %d 부족" % (state.cost(id)-state.ally(state.current_id).mp) if state is ModernBattle else "마나 %d 부족" % (state.actions()[id].mp-state.ally(state.current_id).mp)
	return reason


func _toggle_skills() -> void:
	skills_open=not skills_open; items_open=false; log_open=false; ally_open=""; pending_action=""; _rebuild()


func _toggle_supplies() -> void:
	if not state is ModernBattle: return
	if state.dungeon_enemy_r21!=null and not items_open and not state.CombatItems.button(state.source_item_bag()).buttons[0].enabled:return
	items_open=not items_open; supply_target_set=false; skills_open=false; log_open=false; ally_open=""; pending_action=""; _rebuild()
	if state.dungeon_enemy_r21!=null:state.selected_action='supply_menu' if items_open else 'attack';_persist()


func _sheet(rect: Rect2, title: String, kind: String) -> Panel:
	var p=_panel(rect); _mark("sheet",p); p.mouse_filter=Control.MOUSE_FILTER_STOP
	var style=_style(PAPER,INK); style.set_border_width_all(0); style.border_width_top=0 if kind=="skills" else 2; p.add_theme_stylebox_override("panel",style)
	if sheet_kind!=kind and not motion_reduced:
		p.position.y+=18
		var tween=p.create_tween(); tween.tween_property(p,"position:y",rect.position.y,.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_publish_metrics)
	sheet_kind=kind
	if kind=="status":
		_ink(Rect2(6,13,164,31),"sheet-status",RED,p); _color(Rect2(12,50,rect.size.x-24,1),LINE,p)
	elif kind=="skills": _ink(Rect2(110,-20,390,26),"sheet-skills",INK,p)
	elif kind=="supplies": _ink(Rect2(0,15,228,37),"sheet-supplies",INK,p)
	elif kind=="log": _ink(Rect2(rect.size.x-128,65,114,164),"log-tail",RED,p)
	var fs=33 if kind=="status" else 31
	var title_width=minf(DISPLAY.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x+5,rect.size.x-90)
	if kind in ["skills","supplies"]: _color(Rect2(12,2,title_width,47),PAPER,p)
	var text_width=minf(rect.size.x-100,DISPLAY.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x+(3 if kind in ["skills","supplies"] else 0))
	_mark("sheet-title",_display(title,Rect2(12,8.67 if kind=="status" else 10.22 if kind in ["supplies","log"] else 8.2,text_width,35 if kind=="status" else 33),fs,INK,p))
	if kind in ["status","log"]: _close_button(Rect2(rect.size.x-69,4,57,44),p)
	return p

func _select_supply(id: String) -> void:
	if state is ModernBattle and state.dungeon_enemy_r21!=null and not state.CombatItems.any_target(state,state.actions()[id].item.id):return
	state.choose_action(id); pending_action=id; _rebuild()
	_persist()



func _supply_reason() -> String:
	if pending_action.is_empty(): return "보급품 선택"
	var item=state.actions()[pending_action].item; var a=state.ally(state.selected_ally)
	if a.is_empty() or not supply_target_set: return "대상 선택"
	if state is ModernBattle and state.dungeon_enemy_r21!=null and state.CombatItems.target_ok(state,item.id,a):return ''
	if a.level<item.level: return "레벨 %d 필요" % item.level
	if item.kind=="revive": return "쓰러진 동료 필요" if a.hp>0 else ""
	if a.hp<=0: return "소생이 필요합니다"
	if item.kind in ["hp","mp"] and a[item.kind]>=a["mhp" if item.kind=="hp" else "mmp"]: return ("HP" if item.kind=="hp" else "MP")+"가 가득합니다"
	if item.kind=="shield" and a.shield>=int(round(a.mhp*item.fraction)): return "보호막이 충분합니다"
	if item.kind=="cleanse" and not ["dot","corrosion","bleed","foxflame"].any(func(key): return a.effects.has(key)): return "해제할 효과 없음"
	return ""
