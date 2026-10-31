extends Control
## Slot contract for branch C. Missing slots fall back to original source art.
const Original=preload("res://ui/character_portrait.gd")
var character_id=""
var kind="bust"
var source_path=""
var texture: Texture2D
var shift=Vector2.ZERO

static func preferred_path(id: String,slot: String) -> String:
	var preferred="res://assets/portraits-r21/"+id+"-"+slot+".png"
	if ResourceLoader.exists(preferred): return preferred
	var original="res://assets/portraits-r10/"+id+("-face.png" if slot=="face" else "-cutout.png")
	return original if ResourceLoader.exists(original) else ""

func configure(id: String,slot="bust") -> void:
	character_id=id; kind=slot; source_path=preferred_path(id,slot)
	for c in get_children(): remove_child(c); c.queue_free()
	if not source_path.is_empty():
		texture=load(source_path)
	else:
		var t=Original.new(); add_child(t); t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); t.configure(id)
	clip_contents=true; mouse_filter=MOUSE_FILTER_IGNORE; texture_filter=TEXTURE_FILTER_LINEAR
	queue_redraw()

func _draw() -> void:
	if texture:
		var k=maxf(size.x/texture.get_width(),size.y/texture.get_height())
		var scaled=texture.get_size()*k
		var y=(size.y-scaled.y)*.65 if kind=="face" else 0.0
		draw_texture_rect(texture,Rect2(Vector2((size.x-scaled.x)/2,y)+shift,scaled),false)
