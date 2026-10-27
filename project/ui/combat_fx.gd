extends Node2D
var element="ice"
var healing=false
var reduced=false
var elapsed=0.0

func _process(delta: float) -> void:
	elapsed+=delta; queue_redraw()
	if elapsed>.6: queue_free()

func _draw() -> void:
	var colors={"ice":Color("b5dfe5"),"bolt":Color("d8c38a"),"fire":Color("d88054"),"holy":Color("eadcb2"),"wind":Color("abcba5"),"dark":Color("a896bb"),"none":Color("c6c6bc")}
	var color=Color("9bd9b0") if healing else colors.get(element,Color.WHITE)
	color.a=(1-elapsed/.6)*.85
	if reduced: draw_arc(Vector2.ZERO,24,0,TAU,20,color,2); return
	var r=12+elapsed*70
	if healing or element=="holy":
		draw_arc(Vector2.ZERO,r,0,TAU,28,color,2)
		for i in range(3):
			var p=Vector2((i-1)*19,-elapsed*45); draw_line(p-Vector2(5,0),p+Vector2(5,0),color,2); draw_line(p-Vector2(0,5),p+Vector2(0,5),color,2)
	elif element=="bolt":
		var points=PackedVector2Array([Vector2(-15,-50),Vector2(9,-15),Vector2(-7,0),Vector2(19,42)])
		draw_polyline(points,color,4,true)
	elif element=="ice":
		for i in range(6):
			var direction=Vector2.from_angle(i*TAU/6); draw_line(direction*8,direction*r,color,3,true)
	elif element=="fire":
		for i in range(7): draw_circle(Vector2.from_angle(i*TAU/7)*r*.5+Vector2(0,-elapsed*35),maxf(1,8-elapsed*12),color)
	else:
		draw_arc(Vector2.ZERO,r,-2.7,-.25,18,color,4,true)
		draw_line(Vector2(-r,r*.6),Vector2(r,-r*.6),color,3,true)
