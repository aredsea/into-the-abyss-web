extends Control
## All screen portraits use the shared R24 masters and landmark composition.
const Layout=preload("res://ui/portrait_layout_r24.gd")
var character_id=""
var kind=""
var source_path=""
var picture: Control
static func make(id: String,slot_kind: String,dimensions: Vector2) -> Control:
	var node=load("res://ui/portrait_slot_r24.gd").new()
	node.custom_minimum_size=dimensions;node.size=dimensions;node.configure(id,slot_kind)
	return node
func configure(id: String,slot_kind="upperbody") -> void:
	character_id=id;kind=slot_kind;mouse_filter=MOUSE_FILTER_IGNORE;clip_contents=true
	for child in get_children():remove_child(child);child.queue_free()
	source_path=Layout.path(id)
	if source_path!="":
		picture=Layout.make_portrait(id,Layout.kind_for_legacy(slot_kind),size);add_child(picture)
		picture.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		var material=ShaderMaterial.new();material.shader=preload("res://ui/portrait_slot_r24.gdshader");picture.material=material
	else:
		var icon=TextureRect.new();add_child(icon);icon.texture=preload("res://assets/ui-r24/person.svg")
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(PRESET_FULL_RECT);icon.offset_left=size.x*.27;icon.offset_right=-size.x*.27;icon.offset_top=size.y*.18;icon.offset_bottom=-size.y*.28
		icon.modulate=Color("7a6f60");icon.mouse_filter=MOUSE_FILTER_IGNORE
func knockout() -> void:
	if is_instance_valid(picture) and picture.material is ShaderMaterial:picture.material.set_shader_parameter("knocked_out",true)
