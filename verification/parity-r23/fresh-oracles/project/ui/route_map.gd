extends Control

const Route=preload("res://game/route_v1.gd")
const FONT=preload("res://assets/fonts/GowunBatang-Regular.ttf")
var current="entry"
var path: Array=[]
var options: Array=[]

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func point(id: String) -> Vector2:
	var p=Route.NODES[id].pos
	return Vector2(12+(size.x-24)*p[0],10+(size.y-40)*p[1])

func _draw() -> void:
	for id in Route.NODES:
		for next in Route.NODES[id].next:
			var visited=id in path and next in path
			draw_line(point(id),point(next),Color("8c6833") if visited else Color("bbcbd7"),2 if visited else 1,true)
	for id in Route.NODES:
		var p=point(id); var label=Route.NODES[id].short
		var color=Color("355f80") if id==current else (Color("8c6833") if id in path or id in options else Color("526b7e"))
		draw_circle(p,7,Color("edf3f8"))
		draw_arc(p,7,0,TAU,24,color,1.5,true)
		if id in path: draw_circle(p,4,color)
		if id==current: draw_arc(p,10,0,TAU,24,color,1,true)
		var width=FONT.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
		var left=clampf(p.x-width/2,0,size.x-width)
		draw_rect(Rect2(left-2,p.y+10,width+4,18),Color("edf3f8"))
		draw_string(FONT,Vector2(left,p.y+23),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)
