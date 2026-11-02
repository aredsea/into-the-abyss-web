extends SceneTree
var checks=0
var failures=[]
const World=preload("res://game/persona_world.gd")
const Store=preload("res://game/world_store.gd")
const Cloud=preload("res://game/cloud_store_r22.gd")
func check(ok: bool,what: String):
	checks+=1
	if not ok:failures.append(what);push_error(what)
func _initialize():call_deferred("run")
func run():
	var fixture=JSON.parse_string(FileAccess.get_file_as_string("res://../verification/cloud-r22/fixtures.json"))
	var model=World.new();check(model.restore(fixture.town),"native fixture restore")
	var store=Store.new("user://cloud-test-r22.json")
	var c=Cloud.new();c.model=model;c.storage=store;root.add_child(c);c.account={"code":"","pin":"","rev":0,"auto":false};c.config.server_url=(OS.get_environment("ABYSS_TEST_SERVER") if not OS.get_environment("ABYSS_TEST_SERVER").is_empty() else "http://127.0.0.1:8787")
	store.saved.connect(c.local_saved)
	await c.create_account();check(c.account.rev==1 and c.account.pin.length()==10,"first save issues account/PIN")
	var b=Cloud.new();b.model=World.new();b.storage=Store.new("user://cloud-test-r22-b.json");root.add_child(b);b.config.server_url=c.config.server_url
	b.account={"code":"","pin":"","rev":0,"auto":false,"synced":false};b.model.restore(fixture.town);b.model.s.gold=123
	await b.create_account();check(b.connected() and b.account.code!=c.account.code,"second device starts with a different account and local adventure")
	await b.connect_account(c.account.code,"0000000000");check(b.notice.contains("확인"),"invalid PIN explains failure")
	await b.connect_account(c.account.code,c.account.pin);check(b.account.rev==1,"second device links")
	var restarted=Cloud.new();root.add_child(restarted)
	check(not restarted.can_upload(),"unsynced link remains blocked after preference reload");restarted.queue_free()
	# Linking credentials must never authorize the unrelated local adventure to upload.
	b.model.restore(fixture.town);b.model.s.gold=123
	b.toggle_auto(true)
	b.model.s.run={"phase":"done","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":true,"final":false,"battle":{},"rested":false,"id":0}
	b.model.s.summary={"result":"retreat","gold":0,"xp":0,"wins":0,"lost":0,"gains":[]}
	b.local_saved(b.model.s);await process_frame
	while b.busy:await process_frame
	await b.upload()
	var linked=await b._request(HTTPClient.METHOD_GET,"/v1/save/"+c.account.code)
	check(linked.status==200 and linked.rev==1 and linked.save==model.s,"connect then settlement/manual upload preserves server revision and content")
	b.toggle_auto(false)
	await b.download(1);check(not b.can_upload(),"historical download cannot unlock an unsynced link")
	var original_path=b.storage.path;var original_state=b.model.s.duplicate(true)
	b.storage.path="user://cloud-r22-missing-dir/no.json";await b.download()
	check(not b.can_upload() and b.model.s==original_state,"failed local write cannot unlock link or replace memory");b.storage.path=original_path
	await b.download();check(b.model.s==model.s,"second device restores same save")
	check(b.can_upload(),"latest successful restore enables upload")
	model.s.gold=275;await c.upload();check(c.account.rev==2,"first device revision 2")
	b.model.s.gold=250;await b.upload();check(not b.conflict.is_empty() and b.conflict.rev==2,"stale device receives conflict")
	await b.choose_local();check(b.account.rev==3 and b.conflict.is_empty(),"choose local retries reviewed revision")
	await c.upload();check(not c.conflict.is_empty(),"further conflict is not silently overwritten")
	await c.download();check(c.model.s.gold==250 and c.account.rev==3,"choose server restores latest")
	await c.history();check(c.revisions.size()==3,"revision list")
	await c.download(1);check(c.model.s.gold==300 and c.account.rev==3,"history keeps latest cursor")
	await c.upload();check(c.account.rev==4,"history restoration creates new rev")
	var read_only=Cloud.new();read_only.model=World.new();read_only.storage=Store.new("user://cloud-readonly-r22.json");root.add_child(read_only);read_only.config.server_url=c.config.server_url
	read_only.account={"code":"","pin":"","rev":0,"auto":false}
	await read_only.connect_account(c.account.code,"");await read_only.download();check(read_only.model.s==model.s and read_only.account.pin.is_empty(),"code alone restores read-only")
	await read_only.upload();check(read_only.account.rev==4,"read-only cannot upload")
	read_only.queue_free()
	await c.fetch_rank();check(not c.rank.is_empty() and c.rank.get("pct")==null,"rank with no reached floor")
	var attempt=c.rank_attempt;await c.fetch_rank();check(c.rank_attempt==attempt,"rank attempt throttled 300 seconds")
	c.config.server_url="http://127.0.0.1:1";await c.upload();check(c.notice.contains("이 기기") and c.account.rev==4,"offline preserves revision and local")
	c.config.server_url=(OS.get_environment("ABYSS_TEST_SERVER") if not OS.get_environment("ABYSS_TEST_SERVER").is_empty() else "http://127.0.0.1:8787");c.toggle_auto(true)
	c.model.s.run={"phase":"done","step":0,"gold":0,"xp":0,"wins":0,"event":"","resolved":true,"final":false,"battle":{},"rested":false,"id":0}
	c.model.s.summary={"result":"retreat","gold":0,"xp":0,"wins":0,"lost":0,"gains":[]}
	store.write(c.model.s);await process_frame
	while c.busy:await process_frame
	check(c.account.rev==5,"settlement auto-sync uploads once")
	store.write(c.model.s);await process_frame;check(c.account.rev==5 and not c.busy,"same settlement does not duplicate auto-sync")
	c.config.server_url=(OS.get_environment("ABYSS_TEST_SERVER") if not OS.get_environment("ABYSS_TEST_SERVER").is_empty() else "http://127.0.0.1:8787");await c.delete_account();check(not c.connected() and FileAccess.file_exists(store.path),"delete cloud preserves local")
	c.queue_free();b.queue_free();await process_frame
	FileAccess.open("res://../verification/cloud-r22/native-service-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CLOUD R22 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
