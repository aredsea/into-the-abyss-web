extends RefCounted
## Offline compatibility with 68-cloud's signed links. No key is shipped or saved.
## The native /v1 account API continues to use its own authentication and schema.
const Value=preload("res://game/ui_value_r23.gd")
static func enabled(config: Dictionary) -> bool:
	return config.get("HOST","")!="" and config.get("KEY_X",[]).size()>0
static func decode_key(config: Dictionary) -> PackedByteArray:
	var out=PackedByteArray();var x=config.get("KEY_X",[]);var m=config.get("KEY_M",[])
	if x.size()!=m.size():return out
	for i in x.size():out.append(int(x[i])^int(m[i]))
	return out
static func sha256(bytes: PackedByteArray) -> PackedByteArray:
	var h=HashingContext.new();h.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty():h.update(bytes)
	return h.finish()
static func hmac(key: PackedByteArray,message: PackedByteArray) -> PackedByteArray:
	var block=sha256(key) if key.size()>64 else key.duplicate();block.resize(64)
	var inner=PackedByteArray();var outer=PackedByteArray()
	for v in block:inner.append(v^0x36);outer.append(v^0x5c)
	inner.append_array(message);outer.append_array(sha256(inner))
	return sha256(outer)
static func hex(bytes: PackedByteArray) -> String:return bytes.hex_encode()
static func b64(bytes: PackedByteArray) -> String:
	if bytes.is_empty():return ""
	return Marshalls.raw_to_base64(bytes).replace("+","-").replace("/","_").replace("=","")
static func signed_link(config: Dictionary,payload: String) -> String:
	if not enabled(config):return ""
	var bytes=payload.to_utf8_buffer()
	return "https://"+str(config.HOST)+"/s#"+b64(bytes)+"."+b64(hmac(decode_key(config),bytes))
static func code(value) -> String:
	var s=Value.text(value).to_upper();var r=RegEx.new();r.compile("[ \\t\\r\\n\\f\\v-]");s=r.sub(s,"",true).replace("O","0").replace("I","1").replace("L","1")
	if s.length()!=12:return ""
	for c in s:
		if c not in "0123456789ABCDEFGHJKMNPQRSTVWXYZ":return ""
	return s.substr(0,4)+"-"+s.substr(4,4)+"-"+s.substr(8,4)
static func bounded(value,lo: int,hi: int,fallback: Variant=null) -> Variant:
	var n=Value.number(value,NAN)
	if is_nan(n):return fallback
	if n<=lo:return lo
	if n>=hi:return hi
	return int(floor(n))
static func rank_due(cache: Variant,now: int) -> bool:
	if not cache is Dictionary:return true
	var at=cache.get("at")
	return not ((at is int or at is float) and now>=at and now-at<300)
static func rank_percent(cache: Dictionary,best: int) -> Variant:
	var p=cache.get("pct");var reached=cache.get("best")
	return p if (reached is int or reached is float) and reached==best and (p is int or p is float) else null
