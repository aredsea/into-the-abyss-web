extends Node2D
## Visual-only sequence. Battle resolution stays in battle_v3 / battle_state.
signal impact
signal finished
const Motion = preload("res://ui/motion_library.gd")
const Clock = preload("res://ui/combat_timeline.gd")
const Figure = preload("res://ui/character_sprite.gd")
const Signature = preload("res://ui/signature_sequence.gd")
var clock = Clock.new()
var character_id = "hildegard"
var action = "attack"
var field = Rect2()
var source_rect = Rect2()
var targets: Array = []
var hurt_targets: Array = []
var reduced = false
var damaging = false
var enemy_action = false
var source_image: Texture2D
var figure: Control
var figure_home = Vector2.ZERO
var sheet: Texture2D
var weapon_texture: Texture2D
var clip: Dictionary = {}
var body_frame = 0
var contact_frame = 4
var tint = Color("e4d1a8")
var impact_count = 0
var sequence_id = 0
var on_visual_update: Callable
var contact_wall_time: int = 0
var signature: Control

func _ready() -> void:
	set_meta("combat_sequence", true)
	z_index = 20
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var length = 0.65 if action == "attack" else 0.78
	var contact = 0.22 if action == "attack" else 0.30
	if enemy_action: length = 0.58; contact = 0.20
	if not enemy_action:
		var visual_action = "charge" if character_id == "teiris" and action == "burst" and not damaging else action
		clip = Motion.get_clip(character_id, visual_action)
		if not clip.is_empty():
			sheet = Motion.texture(clip.path)
			length = float(clip.duration)
			contact = float(clip.impact_at)
			contact_frame = int(clip.contact_frame)
	if reduced: length = 0.36; contact = 0.12
	# Keep the existing 30 distinct personal-skill presentations. Their clock
	# follows the same contact timeline as HP, so skipping cannot apply twice.
	if action == "personal" and not enemy_action and clip.is_empty():
		length = 0.7 if reduced else 1.6
		contact = length * 0.42
		signature = Signature.new()
		signature.character_id = character_id
		signature.reduced = reduced
		signature.externally_timed = true
		signature.position = field.position
		signature.size = field.size
		add_child(signature)
	clock.configure(contact, length, 0.0 if reduced or not damaging else 0.035 if character_id == "bargut" else 0.05)
	if action == "personal" and not clip.is_empty():
		var title = Label.new()
		title.text = Figure.info(character_id).name + " · " + clip.label
		title.position = field.position + Vector2(8, 4)
		title.size = Vector2(field.size.x - 16, 30)
		title.add_theme_font_override("font", preload("res://assets/fonts/GowunBatang-Bold.ttf"))
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", tint)
		title.add_theme_color_override("font_shadow_color", Color.BLACK)
		title.add_theme_constant_override("shadow_offset_x", 1)
		title.add_theme_constant_override("shadow_offset_y", 1)
		add_child(title)
	if sheet == null and signature == null:
		if enemy_action:
			var picture = TextureRect.new()
			picture.texture = source_image
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			figure = picture
		else:
			var body = Figure.new()
			body.configure(character_id, action != "guard")
			figure = body
		add_child(figure)
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		figure.position = source_rect.position
		figure.size = source_rect.size
		figure_home = figure.position
	_play_sound("ready")
	_publish()

func _process(delta: float) -> void:
	for event in clock.advance(delta):
		if event == "impact":
			impact_count += 1
			contact_wall_time = Time.get_ticks_msec()
			impact.emit()
			_play_sound("hit" if damaging else "support")
		elif event == "finished":
			_cleanup()
			finished.emit()
			queue_free()
	if is_instance_valid(figure): figure.position = figure_home + _step()
	if is_instance_valid(signature): signature.elapsed = clock.elapsed
	if on_visual_update.is_valid(): on_visual_update.call(self)
	queue_redraw()
	_publish()

