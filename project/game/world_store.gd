extends RefCounted
var path="user://world_v1.json"

func _init(save_path="user://world_v1.json") -> void:
	path=save_path

func read_into(model) -> bool:
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var f=FileAccess.open(candidate,FileAccess.READ)
		if f==null or f.get_length()>524288: continue
		var decoder=JSON.new()
		if decoder.parse(f.get_as_text())!=OK: continue
		if model.restore(decoder.data): return true
	return false

func write(snapshot: Dictionary) -> Error:
	var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null: return FileAccess.get_open_error()
	f.store_string(JSON.stringify(snapshot,"",true,true)); f.flush(); f.close()
	if FileAccess.file_exists(path):
		var err=DirAccess.copy_absolute(path,path+".bak")
		if err!=OK: return err
	return DirAccess.rename_absolute(path+".tmp",path)
