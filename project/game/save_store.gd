extends RefCounted
## Godot maps user:// to IndexedDB for web, and app-private storage on mobile.
const SAVE_PATH = "user://battle_combat_v2.json"

func read_snapshot() -> Variant:
	if not FileAccess.file_exists(SAVE_PATH):
		return null
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return null
	if file.get_length() > 65536:
		return null
	return JSON.parse_string(file.get_as_text())

func write_snapshot(snapshot: Dictionary) -> Error:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot,"",true,true))
	file.flush()
	return OK
