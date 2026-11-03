extends RefCounted
## Original battle record boundary. Slot numbers remain one-based here.
## This does not reinterpret a native schema-3 save as a Lua VER2 record.
const Data=preload("res://game/battle_source_data_r23.gd")
const Stats=preload("res://game/battle_stats_r23.gd")
const Persona=preload("res://game/persona_research_r21.gd")
const Locale=preload("res://game/combat_source_text_r23.gd")
const Text=preload("res://game/combat_display_r22.gd")
const Traits=preload("res://game/trait_rules_r22.gd")
var lang="ko"
var definitions=[]
var skills=[]
static func truth(v: Variant) -> bool:return v!=null and not (v is bool and not v)
func u(s: String,vars: Dictionary={}) -> String:return Locale.u(s,vars,lang)
func t(s: String) -> String:return Locale.t(s,lang)
static func put(target: Dictionary,key: String,value: Variant) -> void:
	if value==null:target.erase(key)
	else:target[key]=value
static func cell(list: Variant,i: int) -> Variant:
	if list is Array:return list[i-1] if i>0 and i<=list.size() else null
	if list is Dictionary:return list.get(i)
	return null
static func unit0() -> Dictionary:
	return {"hp":0,"mhp":1,"mp":0,"mmp":0,"sh":0,"shT":0,"g":10000,"al":1,"tau":0,"df":0,"chg":0,"oath":0,"oT":0,"mk":0,"am":1,"bt":0,"rv":0,"lf":0,"nu":0,"seal":0,"ay":0,"ym":0,"dr":0,"fx":0,"fb":0,"ia":1,"it":0,"sp":100,"cs":0,"de":0,"ag":0,"cr":0,"bf":{},"x":{},"rc":"","ln":"","na":"","bx":0}
static func member_definition(m: Dictionary) -> Dictionary:
	var c=Data.CLASSES.get(m.cls,Data.CLASSES.warrior)
	var d={"cid":m.id,"cls":c.name,"clsid":c.id,"row":c.row,"line":c.line,"el":"none","art":"","trn":""}
	put(d,"lv",m.get('L'))
	if m.id=="persona":
		d.name="{{user}}";d.full="{{user}}";put(d,"skill",m.get('skill'));return d
	var k=Data.CAST.get(m.id,{})
	d.name=k.get('name',m.id);d.full=d.name;d.art=m.id;d.trn=k.get('trait','')
	if k.get('row','')!='':d.row=k.row
	if truth(k.get('el')) and k.el!='':d.el=k.el
	return d
func member_skills(d: Dictionary) -> Array:
	var a=Data.ATTACK.get(d.clsid,Data.ATTACK.warrior)
	var out=[{"id":"atk","name":"일반 공격","mp":0,"tgt":"enemy","ic":a.ic,"d":a.d,"row":"com"}]
	for sk in Data.KITS.get(d.clsid,[]):
		var copy=sk.duplicate(true);copy.row='cls';out.append(copy)
	if d.cid=='persona' and Persona.ready(d.get('skill')):out.append(Persona.skill(d.skill,lang))
	elif d.cid!='persona':
		var k=Data.CAST.get(d.cid,{});var p=Data.PERSONAL.get(d.cid,{})
		out.append({"id":p.get('id','p_'+d.cid),"name":k.get('skill','개인 스킬'),"mp":k.get('skill_mp',0),"tgt":p.get('tgt',k.get('skill_tgt','none')),"ic":p.get('ic','buff'),"d":p.get('d','개인 스킬: '+k.get('skill_d','')),"pv":true,"cid":d.cid,"row":"com"})
	var df=Data.DEFEND.duplicate(true);df.row='com';out.append(df)
	return out
static func skill_slot(lists: Array,i: int,id: String) -> Variant:
	var list=cell(lists,i)
	if list is Array:
		for k in range(list.size()):
			if list[k].id==id:return k+1
	return false