func _step() -> Vector2:
	if reduced or not damaging or enemy_action: return Vector2.ZERO
	if clip.get("approach", false) and not hurt_targets.is_empty():
		# Close actual distance to the selected enemy, then return after recovery.
		# The sprite keeps its scale; no jumping, stretching or duplicate ghost.
		var target: Rect2 = hurt_targets[0]
		var destination = Vector2(target.get_center().x - 47.0, target.end.y - 5.0)
		destination.x = clampf(destination.x, field.position.x + 48, field.end.x - 48)
		destination.y = clampf(destination.y, field.position.y + source_rect.size.y + 8, field.end.y - 8)
		var origin = Vector2(source_rect.get_center().x, source_rect.end.y)
		var ready = minf(clock.impact_at * 0.7, 0.24)
		var recovery = float(clip.get("return_at", clock.duration * 0.66))
		var fraction = smoothstep(0.035, ready, clock.elapsed) * (1.0 - smoothstep(recovery, clock.duration - 0.03, clock.elapsed))
		return (destination - origin) * fraction
	# A posed step already moves the pelvis and planted feet inside the frames.
	if clip.get("root_motion", false): return Vector2.ZERO
	var t = clock.elapsed
	var fraction = smoothstep(0.05, clock.impact_at, t) * (1.0 - smoothstep(clock.impact_at + 0.13, clock.duration, t))
	return Vector2(22.0 * fraction, -2.0 * fraction)

func _draw() -> void:
	if sheet != null:
		body_frame = Motion.frame_at(clip, clock.elapsed)
		if reduced: body_frame = contact_frame if clock.impacted else 0
		Motion.draw_frame(self, clip, body_frame, source_rect, _step())
	_draw_projectile()
	if not clock.impacted: return
	var age = maxf(0.0, float(Time.get_ticks_msec() - contact_wall_time) / 1000.0)
	if not enemy_action and not clip.is_empty(): _skill_effect(age)
	if damaging and age < 0.19:
		for rect in hurt_targets:
			var center: Vector2 = rect.get_center()
			var fade = 1.0 - age / 0.19
			var col = Color(tint, fade)
			var reach = 8.0 + age * 115.0
			if reduced:
				draw_line(center - Vector2(7, 0), center + Vector2(7, 0), col, 2)
			else:
				for i in range(6):
					var direction = Vector2.from_angle(i * TAU / 6.0 + 0.35)
					draw_line(center + direction * reach * 0.4, center + direction * reach, col, 2)
				draw_line(center - Vector2(12, 9), center + Vector2(12, 9), Color("fff3d6"), 3 * fade)
	elif not damaging and age < 0.38:
		var ratio = age / 0.38
		var centers = targets if not targets.is_empty() else [source_rect]
		for rect in centers:
			var center: Vector2 = rect.get_center()
			draw_arc(center, 12 + ratio * 14, -PI, 0, 18, Color("b7d7bd", 1 - ratio), 2)

func _draw_projectile() -> void:
	if reduced or enemy_action or not damaging or not clip.has("launch_at") or clock.impacted: return
	var launch = float(clip.launch_at)
	if clock.elapsed < launch or clock.impact_at <= launch: return
	var p = clampf((clock.elapsed - launch) / (clock.impact_at - launch), 0, 1)
	var origin = source_rect.get_center() + Vector2(35, -12)
	for target in hurt_targets:
		var end: Vector2 = target.get_center()
		var position = origin.lerp(end, p)
		var direction = (end - origin).normalized()
		draw_line(position - direction * 12, position, Color(tint, 0.8), 2)
		draw_circle(position, 3, Color("fff2cf"))

