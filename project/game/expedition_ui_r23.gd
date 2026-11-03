extends RefCounted
## Observable parts of 77-explore, without HTML or host chat calls. These entries
## are painted by expedition_screen_r22 and compared with executed Lua HTML.
const L=preload("res://game/localization_r22.gd")
const SourceLocale=preload("res://data/expe-ui-r23.json")
var w
var lang="ko"
var entries=[]
func u(text: String,values: Dictionary={}) -> String:
	var template=SourceLocale.data.ui.get(text,text) if lang=="en" else text
	var translated=values.duplicate()
	for key in translated:
		if translated[key] is String:translated[key]=t(translated[key])
	return L.u(template,translated,lang).replace("<b>","").replace("</b>","")
func t(value: String) -> String:return SourceLocale.data.words.get(value,L.t(value,lang)) if lang=="en" else value
func text(value: String,role: String="body") -> void:entries.append({"text":value,"role":role})
func button(id: String,label: String,sub: String="",enabled: bool=true) -> void:
	entries.append({"text":label,"sub":sub,"action":id,"enabled":enabled,"role":"button"})
func build(world,kind: String,g: Dictionary,r: Dictionary,extra: Dictionary={}) -> Array:
	w=world;lang=g.get("lang","ko");entries=[]
	match kind:
		"bar":entries.append({"text":"","role":"bar","kind":extra.kind,"ratio":clampf(extra.cur/extra.maximum,0,1) if extra.maximum>0 else 0.0})
		"pips":pips(r)
		"head":head(r)
		"last":last(r)
		"use_row":use_row(g,r,int(extra.slot))
		"use_btn":use_button(g,r,extra.id,int(extra.slot),extra.can,extra.get("why",""))
		"party":party(g,r)
		"retreat":retreat(r)
		"done_act":done_act(g,r,r.get("summary",{}))
		"done":done(g,r)
	return entries
func pips(r: Dictionary) -> void:
	for k in range(1,6):
		entries.append({"text":str(k),"role":"pip","state":"done" if k<=r.step else "cur" if r.phase=="explore" and k==r.step+1 else ""})
	entries.append({"text":u("휴식"),"role":"pip","state":"cur" if r.phase=="rest" else "done" if r.step>=5 else ""})
	entries.append({"text":u("보스"),"role":"pip","state":""})
func head(r: Dictionary) -> void:
	var info=w.dungeon_rules.floor_info(int(r.floor));var z=w.dungeon_rules.zones[info.zone]
	text(u("{floor}층 {zone}{deep}",{"floor":r.floor,"zone":z.name,"deep":u(" 심층 {n}",{"n":info.dc}) if info.dk>0 else ""}),"title")
	text(u("휴식") if r.phase=="rest" else u("입장") if r.step==0 else u("탐색 {step}/{total}",{"step":r.step,"total":5}))
	pips(r)
	text("★"+str(int(w.dungeon_rules.floor_star(info))))
	text(u("적 Lv {lv}",{"lv":w.dungeon_rules.floor_level(r.avg,info)}))
	var lead=u("구역 보스 {name}" if r.boss_kind=="boss" else "우두머리 {name}",{"name":r.boss_name})
	text(u("층 끝: {lead}",{"lead":lead}))
	var got=r.loot.get("gear",[]).size()
	for n in r.loot.items.values():got+=n
	text(u("모은 금화 {gold}",{"gold":r.loot.gold}));text(u("물건 {n}개",{"n":got}));text(u("경험치 {exp}",{"exp":r.exp}))
func last(r: Dictionary) -> void:
	if r.get("last","")!="":text(r.last)
func have(g: Dictionary,r: Dictionary,id: String) -> int:
	var bank=g.get("items",{});var pouch=r.loot.items
	return int(bank.get(id,0) if bank is Dictionary else 0)+int(pouch.get(id,0) if pouch is Dictionary else 0)
func use_button(g: Dictionary,r: Dictionary,id: String,slot: int,can: bool,why: String="") -> void:
	var n=have(g,r,id)
	button("ex_u_%s_%d"%[id,slot],t(w.expedition_item_name(id)),why if why!="" else u("보유 {n}",{"n":n}),can and n>0)
