extends Control
## R20b typed vector resource with even-odd holes and cached coverage.
var kind = "base"
var tint = Color("111715")
var text_source: Control
const BLACK = Color("111715")
const RED = Color("d83219")
static var data: Dictionary = {}
static var meshes: Dictionary = {}
static var preparation: Dictionary = {}
var paint_layer = -1 # Isolated-layer verification uses the production renderer.

static func load_paths() -> Dictionary:
	return load("res://assets/ui-r20/ink-paths.res").get_meta("ink")

static func compile_meshes(key: String, paint: Array) -> void:
	if meshes.has(key): return
	var compiled=[]
	for layer in paint:
		var arrays=[]; arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=layer.vertices; arrays[Mesh.ARRAY_INDEX]=layer.indices
		var mesh=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var color=Color(layer.color[0]/255.0,layer.color[1]/255.0,layer.color[2]/255.0)
		var outlines=[]
		for path in layer.paths:
			var closed=path.duplicate(); closed.append(path[0]); outlines.append(closed)
		compiled.append([mesh,color,outlines])
	meshes[key]=compiled

static func prepare_initial() -> void:
	if not preparation.is_empty(): return
	var memory_before=OS.get_static_memory_usage(); var start=Time.get_ticks_usec()
	data=load_paths(); var loaded=Time.get_ticks_usec()
	# These are the three visible assets on every initial battle screen. Meshes
	# are independent of viewport dimensions and shared by every subsequent UI.
	for name in ["battle-mask-base","edge-base","gesture-base"]:
		var cover=name.begins_with("battle-mask")
		compile_meshes(name+str(cover)+"-1",[data.assets[name].cover] if cover else data.assets[name].layers)
	var done=Time.get_ticks_usec()
	preparation={"total_ms":(done-start)/1000.0,"load_ms":(loaded-start)/1000.0,"mesh_ms":(done-loaded)/1000.0,"cache_cpu_ms":0.0,"cpu_ms":(done-start)/1000.0,"mesh_cache_entries":meshes.size(),"texture_cache_entries":0,"static_before_bytes":memory_before,"static_after_bytes":OS.get_static_memory_usage()}
	preparation.static_delta_bytes=preparation.static_after_bytes-memory_before
	preparation.static_counter_available=preparation.static_after_bytes>0
	var packed_bytes=0; var initial_mesh_bytes=0
	for name in data.assets:
		var a=data.assets[name]; var paint=a.layers.duplicate()
		if a.has("cover"): paint.append(a.cover)
		for layer in paint:
			packed_bytes+=layer.vertices.size()*8+layer.indices.size()*4
			for path in layer.paths: packed_bytes+=path.size()*8
		for layer in ([a.cover] if name=="battle-mask-base" else a.layers if name in ["edge-base","gesture-base"] else []):
			initial_mesh_bytes+=layer.vertices.size()*8+layer.indices.size()*4
	preparation.retained_packed_vector_bytes=packed_bytes
	preparation.initial_mesh_buffer_bytes=initial_mesh_bytes
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__abyssInkPrep = "+JSON.stringify(preparation)+";",true)

class PaintSurface extends Node2D:
	var paint_meshes: Array = []
	func _draw() -> void:
		for paint in paint_meshes:
			draw_mesh(paint[0], null, Transform2D.IDENTITY, paint[1])
			# A subpixel, low-alpha fringe smooths the single threshold contour.
			# Unlike viewport MSAA this works on WebGL's Compatibility renderer.
			var feather=paint[1]; feather.a=.10
			for path in paint[2]:
				draw_polyline(path,feather,.5,true)

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	prepare_initial()
	call_deferred("_bake")

func asset_name() -> String:
	if kind.begins_with("edge-"): return kind
	if kind.begins_with("mask-"): return "battle-"+kind
	return {"base":"gesture-base", "target-bloom":"gesture-target", "sheet-status":"gesture-status", "sheet-skills":"gesture-skills", "sheet-supplies":"gesture-supplies", "log-tail":"gesture-log-r17-hires"}.get(kind,kind)

func asset() -> Dictionary:
	if data.is_empty(): data=load_paths()
	return data.assets[asset_name()]

func layers() -> Array:
	var a=asset()
	if paint_layer>=0: return [a.layers[paint_layer]]
	return [a.cover] if kind.begins_with("mask-") else a.layers

func _bake() -> void:
	var a=asset(); var key=asset_name()+str(kind.begins_with("mask-"))+str(paint_layer)
	compile_meshes(key,layers())
	var visible=Rect2(Vector2.ZERO,size)
	if is_instance_valid(text_source):
		var clip: Rect2=text_source.frame; clip.position-=global_position
		visible=visible.intersection(clip)
	if not visible.has_area(): return
	var crop=Control.new(); crop.position=visible.position; crop.size=visible.size
	crop.clip_contents=true; crop.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(crop)
	var painter=PaintSurface.new(); painter.paint_meshes=meshes[key]
	painter.scale=size/Vector2(a.size[0],a.size[1]); painter.position=-visible.position
	crop.add_child(painter)

func bounds(polygon: PackedVector2Array) -> Rect2:
	var r=Rect2(polygon[0],Vector2.ZERO)
	for point in polygon: r=r.expand(point)
	return r

func raw_polygons() -> Array:
	var result=[]; var a=asset(); var ratio=size/Vector2(a.size[0],a.size[1])
	for layer in layers():
		for path in layer.paths:
			var p=PackedVector2Array()
			for v in path: p.append(Vector2(v[0],v[1])*ratio)
			result.append({"polygon":p,"color":Color(layer.color[0]/255.0,layer.color[1]/255.0,layer.color[2]/255.0),"fill_rule":"even-odd"})
	return result

func polygons() -> Array:
	# Comp paint is behind foreground text, with explicit heading paper backing.
	return raw_polygons()

