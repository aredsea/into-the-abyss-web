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
			var yy=clampf(15+9*u+sin(u*19+float(kind.hash()%13))*6+rng.randf_range(-7,7),3,35)
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
			shapes.append(_shape([a+Vector2(-5,-16),b+Vector2(9,-13),b+Vector2(-2,rng.randf_range(-2,4)),a+Vector2(-3,rng.randf_range(-1,5))],BLACK))
			if rng.randf()<.72:
				shapes.append(_shape([a+Vector2(-11,3),b+Vector2(12,0),b+Vector2(18,rng.randf_range(7,14)),a+Vector2(-7,7)],RED))
		for i in range(48):
			var p=edge[rng.randi_range(0,65)]+Vector2(rng.randf_range(-4,4),rng.randf_range(4,21))
			shapes.append(_shape([p,p+Vector2(2,-1),p+Vector2(rng.randf_range(1,5),2)],RED if i%3 else BLACK))
		# Dry-brush paper channels interrupt the lip instead of a solid band.
		for i in range(31):
			var p=edge[rng.randi_range(0,65)]+Vector2(-8,rng.randf_range(-3,8))
			shapes.append(_shape([p,p+Vector2(rng.randf_range(12,28),-9),p+Vector2(9,0),p+Vector2(-8,7)],Color("f4efe3")))
	elif kind=="target-ring":
		var outer=[]; var inner=[]
		for i in range(57):
			var a=TAU*i/56.0
			var point=Vector2(size.x*.5+cos(a)*size.x*.48,size.y*.88+sin(a)*8-cos(a)*4)
			outer.append(point+Vector2(0,rng.randf_range(-1,1)))
			inner.append(Vector2(size.x*.5+cos(a)*(size.x*.48-3),size.y*.88+sin(a)*5-cos(a)*4))
		for piece in Geometry2D.clip_polygons(PackedVector2Array(outer),PackedVector2Array(inner)):
			if not Geometry2D.is_polygon_clockwise(piece): shapes.append({"polygon":piece,"color":RED})
		for x in [3.0,size.x-7]:
			for y in [2.0,size.y*.7]:
				shapes.append(_shape([Vector2(x,y),Vector2(x+3,y+1),Vector2(x+7,y+18),Vector2(x+4,y+18)],RED))
		for i in range(25):
			var point=Vector2(rng.randf_range(0,size.x),rng.randf_range(size.y*.67,size.y))
			shapes.append(_shape([point,point+Vector2(9,-9),point+Vector2(3,5)],RED))
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
		# Long tapered channels, irregular tips and exposed black bristles.
		# These are freshly authored vector gaps, not a traced raster contour.
		for i in range(19):
			var t=i/18.0
			var p=Vector2(size.x*(.12+.69*t),size.y*(.88-.2*t))
			var length=rng.randf_range(25,100)
			shapes.append(_shape([p,p+Vector2(length*.34,-length),p+Vector2(length*.34+2,-length+8),p+Vector2(rng.randf_range(1,4),4)],Color("f4efe3")))
	elif kind.begins_with("sheet-"):
		for i in range(27):
			var p=Vector2(rng.randf_range(-4,size.x*.2),rng.randf_range(0,size.y*.5))
			var end=Vector2(rng.randf_range(size.x*.55,size.x),rng.randf_range(size.y*.55,size.y))
			shapes.append(_shape([p,end,end+Vector2(-10,rng.randf_range(1,4)),p+Vector2(3,rng.randf_range(3,8))],RED if kind=="sheet-status" or i%3==0 else BLACK))
		for i in range(22):
			var p=Vector2(rng.randf_range(0,size.x),rng.randf_range(0,size.y))
			shapes.append(_shape([p,p+Vector2(3,1),p+Vector2(7,3)],tint))
	elif kind=="base":
		# Broad diagonal dry brush: individually tapered bristles leave paper
		# channels. Geometry is authored here, never sampled from reference ink.
		for i in range(40):
			var x=rng.randf_range(-28,size.x*.78)
			var y=size.y*(.45-.42*x/size.x)+rng.randf_range(-6,8)
			var length=rng.randf_range(20,68)
			shapes.append(_shape([Vector2(x,y),Vector2(x+length,y-12),Vector2(x+length-9,y-5),Vector2(x-5,y+8)],BLACK))
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
