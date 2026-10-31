extends Control
## Sample the original portrait, cropped to eyebrows/chin; never modify pixels.
var id=""
var picture: Texture2D
var reference_party=false
func configure(who: String) -> void:
	id=who
	picture=load("res://assets/portraits-r10/"+id+"-face.png") if id in ["hildegard","bargut","teiris","berenga"] else load("res://assets/"+id+".webp")
	queue_redraw()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE; clip_contents=true
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _draw() -> void:
	if picture==null: return
	var width=84.0 if reference_party and id in ["hildegard","bargut","teiris","berenga"] else size.x
	var ratio=width/picture.get_width()
	var top={"hildegard":-33.0,"bargut":-37.0,"teiris":-30.0,"berenga":-31.0}.get(id,-size.x*.27)
	if reference_party: top+=1 # CSS face-frame's 1px border.
	elif id in ["hildegard","bargut","teiris","berenga"]: top*=size.x/84.0
	# CSS fixes the source face at 84px even when the party column shrinks.
	draw_texture_rect(picture,Rect2((size.x-width)/2,top,width,picture.get_height()*ratio),false)
