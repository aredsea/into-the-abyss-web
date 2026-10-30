extends Control
## Original vector geometry. Drawing and tests share polygons(). No image traces.
var kind = "base"
var tint = Color("111715")
var text_source: Control
const BLACK=Color("111715")
const RED=Color("d83219")
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _shape(points: Array, color: Color) -> Dictionary:
	var polygon=PackedVector2Array(points)
	if Geometry2D.is_polygon_clockwise(polygon): polygon.reverse()
	return {"polygon":polygon,"color":color}

func bounds(polygon: PackedVector2Array) -> Rect2:
	var r=Rect2(polygon[0],Vector2.ZERO)
	for point in polygon: r=r.expand(point)
	return r

func raw_polygons() -> Array:
	var rng=RandomNumberGenerator.new(); rng.seed=170031+kind.hash()
	var shapes=[]
	if kind.begins_with("edge"):
		var edge=[]
		var field_text=text_source.field_text_regions() if is_instance_valid(text_source) else []
		for i in range(66):
			var u=i/65.0
			var yy=clampf(9+11*u+sin(u*19+float(kind.hash()%13))*5+rng.randf_range(-6,6),3,27)
			# Even the paper transition must stay below enemy nameplates.
			for region in field_text:
				var r: Rect2=region.rect
				if global_position.x+size.x*u>=r.position.x-4 and global_position.x+size.x*u<=r.end.x+4:
					yy=maxf(yy,r.end.y-global_position.y+3)
			edge.append(Vector2(size.x*u,yy))
		var paper=[Vector2(0,size.y),Vector2(size.x,size.y)]
		for i in range(edge.size()-1,-1,-1): paper.append(edge[i])
		shapes.append(_shape(paper,tint))
		# Broken dark lip and vermilion wash follow the irregular paper tear.
		for i in range(0,64,2):
			var a=edge[i]; var b=edge[mini(i+3,65)]
			# Taper toward the title before the safety subtraction, preserving
			# a torn silhouette instead of a long cut along the text rectangle.
			if a.x>9 and a.x<size.x-61: a.y=minf(a.y,rng.randf_range(12,17))
			if b.x>9 and b.x<size.x-61: b.y=minf(b.y,rng.randf_range(12,17))
			shapes.append(_shape([a+Vector2(-2,-5),b+Vector2(3,-3),b+Vector2(-2,rng.randf_range(3,7)),a+Vector2(-3,rng.randf_range(1,6))],BLACK))
			if rng.randf()<.72:
				shapes.append(_shape([a+Vector2(-4,3),b+Vector2(8,0),b+Vector2(-3,rng.randf_range(5,9)),a+Vector2(2,9)],RED))
		for i in range(48):
			var p=edge[rng.randi_range(0,65)]+Vector2(rng.randf_range(-4,4),rng.randf_range(4,21))
			shapes.append(_shape([p,p+Vector2(2,-1),p+Vector2(rng.randf_range(1,5),2)],RED if i%3 else BLACK))
	elif kind=="log-tail":
		# Broad continuous brush body with a dark shoulder and split bristles.
		for color in [BLACK,RED]:
			var left=[]; var right=[]
			for i in range(27):
				var t=i/26.0
				var center=Vector2(size.x*(.80-.55*t),size.y*(.09+.78*t))
				var half=size.x*(.055+.29*pow(sin(PI*t),.7))
				if color==RED: center+=Vector2(-1,5); half*=.87
				left.append(center+Vector2(-half+rng.randf_range(-3,2),rng.randf_range(-2,2)))
				right.append(center+Vector2(half+rng.randf_range(-2,3),rng.randf_range(-2,2)))
			right.reverse(); left.append_array(right); shapes.append(_shape(left,color))
		for i in range(28):
			var t=rng.randf_range(.65,.91)
			var p=Vector2(size.x*(.80-.55*t)+rng.randf_range(-12,12),size.y*(.09+.78*t))
			shapes.append(_shape([p,p+Vector2(rng.randf_range(2,5),1),p+Vector2(-rng.randf_range(3,11),rng.randf_range(10,28))],RED if i%5 else BLACK))
		# A few tapering dry-brush gaps split the end, without turning the
		# broad painted body into a bundle of independent hairlines.
		for i in range(7):
			var p=Vector2(size.x*(.15+i*.035),size.y*rng.randf_range(.88,.98))
			shapes.append(_shape([p,p+Vector2(2,0),p+Vector2(rng.randf_range(6,15),-rng.randf_range(15,43))],Color("f4efe3")))
	elif kind=="base":
		var top=[]; var bottom=[]
		for i in range(42):
			var t=i/41.0
			top.append(Vector2(size.x*t,size.y*(.28-.14*t)+rng.randf_range(-4,3)))
			bottom.append(Vector2(size.x*t,size.y*(.66-.28*t)+rng.randf_range(-4,4)))
		bottom.reverse(); top.append_array(bottom); shapes.append(_shape(top,BLACK))
	else:
		for i in range(18):
			var y=size.y*.3+rng.randf_range(-size.y*.13,size.y*.13)
			shapes.append(_shape([Vector2(0,y),Vector2(size.x*rng.randf_range(.8,1),y-size.y*.25),Vector2(size.x*.9,y+size.y*.1),Vector2(size.x*.04,y+size.y*.3)],tint))
	return shapes

func polygons() -> Array:
	var result=[]
	var regions=text_source.text_regions(3.0) if is_instance_valid(text_source) else []
	for shape in raw_polygons():
		if shape.color!=BLACK and shape.color!=RED:
			result.append(shape); continue # Paper is background, not ink.
		var pieces=[shape.polygon]
		var box=bounds(shape.polygon)
		for region in regions:
			var r: Rect2=region.rect
			r.position-=global_position
			if not r.intersects(box): continue
			var cut=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
			var next=[]
			for p in pieces: next.append_array(Geometry2D.clip_polygons(p,cut))
			pieces=next
		for p in pieces:
			if not Geometry2D.is_polygon_clockwise(p): result.append({"polygon":p,"color":shape.color})
	return result

func _draw() -> void:
	for shape in polygons(): draw_colored_polygon(shape.polygon,shape.color)
