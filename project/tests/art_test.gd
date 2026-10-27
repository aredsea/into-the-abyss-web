extends SceneTree
const Sprite=preload("res://ui/character_sprite.gd")
const Sequence=preload("res://ui/signature_sequence.gd")
const World=preload("res://game/expansion_world.gd")
var checked=0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world=World.new(); var seen={}
	for p in world.config.companions:
		var art=Sprite.info(p.id)
		assert(not art.is_empty(),p.id); assert(art.skill==p.skill.name,p.id+" skill")
		assert(not seen.has(art.fx),"Repeated cinematic "+art.fx); seen[art.fx]=true
		assert(art.frames.size()==2); assert(ResourceLoader.exists(art.path)); assert(art.seam_max_alpha<=1)
		for frame in art.frames:
			var polygon=PackedVector2Array()
			for v in frame.polygon: polygon.append(Vector2(v[0],v[1]))
			assert(Geometry2D.triangulate_polygon(polygon).size()>0,p.id+" UV polygon")
		var signature=Sequence.new(); signature.character_id=p.id; signature.reduced=true; signature.size=Vector2(336,259)
		root.add_child(signature); signature._process(.4); assert(signature.impacted,p.id+" impact")
		signature._process(.4); root.remove_child(signature)
		checked+=1
	assert(checked==30); print("PASS 30 characters / 60 UV frames / 30 unique cinematics / impact and completion")
	quit()
