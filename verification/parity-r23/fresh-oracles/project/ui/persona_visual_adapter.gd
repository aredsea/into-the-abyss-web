extends RefCounted
## The source persona has no portrait (pimg(nil)). Supply that neutral placeholder
## to the legacy renderer in memory. No battle file or portrait asset is changed.
const Portrait=preload("res://ui/character_portrait.gd")
static var placeholder: ImageTexture
static func prepare() -> void:
	if placeholder!=null:return
	var picture=Image.new()
	picture.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="160" viewBox="0 0 128 160"><rect width="128" height="160" fill="#e6dfcf"/><circle cx="64" cy="47" r="25" fill="#62665d"/><path d="M16 160v-34c0-29 21-47 48-47s48 18 48 47v34z" fill="#62665d"/></svg>')
	placeholder=ImageTexture.create_from_image(picture)
	placeholder.take_over_path("res://assets/persona.webp")
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector2Array([Vector2.ZERO,Vector2(128,0),Vector2(128,160),Vector2(0,160)])
	arrays[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3])
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	Portrait.cache.persona={"texture":placeholder,"mesh":mesh,"bounds":Rect2(0,0,128,160),"path":""}
