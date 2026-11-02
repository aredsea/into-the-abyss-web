extends Node
## Public endpoint only. A user's PIN stays on their own device and in HTTPS bodies.
signal changed
const PREFS="user://cloud_r22.json"
var config: Dictionary={}
var account={"code":"","pin":"","rev":0,"auto":false}
var busy=false
var notice="클라우드에 연결하면 다른 기기에서도 이어할 수 있습니다."
var conflict: Dictionary={}
var revisions: Array=[]
var remote: Dictionary={}
var first_credentials=false
var rank: Dictionary={}
var rank_attempt=0
var applying=false
var last_auto=""
var auto_pending=false
var model
var storage

func _ready() -> void:
	config=JSON.parse_string(FileAccess.get_file_as_string("res://data/cloud-r22.json"))
	var raw=""
	if OS.has_feature("web"):
		raw=str(JavaScriptBridge.eval("localStorage.getItem('abyss.cloud.r22') || ''",true))
	elif FileAccess.file_exists(PREFS):raw=FileAccess.get_file_as_string(PREFS)
	var saved=JSON.parse_string(raw) if not raw.is_empty() else null
	if saved is Dictionary:
		for key in account:
			if saved.has(key) and typeof(saved[key])==typeof(account[key]):account[key]=saved[key]
		# JSON numbers decode as float; convert only an exact nonnegative revision.
		if saved.get("rev") is float and saved.rev>=0 and saved.rev==floor(saved.rev):account.rev=int(saved.rev)

func persist() -> void:
	var value=JSON.stringify(account)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.setItem('abyss.cloud.r22',"+JSON.stringify(value)+")",true)
	else:
		var f=FileAccess.open(PREFS,FileAccess.WRITE)
		if f!=null:f.store_string(value)

func enabled() -> bool:return not str(config.get("server_url","")).is_empty()
func connected() -> bool:return not account.code.is_empty()
func _request(method: HTTPClient.Method,path: String,payload=null) -> Dictionary:
	if busy:return {"status":0,"error":"busy"}
	if not enabled():
		notice="서버 연결 준비 중입니다. 이 기기 저장은 계속됩니다.";changed.emit();return {"status":0}
	busy=true;notice="연결 중…";changed.emit()
	var request=HTTPRequest.new();add_child(request);request.timeout=float(config.get("timeout_seconds",12))
	var url=str(config.server_url).trim_suffix("/")+path
	var error=request.request(url,PackedStringArray(["Content-Type: application/json"]),method,"" if payload==null else JSON.stringify(payload,"",true,true))
	var out={"status":0}
	if error==OK:
		var result=await request.request_completed
		if result[0]==HTTPRequest.RESULT_SUCCESS:
			var decoded=JSON.parse_string(result[3].get_string_from_utf8())
			if decoded is Dictionary:out=decoded;out.status=int(result[1])
	request.queue_free();busy=false
	if auto_pending:call_deferred("_flush_auto")
	if out.status==0:notice="연결할 수 없어 이 기기에만 저장했습니다. 나중에 다시 시도하세요."
	elif out.status==403:notice="계정 코드와 쓰기 PIN을 확인해 주세요."
	elif out.status==429:notice="요청이 많습니다. 잠시 뒤 다시 시도하세요."
	elif out.status==422:notice="저장 형식을 확인하지 못했습니다. 이 기기 저장은 유지됩니다."
	elif out.status==400:notice="계정 코드의 형식을 확인해 주세요."
	elif out.status==404:notice="서버에서 이 기록을 찾지 못했습니다. 계정 코드를 확인해 주세요."
	elif out.status==413:notice="클라우드 저장 한도인 64KB를 넘었습니다. 이 기기 저장은 유지됩니다."
	elif out.status>=500:notice="서버가 응답하지 않습니다. 이 기기 저장은 유지됩니다."
	return out

func create_account() -> void:
	if busy or connected():return
	var r=await _request(HTTPClient.METHOD_POST,"/v1/account",{"save":model.s})
	if r.status==201:
		account.code=r.code;account.pin=r.pin;account.rev=int(r.rev);persist();first_credentials=true;notice="계정 코드와 쓰기 PIN을 적어 두세요."
	changed.emit()