func use_row(g: Dictionary,r: Dictionary,slot: int) -> void:
	var m=r.pm[slot-1];var down=r.hp[slot-1]<=0
	for id in ["hp_s","hp_m","hp_l","mp_s","mp_m","mp_l"]:
		if down or have(g,r,id)<=0:continue
		var d=w.item_def(w.web_item_id(id));var lv=d.level
		var need=r.hp[slot-1]<r.mhp[slot-1] if d.kind=="hp" else r.mmp[slot-1]>0 and r.mp[slot-1]<r.mmp[slot-1]
		use_button(g,r,id,slot,need and m.L>=lv,u("Lv {lv} 필요",{"lv":lv}) if m.L<lv else "")
	if down and have(g,r,"bandage")>0:use_button(g,r,"bandage",slot,true)
func party(g: Dictionary,r: Dictionary) -> void:
	text(u("파티"),"title");text(u("HP와 MP는 전투를 거치며 이어진다" if r.real else "아직 싸우지 않아 가득 차 있다"))
	for i in range(mini(4,r.pm.size())):
		var m=r.pm[i]
		if m.get("id","")=="":continue
		entries.append({"role":"face","id":m.id,"text":""})
		var name=g.get("persona",{}).get("name","") if m.id=="persona" else w.expedition_member_name(m.id)
		if name=="":name="당신"
		text(t(name),"name")
		var cls=""
		for c in w.config.classes:
			if c.id==m.cls or c.name==m.cls:cls=c.name;break
		text(u("{cls}, Lv {lv}{down}",{"cls":cls,"lv":m.L,"down":u(", 부상 이탈") if r.hp[i]<=0 else ""}))
		meter("hp",r.hp[i],r.mhp[i])
		if r.mmp[i]>0:meter("mp",r.mp[i],r.mmp[i])
		use_row(g,r,i+1)
func meter(kind: String,cur: float,maximum: float) -> void:
	entries.append({"text":"%s %d/%d"%[kind.to_upper(),cur,maximum],"role":"bar","kind":kind,"ratio":clampf(cur/maximum,0,1) if maximum>0 else 0.0})
func retreat(r: Dictionary) -> void:
	if r.get("ask",false):
		text(u("정말 퇴각할까요? 지금까지 모은 금화 {gold}, 물건, 경험치 {exp}는 가져가지만 <b>층 보스 보상과 돌파 기록은 받지 못합니다.</b>",{"gold":r.loot.gold,"exp":r.exp}))
		button("ex_retreat_yes",u("퇴각한다"));button("ex_retreat_no",u("계속한다"))
	else:button("ex_retreat",u("퇴각"),u("모은 것만 가져간다"))
func done_act(g: Dictionary,r: Dictionary,s: Dictionary) -> void:
	if s.get("result")=="clear" and r.get("note")!=null and not (r.note is bool and not r.note):
		var d=g.get("dungeon",{});var best=int(d.get("best",0));var mx=best+1;var order=w.dungeon_rules.config.zone_order
		for i in range(order.size()-1):
			if order[i] in d.get("cleared_bosses",[]):mx=maxi(mx,3*(i+1)+1)
		if r.floor+1<=mx:button("ex_next",u("다음 층으로 내려간다"),u("{floor}층으로 곧장 들어간다. 파티는 지금 그대로",{"floor":r.floor+1}))
		button("ex_home",u("토르바로 돌아간다"),u("정비하고 다음에 다시 출정한다"))
	else:button("ex_home",u("토르바로 돌아간다"),u("다음 층은 출정 화면에서 고른다"))
