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

# Ordered visible copy and controls from 60-create. The form consumes this same
# model; the source comparison does not test a disconnected HTML imitation.
func line(value: String,role="text") -> Dictionary:return {"role":role,"text":value}
func source_copy(value: String,vars: Dictionary,lang: String) -> String:
	var tags=RegEx.new();tags.compile("<[^>]*>")
	return tags.sub(L.u(value,vars,lang)," ",true).strip_edges()
func pick(id: String,name: String,sub: String,on: bool,lang: String,group: String) -> Dictionary:
	return {"role":"choice","id":id,"text":L.t(name,lang),"sub":L.t(sub,lang),"selected":on,"disabled":false,"group":group}
func detail(kind: String,entry: Dictionary,lang: String,syn: Dictionary={}) -> Array:
	return entry_trait(kind,entry,lang,syn).map(func(s):return line(s))
func total_entries(p: Dictionary,lang="ko") -> Array:
	var out=[];var n=rules.total(p);var custom=p.get("bonus_custom",0)==1
	var descriptions={5:"기본 난이도. 직업 기본값을 조금 다듬는 정도",10:"조금 수월한 시작. 약한 능력치를 메워 준다",20:"쉬운 시작. 주력 능력치를 크게 키워 준다"}
	for value in [5,10,20]:out.append(pick("cr_tot_"+str(value),L.u("{n}점",{"n":value},lang),descriptions[value],not custom and n==value,lang,"totals"))
	out.append(pick("cr_tot_free",L.u("직접 정하기…",{},lang),L.u("아래 버튼으로 숫자를 맞추세요" if custom else "0~99점 사이에서 원하는 값",{},lang),custom,lang,"totals"))
	if custom:
		for pair in [["m5","−5"],["m1","−1"],["value",str(n)+" "+L.u("점",{},lang)],["p1","+1"],["p5","+5"]]:
			out.append(line(pair[1],"total_value") if pair[0]=="value" else {"role":"adjust","id":"cr_tot_"+pair[0],"text":pair[1],"selected":false,"disabled":n<=0 if pair[0].begins_with("m") else n>=99,"group":"total_adjust"})
		out.append(line(L.u("높일수록 쉽고, 낮출수록 어렵습니다",{},lang)))
	return out
