extends Control
## The reskin lane's only portrait entry point. The portrait lane can replace
## this implementation without changing any screen or gameplay data.
var character_id=""
var kind=""
var source_path=""
var picture: TextureRect
static func make(id: String,slot_kind: String,dimensions: Vector2) -> Control:
	var node=load("res://ui/portrait_slot_r24.gd").new()
	node.custom_minimum_size=dimensions;node.size=dimensions;node.configure(id,slot_kind)
	return node
func configure(id: String,slot_kind="upperbody") -> void:
	character_id=id;kind=slot_kind;mouse_filter=MOUSE_FILTER_IGNORE
	for child in get_children():remove_child(child);child.queue_free()
	var wash=TextureRect.new();add_child(wash);wash.texture=preload("res://assets/ui-r24/wash.png");wash.set_anchors_and_offsets_preset(PRESET_FULL_RECT);wash.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;wash.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;wash.mouse_filter=MOUSE_FILTER_IGNORE
	source_path="res://assets/portraits-r21/"+id+"-upperbody.png"
	if not ResourceLoader.exists(source_path):source_path="res://assets/"+id+".webp"
	if id=="persona" or not ResourceLoader.exists(source_path):
		source_path="";var icon=TextureRect.new();add_child(icon);icon.texture=preload("res://assets/ui-r24/person.svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.set_anchors_and_offsets_preset(PRESET_FULL_RECT);icon.offset_left=size.x*.22;icon.offset_right=-size.x*.22;icon.offset_top=size.y*.18;icon.offset_bottom=-size.y*.25;icon.modulate=Color("7a6f60");icon.mouse_filter=MOUSE_FILTER_IGNORE;return
	picture=TextureRect.new();add_child(picture);picture.texture=load(source_path);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.mouse_filter=MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=preload("res://ui/portrait_slot_r24.gdshader") if source_path.contains("upperbody") else preload("res://ui/portrait_slot_multiply_r24.gdshader");picture.material=material
	resized.connect(_layout) if not resized.is_connected(_layout) else false
	_layout()
func _layout() -> void:
	if not is_instance_valid(picture):return
	picture.position=Vector2(size.x*.02,size.y*.055);picture.size=Vector2(size.x*.96,size.y*.945)
func knockout() -> void:
	if is_instance_valid(picture) and picture.material is ShaderMaterial:picture.material.set_shader_parameter("knocked_out",true)
