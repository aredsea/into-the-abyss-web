extends "res://ui/forged_button.gd"
var caption=""
var emblem: Texture2D
func configure(label: String, id: String) -> void:
	caption=label; navigation=true
	emblem=load("res://assets/ui-r11/"+id+".svg")
	tooltip_text=label
func _draw() -> void:
	super._draw()
	if emblem: draw_texture_rect(emblem,Rect2((size.x-23)/2,5,23,23),false)
	var width=UI.TITLE.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	draw_string(UI.TITLE,Vector2((size.x-width)/2,44),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,UI.BLUE if active else UI.MUTED)
