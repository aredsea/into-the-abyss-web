extends SceneTree
const World=preload("res://game/settings_world_r22.gd")
const Store=preload("res://game/settings_save_r22.gd")
const Journey=preload("res://game/cloud_recap_r23.gd")
class LocalCloud extends "res://game/cloud_store_r22.gd":
	var response={}
	func _request(_method: HTTPClient.Method,_path: String,_payload=null) -> Dictionary:return response.duplicate(true)
	func persist() -> void:pass
class FailingStore extends "res://game/settings_save_r22.gd":
	func write(_snapshot: Dictionary) -> Error:return ERR_CANT_CREATE
var checks=0
var failures=[]
func check(ok: bool,text: String):
	checks+=1
	if not ok:failures.append(text);push_error(text)
func _initialize():call_deferred("run")
func run():
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/cloud-r22/fixtures.json")).town
	var expected=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/phase2/oracle.json")).native_recap.value
	var c=LocalCloud.new();c.model=World.new();c.storage=Store.new("user://r23-journey-download.json")
	c.account={"code":"0123-4567-89AB","pin":"","rev":8,"auto":false,"synced":false}
	c.response={"status":200,"rev":9,"save":fixture};c.model.s.gold=123
	var original=fixture.duplicate(true)
	await c.download()
	check(c.recap_context==expected,"real download emits source Lua recap from native fields")
	check(c.account.rev==9 and c.account.synced,"latest download advances the CAS cursor")
	check(fixture==original,"narrative projection leaves input snapshot untouched")
	var restored=World.new();check(c.storage.read_into(restored),"downloaded adventure reloads from disk")
	check(Journey.recap(Journey.from_native(restored.s))==expected,"saved/reloaded facts produce the same source context")
	c.account.rev=12;c.response.rev=3;await c.download(3)
	check(c.account.rev==12 and c.recap_context==expected,"historic restore preserves CAS cursor and recreates source facts")
	var before=c.model.s.duplicate(true);c.recap_context="previous";c.storage=FailingStore.new();c.response.rev=20
	await c.download()
	check(c.model.s==before and c.recap_context=="previous" and c.account.rev==12,"failed disk write cannot publish new state, recap or revision")
	c.response.save={"schema":-1};await c.download()
	check(c.model.s==before and c.recap_context=="previous","invalid remote snapshot leaves the existing journey intact")
	c.free()
	FileAccess.open("res://../verification/parity-r23/phase2/cloud-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CLOUD JOURNEY R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
