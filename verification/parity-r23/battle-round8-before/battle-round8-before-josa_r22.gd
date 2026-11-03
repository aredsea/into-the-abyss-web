extends RefCounted
## 15-josa.lua: skip punctuation/emoji, ASCII letter/digit readings, rieul exception.
const ASCII={"L":8,"M":16,"N":4,"R":8,"0":21,"1":8,"3":16,"6":1,"7":8,"8":8}
static func word(value: Variant) -> String:return "" if value==null else str(value)
static func jong(value: Variant) -> int:
	var s=word(value)
	for i in range(s.length()-1,-1,-1):
		var cp=s.unicode_at(i)
		if cp>=0xAC00 and cp<=0xD7A3:return (cp-0xAC00)%28
		if cp<128 and ((cp>=48 and cp<=57) or (cp>=65 and cp<=90) or (cp>=97 and cp<=122)):return ASCII.get(s[i].to_upper(),0)
	return 0
static func tail(value: Variant,key: String,lang="ko") -> String:
	if lang=="en":return ""
	if word(value).contains("{{"):return {"이가":"(이)가","을를":"(을)를","은는":"(은)는","와과":"(와)과","으로":"(으)로","이다":"이었다","에게":"에게"}.get(key,"")
	var j=jong(value)
	match key:
		"이가":return "이" if j>0 else "가"
		"을를":return "을" if j>0 else "를"
		"은는":return "은" if j>0 else "는"
		"와과":return "과" if j>0 else "와"
		"으로":return "로" if j in [0,8] else "으로"
		"이다":return "이었다" if j>0 else "였다"
		"에게":return "에게"
	return ""
static func p(value: Variant,key: String,lang="ko") -> String:return word(value)+tail(value,key,lang)