func page(kind: String,p: Dictionary,lang="ko") -> Array:
	var out=[]
	if kind=="race":
		for r in rules.data.races:out.append(pick("cr_race_"+r.id,r.name,r.tag,p.race==r.name,lang,"races"))
		var r=rules.by(rules.data.races,"name",p.race)
		if r.get("id")=="beast":
			out.append(line(L.u("계통",{},lang),"heading"))
			for l in rules.data.lineages:out.append(pick("cr_lin_"+l.id,l.name,l.tag,p.lineage==l.name,lang,"lineages"))
		if r.is_empty():out.append(line(L.u("종족을 고르면 특성이 보입니다.",{},lang)))
		else:
			out.append(line(L.t(r.name,lang),"heading"));out.append(line(L.t(r.d,lang)))
			if r.id=="beast":
				var l=rules.by(rules.data.lineages,"name",p.lineage)
				if not l.is_empty():out.append_array(detail("종족",l,lang,r))
				else:out.append(line(L.u("계통을 고르면 개인 특성이 정해집니다. (시너지 2명이면 {effect})",{"effect":rules.syn_text(r,lang)},lang)))
			else:out.append_array(detail("종족",r,lang))
	elif kind=="nation":
		for n in rules.data.nations:
			var bl=rules.blocked(p.race,n.id);var note=rules.note(p,n.id)
			var e=pick("cr_nat_"+n.id,n.name,bl.s if not bl.is_empty() else note if note!="" else n.tag,p.nation==n.name,lang,"nations")
			if not bl.is_empty():e.blocked=true;e.reason=L.t(bl.m,lang)
			out.append(e)
		var n=rules.by(rules.data.nations,"name",p.nation)
		if n.is_empty():out.append(line(L.u("출신을 고르면 특성이 보입니다.",{},lang)))
		else:
			out.append(line(L.t(n.name,lang),"heading"));out.append(line(L.t(n.d,lang)))
			var note=rules.note(p,n.id)
			if note!="":out.append(line(L.t(note,lang)))
			out.append_array(detail("출신",n,lang))
	elif kind=="class":
		for c in rules.data.classes:out.append(pick("cr_cls_"+c.id,c.name,L.u("{line}, {row}",{"line":c.line,"row":c.row},lang),p.cls==c.name,lang,"classes"))
		var c=rules.cls(p.cls)
		if c.is_empty():out.append(line(L.u("직업을 고르면 스킬과 기본 능력치가 보입니다.",{},lang)))
		else:
			out.append(line(L.t(c.name,lang),"heading"));out.append(line(L.t(rules.data.descriptions[c.id],lang)))
			for skill in c.skills:out.append(line(L.t(skill,lang)))
			for stat in [["hp","체력"],["mp","마력"],["str","힘"],["agi","민첩"],["int","지능"],["def","방어"],["spd","속도"]]:out.append(line(source_copy(stat[1]+" <b>{n}</b>",{"n":c[stat[0]]},lang)))
			out.append_array(detail(L.u("계열 {line}",{"line":c.line},lang),rules.data.lines[c.line],lang))
			var note=rules.data.class_notes.get(rules.nation_id(p.nation),{}).get(c.id,"")
			if note!="":out.append(line(L.t(note,lang)))
	elif kind=="stats":
		var c=rules.cls(p.cls)
		if c.is_empty():return [line(L.u("먼저 직업을 골라 주세요.",{},lang))]
		var n=rules.total(p);var cap=rules.cap(n);var left=rules.left(p)
		out.append(line(L.u("보너스 총량",{},lang),"heading"));out.append_array(total_entries(p,lang))
		var remaining=L.u("남은 점수 <b>{left}</b> / {total}<small>한 능력치에 최대 {cap}점까지, 속도는 1점에 2씩 오릅니다</small>",{"left":left,"total":n,"cap":cap},lang).split("<small>",true,1)
		out.append(line(source_copy(remaining[0],{},lang),"heading"))
		if remaining.size()>1:out.append(line(source_copy(remaining[1],{},lang),"note"))
		for stat in rules.data.stats:
			var k=stat[0];var b=int(p.bonus.get(k,0));var value=c[k]+b*stat[2]
			var maximum=maxf(stat[3],c[k]+cap*stat[2])
			var decimal=preload("res://game/combat_display_r22.gd")
			out.append({"role":"stat","text":L.t(stat[1],lang)+" "+str(int(value))+(" +"+str(int(b*stat[2])) if b>0 else ""),"key":k,"minus":b<=0,"plus":left<=0 or b>=cap,"base_ratio":float(decimal.fixed_decimal(minf(1,c[k]/maximum),3)),"total_ratio":float(decimal.fixed_decimal(minf(1,value/maximum),3))})
		for stat in [["hp","체력"],["mp","마력"]]:out.append(line(source_copy(stat[1]+" <b>{n}</b>",{"n":c[stat[0]]},lang)))
		for pair in [["auto","직업 추천대로"],["clear","점수 비우기"]]:out.append({"role":"adjust","id":"cr_"+pair[0],"text":L.u(pair[1],{},lang),"selected":false,"disabled":false,"group":"recommend"})
	return out
func visible(entries: Array) -> String:
	var out=[]
	for e in entries:
		out.append(e.text)
		if e.has("sub") and e.sub!="":out.append(e.sub)
		if e.role=="stat":out.append("-");out.append("+")
	var re=RegEx.new();re.compile("\\s+");return re.sub(" ".join(out)," ",true).strip_edges()
func controls(entries: Array) -> Array:
	var out=[]
	for e in entries:
		if e.has("id"):out.append({"id":e.id,"text":e.text+(" "+e.sub if e.get("sub","")!="" else ""),"disabled":e.disabled,"selected":e.selected})
		elif e.role=="stat":
			out.append({"id":"cr_dn_"+e.key,"text":"-","disabled":e.minus,"selected":false})
			out.append({"id":"cr_up_"+e.key,"text":"+","disabled":e.plus,"selected":false})
	return out
func meters(entries: Array) -> Array:
	var out=[]
	for e in entries:
		if e.role=="stat":out.append({"kind":"tot","ratio":e.total_ratio});out.append({"kind":"b0","ratio":e.base_ratio})
	return out
