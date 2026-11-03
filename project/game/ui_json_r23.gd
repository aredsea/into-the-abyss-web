extends RefCounted
## mem_jget's table-only storage boundary. Unavailable/corrupt storage yields nil.
static func table(raw: Variant) -> Variant:
	if not raw is String:return null
	var parser=JSON.new()
	if parser.parse(raw)!=OK:return null
	return parser.data if parser.data is Dictionary or parser.data is Array else null
static func read_table(path: String) -> Variant:
	var f=FileAccess.open(path,FileAccess.READ)
	return table(f.get_as_text()) if f!=null else null
