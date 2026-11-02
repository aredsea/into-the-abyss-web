extends "res://game/chronicle_save_r22.gd"
## Reset archives memory and both on-disk generations before replacing the active slot.
const World=preload("res://game/settings_world_r22.gd")
var archive_path=""
func reset_world(model):
	var archive=path+".before-reset-"+str(Time.get_unix_time_from_system()).replace(".","-")
	var n=0
	while FileAccess.file_exists(archive+".json"):n+=1;archive=path+".before-reset-"+str(Time.get_ticks_usec())+"-"+str(n)
	var candidate=model.s.duplicate(true);Chronicle.flush(candidate)
	var f=FileAccess.open(archive+".json",FileAccess.WRITE)
	if f==null:return null
	f.store_string(JSON.stringify(candidate,"",true,true));f.flush();f.close()
	for suffix in ["",".bak"]:
		if FileAccess.file_exists(path+suffix) and DirAccess.copy_absolute(path+suffix,archive+".disk"+suffix)!=OK:return null
	var fresh=World.new()
	if write(fresh.s)!=OK:return null
	archive_path=archive+".json";return fresh
