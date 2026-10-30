extends Control
signal session_finished
var session_data: Dictionary={}
var session_snapshot: Dictionary={}
var session_save: Callable

const BattleState = preload("res://game/battle_state.gd")
const ModernBattle=preload("res://game/battle_v3.gd")
const CharacterSprite=preload("res://ui/character_sprite.gd")
const SignatureSequence=preload("res://ui/signature_sequence.gd")
const ForgedButton=preload("res://ui/forged_button.gd")
const CombatFX=preload("res://ui/combat_fx.gd")
const CombatPresentation=preload("res://ui/combat_presentation.gd")
const SaveStore = preload("res://game/save_store.gd")
const UI=preload("res://ui/fantasy_theme.gd")
const INK = Color("111715")
const GOLD = Color("d83219")
const LINE = Color("b8b8ab")
const PAPER = Color("f4efe3")
const RED = Color("d83219")
const DISPLAY = preload("res://assets/fonts/AbyssNotoBlackCondensed.ttf")
const BODY = preload("res://assets/fonts/AbyssNotoText500.ttf")
const BODY_BOLD = preload("res://assets/fonts/AbyssNotoText800.ttf")
const InkR17 = preload("res://ui/battle_ink_r17.gd")
const FaceR17 = preload("res://ui/battle_face_r17.gd")
var state
var storage = SaveStore.new()
var font: Font = BODY_BOLD
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
var shown_hp: Dictionary = {}
var presenting_source = ""

func _ready() -> void:
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

func _meter(rect: Rect2, current: int, maximum: int, hp = true, parent: Control = self, inline_text = "") -> void:
	_color(rect,Color("d2d1c5"),parent)
	_color(Rect2(rect.position,Vector2(rect.size.x*clampf(float(current)/maxi(1,maximum),0,1),rect.size.y)),RED if hp else Color("32738a"),parent)
	if not inline_text.is_empty(): _label(inline_text,rect,12,INK,parent,HORIZONTAL_ALIGNMENT_CENTER)

func _rebuild() -> void:
	if state==null: return
	if preview_tween: preview_tween.kill()
	for child in get_children():
		if child.has_meta("combat_sequence"): continue
		remove_child(child); child.queue_free()
	controls.clear(); text_metrics.clear(); enemy_visuals.clear(); shown_hp.clear()
	var view=get_viewport_rect().size; var w=minf(view.x,430); var h=view.y
	frame=Rect2((view-Vector2(w,h))/2,Vector2(w,h))
	var x=frame.position.x; var y=frame.position.y; var delta=h-844
	_color(frame,PAPER)
	_label(str(state.data.get("location","학술원 폐허")),Rect2(x+12,y,w-95,41),16)
	_label("턴 "+str(state.turn_count),Rect2(x+w-78,y,66,41),16,INK,self,HORIZONTAL_ALIGNMENT_RIGHT)
	_queue(Rect2(x+12,y+43,w-24,44))
	_battlefield(Rect2(x,y+94,w,288+delta))
	var mode="status" if not ally_open.is_empty() else "skills" if skills_open else "supplies" if items_open else "log" if log_open else "target" if not pending_action.is_empty() else "base"
	_ink(Rect2(x,y+352+delta,w,76),"edge-"+mode,PAPER)
	if mode=="base": _ink(Rect2(x,y+351+delta,w*.64,32),"base",INK)
	var a=state.ally(state.current_id)
	var title=a.name+"의 차례" if not a.is_empty() else state.enemy(state.current_id).name+" 행동 중"
	_display(title,Rect2(x+12,y+381+delta,w-76,49),38)
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
		if i==0:
			var sb=slot.get_theme_stylebox("panel").duplicate(); sb.set_border_width_all(2); slot.add_theme_stylebox_override("panel",sb)
		if i<state.data.queue.size():
			var id=state.data.queue[i]; var a=state.ally(id)
			if not a.is_empty(): _companion_picture(id,Rect2(3,2,col-6,36),slot)
			else:
				var e=state.enemy(id)
				if not e.is_empty(): _enemy_art(e,Rect2(3,2,col-6,35),slot)
		_label(str(i+1),Rect2(col-14,27,13,14),12,RED if i==0 else INK,slot,HORIZONTAL_ALIGNMENT_RIGHT)

