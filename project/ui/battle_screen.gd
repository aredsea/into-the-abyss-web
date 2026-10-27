extends Control
signal session_finished
var session_data: Dictionary={}
var session_snapshot: Dictionary={}
var session_save: Callable

const BattleState = preload("res://game/battle_state.gd")
const SaveStore = preload("res://game/save_store.gd")
const INK = Color("eae4d6")
const GOLD = Color("d7b67e")
const LINE = Color("756a50")
var state
var storage = SaveStore.new()
var font: Font = preload("res://assets/fonts/NanumGothic-Regular.ttf")
var textures = {}
var frame = Rect2()
var controls = {}
var text_metrics = []
var skills_open = false
var ally_open = ""
var actor: TextureRect
var preview_tween: Tween
var storage_error = OK
var motion_reduced = false
var pending_action = ""
var busy = false
var log_open = false
var notice = ""
var scene_data: Dictionary
var animation_ally = ""
var playback_generation = 0

func _ready() -> void:
	scene_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/battle_scene.json"))
	assert(scene_data is Dictionary)
	state = BattleState.new(scene_data)
	if not session_data.is_empty():
		scene_data=session_data
		state=BattleState.new(scene_data)
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

func _label(text: String, rect: Rect2, fs = 12, color = INK, parent: Control = self, align = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	# NanumGothic has ASCII hyphen, but not mathematical minus U+2212.
	text=text.replace("−","-")
	var node = Label.new()
	node.text = text
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", fs)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_put(node, rect, parent)
	var needed = 0.0
	for line in text.split("\n"):
		needed=maxf(needed,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x)
	var missing=[]
	for i in range(text.length()):
		var cp=text.unicode_at(i)
		if cp not in [9,10,13] and not font.has_char(cp):
			missing.append(cp)
	text_metrics.append({"text":text,"font":fs,"available":rect.size.x,"needed":needed,"missing_glyphs":missing})
	return node

func _style(bg: Color, line: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = line
	style.set_border_width_all(1)
	return style

func _button(id: String, rect: Rect2, callback: Callable, active = false, parent: Control = self, bare = false) -> Button:
	var button = Button.new()
	button.name = id.replace(":", "_")
	if bare:
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	else:
		button.add_theme_stylebox_override("normal", _style(Color("4b402c") if active else Color("242c2a"), GOLD if active else LINE))
		button.add_theme_stylebox_override("hover", _style(Color("414137"), GOLD))
	button.add_theme_stylebox_override("pressed", _style(Color("55462d"), GOLD))
	button.add_theme_stylebox_override("focus", _style(Color(0,0,0,0), GOLD))
	button.pressed.connect(callback)
	_put(button, rect, parent)
	controls[id] = {"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}
	return button

func _panel(rect: Rect2, parent: Control = self) -> Panel:
	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", _style(Color("191f1e"), LINE))
	_put(panel, rect, parent)
	var metal = _picture("res://assets/metal.png", Rect2(Vector2.ONE,rect.size-Vector2(2,2)), panel)
	metal.modulate = Color(1,1,1,0.16)
	return panel

func _meter(rect: Rect2, current: int, maximum: int, hp = true, parent: Control = self, inline_text = "") -> void:
	_color(rect, Color("080c0d"), parent)
	var inner = rect.grow(-1)
	_color(Rect2(inner.position,Vector2(inner.size.x*float(current)/maximum,inner.size.y)),Color("b56651") if hp else Color("719da9"),parent)
	if not inline_text.is_empty():
		_label(inline_text,rect,12,INK,parent,HORIZONTAL_ALIGNMENT_CENTER)

func _rebuild() -> void:
	if state == null:
		return
	if preview_tween:
		preview_tween.kill()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	controls.clear()
	text_metrics.clear()
	var view = get_viewport_rect().size
	var w = minf(view.x,430)
	var h = minf(view.y,860)
	frame = Rect2((view-Vector2(w,h))/2,Vector2(w,h))
	var party_h = clampf(180+(h-780)*0.375,180,210)
	var stage_h = h-283-party_h
	var x = frame.position.x+7
	var y = frame.position.y
	var width = w-14
	_color(frame,Color("151a1b"))
	_label("학술원 폐허 상층 · 2층",Rect2(x+3,y,230,28),14)
	var log_button=_button("log",Rect2(x+width-48,y,48,28),_toggle_log)
	_label("기록",Rect2(0,0,48,28),12,GOLD,log_button,HORIZONTAL_ALIGNMENT_CENTER)
	_queue(Rect2(x,y+31,width,50))
	var field = Rect2(x,y+84,width,stage_h)
	_battlefield(field)
	var party_y = field.end.y+3
	_party(Rect2(x,party_y,width,party_h))
	var detail_y = party_y+party_h+3
	_detail(Rect2(x,detail_y,width,44))
	_commands(Rect2(x,detail_y+47,width,140))
	if skills_open:
		var count=_skill_ids().size()
		_skills(Rect2(x+6,frame.end.y-146-(54+count*54),width-12,54+count*54))
	if not ally_open.is_empty():
		_ally_sheet(Rect2(x+8,field.end.y-156,width-16,150))
	if not pending_action.is_empty():
		_confirm_sheet(Rect2(x+6,frame.end.y-310,width-12,162))
	if log_open:
		_log_sheet(Rect2(x+6,field.position.y+12,width-12,field.size.y+party_h-24))
	if not state.result.is_empty():
		_result_sheet(Rect2(x+12,field.position.y+36,width-24,220))
	call_deferred("_publish_metrics")

func _queue(rect: Rect2) -> void:
	_label("지금\n이후\n→",Rect2(rect.position,Vector2(30,48)),12,GOLD)
	var col = (rect.size.x-34)/8
	for i in range(state.data.queue.size()):
		var id = state.data.queue[i]
		var friend = not state.ally(id).is_empty()
		var entry = state.ally(id) if friend else state.enemy(id)
		var xpos = rect.position.x+34+i*col
		if friend:
			_picture("res://assets/"+id+".webp",Rect2(xpos+3,rect.position.y+1,25,27))
		else:
			_picture(entry.art,Rect2(xpos+3,rect.position.y+1,25,27),self,true)
		var short_names = {"hildegard":"힐데","executor":"집행","teiris":"테이","orb":"수정","bargut":"바르","apprentice":"견습","berenga":"베렝","lantern":"등불"}
		_label(short_names[id],Rect2(xpos,rect.position.y+30,col,18),12,GOLD if i==0 else INK,self,HORIZONTAL_ALIGNMENT_CENTER)

func _battlefield(rect: Rect2) -> void:
	var field = Control.new()
	field.clip_contents = true
	_put(field,rect)
	var back = _picture("res://assets/src/academy.png",Rect2(Vector2.ZERO,rect.size),field,true)
	back.modulate = Color(0.53,0.53,0.53)
	for id in ["lantern","apprentice","orb","executor"]:
		var e = state.enemy(id)
		if e.hp<=0:
			continue
		var height = (140 if frame.size.y<820 else 162) if id=="executor" else (110 if id=="apprentice" else 90)
		var bbox = e.bbox
		var art_w = height*(bbox[2]-bbox[0])/(bbox[3]-bbox[1])
		var summary_w = 122 if id=="executor" else 108
		var center = rect.size.x*{"lantern":0.16,"apprentice":0.48,"orb":0.84,"executor":0.815}[id]
		var top = rect.size.y-height-43 if id=="executor" else 3.0
		var hit_width = maxf(art_w,summary_w)
		var hit = _button("enemy:"+id,Rect2(center-hit_width/2,top,hit_width,height+40),_enemy_pressed.bind(id),false,field,true)
		# Hit coordinates are local to field. Publish global values for QA.
		controls["enemy:"+id].rect = [rect.position.x+center-hit_width/2,rect.position.y+top,hit_width,height+40]
		var atlas = AtlasTexture.new()
		atlas.atlas = _texture(e.art)
		atlas.region = Rect2(bbox[0],bbox[1],bbox[2]-bbox[0],bbox[3]-bbox[1])
		var art = TextureRect.new()
		art.texture = atlas
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_put(art,Rect2((hit_width-art_w)/2,0,art_w,height),hit)
		var summary = _panel(Rect2((hit_width-summary_w)/2,height,summary_w,40),hit)
		if id==state.selected_enemy:
			summary.add_theme_stylebox_override("panel",_style(Color("30291e"),GOLD))
		_label("Lv.%d %s" % [e.level,e.name],Rect2(3,1,summary_w-6,18),12,INK,summary,HORIZONTAL_ALIGNMENT_CENTER)
		_meter(Rect2(3,21,summary_w-6,16),e.hp,e.mhp,true,summary,"HP %d / %d" % [e.hp,e.mhp])
	actor = TextureRect.new()
	actor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	actor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_actor_texture(false)
	_put(actor,Rect2(rect.size.x*0.34-133.333,rect.size.y-166,266.667,160),field)
	controls["field"]={"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y]}

func _actor_texture(attack: bool) -> void:
	var atlas = AtlasTexture.new()
	atlas.atlas = _texture("res://assets/sprites_4.png")
	var a=state.ally(animation_ally if not animation_ally.is_empty() else state.last_ally)
	atlas.region = Rect2(640 if attack else 0,a.sprite_row*384,640,384)
	actor.texture = atlas

func _party(rect: Rect2) -> void:
	var gap = 3.0
	var col = (rect.size.x-gap*3)/4
	for i in range(4):
		var a = state.data.allies[i]
		var button = _button("ally:"+a.id,Rect2(rect.position+Vector2(i*(col+gap),0),Vector2(col,rect.size.y)),_ally_pressed.bind(a.id),a.id==state.current_id)
		var pic_h = rect.size.y-88
		_picture("res://assets/"+a.id+".webp",Rect2(4,4,col-8,pic_h),button)
		_color(Rect2(7,7,30,18),Color("18201e"),button)
		_label(a.row,Rect2(8,7,28,18),12,INK,button,HORIZONTAL_ALIGNMENT_CENTER)
		_label(a.name,Rect2(3,pic_h+5,col-6,18),12,INK,button,HORIZONTAL_ALIGNMENT_CENTER)
		for n in range(2):
			var value = a.hp if n==0 else a.mp
			var maximum = a.mhp if n==0 else a.mmp
			var by = pic_h+26+n*28
			_label("HP" if n==0 else "MP",Rect2(4,by,22,16),12,INK,button)
			_label("%d/%d" % [value,maximum],Rect2(24,by,col-28,16),12,INK,button,HORIZONTAL_ALIGNMENT_RIGHT)
			_meter(Rect2(4,by+16,col-8,10),value,maximum,n==0,button)

func _detail(rect: Rect2) -> void:
	var panel = _panel(rect)
	var e = state.enemy(state.selected_enemy)
	_label("약점",Rect2(6,1,27,20),12,GOLD,panel)
	var xpos = 34.0
	for element in e.weak:
		_picture("res://assets/ic_"+element+".webp",Rect2(xpos,4,15,15),panel)
		_label(state.data.elements[element],Rect2(xpos+17,1,30,20),12,INK,panel)
		xpos+=51
	var remaining=str(int(e.gauge)) if e.gauge==floor(e.gauge) else "%.1f" % e.gauge
	_label("심연 %s / %d" % [remaining,e.max],Rect2(rect.size.x-112,1,106,20),12,GOLD,panel,HORIZONTAL_ALIGNMENT_RIGHT)
	_label(state.intent(e),Rect2(6,22,rect.size.x-12,18),12,GOLD,panel)

func _commands(rect: Rect2) -> void:
	var panel=_panel(rect)
	var a=state.ally(state.current_id)
	var is_player=state.player_turn() and not busy
	var title=a.name+"의 차례" if not a.is_empty() else state.enemy(state.current_id).short+" 행동 중"
	if not state.result.is_empty(): title="전투 승리" if state.result=="victory" else "전투 패배"
	_label(title,Rect2(6,2,rect.size.x-12,20),14,GOLD,panel)
	var summary="적을 선택하고 행동하세요"
	if not a.is_empty(): summary="%s · 심연 깎기 %d · MP %d/%d" % [state.data.elements[a.element],a.skills.attack.brk,a.mp,a.mmp]
	if busy: summary=state.events[-1] if not state.events.is_empty() else "행동 처리 중 · 입력 대기"
	_label(_wrap(summary,rect.size.x-12,12),Rect2(6,22,rect.size.x-12,28),12,INK,panel)
	var col=(rect.size.x-24)/3
	for i in range(3):
		var id=["attack","skills","guard"][i]
		var button=_button("action:"+id,Rect2(6+i*(col+6),50,col,84),_action_pressed.bind(id),pending_action==id,panel)
		button.disabled=not is_player
		if not a.is_empty() and id=="guard": button.disabled=button.disabled or not state.unavailable(id).is_empty()
		controls["action:"+id].rect=[rect.position.x+6+i*(col+6),rect.position.y+50,col,84]
		var icon={"attack":"attack","skills":"taunt","guard":"defend"}[id]
		_picture("res://assets/ic_"+icon+".webp",Rect2((col-36)/2,7,36,36),button)
		_label({"attack":"공격","skills":"스킬","guard":"방어"}[id],Rect2(0,46,col,23),16,INK,button,HORIZONTAL_ALIGNMENT_CENTER)
		var cost="선택" if id=="skills" else "MP %d" % a.skills[id].mp if not a.is_empty() else "대기"
		if not a.is_empty() and id=="guard" and a.skills.guard.has("disabled"): cost="비용 미정"
		_label(cost,Rect2(0,68,col,14),12,INK,button,HORIZONTAL_ALIGNMENT_CENTER)

func _skill_ids() -> Array:
	var ids=[]
	for id in state.actions():
		if id not in ["attack","guard"]: ids.append(id)
	return ids

func _skills(rect: Rect2) -> void:
	var panel=_panel(rect)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	_label(state.ally(state.current_id).name+"의 스킬",Rect2(8,6,rect.size.x-66,40),14,GOLD,panel)
	_close_button(Rect2(rect.size.x-52,6,44,44),panel)
	var ids=_skill_ids()
	for i in range(ids.size()):
		var id=ids[i]; var skill=state.actions()[id]
		var button=_button("skill:"+id,Rect2(8,54+i*54,rect.size.x-16,50),_action_pressed.bind(id),false,panel)
		controls["skill:"+id].rect=[rect.position.x+8,rect.position.y+54+i*54,rect.size.x-16,50]
		var reason=state.unavailable(id)
		button.disabled=not reason.is_empty()
		_label("%s · MP %d" % [skill.name,skill.mp],Rect2(7,2,rect.size.x-30,22),13,GOLD,button)
		_label(reason if not reason.is_empty() else _summary(id),Rect2(7,25,rect.size.x-30,22),12,INK,button)

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
	log_open=not log_open; _rebuild()

func _log_sheet(rect: Rect2) -> void:
	var panel=_panel(rect)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	_label("전투 기록",Rect2(8,5,180,42),15,GOLD,panel)
	var close=_button("close_log",Rect2(rect.size.x-52,5,44,44),_toggle_log,false,panel)
	_label("닫기",Rect2(0,0,44,44),12,INK,close,HORIZONTAL_ALIGNMENT_CENTER)
	controls.close_log.rect=[rect.end.x-52,rect.position.y+5,44,44]
	var scroll=ScrollContainer.new()
	_put(scroll,Rect2(8,52,rect.size.x-16,rect.size.y-60),panel)
	scroll.mouse_filter=Control.MOUSE_FILTER_STOP
	var content=VBoxContainer.new(); scroll.add_child(content)
	var entries=state.history if not state.history.is_empty() else ["아직 실행한 행동이 없습니다."]
	for i in range(entries.size()-1,-1,-1):
		var message=_wrap(entries[i],rect.size.x-40,12)
		var label=Label.new(); label.text=message
		label.add_theme_font_override("font",font); label.add_theme_font_size_override("font_size",12)
		content.add_child(label)

func _result_sheet(rect: Rect2) -> void:
	var panel=_panel(rect)
	panel.mouse_filter=Control.MOUSE_FILTER_STOP
	_label("전투 승리" if state.result=="victory" else "전투 패배",Rect2(8,15,rect.size.x-16,42),24,GOLD,panel,HORIZONTAL_ALIGNMENT_CENTER)
	_label("적을 모두 쓰러뜨렸습니다." if state.result=="victory" else "부상으로 전투에서 이탈했습니다.",Rect2(8,64,rect.size.x-16,32),13,INK,panel,HORIZONTAL_ALIGNMENT_CENTER)
	var button=_button("retry",Rect2(14,152,rect.size.x-28,52),_retry,true,panel)
	_label(("원정으로" if state.result=="victory" else "정산으로") if session_save.is_valid() else "다시 전투",Rect2(0,0,rect.size.x-28,52),16,INK,button,HORIZONTAL_ALIGNMENT_CENTER)
	controls.retry.rect=[rect.position.x+14,rect.position.y+152,rect.size.x-28,52]

func _close_button(rect: Rect2, parent: Control) -> void:
	var button = _button("close",rect,_close_sheets,false,parent)
	_label("닫기",Rect2(Vector2.ZERO,rect.size),12,INK,button,HORIZONTAL_ALIGNMENT_CENTER)
	var g=parent.global_position+rect.position
	controls["close"].rect=[g.x,g.y,rect.size.x,rect.size.y]

func _ally_sheet(rect: Rect2) -> void:
	var a = state.ally(ally_open)
	var panel = _panel(rect)
	_label(a.name,Rect2(8,6,210,40),14,GOLD,panel)
	_close_button(Rect2(rect.size.x-52,6,44,44),panel)
	_picture("res://assets/"+a.id+".webp",Rect2(10,59,56,76),panel)
	_label(a.row+" · "+a.cls,Rect2(74,57,rect.size.x-84,24),13,INK,panel)
	_label("HP %d/%d · MP %d/%d" % [a.hp,a.mhp,a.mp,a.mmp],Rect2(74,81,rect.size.x-84,24),13,INK,panel)
	_label(_wrap(state.effects_text(a),rect.size.x-84,12),Rect2(74,104,rect.size.x-84,42),12,INK,panel)

func _enemy_pressed(id: String) -> void:
	state.choose_enemy(id)
	_persist()
	_rebuild()

func _ally_pressed(id: String) -> void:
	ally_open=id
	skills_open=false
	_rebuild()

func _action_pressed(id: String) -> void:
	if busy or not state.player_turn(): return
	if id=="skills":
		skills_open=not skills_open; ally_open=""; pending_action=""; _rebuild(); return
	if not state.unavailable(id).is_empty(): return
	state.choose_action(id); pending_action=id; skills_open=false; ally_open=""; _rebuild()

func _close_sheets() -> void:
	skills_open=false; ally_open=""; pending_action=""; log_open=false; _rebuild()

func _commit() -> void:
	if busy or pending_action.is_empty(): return
	var id=pending_action
	animation_ally=state.current_id
	if not state.act(id): return
	pending_action=""; busy=true; _persist(); _rebuild(); _preview(id)
	_resume_automatic()

func _resume_automatic() -> void:
	busy=true; playback_generation+=1
	call_deferred("_publish_metrics")
	var generation=playback_generation
	await get_tree().create_timer(0.85).timeout
	if generation!=playback_generation: return
	animation_ally=""
	while state.result.is_empty() and (not state.player_turn() or state.ally(state.current_id).charging):
		state.automatic_turn(); _persist(); _rebuild()
		await get_tree().create_timer(1.0).timeout
		if generation!=playback_generation: return
	busy=false; _rebuild()

func _retry() -> void:
	if session_save.is_valid():
		session_finished.emit()
		return
	playback_generation+=1; state=BattleState.new(scene_data)
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
	if not OS.has_feature("web"):
		return
	var report={"build":state.data.build,"busy":busy,"pending_action":pending_action,"result":state.result,"current_id":state.current_id,"events":state.events,"engine":Engine.get_version_info().string,"state":state.snapshot(),"controls":controls,"text":text_metrics,"skills_open":skills_open,"ally_open":ally_open,"motion_reduced":motion_reduced,"storage_persistent":OS.is_userfs_persistent(),"storage_error":storage_error,"frame":[frame.position.x,frame.position.y,frame.size.x,frame.size.y],"viewport":[get_viewport_rect().size.x,get_viewport_rect().size.y],"enemy_hp":state.data.enemies.map(func(e):return {"id":e.id,"hp":e.hp,"mhp":e.mhp})}
	JavaScriptBridge.eval("window.__abyssPreview = "+JSON.stringify(report)+";",true)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close_sheets()
