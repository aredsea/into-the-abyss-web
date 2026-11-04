extends Control
## The original stat allocation meter, inside the existing form row.
const T=preload("res://ui/town_theme_r21.gd")
var base_ratio=0.0
var total_ratio=0.0
func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),T.LINE)
	draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*total_ratio,size.y)),T.ACTION_RED)
	draw_rect(Rect2(Vector2.ZERO,Vector2(size.x*base_ratio,size.y)),T.INK)