func _skill_effect(age: float) -> void:
	# These strokes depict resolved results; they never create damage or statuses.
	if age > 0.38 or reduced: return
	var p = clampf(age / 0.38, 0, 1)
	var col = Color(tint, (1.0 - p) * 0.8)
	if action == "guard" or (character_id == "hildegard" and action in ["personal", "duty"]):
		var c = source_rect.get_center() + Vector2(35, 0)
		var h = 28.0 + p * 5
		draw_polyline(PackedVector2Array([c + Vector2(-11,-h),c + Vector2(9,-h*.8),c + Vector2(14,0),c + Vector2(7,h*.7),c + Vector2(-9,h)]),col,2)
	if character_id == "hildegard" and action in ["taunt", "personal", "duty"]:
		var c = source_rect.get_center() + Vector2(12, -4)
		for i in range(2): draw_arc(c, 22 + p * 30 + i * 6, -0.65, 0.65, 16, col, 2)
	elif character_id == "bargut" and action == "personal" and damaging:
		for rect in hurt_targets:
			var c = rect.get_center()
			draw_polyline(PackedVector2Array([c+Vector2(-19,-13),c+Vector2(-5,-4),c+Vector2(-9,6),c+Vector2(13,16)]),col,2)
	elif character_id == "teiris" and damaging:
		for rect in hurt_targets:
			var c = rect.get_center()
			var reach = (23 if action in ["personal", "burst"] else 13) * p
			for i in range(5):
				var direction = Vector2.from_angle(i * TAU / 5)
				var tip = c + direction * reach
				draw_line(tip, tip + direction * 7, col, 2)
	elif character_id == "berenga" and not damaging and action in ["personal", "hshield", "bless"]:
		for rect in targets:
			var c = rect.get_center()
			if action == "personal":
				draw_line(c + Vector2(-7,-5), c + Vector2(7,-5), col, 2)
				draw_line(c + Vector2(0,-12), c + Vector2(0,2), col, 2)
				for i in range(2): draw_arc(c, 13 + i * 5, p * PI + i * PI, p * PI + i * PI + 1.6, 12, col, 2)
			elif action == "hshield": draw_arc(c, 18, PI, TAU, 20, col, 2)
			else: draw_polyline(PackedVector2Array([c+Vector2(-8,2-p*12),c+Vector2(0,-6-p*12),c+Vector2(8,2-p*12)]),col,2)

func reaction_offset() -> Vector2:
	if reduced or not damaging or not clock.impacted: return Vector2.ZERO
	var age = float(Time.get_ticks_msec() - contact_wall_time) / 1000.0
	return Vector2(((-1 if enemy_action else 1) * 5.0) * maxf(0, 1 - age / 0.18), 0)

func shake_offset() -> Vector2:
	if reduced or not damaging or not clock.impacted: return Vector2.ZERO
	var age = float(Time.get_ticks_msec() - contact_wall_time) / 1000.0
	if age >= 0.10: return Vector2.ZERO
	return Vector2(roundf(sin(age * 170) * 2 * (1 - age / 0.10)), 0)

func skip() -> void:
	for event in clock.skip():
		if event == "impact": impact_count += 1; impact.emit()
	_publish()
	_cleanup()
	finished.emit()
	queue_free()

func _cleanup() -> void:
	if on_visual_update.is_valid(): on_visual_update.call(null)

func _exit_tree() -> void:
	_cleanup()

func _play_sound(kind: String) -> void:
	var path = "res://assets/audio/combat-" + kind + ".wav"
	if not ResourceLoader.exists(path): return
	var player = AudioStreamPlayer.new()
	player.stream = load(path)
	player.volume_db = -16.0
	get_parent().add_child(player)
	player.set_meta("combat_sequence", true)
	player.finished.connect(player.queue_free)
	player.play()

func _publish() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__abyssMotion=" + JSON.stringify({"sequence":sequence_id,"character":character_id,"action":action,"elapsed":clock.elapsed,"contact":clock.impact_at,"impacted":clock.impacted,"impact_count":impact_count,"stop":clock.remaining_stop,"done":clock.finished,"reduced":reduced,"frame":body_frame,"sheet":clip.get("path", ""),"damaging":damaging}), true)
