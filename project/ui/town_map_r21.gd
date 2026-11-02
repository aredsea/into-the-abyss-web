extends Control
## Presentation of A's serial state machine, never a route generator.
const T=preload("res://ui/town_theme_r21.gd")
var progress=0
var steps=5
var phase="explore"
var points=[]
func configure(run: Dictionary,count: int) -> void:
	progress=int(run.step);steps=count;phase=run.phase;mouse_filter=MOUSE_FILTER_IGNORE
	points=[Vector2(177,20),Vector2(81,77),Vector2(267,123),Vector2(98,170),Vector2(264,217),Vector2(177,262),Vector2(85,303),Vector2(274,303)]
	queue_redraw()
func _draw() -> void:
	if points.is_empty():return
	for i in range(points.size()-1):
		var color=T.RED if i<progress else Color("ddd4bd")
		draw_line(points[i],points[i+1],T.INK,6,true);draw_line(points[i],points[i+1],color,3,true)
	var current=6 if phase=="rest" else mini(progress,steps)
	for i in range(points.size()):
		var at=points[i];var reached=i<=current
		draw_circle(at,17,T.PAPER,true,-1,true);draw_circle(at,15,T.RED if reached else T.INK,true,-1,true)
		if i==current:draw_arc(at,21,0,TAU,36,T.RED,3,true)
		if i==0:
			for x in [-6,6]:draw_line(at+Vector2(x,7),at+Vector2(x,-7),T.PAPER,2,true)
			draw_line(at+Vector2(-7,-6),at+Vector2(7,-6),T.PAPER,2,true)
		elif i==steps+1:
			draw_line(at+Vector2(-8,5),at+Vector2(8,5),T.PAPER,3,true)
			draw_line(at+Vector2(-7,-6),at+Vector2(-7,9),T.PAPER,2,true)
			draw_line(at+Vector2(7,0),at+Vector2(7,9),T.PAPER,2,true)
			draw_rect(Rect2(at+Vector2(-4,-2),Vector2(9,5)),T.PAPER)
		elif i==steps+2:
			draw_polyline(PackedVector2Array([at+Vector2(-7,-6),at+Vector2(0,-9),at+Vector2(7,-6),at+Vector2(6,3),at+Vector2(0,9),at+Vector2(-6,3),at+Vector2(-7,-6)]),T.PAPER,2,true)
		else:
			# A generic compass marks an unresolved roll, never a promised fight/loot.
			draw_colored_polygon(PackedVector2Array([at+Vector2(0,-9),at+Vector2(4,0),at+Vector2(0,9),at+Vector2(-4,0)]),T.PAPER)
			draw_line(at+Vector2(-8,0),at+Vector2(8,0),T.PAPER,2,true)
		var text="입구" if i==0 else "휴식" if i==steps+1 else "층 보스" if i==steps+2 else "탐색 %d"%i
		var w=T.BOLD.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		draw_rect(Rect2(at+Vector2(-w/2-5,21),Vector2(w+10,18)),T.PAPER)
		draw_string(T.BOLD,at+Vector2(-w/2,34),text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,T.INK)
		if i==current:
			draw_colored_polygon(PackedVector2Array([at+Vector2(-5,-32),at+Vector2(5,-32),at+Vector2(0,-24)]),T.RED)
