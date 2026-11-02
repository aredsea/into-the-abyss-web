extends SceneTree
const Cloud=preload("res://game/cloud_store_r22.gd")
var checks=0
var failures=[]
func check(ok: bool,msg: String):
	checks+=1
	if not ok:failures.append(msg);push_error(msg)
func _initialize():call_deferred("run")
func run():
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/cloud-r22/p9c/archived-fixture.json"))
	var c=Cloud.new();root.add_child(c);c.config.server_url=(OS.get_environment("ABYSS_TEST_SERVER") if not OS.get_environment("ABYSS_TEST_SERVER").is_empty() else "http://127.0.0.1:8787");c.account={"code":"","pin":"","rev":0,"auto":false,"synced":false}
	await c.connect_account(fixture.code,"0000000000")
	check(not c.connected() and c.notice.contains("PIN"),"wrong archived PIN remains rejected")
	await c.connect_account(fixture.code,fixture.pin)
	check(c.connected() and c.archived and not c.can_upload(),"verified archived account connects only for erasure")
	check(c.notice.contains("보관") and c.notice.contains("삭제"),"archived notice explains erasure")
	await c.download()
	check(c.archived and not c.can_upload() and c.notice.contains("보관"),"archive download returns archived without changing local adventure")
	await c.delete_account()
	check(not c.connected() and not c.archived and c.notice.contains("삭제"),"410 deleted clears archived credentials")
	c.queue_free();await process_frame
	FileAccess.open("res://../verification/cloud-r22/p9c/native-archive-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CLOUD ARCHIVE R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
