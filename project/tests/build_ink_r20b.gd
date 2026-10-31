extends SceneTree
func _initialize() -> void:
	var doc=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/ui-r20/compact-intermediate.json"))
	for a in doc.assets.values():
		var paint=a.layers.duplicate()
		if a.has("cover"): paint.append(a.cover)
		for layer in paint:
			var paths=[]
			for path in layer.paths:
				var points=PackedVector2Array()
				for p in path: points.append(Vector2(p[0],p[1]).snapped(Vector2.ONE/128.0))
				paths.append(points)
			layer.paths=paths
			var vertices=PackedVector2Array()
			for p in layer.vertices: vertices.append(Vector2(p[0],p[1]).snapped(Vector2.ONE/128.0))
			layer.vertices=vertices; layer.indices=PackedInt32Array(layer.indices)
	var resource=Resource.new(); resource.set_meta("ink",doc)
	var intermediate="res://../verification/ui-r20/ink-blocks.res"
	var result=ResourceSaver.save(resource,intermediate,ResourceSaver.FLAG_COMPRESS)
	if result!=OK: quit(result); return
	var input=FileAccess.open(intermediate,FileAccess.READ)
	assert(input.get_buffer(4).get_string_from_ascii()=="RSCC")
	var mode=input.get_32(); var block_size=input.get_32(); var total=input.get_32()
	var sizes=[]
	for i in range(total/block_size+1): sizes.append(input.get_32())
	var raw=PackedByteArray()
	for i in range(sizes.size()):
		raw.append_array(input.get_buffer(sizes[i]).decompress(mini(block_size,total-i*block_size),mode))
	input.close(); assert(raw.size()==total)
	# RSCC is Godot's standard compressed-resource envelope. One complete block
	# shares the compression dictionary across all repeated contours/indices;
	# ResourceSaver's default 4 KiB blocks cannot share that dictionary.
	var compressed=raw.compress(FileAccess.COMPRESSION_ZSTD)
	var output=FileAccess.open("res://assets/ui-r20/ink-paths.res",FileAccess.WRITE)
	output.store_buffer("RSCC".to_ascii_buffer())
	output.store_32(FileAccess.COMPRESSION_ZSTD)
	output.store_32(raw.size()+1); output.store_32(raw.size())
	output.store_32(compressed.size()); output.store_buffer(compressed)
	output.store_buffer("RSCC".to_ascii_buffer()); output.close()
	var loaded=ResourceLoader.load("res://assets/ui-r20/ink-paths.res","",ResourceLoader.CACHE_MODE_IGNORE)
	if loaded==null or loaded.get_meta("ink")!=doc:
		push_error("Binary resource round-trip failed"); quit(1); return
	var evidence=FileAccess.open("res://../verification/ui-r20/binary-roundtrip.json",FileAccess.WRITE)
	evidence.store_string(JSON.stringify({"roundtrip_equal":true,"assets":doc.assets.size(),"compressed_bytes":compressed.size()+24,"decoded_resource_bytes":raw.size(),"resource_sha256":FileAccess.get_sha256("res://assets/ui-r20/ink-paths.res"),"compression":"Godot RSCC single-block Zstandard","raster_payload":false},"  ")); evidence.close()
	print("Compact resource round-trip: ",compressed.size()+24," bytes; ",raw.size()," decoded bytes")
	quit(0)
