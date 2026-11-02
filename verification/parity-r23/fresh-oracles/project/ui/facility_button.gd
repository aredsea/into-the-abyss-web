extends "res://ui/forged_button.gd"
var caption=""
var purpose=""
var emblem: Texture2D
func configure(title: String, subtitle: String, icon_name: String) -> void:
	caption=title; purpose=subtitle; emblem=load("res://assets/ui-r11/"+icon_name+".svg")
func _draw() -> void:
	super._draw()
	if emblem: draw_texture_rect(emblem,Rect2(10,(size.y-30)/2,30,30),false)
	draw_string(UI.TITLE,Vector2(48,size.y/2-2),caption,HORIZONTAL_ALIGNMENT_LEFT,size.x-56,14,UI.INK)
	draw_string(UI.BODY,Vector2(48,size.y/2+17),purpose,HORIZONTAL_ALIGNMENT_LEFT,size.x-56,11,UI.MUTED)
