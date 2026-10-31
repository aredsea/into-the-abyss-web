extends Control
## CSS object-fit:cover with explicit object-position. Original texture only.
var picture: Texture2D
var alignment=Vector2(.5,0)
func _ready() -> void:
	clip_contents=true; mouse_filter=MOUSE_FILTER_IGNORE; texture_filter=TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if picture==null: return
	var factor=maxf(size.x/picture.get_width(),size.y/picture.get_height())
	var extent=picture.get_size()*factor
	draw_texture_rect(picture,Rect2((size-extent)*alignment,extent),false)
