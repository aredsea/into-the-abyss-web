extends Control
## Geometric card boundary from the approved collage, independent of portrait RGB.
func _ready() -> void:
	clip_children=CanvasItem.CLIP_CHILDREN_ONLY
	mouse_filter=MOUSE_FILTER_IGNORE
func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(0,20),Vector2(size.x,0),Vector2(size.x,size.y-35),Vector2(0,size.y)]),Color.WHITE)
