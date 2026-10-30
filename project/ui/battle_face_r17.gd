extends Control
## Sample the original portrait, cropped to eyebrows/chin; never modify pixels.
var id=""
var picture: Texture2D
func configure(who: String) -> void:
	id=who
	picture=load("res://assets/portraits-r10/"+id+"-face.png") if id in ["hildegard","bargut","teiris","berenga"] else load("res://assets/"+id+".webp")
	queue_redraw()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE; clip_contents=true
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if picture==null: return
	var ratio=size.x/picture.get_width()
	var top={"hildegard":-33.0,"bargut":-37.0,"teiris":-30.0,"berenga":-31.0}.get(id,-size.x*.27)
	if id in ["hildegard","bargut","teiris","berenga"]: top*=size.x/84.0
	draw_texture_rect(picture,Rect2(0,top,size.x,picture.get_height()*ratio),false)