func connect_account(code: String,pin: String) -> void:
	if busy:return
	code=code.strip_edges().to_upper().replace(" ","")
	pin=pin.strip_edges().to_upper().replace(" ","").replace("-","")
	var r=await _request(HTTPClient.METHOD_GET,"/v1/save/"+code.uri_encode()) if pin.is_empty() else await _request(HTTPClient.METHOD_POST,"/v1/account/connect",{"code":code,"pin":pin})
	if r.status==200:
		account.code=r.code;account.pin=pin;account.rev=int(r.rev);persist();remote=r;conflict={};revisions=[];rank={};rank_attempt=0;first_credentials=false;notice="읽기 전용으로 연결했습니다. 서버 기록을 불러올 수 있습니다." if pin.is_empty() else "연결했습니다. 서버 기록을 확인하고 불러오세요."
	changed.emit()

func upload() -> void:
	if busy or not connected() or account.pin.is_empty():return
	var r=await _request(HTTPClient.METHOD_PUT,"/v1/save",{"code":account.code,"pin":account.pin,"rev":account.rev,"save":model.s})
	if r.status==200:
		account.rev=int(r.rev);persist();conflict={};remote=r;notice="클라우드에 저장했습니다. · 기록 %d"%account.rev
	elif r.status==409:
		conflict=r;notice="다른 기기에 새 기록이 있습니다. 두 기록을 비교해 선택하세요."
	changed.emit()

func download(revision=0) -> void:
	if busy or not connected():return
	var suffix="?rev="+str(revision) if revision>0 else ""
	var r=await _request(HTTPClient.METHOD_GET,"/v1/save/"+account.code+suffix)
	if r.status==200:
		# Validate on a disposable model and preserve local save before changing memory.
		var probe=preload("res://game/persona_world.gd").new()
		if probe.restore(r.get("save")):
			applying=true
			var error=storage.write(probe.s)
			if error==OK:
				model.s=probe.s;model.ensure_dungeon();remote=r;conflict={}
				# Restoring history never moves the optimistic-lock cursor backwards.
				if revision==0:account.rev=int(r.rev)
				persist();notice="기록 %d을 이 기기에 불러왔습니다. 이전 저장은 백업에 남습니다."%int(r.rev)
			else:notice="이 기기 저장에 실패해 불러오기를 취소했습니다."
			applying=false
		else:notice="이 판에서 읽을 수 없는 기록입니다. 이 기기 저장은 유지됩니다."
	changed.emit()

func choose_local() -> void:
	if conflict.is_empty() or busy:return
	# Retry exactly the revision the user reviewed; a further race still returns 409.
	account.rev=int(conflict.rev);persist();await upload()

func history() -> void:
	if busy or not connected():return
	var r=await _request(HTTPClient.METHOD_GET,"/v1/save/"+account.code+"/revs")
	if r.status==200:revisions=r.revs;notice="최근 기록은 최대 10개까지 보관합니다."
	changed.emit()

func delete_account() -> void:
	if busy or not connected() or account.pin.is_empty():return
	var r=await _request(HTTPClient.METHOD_DELETE,"/v1/account",{"code":account.code,"pin":account.pin})
	if r.status==200:
		account={"code":"","pin":"","rev":0,"auto":false};persist();remote={};conflict={};revisions=[];rank={};rank_attempt=0;first_credentials=false;notice="클라우드 계정과 기록을 삭제했습니다. 이 기기 저장은 남아 있습니다."
	changed.emit()

func toggle_auto(value: bool) -> void:
	account.auto=value;persist();changed.emit()

func local_saved(snapshot: Dictionary) -> void:
	if applying or not account.auto or not connected() or account.pin.is_empty():return
	if snapshot.get("summary",{}).is_empty() or snapshot.get("run",{}).get("phase","")!="done":return
	var key=str(snapshot.runs)+":"+str(snapshot.day)
	if key==last_auto:return
	auto_pending=true;call_deferred("_flush_auto")

func _flush_auto() -> void:
	if not auto_pending or busy or not account.auto or not connected() or not conflict.is_empty():return
	auto_pending=false;last_auto=str(model.s.runs)+":"+str(model.s.day);await upload()

func fetch_rank() -> void:
	if busy or not connected():return
	var now=int(Time.get_unix_time_from_system())
	if rank_attempt>0 and now-rank_attempt<300:
		notice="순위는 5분마다 새로 확인합니다.";changed.emit();return
	rank_attempt=now
	var submitted={"status":200} if account.pin.is_empty() else await _request(HTTPClient.METHOD_POST,"/v1/rank",{"code":account.code,"pin":account.pin})
	if submitted.status==200:
		var r=await _request(HTTPClient.METHOD_GET,"/v1/rank?code="+account.code)
		if r.status==200:rank=r;notice="클라우드에 저장한 최고 도달 층으로 계산했습니다."
	elif submitted.status==422:notice="순위 등록 조건을 충족하지 못했습니다. · "+" / ".join(submitted.get("reasons",[]))
	changed.emit()