func _battlefield(rect: Rect2) -> void:
	var field=Control.new(); field.clip_contents=true; _put(field,rect)
	field_visual=field; field_home=field.position
	var back=_picture("res://assets/src/academy.png",Rect2(Vector2.ZERO,rect.size),field,true); field_back=back
	var material=ShaderMaterial.new(); material.shader=preload("res://assets/ui-r17/print.gdshader"); back.material=material
	var enemies=state.data.enemies.filter(func(e): return e.hp>0)
	var small=enemies.filter(func(e): return e.id!="executor")
	var order={"lantern":0,"apprentice":1,"orb":2}
	small.sort_custom(func(a,b): return order.get(a.id,3)<order.get(b.id,3))
	var big_height=minf(103,65+(rect.size.y-224)*.594)
	# Keep small-enemy touch areas above the executor's so short fields never overlap.
	var small_height=75.0 if small.size()==enemies.size() else minf(75.0,rect.size.y-big_height-44-12-34-1)
	for i in range(enemies.size()):
		var e=enemies[i]; var big=e.id=="executor"; var index=small.find(e)
		var center=rect.size.x*.815 if big else rect.size.x*(index+.5)/maxi(1,small.size())
		var height=big_height if big else small_height
		var top=rect.size.y-height-44 if big else 12.0
		var hud_w=minf(119 if big else 112,rect.size.x/maxi(1,small.size())-4)
		var hit=_button("enemy:"+e.id,Rect2(center-hud_w/2,top,hud_w,height+34),_enemy_pressed.bind(e.id),false,field,true)
		if not pending_action.is_empty() and state.selected_enemy==e.id:
			_ink(Rect2(-5,height-20,hud_w+10,24),"target-"+e.id,RED,hit)
		var art=_enemy_art(e,Rect2(0,0,hud_w,height),hit)
		enemy_visuals[e.id]={"node":art,"home":art.position}; shown_hp[e.id]=e.hp
		var hud=_color(Rect2(0,height+5,hud_w,30),PAPER,hit)
		_label(e.name,Rect2(2,0,hud_w-4,14),12,INK,hud,HORIZONTAL_ALIGNMENT_CENTER)
		_meter(Rect2(3,14,hud_w-6,2),e.hp,e.mhp,true,hud)
		_label("HP %d/%d" % [e.hp,e.mhp],Rect2(2,16,hud_w-4,14),12,INK,hud,HORIZONTAL_ALIGNMENT_CENTER)
	actor=CharacterSprite.new(); actor.idle_enabled=true; _actor_texture(false)
	var actor_h=minf(145,rect.size.y-128)
	_put(actor,Rect2(rect.size.x*.07,rect.size.y-actor_h,rect.size.x*.38,actor_h),field)
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
		var b=_button("ally:"+a.id,Rect2(rect.position+Vector2(i*(col+6),7),Vector2(col,143)),_ally_pressed.bind(a.id),false,self,true)
		var face=FaceR17.new(); face.configure(a.id); _put(face,Rect2(0,0,col,51),b)
		if a.id==state.current_id or a.id==ally_open or (items_open and supply_target_set and a.id==state.selected_ally):
			var border=_panel(Rect2(0,0,col,51),b); var sb=_style(Color.TRANSPARENT,RED); sb.set_border_width_all(2); border.add_theme_stylebox_override("panel",sb)
		_label(a.name,Rect2(0,51,col,17),12,INK,b)
		_label(a.row,Rect2(0,68,col*.5,17),12,Color("575f55"),b)
		_label("차례" if a.id==state.current_id else "선택" if a.id==ally_open or (items_open and supply_target_set and a.id==state.selected_ally) else "",Rect2(col*.5,68,col*.5,17),12,RED,b,HORIZONTAL_ALIGNMENT_RIGHT)
		for j in range(2):
			var current=a.hp if j==0 else a.mp; var maximum=a.mhp if j==0 else a.mmp; var yy=85+j*25
			_label("HP" if j==0 else "MP",Rect2(0,yy,18,19),12,INK,b)
			_label("%d/%d" % [current,maximum],Rect2(18,yy,col-18,19),13,INK,b,HORIZONTAL_ALIGNMENT_RIGHT)
			_meter(Rect2(0,yy+19,col,3),current,maximum,j==0,b)

