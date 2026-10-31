extends Node2D
## Visual-only sequence. Battle resolution stays in battle_v3 / battle_state.
signal impact
signal finished
const Motion = preload("res://ui/motion_library.gd")
const Clock = preload("res://ui/combat_timeline.gd")
const Figure = preload("res://ui/battle_body_r18.gd")
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
var element="none"
var clip_start=0.0
var hit_material: ShaderMaterial
var flash_frame=-10
const FX=preload("res://ui/combat_fx.gd")

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
	if action == "personal" and not enemy_action:
		clip_start=.6 if not reduced else 0.0
		if not reduced:
			length=clip_start+float(clip.duration) if not clip.is_empty() else 1.65
			contact=clip_start+float(clip.impact_at) if not clip.is_empty() else 1.10
			length=maxf(length,contact+.4)
		signature=Signature.new(); signature.character_id=character_id
		signature.reduced=reduced; signature.externally_timed=true
		signature.duration=length; signature.contact_at=contact
		signature.position=field.position; signature.size=field.size
		add_child(signature)
	clock.configure(contact,length,0.0 if reduced or not damaging else .035)
	var shader=Shader.new(); shader.code="shader_type canvas_item; void fragment(){ vec4 c=texture(TEXTURE,UV); COLOR=vec4(vec3(1.0),c.a); }"
	hit_material=ShaderMaterial.new(); hit_material.shader=shader
	if sheet == null:
		if enemy_action:
			var picture = TextureRect.new()
			picture.texture = source_image
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			figure = picture
		else:
			var body = Figure.new()
			body.battle_pixels=true
			body.configure(character_id, action != "guard")
			figure = body
		add_child(figure)
		figure.mouse_filter = Control.MOUSE_FILTER_IGNORE
		figure.position = source_rect.position
		figure.size = source_rect.size
		figure_home = figure.position
	if is_instance_valid(signature): move_child(signature,get_child_count()-1)
	_play_sound("ready")
	_publish()

func _process(delta: float) -> void:
	for event in clock.advance(delta):
		if event == "impact":
			impact_count += 1
			flash_frame=Engine.get_process_frames()
			contact_wall_time = Time.get_ticks_msec()
			impact.emit()
			_play_sound("hit" if damaging else "support")
		elif event == "finished":
			_cleanup()
			finished.emit()
			queue_free()
	if is_instance_valid(figure): figure.position = figure_home + _step()
	if is_instance_valid(signature):
		signature.elapsed=clock.elapsed; signature.refresh()
	if is_instance_valid(figure) and signature!=null: figure.visible=clock.elapsed>=clip_start or reduced
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
		var ready = clip_start+minf((clock.impact_at-clip_start)*.7,.24)
		var recovery = clip_start+float(clip.get("return_at",(clock.duration-clip_start)*.66))
		var fraction = smoothstep(clip_start+.035, ready, clock.elapsed) * (1.0 - smoothstep(recovery, clock.duration - 0.03, clock.elapsed))
		return (destination - origin) * fraction
	# A posed step already moves the pelvis and planted feet inside the frames.
	if clip.get("root_motion", false): return Vector2.ZERO
	var t = clock.elapsed
	var fraction = smoothstep(0.05, clock.impact_at, t) * (1.0 - smoothstep(clock.impact_at + 0.13, clock.duration, t))
	return Vector2(22.0 * fraction, -2.0 * fraction)

func _draw() -> void:
	if sheet!=null and (clock.elapsed>=clip_start or reduced):
		body_frame=Motion.frame_at(clip,maxf(0,clock.elapsed-clip_start))
		if reduced: body_frame=contact_frame if clock.impacted else 0
		Motion.draw_frame(self,clip,body_frame,source_rect,_step(),2)
	var personal=action=="personal" and not enemy_action
	var motif=Figure.info(character_id).get("fx","") if personal else "shelter" if action=="guard" else "wolf_roar" if action=="taunt" else "triage" if action.begins_with("item:") else ""
	var visual_targets=targets if not targets.is_empty() else [source_rect]
	if action in ["guard","taunt"]: visual_targets=[source_rect]
	FX.paint(self,element,motif,clock.elapsed,clock.impact_at,clock.duration,source_rect,visual_targets,reduced,personal,field)

func hit_flash() -> bool:
	var frames=Engine.get_process_frames()-flash_frame
	return not reduced and damaging and clock.impacted and frames>=0 and frames<2

func reaction_offset() -> Vector2:
	if reduced or not damaging or not clock.impacted: return Vector2.ZERO
	var age = clock.elapsed-clock.impact_at
	return Vector2(((-1 if enemy_action else 1) * 5.0) * maxf(0, 1 - age / 0.18), 0)

func shake_offset() -> Vector2:
	if reduced or not damaging or not clock.impacted: return Vector2.ZERO
	var age = clock.elapsed-clock.impact_at
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
