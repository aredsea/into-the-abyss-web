extends SceneTree
const Cloud=preload("res://game/cloud_store_r22.gd")
const World=preload("res://game/settings_world_r22.gd")
var checks=0
var failures=[]
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func _initialize():
	create_timer(30).timeout.connect(func():quit(98));call_deferred("run")
func write_preferences(value: Dictionary) -> void:
	var file=FileAccess.open(Cloud.PREFS,FileAccess.WRITE);file.store_string(JSON.stringify(value));file.flush();file.close()
func run():
	var existed=FileAccess.file_exists(Cloud.PREFS);var before=FileAccess.get_file_as_bytes(Cloud.PREFS) if existed else PackedByteArray()
	var c=Cloud.new();root.add_child(c);c.model=World.new();c.config.server_url="http://127.0.0.1:1";c.config.timeout_seconds=1
	c.account={"code":"ABCD-EFGH-JKMP","pin":"","rev":8,"auto":false,"synced":false};c.rank_attempt=123;c.rank={"best":3,"pct":50,"n":2,"top":5,"at":123};c.persist()
	var restarted=Cloud.new();root.add_child(restarted)
	var equal_rank=restarted.rank.size()==c.rank.size()
	for key in c.rank:equal_rank=equal_rank and restarted.rank.get(key)==c.rank[key]
	check(restarted.rank_attempt==123 and equal_rank,"rank result and attempt survive preference reload: "+str(restarted.rank_attempt)+" "+JSON.stringify(restarted.rank))
	check(restarted.account.rev==8 and restarted.account.pin=="","old account fields survive additive preference change")
	var state=c.model.s.duplicate(true);await c.connect_account("bad-code","")
	check(c.account.rev==8 and c.model.s==state and c.notice.contains("형식"),"invalid account code never changes account or adventure")
	c.rank_attempt=-1;c.rank={"best":3,"pct":50,"n":2,"top":5,"at":123};await c.fetch_rank();var attempt=c.rank_attempt
	check(attempt>0 and c.model.s==state,"failed request consumes allowance and preserves the adventure")
	check(c.rank.is_empty(),"failed refresh cannot display the previous percentile")
	await c.fetch_rank();check(c.rank_attempt==attempt and c.notice.contains("5분"),"failed attempt throttles immediate retry")
	var again=Cloud.new();root.add_child(again);check(again.rank_attempt==attempt,"failed-attempt throttle survives restart")
	var saved=JSON.parse_string(FileAccess.get_file_as_string(Cloud.PREFS));saved.code="0123-4567-89AB"
	write_preferences(saved)
	var different=Cloud.new();root.add_child(different);check(different.rank_attempt==-1 and different.rank.is_empty(),"rank cache cannot cross account boundaries")
	saved.code=saved.rank_cache_r23.code;saved.rank_cache_r23.value={"best":3,"pct":"50"}
	write_preferences(saved)
	var malformed=Cloud.new();root.add_child(malformed)
	check(malformed.rank.is_empty(),"incomplete or malformed cached metadata cannot enter rank UI")
	check(malformed.rank_attempt==attempt,"dropping malformed metadata preserves the retry allowance")
	for node in [c,restarted,again,different,malformed]:root.remove_child(node);node.queue_free()
	await process_frame
	if existed:FileAccess.open(Cloud.PREFS,FileAccess.WRITE).store_buffer(before)
	else:DirAccess.remove_absolute(Cloud.PREFS)
	FileAccess.open("res://../verification/parity-r23/cloud-compat-results.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures},"\t"))
	print("CLOUD COMPAT R23 CHECKS ",checks," FAILURES ",failures.size());quit(0 if failures.is_empty() else 1)
