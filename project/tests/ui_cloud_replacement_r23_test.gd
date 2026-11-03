extends SceneTree
const W=preload("res://game/settings_world_r22.gd")
const Store=preload("res://game/settings_save_r22.gd")
class LocalCloud extends "res://game/cloud_store_r22.gd":
	var response={}
	var requests=[]
	func _request(method: HTTPClient.Method,path: String,payload=null) -> Dictionary:
		requests.append({"method":method,"path":path,"payload":payload});return response.duplicate(true)
	func persist() -> void:pass
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():create_timer(60).timeout.connect(func():quit(98));call_deferred("run")
func run():
	var oracle=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/parity-r23/ui-phase3/ui-oracle.json"))
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/cloud-r22/fixtures.json")).town
	for f in oracle.cloud:
		var c=LocalCloud.new();c.model=W.new();c.storage=Store.new("user://ui-phase3-cloud-matrix.json");c.config={"server_url":"http://127.0.0.1:8787"}
		c.model.s.gold=300;var before=c.model.s.duplicate(true)
		c.response={"status":200,"code":"ABCD-EFGH-JKMP","rev":3,"save":fixture.duplicate(true)};c.response.save.gold=777
		if f.mode in ["404","429","500"]:c.response.status=int(f.mode)
		elif f.mode in ["envelope","body","request_error"]:c.response={"status":0}
		elif f.mode=="version":c.response.save={"schema":999}
		elif f.mode=="invalid":c.response.save={"schema":3,"gold":777}
		if f.action=="op_cpin":
			if f.mode in ["cancel","pin_cancel"]:
				check(f.account=="" and c.model.s==before,"cancel leaves account and adventure unchanged");c.free();continue
			if f.mode=="pin":c.response.status=403
			await c.connect_account("bad" if f.mode=="code" else "ABCD-EFGH-JKMP","bad" if f.mode=="pin" else "23456789AB")
			check(c.model.s==before,"connecting never uploads or replaces local adventure: "+f.mode)
			if f.mode in ["code","pin"]:check(not c.connected(),"invalid credentials rejected: "+f.mode)
			elif f.mode=="success":check(c.connected() and not c.can_upload() and f.account==c.account.code,"connected account correspondence and restore-first guard")
		else:
			c.account={"code":"ABCD-EFGH-JKMP","pin":"","rev":1,"auto":false,"synced":false}
			if f.mode in ["cancel","code"]:
				check(f.gold==300 and c.model.s==before,"cancel/invalid code preserve source and native adventure");c.free();continue
			await c.download()
			check(c.model.s.gold==f.gold,"source/native restore gold correspondence: "+f.mode)
			if f.gold==300:check(c.model.s==before and c.account.rev==1,"invalid/unavailable remote keeps all state and revision: "+f.mode)
			else:
				var resumed=W.new();check(c.storage.read_into(resumed) and resumed.s.gold==777,"restored adventure survives local resume")
		c.free()
	FileAccess.open("res://../verification/parity-r23/ui-phase3/ui-cloud-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("UI CLOUD REPLACEMENT R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
