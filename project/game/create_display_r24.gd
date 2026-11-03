extends RefCounted
## Source-visible contracts. Canvas composition remains in create_screen.gd.
const L=preload("res://game/localization_r22.gd")
var rules=preload("res://game/persona_rules.gd").new()
func option(name: String,sub: String,selected: bool,lang="ko") -> Dictionary:
	return {"name":L.t(name,lang),"sub":L.t(sub,lang),"selected":selected,"disabled":false}
func trait_row(kind: String,tr: String,te: String,syn: String,entry: Dictionary={},lang="ko") -> Array:
	if lang!="ko" and entry.get("syn2_raw","")!="":
		te=rules.parameter_text(L.t(entry.te_raw,lang)) if entry.has("te_raw") else L.t(te,lang)
		syn=rules.syn_text(entry,lang)
	return [L.u(kind,{},lang),L.t(tr,lang),L.t(te,lang),L.u("시너지 2명이면 {effect}",{"effect":L.t(syn,lang)},lang)]
func entry_trait(kind: String,entry: Dictionary,lang="ko",syn_entry: Dictionary={}) -> Array:
	var syn=syn_entry if not syn_entry.is_empty() else entry
	var merged=entry.duplicate(true)
	for key in ["syn2_raw","syn3_raw"]:
		if syn.has(key):merged[key]=syn[key]
	return trait_row(kind,entry.get("tr",""),entry.get("te",""),syn.get("syn",""),merged,lang)
func head(page: int,lang="ko") -> Array:
	var subs=["어느 종족으로 살아왔나요?","어느 나라에서 왔나요?","어떤 일로 먹고사나요?","직업 기본값 위에 점수 {n}점을 나눠 주세요.","이대로 시작할까요? 결정하면 첫 만남을 고르게 됩니다."]
	return ["%d / 5"%page,L.u(rules.data.steps[page-1],{},lang),subs[page-1]]
func nav(p: Dictionary,page: int,lang="ko") -> Array:
	var out=[]
	if page>1:out.append({"id":"cr_back","text":L.u("◀ 뒤로",{},lang),"disabled":false})
	out.append({"id":"cr_done" if page==5 else "cr_next","text":L.u("이 모험가로 결정" if page==5 else "다음 ▶",{},lang),"disabled":not rules.reach(p,5) if page==5 else not rules.ok(p,page)})
	return out
func confirmation(p: Dictionary,lang="ko") -> Array:
	var out=[]
	for row in [["이름","{{user}}"],["종족",p.race+("("+p.lineage+")" if p.lineage!="" else "")],["출신",p.nation],["직업",p.cls]]:out.append(L.u(row[0],{},lang));out.append(L.t(row[1],lang))
	var total=rules.calc(p)
	for stat in rules.data.stats:out.append(L.u("{name} {n}",{"name":stat[1],"n":total.get(stat[0],0)},lang))
	var race=rules.by(rules.data.races,"name",p.race);var nation=rules.by(rules.data.nations,"name",p.nation);var cls=rules.cls(p.cls)
	if not race.is_empty():
		var it=rules.by(rules.data.lineages,"name",p.lineage) if race.id=="beast" else race
		if not it.is_empty():out.append_array(entry_trait("종족",it,lang,race))
	if not nation.is_empty():out.append_array(entry_trait("출신",nation,lang))
	if not cls.is_empty():out.append_array(entry_trait("직업",rules.data.lines[cls.line],lang))
	return out
