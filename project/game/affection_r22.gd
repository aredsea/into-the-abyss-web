extends RefCounted
## One shared stage definition for codex, status and the inn.
static func stage(a: float) -> String:
	if a<=-60:return "적대"
	if a<=-20:return "불신"
	if a<20:return "낯섦"
	if a<50:return "신뢰"
	if a<80:return "유대"
	if a<100:return "깊은 인연"
	if a<150:return "맹세"
	return "운명"
static func progress(a: float) -> Dictionary:
	a=clampf(a,-100,200)
	for value in [-59,-19,20,50,80,100,150]:
		if a<value:return {"stage":stage(a),"goal":value,"remaining":snappedf(value-a,.01),"next":stage(value)}
	return {"stage":stage(a),"goal":200,"remaining":0,"next":""}
