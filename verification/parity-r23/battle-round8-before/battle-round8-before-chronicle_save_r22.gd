extends "res://game/world_store.gd"
const Chronicle=preload("res://game/chronicle_store_r22.gd")
func write(snapshot: Dictionary) -> Error:
	var candidate=snapshot.duplicate(true);Chronicle.flush(candidate)
	var error=super(candidate)
	if error==OK:snapshot.chronicle_r22=candidate.chronicle_r22
	return error