func foe_definition(state: Dictionary,j: int) -> Dictionary:
	var id=cell(state.fl,j);var f=Data.FOES.get(id,{}) if id is String else {}
	if f.is_empty():return {"name":"","full":"","glyph":"","lv":"","wk":[],"acts":[{"id":"none","name":"","kind":"guard","ic":"defend"}],"row":"전열","spd":100,"kind":"mob","empty":true}
	var d=f.duplicate(true);d.id=id;d.foe=id
	var gr=cell(state.get('fg',[]),j);var deep=state.get('dk',0)>0
	if gr=='chiefb':gr='chief';deep=true
	elif gr=='eliteb':gr='elite';deep=true
	d.grade=gr if truth(gr) and gr!='' else f.grade;d.deepn=deep
	d.kind=Data.GRADES.get(d.grade,Data.GRADES.mob).kind;d.elite=d.kind=='elite';d.boss=d.kind=='boss'
	if d.grade=='minion':d.srole='하수인'
	d.glyph='적';d.ic='fam-%02d'%f.fam;d.name=(u('깊은 ') if deep else '')+t(f.name);d.full=d.name
	d.lvn=minf(Data.LEVEL_MAX,state.get('el',1))
	d.lv='Lv.'+Text.lua_string(d.lvn)+u({'elite':' 정예','chief':' 우두머리','boss':' 구역 보스','core':' 균열 핵','minion':' 하수인'}.get(d.grade,''))
	var unit=cell(state.get('u',[]),4+j)
	if truth(f.get('ph2')) and unit is Dictionary and unit.get('ph')==2:
		d.wk=unit.cwk if truth(f.ph2.get('cycle')) and unit.get('cwk') is Array and unit.cwk.size()==2 else f.ph2.wk
		d.acts=f.ph2.acts
	return d
func bind_foes(state: Dictionary) -> void:
	definitions.resize(16)
	if truth(state.get('fl')):
		var ne=int(state.get('ne',state.fl.size()))
		for j in range(1,ne+1):definitions[3+j]=foe_definition(state,j)
		for k in range(4+ne,16):definitions[k]=false
		return
	for j in range(4):
		var e=Data.LEGACY[j];var d=e.duplicate(true)
		d.lvn=minf(Data.LEVEL_MAX+2,state.get('el',40)+e.get('lvo',0));d.lv='Lv.'+Text.lua_string(d.lvn)+(u(' 정예') if truth(e.get('elite')) else '')
		definitions[4+j]=d
	for k in range(8,16):definitions[k]=false
func bind(state: Dictionary) -> void:
	definitions.resize(16);skills=[]
	for i in range(4):
		var m=cell(state.pm,i+1)
		if m is Dictionary and m.id!='':definitions[i]=member_definition(m);skills.append(member_skills(definitions[i]))
		else:
			definitions[i]={"cid":"","name":"빈 자리","full":"빈 자리","cls":"","clsid":"","row":"","line":"","el":"none","art":"","trn":"","empty":true};skills.append([])
	bind_foes(state)
	if state.get('pend',0)>0:
		var slot=skill_slot(skills,int(state.cur),state.pid) if truth(state.get('pid')) and truth(state.get('cur')) else false
		if truth(slot):state.pend=slot
		else:state.pend=0;state.erase('pid')
static func trait_ids(m: Variant) -> Array:
	var k=m if m is Dictionary and m.get('id')=='persona' else Data.CAST.get(m.get('id') if m is Dictionary else m,{})
	var persona=m is Dictionary and m.get('id')=='persona'
	var r=Traits.TAGS.get(k.get('race',''),'')
	var n=Traits.TAGS.get(k.get('nat' if persona else 'nation',''),'')
	var l={"개":"dog","여우":"dog","늑대":"dog","개과":"dog","고양이":"cat","표범":"cat","고양이과":"cat"}.get(k.get('lin' if persona else 'lineage',''),'') if r=='beast' else ''
	return [r,l,n]
