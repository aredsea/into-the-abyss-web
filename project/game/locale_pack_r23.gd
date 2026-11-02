extends RefCounted
## 01-game's lazy JSON dictionaries. A failed decode is cached as an empty table.
var raw: Dictionary={}
var words_raw="{}"
var ui={}
var words: Variant=null
func _init(packs: Dictionary={},dictionary="{}"):
	raw=packs.duplicate();words_raw=dictionary
func table(value: String) -> Variant:
	var parser=JSON.new()
	if parser.parse(value)!=OK:return {}
	return parser.data if parser.data is Dictionary or parser.data is Array else {}
func pack(lang: String) -> Variant:
	if not ui.has(lang):ui[lang]=table(raw.get(lang,"{}"))
	return ui[lang]
func dictionary() -> Variant:
	if words==null:words=table(words_raw)
	return words