func _detail(rect: Rect2) -> void:
	var e=state.enemy(state.selected_enemy)
	if e.is_empty(): return
	_color(Rect2(rect.position,Vector2(rect.size.x,1)),LINE)
	_label(e.name,Rect2(rect.position+Vector2(0,4),Vector2(rect.size.x-100,18)),12)
	_label("HP %d/%d" % [e.hp,e.mhp],Rect2(rect.position+Vector2(rect.size.x-100,4),Vector2(100,18)),12,INK,self,HORIZONTAL_ALIGNMENT_RIGHT)
	var weak=[]
	for element in e.get("weak",[]): weak.append(state.data.elements.get(element,element))
	if not weak.is_empty(): _label("약점 "+" · ".join(weak),Rect2(rect.position+Vector2(0,22),Vector2(rect.size.x-112,17)),12)
	if e.has("gauge"): _label("심연 %s/%d" % [str(e.gauge),e.max],Rect2(rect.position+Vector2(rect.size.x-112,22),Vector2(112,17)),12,INK,self,HORIZONTAL_ALIGNMENT_RIGHT)
	_label(state.intent(e),Rect2(rect.position+Vector2(0,39),Vector2(rect.size.x,20)),12)

func _commands(rect: Rect2) -> void:
	var ready=state.player_turn() and not busy
	var ids=state.actions().keys().filter(func(id): return not id.begins_with("item:")) if ready else []
	var col=(rect.size.x-7)/2
	for i in range(mini(ids.size(),4)):
		var id=ids[i]; var sk=state.actions()[id]; var active=(pending_action==id or (pending_action.is_empty() and id=="attack")) and _reason(id).is_empty()
		var b=_button("action:"+id,Rect2(rect.position+Vector2((i%2)*(col+7),int(i/2)*63),Vector2(col,56)),_action_pressed.bind(id),active)
		var reason=_reason(id); b.disabled=not reason.is_empty() or (not pending_action.is_empty() and pending_action!=id)
		var color=Color.WHITE if active else Color("596057") if b.disabled else INK
		var title=sk.name.split("(")[0].strip_edges()
		var icon="sword" if sk.target.begins_with("적") else "shield"
		var pic=_picture("res://assets/ui-r17/"+icon+".svg",Rect2(8,13,20,25),b)
		pic.modulate=color
		_display(title,Rect2(36,3,col-43,28),22,color,b)
		var mp=state.cost(id) if state is ModernBattle else sk.mp
		var cost_text="MP %d" % mp
		var a=state.ally(state.current_id)
		if state is ModernBattle and (id=="blood" or (id=="personal" and a.id in ["tika","levia"])): cost_text="HP %d" % state.hp_cost(a,id)
		_label(reason if not reason.is_empty() else cost_text+" · "+sk.target,Rect2(36,32,col-43,21),12,color,b)
		b.tooltip_text=reason if not reason.is_empty() else sk.note
	if busy:
		var skip=_button("skip-motion",Rect2(rect.position,Vector2(rect.size.x,56)),_skip_motion)
		_label("연출 건너뛰기",Rect2(10,0,rect.size.x-20,56),14,INK,skip,HORIZONTAL_ALIGNMENT_CENTER)
	var pos=rect.position+Vector2(0,126)
	if not pending_action.is_empty():
		_label("대상을 선택하세요",Rect2(pos,Vector2(rect.size.x-128,44)),12)
		var cancel=_button("cancel-action",Rect2(pos+Vector2(rect.size.x-120,0),Vector2(120,44)),_close_sheets)
		_label("취소",Rect2(0,0,120,44),14,INK,cancel,HORIZONTAL_ALIGNMENT_CENTER)
	else:
		for i in range(2):
			var id="supplies" if i==0 else "log"
			var b=_button(id,Rect2(pos+Vector2(i*(col+7),0),Vector2(col,44)),_toggle_supplies if i==0 else _toggle_log)
			# Legacy (pre-v3) battles have no item actions or selected_ally.
			b.disabled=not ready or (i==0 and not state is ModernBattle)
			_label("보급품" if i==0 else "전투 기록",Rect2(0,0,col,44),14,INK,b,HORIZONTAL_ALIGNMENT_CENTER)
		if ready:
			var more=_button("skills",Rect2(frame.end.x-56,frame.position.y+390+(frame.size.y-844),44,44),_toggle_skills,false,self,true)
			_label("기술",Rect2(0,0,44,44),12,INK,more,HORIZONTAL_ALIGNMENT_CENTER)