func done(g: Dictionary,r: Dictionary) -> void:
	var s=r.get("summary",{"result":"retreat","gold":0,"exp":0,"items":{},"lv":[],"lost_items":{}})
	var result=s.result
	text(u("{floor}층 {result}",{"floor":s.get("floor","{floor}"),"result":u({"clear":"층 돌파","retreat":"퇴각","defeat":"도전 실패"}.get(result,""))}),"title")
	text((u("구역 보스를 처음 쓰러뜨렸다") if s.get("first",false) else u("{boss:을를} 쓰러뜨렸다",{"boss":r.boss_name})) if result=="clear" else u("보스는 상대하지 않았다. 모은 것만 가져왔다") if result=="retreat" else u("파티가 무너졌다"))
	if result!="defeat":
		text(u("금화 <b>{gold}</b>",{"gold":s.gold}))
		var ids=s.items.keys();ids.sort()
		for id in ids:text(t(w.expedition_item_name(id))+" ×"+str(int(s.items[id])))
		for code in s.get("gear",[]):
			if not w.combat_gear_rules.gear_roll(code).is_empty():text(u("장비:")+" "+w.expedition_gear_label(code,lang=="en"))
		if s.get("gear_lost",0)>0:text(u("가방이 가득 찼습니다. 장비 {n}개는 버려졌습니다",{"n":s.gear_lost}))
		text(u("경험치 <b>{exp}</b>{level}",{"exp":s.exp,"level":" ("+", ".join(s.lv)+")" if not s.lv.is_empty() else ""}))
		if not s.get("aff",[]).is_empty():text(u("호감 ▲ {list}",{"list":", ".join(s.aff)}))
	else:
		text(u("모은 금화 {gold:와과} 물건을 잃었다. 들고 간 금화 {penalty:을를} 잃었다",{"gold":s.lost_gold,"penalty":s.get("penalty",0)}))
		for code in s.get("kept_gear",[]):
			if not w.combat_gear_rules.gear_roll(code).is_empty():text(u("챙긴 장비:")+" "+w.expedition_gear_label(code,lang=="en"))
		if s.get("lost_gear",0)>0:text(u("장비 {n}개는 잃었다",{"n":s.lost_gear}))
	text(u("탐색 {steps}번, 전투 승리 {wins}번",{"steps":s.steps,"wins":s.wins}))
	done_act(g,r,s)

func sortie(world,kind: String) -> Array:
	w=world;lang=L.language(w.s);entries=[]
	if kind=="summary":
		var q=w.sortie_quest_summary({"lv":w.dungeon_floor_view(w.selected_floor,w.average_level()).el})
		text(u("출전 {n}명",{"n":q.n}));text(u("평균 Lv {avg}",{"avg":q.avg}) if q.n>0 else u("평균 -"))
		text(u("적 Lv {lv}",{"lv":q.elv}));text(u("전열 {n}명",{"n":q.front}))
		for warning in q.warns:text(warning)
	elif kind=="cards":
		text(u("동료 고르기"),"title");text(u("동료 {n} / {cap}명 (카드를 눌러 넣고 뺀다)",{"n":w.s.party.size(),"cap":3 if w.s.persona.fight==1 else 4}))
		for f in [["all","전체"],["front","전열"],["back","후열"]]:
			button("so_f_"+f[0],u(f[1]));entries[-1].selected=w.sortie_filter(w.s.ui.get("tab",""))==("" if f[0]=="all" else f[0])
		var list=w.sortie_candidate_records(w.s.ui.get("tab",""))
		if w.s.owned.is_empty():text(u("아직 동료가 없다. 길드의 「동료 소개」 창구에서 사람을 이어 받을 수 있다."))
		elif list.is_empty():text(u("이 열에는 동료가 없다."))
		for x in list:
			var c=w.person(x.cid);var full=w.s.party.size()>=(3 if w.s.persona.fight==1 else 4)
			entries.append({"role":"face","id":x.cid,"text":""})
			var el={"fire":"화염","ice":"냉기","bolt":"번개","wind":"바람","holy":"신성","dark":"어둠","none":"무"}.get(c.get("element","none"),"무")
			button("so_tg_"+x.cid,t(c.name)+(u("출전") if x.on else ""),u("{cls}, {row}",{"cls":c["class"],"row":c.row})+"\n"+u("Lv {lv} · {el}속성",{"lv":x.lv,"el":el}),not full or x.on)
			entries.append({"text":"","role":"bar","kind":"aff","ratio":clampf(floor(float(w.s.members[x.cid].aff))/200,0,1)})
	return entries
