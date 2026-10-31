extends RefCounted
## All effect strokes are opaque, non-antialiased squares on a 3px lattice.
var canvas: CanvasItem
var grid = 3.0
var clip_rect=Rect2()
func _init(target: CanvasItem) -> void: canvas = target
func snap(v: Vector2) -> Vector2: return (v / grid).round() * grid
func block(rect: Rect2,color: Color) -> void:
	if clip_rect.has_area(): rect=rect.intersection(clip_rect)
	if rect.has_area(): canvas.draw_rect(rect,color)
func draw_line(a: Vector2, b: Vector2, color: Color, width = 3.0, _aa = false) -> void:
	var steps = maxi(1, ceili((b-a).length()/grid))
	var side = maxf(grid, ceilf(width/grid)*grid)
	for i in range(steps+1): block(Rect2(snap(a.lerp(b,float(i)/steps)),Vector2.ONE*side),color)
func draw_polyline(points: PackedVector2Array, color: Color, width = 3.0) -> void:
	for i in range(points.size()-1): draw_line(points[i],points[i+1],color,width)
func draw_arc(c: Vector2, r: float, a: float, b: float, _count: int, color: Color, width = 3.0) -> void:
	var steps = maxi(8,ceili(absf(b-a)*r/grid))
	for i in range(steps):
		draw_line(c+Vector2.from_angle(lerpf(a,b,float(i)/steps))*r,c+Vector2.from_angle(lerpf(a,b,float(i+1)/steps))*r,color,width)
func draw_rect(rect: Rect2, color: Color, filled = true, width = 3.0) -> void:
	if filled: block(Rect2(snap(rect.position),snap(rect.size)),color)
	else:
		var a=rect.position; var b=rect.end
		draw_polyline(PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y),a]),color,width)
func draw_circle(c: Vector2, r: float, color: Color) -> void:
	for y in range(-ceili(r/grid),ceili(r/grid)+1):
		for x in range(-ceili(r/grid),ceili(r/grid)+1):
			var p=Vector2(x,y)*grid
			if p.length()<=r: block(Rect2(snap(c+p),Vector2.ONE*grid),color)
func draw_colored_polygon(points: PackedVector2Array, color: Color) -> void:
	var lo=points[0]; var hi=lo
	for p in points: lo=lo.min(p); hi=hi.max(p)
	for y in range(floori(lo.y/grid),ceili(hi.y/grid)+1):
		for x in range(floori(lo.x/grid),ceili(hi.x/grid)+1):
			var p=Vector2(x,y)*grid
			if Geometry2D.is_point_in_polygon(p+Vector2.ONE*grid*.5,points): block(Rect2(p,Vector2.ONE*grid),color)