func _skill_ids() -> Array:
	return state.actions().keys().filter(func(id): return id not in ["attack","guard"] and not id.begins_with("item:"))

func _skills(rect: Rect2) -> void:
	var p=_sheet(rect,"기술 선택","skills"); var a=state.ally(state.current_id)
	_label("MP %d/%d" % [a.mp,a.mmp],Rect2(rect.size.x-170,3,92,44),12,INK,p,HORIZONTAL_ALIGNMENT_RIGHT)
	var ids=_skill_ids()
	var scroll=ScrollContainer.new(); _put(scroll,Rect2(12,49,rect.size.x-24,145),p); scroll.mouse_filter=Control.MOUSE_FILTER_STOP
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list=VBoxContainer.new(); scroll.add_child(list); list.size_flags_horizontal=SIZE_EXPAND_FILL
	for id in ids:
		var sk=state.actions()[id]; var reason=_reason(id); var width=rect.size.x-36
		var b=_button("skill:"+id,Rect2(0,0,width,69),_action_pressed.bind(id),false,list)
		b.custom_minimum_size=Vector2(width,69); b.disabled=not reason.is_empty()
		_display(sk.name.split("(")[0].strip_edges(),Rect2(10,2,width-20,25),21,Color("596057") if b.disabled else INK,b)
		_label("MP %d · %s" % [state.cost(id) if state is ModernBattle else sk.mp,sk.target],Rect2(10,27,width-20,19),12,INK,b)
		_label(reason,Rect2(10,46,width-20,20),12,Color("596057"),b)
	var cancel=_button("cancel-action",Rect2(12,201,rect.size.x-24,44),_close_sheets,false,p)
	_label("취소",Rect2(0,0,rect.size.x-24,44),14,INK,cancel,HORIZONTAL_ALIGNMENT_CENTER)

func _summary(id: String) -> String:
	var summaries={"attack":"선택한 적 1명에게 일반 공격","guard":"자신 · 피해 -40%% · %d턴" % state.actions().guard.turns,"taunt":"자신 · 도발 2턴 · 위압으로 심연 20","duty":"자신 도발·피해 -25% · HP 최저 적 심연 15","burst":"적 전체 ×1.9 · 충전 · 행동 간격 2배","hshield":"아군 전체 · 보호막 18 · 2턴","bless":"아군 전체 · 공격·방어 +15% · 3턴","personal":"적 전체 ×1.9 · 즉시 · 전투당 1회"}
	return summaries.get(id,"")

func _wrap(message: String,width: float,fs: int) -> String:
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
	var p=_sheet(rect,"전투 기록","log")
	_ink(Rect2(rect.size.x-105,72,88,153),"log-tail",RED,p)
	var scroll=ScrollContainer.new(); _put(scroll,Rect2(12,49,rect.size.x-124,186),p)
	scroll.mouse_filter=Control.MOUSE_FILTER_STOP; scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list=VBoxContainer.new(); scroll.add_child(list); list.size_flags_horizontal=SIZE_EXPAND_FILL
	var entries=state.history if not state.history.is_empty() else ["아직 실행한 행동이 없습니다."]
	for i in range(entries.size()-1,-1,-1):
		var label=Label.new(); label.text=_wrap(entries[i],rect.size.x-136,14)
		label.add_theme_font_override("font",BODY); label.add_theme_font_size_override("font_size",14); label.add_theme_color_override("font_color",INK)
		list.add_child(label)
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
	_label("닫기",Rect2(Vector2.ZERO,rect.size),12,INK,b,HORIZONTAL_ALIGNMENT_CENTER)