static func migrate(state: Dictionary) -> Dictionary:
	if state.get('ver')==2 and state.get('u') is Array and state.u.size()==8 and (state.get('pm') is Array or state.get('pm') is Dictionary):
		for i in range(4):
			var unit=state.u[i];var member=cell(state.pm,i+1)
			if not unit is Dictionary:continue
			if not unit.get('rc') is String or not unit.get('ln') is String or not unit.get('na') is String:
				var ids=trait_ids(member) if member is Dictionary and member.get('id')!='' else ['','','']
				unit.rc=ids[0];unit.ln=ids[1];unit.na=ids[2]
			if not (unit.get('bx') is int or unit.get('bx') is float):unit.bx=0
			if not (unit.get('x') is Dictionary or unit.get('x') is Array):unit.x={}
		state.ver=Data.VERSION
	return state
static func apply_carry(state: Dictionary,carry: Dictionary) -> void:
	for i in range(4):
		var unit=cell(state.u,i+1)
		if not unit is Dictionary or unit.get('empty')==1:continue
		var hp=Stats.number(cell(carry.get('hp',[]),i+1),NAN);var mp=Stats.number(cell(carry.get('mp',[]),i+1),NAN)
		if not is_nan(hp):
			if hp<=0:unit.hp=0;unit.al=0;unit.g=1000000000
			else:unit.hp=maxf(1,minf(unit.mhp,floor(hp)))
		if not is_nan(mp):unit.mp=maxf(0,minf(unit.mmp,floor(mp)))
func name(i: int) -> String:
	return t(definitions[i-1].name)
func result_context(state: Dictionary) -> Variant:
	if not truth(state.get('fl')):return false
	var names=[];var seen={}
	for j in range(4,state.u.size()):
		var d=definitions[j]
		if state.u[j].get('empty')!=1 and not truth(d.get('empty')) and not seen.has(d.name):seen[d.name]=true;names.append(t(d.name))
	var src=''
	if truth(state.get('dn')):
		var dn=state.dn;var boss=dn.get('kind')=='boss' or dn.get('stage')==2
		var kind=' (층 보스 레이드 전투)' if boss else ' (구역 전투, 층 보스가 아직 남아 있다)' if dn.get('stage')==1 else ' (탐색 중 만난 전투, 층 보스가 아직 남아 있다)'
		src=u('장소: {place}{kind}. ',{"place":state.get('place','대던전'),"kind":u(kind)})
	elif truth(state.get('place')) and state.place!='':src=u('장소: {place}. ',{"place":state.place})
	return src+u('맞선 적: {names}.',{"names":', '.join(names)})
func damage_line(actor: int,res: Dictionary,options: Dictionary) -> String:
	var who=name(actor);var target=name(int(res.i));var skill=u('{skill:으로} ',{"skill":options.sk}) if truth(options.get('sk')) else ''
	var verb=options.get('vb');var connected=Text.verb_connection(verb);var src=''
	var vars={"who":who,"particle":Text.Josa.tail(who,'이가',lang),"skill":skill,"verb":connected if truth(connected) else verb,"target":target,"damage":res.d}
	if truth(connected):
		src=u('<b>{who}</b>{particle} {skill}{verb} {target}에게 <em>{damage}</em> 피해를 입혔다',vars) if '을 ' in verb or '를 ' in verb else u('<b>{who}</b>{particle} {skill}{target:을를} {verb} <em>{damage}</em> 피해를 입혔다',vars)
	else:src=u('<b>{who}</b>{particle} {skill}{target:을를} {verb}. <em>{damage}</em> 피해를 입혔다',vars)
	var tags=res.get('tags',[]).duplicate()
	if res.sh>0:tags.append(u('보호막 {n} 흡수',{"n":res.sh}))
	if not tags.is_empty():src+='('+', '.join(tags)+')'
	if res.get('ab',0)>0:src+=u('. {target}의 <i>심연 −{n}</i>',{"target":target,"n":res.ab})
	if res.get('kill')==1:src+=u('. <b>{target}</b>{particle} 쓰러졌다' if res.i>=5 else '. <b>{target}</b>{particle} 부상으로 물러났다',{"target":target,"particle":Text.Josa.tail(target,'이가',lang)})
	return src
