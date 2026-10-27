extends Node2D
## Visual-only sequence. Battle resolution stays in battle_v3 / battle_state.
signal impact
signal finished
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
	var length = 0.65 if action == "attack" else 0.78
	var contact = 0.22 if action == "attack" else 0.30
	if enemy_action: length = 0.58; contact = 0.20
	var manifest_path = "res://data/motion-r6.json"
	if FileAccess.file_exists(manifest_path) and not enemy_action:
		var catalog = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
		clip = catalog.get(character_id + ":" + action, {})
		if not clip.is_empty():
			sheet = load(clip.path)
			length = float(clip.get("duration", length))
			contact = float(clip.get("impact_at", contact))
			contact_frame = int(clip.get("contact_frame", 4))
	if reduced: length = 0.36; contact = 0.12
	# Keep the existing 30 distinct personal-skill presentations. Their clock
	# follows the same contact timeline as HP, so skipping cannot apply twice.
	if action == "personal" and not enemy_action:
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
	var t = clock.elapsed
	var fraction = smoothstep(0.05, clock.impact_at, t) * (1.0 - smoothstep(clock.impact_at + 0.13, clock.duration, t))
	return Vector2(22.0 * fraction, -2.0 * fraction)

func _draw() -> void:
	if sheet != null:
		var count = int(clip.frames)
		var t = clock.elapsed
		if t <= clock.impact_at:
			body_frame = mini(contact_frame, int(t / clock.impact_at * contact_frame))
		else:
			body_frame = mini(count - 1, contact_frame + int((t - clock.impact_at) / (clock.duration - clock.impact_at) * (count - contact_frame)))
		if reduced: body_frame = contact_frame if clock.impacted else 0
		var region = Rect2((body_frame % 5) * 256, int(body_frame / 5) * 256, 256, 256)
		var side = source_rect.size.y * 256.0 / 204.0
		var origin = Vector2(source_rect.get_center().x - side / 2.0, source_rect.end.y - side * 230.0 / 256.0)
		draw_texture_rect_region(sheet, Rect2(origin + _step(), Vector2.ONE * side), region)
	if not clock.impacted: return
	var age = maxf(0.0, float(Time.get_ticks_msec() - contact_wall_time) / 1000.0)
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