func _ally_sheet(rect: Rect2) -> void:
	var a=state.ally(ally_open); var p=_sheet(rect,a.name,"status")
	var portrait=preload("res://ui/character_portrait.gd").new(); portrait.configure(a.id)
	portrait.face_texture=null
	portrait.portrait=portrait.prepare(a.id)
	_put(portrait,Rect2(7,52,153,192),p)
	var x=164.0; var width=rect.size.x-x-12
	_label(a.row+" · "+a.cls,Rect2(x,54,width,25),14,INK,p)
	for j in range(2):
		var current=a.hp if j==0 else a.mp; var maximum=a.mhp if j==0 else a.mmp; var yy=86+j*55
		_label("HP" if j==0 else "MP",Rect2(x,yy,24,32),12,INK,p)
		_display("%d/%d" % [current,maximum],Rect2(x+28,yy,width-28,32),28,INK,p)
		_meter(Rect2(x,yy+32,width,6),current,maximum,j==0,p)
	_label(_wrap(state.effects_text(a),width,12),Rect2(x,199,width,44),12,INK,p)

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
	if busy or not state.player_turn() or not state.unavailable(id).is_empty(): return
	state.choose_action(id); pending_action=id; skills_open=false; ally_open=""
	if state is ModernBattle and (state.actions()[id].target not in ["적 1","아군 1"]): _commit()
	else: _rebuild()

func _close_sheets() -> void:
	if busy: return
	skills_open=false; items_open=false; ally_open=""; pending_action=""; log_open=false; _rebuild()

func _capture_visual_before() -> Dictionary:
	var before={}
	for unit in state.data.allies+state.data.enemies:
		before[unit.id]={"hp":unit.hp,"shield":unit.get("shield",0),"gauge":unit.get("gauge",0),"effects":unit.effects.duplicate(true)}
	return before

func _commit() -> void:
	if busy or pending_action.is_empty(): return
	var id=pending_action
	var before=_capture_visual_before()
	animation_ally=state.current_id
	presenting_source=animation_ally
	# Build the old visual state before resolving once. No post-action HP leak.
	pending_action=""; skills_open=false; items_open=false; ally_open=""; busy=true
	_rebuild()
	if not state.act(id):
		busy=false; _rebuild(); return
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
		current.tint={"ice":Color("b9e0e4"),"bolt":Color("e9d494"),"holy":Color("e9e1ba")}.get(state.ally(source).element,Color("edc69b"))
	motion_hurt_ids=[]
	for unit in state.data.allies+state.data.enemies:
		var old=before[unit.id]
		var hurt=unit.hp<old.hp or unit.get("shield",0)<old.shield
		var changed=hurt or unit.hp!=old.hp or unit.effects!=old.effects or unit.get("gauge",0)!=old.gauge or unit.get("shield",0)!=old.shield
		var ally_unit=not state.ally(unit.id).is_empty()
		var key=("ally:" if ally_unit else "enemy:")+unit.id
		if not changed or not controls.has(key): continue
		var rect=controls[key].rect
		var target=Rect2(rect[0],rect[1],rect[2],minf(rect[3],72) if ally_unit else rect[3]-40)
		current.targets.append(target)
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
	if is_instance_valid(field_back): field_back.position=current.shake_offset() if current!=null else Vector2.ZERO
	for id in enemy_visuals:
		var visual=enemy_visuals[id].node
		if not is_instance_valid(visual): continue
		visual.visible=current==null or not (current.enemy_action and current.character_id==id)
		visual.position=enemy_visuals[id].home
		if current!=null: visual.position+=current.shake_offset()
		visual.modulate=Color.WHITE
		if current!=null and id in motion_hurt_ids and current.clock.impacted:
			visual.position+=current.reaction_offset()
			if current.clock.remaining_stop>0: visual.modulate=Color(1.3,1.2,1.1)

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
		state.automatic_turn(); _persist()
		await _present_action(before,source,"enemy" if state.ally(source).is_empty() else "burst")
		if generation!=playback_generation: return
	busy=false; _rebuild()

