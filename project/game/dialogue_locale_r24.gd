extends RefCounted
## Presentation-only index. Korean save/history strings and gameplay IDs stay intact.
static var translations={}
static var loaded=false

static func source_at(data: Dictionary,path: String) -> String:
	var node: Variant=data
	for key in path.split("/"):
		if node is Array:
			if not key.is_valid_int() or int(key)<0 or int(key)>=node.size():return ""
			node=node[int(key)]
		elif node is Dictionary:node=node.get(key)
		else:return ""
	return node if node is String else ""

static func load_translations() -> void:
	if loaded:return
	loaded=true
	for filename in DirAccess.get_files_at("res://data/dialogue-r21"):
		if not filename.ends_with(".json"):continue
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue-r21/"+filename))
		if not data is Dictionary:continue
		for path in data.get("en",{}).get("display",{}):
			var source=source_at(data,path);var english=data.en.display[path]
			if not source.is_empty() and english is String and not english.strip_edges().is_empty():translations[source]=english

static func render(value: String) -> String:
	load_translations()
	var lines=[]
	for line in value.split("\n",true):lines.append(translations.get(line,line))
	return "\n".join(lines)