func _retry() -> void:
	if session_save.is_valid():
		session_finished.emit()
		return
	playback_generation+=1; state=ModernBattle.new(scene_data) if scene_data.get("rules_version",2)==3 else BattleState.new(scene_data)
	busy=false; pending_action=""; animation_ally=""; skills_open=false; ally_open=""; log_open=false
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
	for key in controls:
		var node=find_child(str(key).replace(":","_"),true,false)
		if node is Button: controls[key].rect=[node.global_position.x,node.global_position.y,node.size.x,node.size.y]
	if not OS.has_feature("web"):
		return
	var report={"ui_build":"battle-r17-20261031-pass2","items_open":items_open,"log_open":log_open,"build":state.data.build,"busy":busy,"pending_action":pending_action,"result":state.result,"current_id":state.current_id,"events":state.events,"engine":Engine.get_version_info().string,"state":state.snapshot(),"controls":controls,"text":text_metrics,"skills_open":skills_open,"ally_open":ally_open,"motion_reduced":motion_reduced,"storage_persistent":OS.is_userfs_persistent(),"storage_error":storage_error,"frame":[frame.position.x,frame.position.y,frame.size.x,frame.size.y],"viewport":[get_viewport_rect().size.x,get_viewport_rect().size.y],"shown_hp":shown_hp,"motion_serial":motion_serial,"actor_art":CharacterSprite.info(animation_ally if not animation_ally.is_empty() else state.last_ally).get("path",""),"enemy_hp":state.data.enemies.map(func(e):return {"id":e.id,"hp":e.hp,"mhp":e.mhp})}
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
		var fx=CombatFX.new(); fx.position=center; fx.element=element; fx.healing=healing; fx.reduced=motion_reduced; add_child(fx)
		var label=_label(text_value,Rect2(center-Vector2(53,10),Vector2(106,32)),fs,Color("9bd9b0") if healing else UI.PAPER,self,HORIZONTAL_ALIGNMENT_CENTER)
		var tween=create_tween(); tween.tween_property(label,"position:y",label.position.y-24,.48); tween.tween_property(label,"modulate:a",0,.18)

func _supplies(rect: Rect2) -> void:
	var p=_sheet(rect,"전투 보급품","supplies")
	var scroll=ScrollContainer.new(); _put(scroll,Rect2(12,44,rect.size.x-24,132),p); scroll.mouse_filter=Control.MOUSE_FILTER_STOP
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	var list=VBoxContainer.new(); list.add_theme_constant_override("separation",0); scroll.add_child(list); list.size_flags_horizontal=SIZE_EXPAND_FILL
	var count=0
	for id in state.actions():
		if not id.begins_with("item:"): continue
		var sk=state.actions()[id]; var amount=state.inventory.get(id.substr(5),0)
		if amount<=0: continue
		count+=1; var width=rect.size.x-36
		var b=_button(id,Rect2(0,0,width,44),_select_supply.bind(id),pending_action==id,list)
		b.custom_minimum_size=Vector2(width,44)
		var tint=Color.WHITE if pending_action==id else INK
		_display(sk.name,Rect2(8,0,width-155,44),19,tint,b)
		var item=sk.item
		var description="Lv.%d" % item.level
		if item.kind in ["hp","mp","shield"]: description=("HP" if item.kind=="hp" else "MP" if item.kind=="mp" else "보호막")+" %d%%" % int(item.fraction*100)
		elif item.kind=="revive": description="소생 HP 25%"
		elif item.kind=="cleanse": description="해로운 효과 해제"
		_label(description,Rect2(width-143,0,100,44),12,tint,b)
		_label("×"+str(int(amount)),Rect2(width-48,0,40,44),14,Color.WHITE if pending_action==id else INK,b,HORIZONTAL_ALIGNMENT_RIGHT)
	if count==0: _label("사용할 보급품이 없습니다.",Rect2(12,80,rect.size.x-24,44),14,INK,p)
	var a=state.ally(state.selected_ally)
	_label("아군 카드를 눌러 대상 선택" if pending_action.is_empty() or not supply_target_set else "대상 "+a.name+" · HP %d/%d · MP %d/%d" % [a.hp,a.mhp,a.mp,a.mmp],Rect2(12,175,rect.size.x-24,24),12,INK,p)
	var col=(rect.size.x-32)/2
	var cancel=_button("cancel-action",Rect2(12,201,col,44),_close_sheets,false,p)
	_label("취소",Rect2(0,0,col,44),14,INK,cancel,HORIZONTAL_ALIGNMENT_CENTER)
	var use=_button("use-supply",Rect2(20+col,201,col,44),_commit,true,p); use.disabled=not _supply_reason().is_empty()
	_label("사용하기" if not use.disabled else _supply_reason(),Rect2(0,0,col,44),12 if use.disabled else 14,Color.WHITE if not use.disabled else INK,use,HORIZONTAL_ALIGNMENT_CENTER)

func _type(text: String, rect: Rect2, fs: int, color: Color, parent: Control, align: int, face: Font) -> Label:
	text=text.replace("−","-")
	while fs>12 and face.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x>rect.size.x: fs-=1
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


func _ink(rect: Rect2, kind: String, tint: Color, parent: Control=self) -> void:
	var ink=InkR17.new(); ink.kind=kind; ink.tint=tint; ink.text_source=self; _put(ink,rect,parent)

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


func _enemy_art(e: Dictionary, rect: Rect2, parent: Control) -> TextureRect:
	var atlas=AtlasTexture.new(); atlas.atlas=_texture(e.art); var b=e.bbox
	atlas.region=Rect2(b[0],b[1],b[2]-b[0],b[3]-b[1])
	var art=TextureRect.new(); art.texture=atlas; art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_put(art,rect,parent); return art


func _reason(id: String) -> String:
	var reason=state.unavailable(id)
	if reason=="MP 부족": return "마나 %d 부족" % (state.cost(id)-state.ally(state.current_id).mp) if state is ModernBattle else "마나 %d 부족" % (state.actions()[id].mp-state.ally(state.current_id).mp)
	return reason


func _toggle_skills() -> void:
	skills_open=not skills_open; items_open=false; log_open=false; ally_open=""; pending_action=""; _rebuild()


func _toggle_supplies() -> void:
	if not state is ModernBattle: return
	items_open=not items_open; supply_target_set=false; skills_open=false; log_open=false; ally_open=""; pending_action=""; _rebuild()


func _sheet(rect: Rect2, title: String, kind: String) -> Panel:
	var p=_panel(rect); p.mouse_filter=Control.MOUSE_FILTER_STOP
	if sheet_kind!=kind and not motion_reduced:
		p.position.y+=18
		var tween=p.create_tween(); tween.tween_property(p,"position:y",rect.position.y,.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_publish_metrics)
	sheet_kind=kind
	var title_width=minf(DISPLAY.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,31).x+5,rect.size.x-90)
	_color(Rect2(12,3,title_width,44),PAPER,p)
	_display(title,Rect2(12,3,rect.size.x-90,44),31,INK,p)
	_close_button(Rect2(rect.size.x-68,0,56,44),p)
	return p


func _select_supply(id: String) -> void:
	state.choose_action(id); pending_action=id; _rebuild()



func _supply_reason() -> String:
	if pending_action.is_empty(): return "보급품 선택"
	var item=state.actions()[pending_action].item; var a=state.ally(state.selected_ally)
	if a.is_empty() or not supply_target_set: return "대상 선택"
	if a.level<item.level: return "레벨 %d 필요" % item.level
	if item.kind=="revive": return "쓰러진 동료 필요" if a.hp>0 else ""
	if a.hp<=0: return "소생이 필요합니다"
	if item.kind in ["hp","mp"] and a[item.kind]>=a["mhp" if item.kind=="hp" else "mmp"]: return ("HP" if item.kind=="hp" else "MP")+"가 가득합니다"
	if item.kind=="shield" and a.shield>=int(round(a.mhp*item.fraction)): return "보호막이 충분합니다"
	if item.kind=="cleanse" and not ["dot","corrosion","bleed","foxflame"].any(func(key): return a.effects.has(key)): return "해제할 효과 없음"
	return ""
