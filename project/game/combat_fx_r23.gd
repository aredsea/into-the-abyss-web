extends RefCounted
## 40-fx.lua source-record rendering boundary. Slot maps use JSON string keys.
## Produces the complete layer contract, without touching the r17-r20 scene tree.
const Text=preload("res://game/combat_display_r22.gd")
const Locale=preload("res://game/combat_source_text_r23.gd")
var lang="ko"
var definitions=[]
var profile: Variant=null
var profile_available=false
static func truth(v: Variant) -> bool:return v!=null and not (v is bool and not v)
static func fallback(v: Variant,default: Variant) -> Variant:return v if truth(v) else default
static func s(v: Variant) -> String:return Text.lua_string(v)
func u(text: String,vars: Dictionary={}) -> String:return Locale.u(text,vars,lang)
func translate(text: String) -> String:return Locale.t(text,lang)
static func layers(cuts: bool=true) -> Dictionary:
	var L={"u":{},"icwf":{},"hit":{},"hk":{},"bz":[],"panel":"","field":"","party":"","cls":{},"vars":{},"lun":{},"trg":{},"drn":{}}
	if cuts:L.cuts=[]
	return L
static func style(t: float,x: Variant=null) -> String:
	return 'style="--t:'+Text.fixed_two(t)+'s'+(';' + s(x) if truth(x) else '')+'"'
static func put(L: Dictionary,i: int,text: String) -> void:
	var key=str(i);L.u[key]=L.u.get(key,"")+text
static func number(txt: Variant,t: float,cls: Variant=null,left: Variant=null,top: Variant=null) -> String:
	return '<b class="dn '+(s(cls) if truth(cls) else '')+'" '+style(t,('left:'+s(left)+'%;' if truth(left) else '')+('top:'+s(top)+'%' if truth(top) else ''))+'>'+s(txt)+'</b>'
func critical(txt: Variant,t: float) -> String:
	return '<b class="cn" '+style(t)+'><small>'+u("치명타")+'</small>'+s(txt)+'</b>'
static func plaque(txt: Variant,t: float,cls: Variant=null) -> String:
	return '<span class="sk '+(s(cls) if truth(cls) else '')+'" '+style(t)+'>'+s(txt)+'</span>'
static func camera_add(L: Dictionary,cls: String,t: float,k: Variant,rank: float) -> void:
	var value={"cls":cls,"t":t,"rank":rank}
	if k!=null:value.k=k
	L.bz.append(value)
static func hit(L: Dictionary,i: int,t: float,o: Dictionary) -> float:
	var tier=int(o.get("tier",0));var k=o.get("k");var hs=[0,.10,.15][tier];var ex=Text.scale_style(k);var key=str(i)
	if truth(o.get("arc")):put(L,i,'<i class="arc fx-arc" '+style(t-.16,'--s:'+s(o.arc)+'px;--r:'+s(fallback(o.get("r"),-18))+'deg'+ex)+'></i>')
	var el=o.get("el","");var element=el if el in ["fire","ice","bolt","wind","holy","dark"] else "hit"
	put(L,i,'<i class="spr fx-'+element+'" '+style(t,'--s:'+s([84,112,150][tier])+'px'+ex)+'></i>')
	if truth(o.get("crit")):put(L,i,'<i class="crt fx-crit" '+style(t,'--s:'+s(200 if tier==2 else 150)+'px'+ex)+'></i>')
	if i<=4:
		if not truth(L.icwf.get(key)):L.icwf[key]=t
	else:put(L,i,'<i class="wf" '+style(t,'--p:'+['.4','.55','.75'][tier]+ex)+'></i>')
	if truth(o.get("abfx")):put(L,i,'<i class="hf ab" '+style(t)+'></i>')
	if not truth(L.hit.get(key)):
		L.hit[key]=t+hs
		if k!=null:L.hk[key]=k
		else:L.hk.erase(key)
	if tier==1:camera_add(L,"z3",t+hs,null,1)
	if tier==2:camera_add(L,"z6",t+hs,k,3)
	return hs
func abyss(L: Dictionary,r: Dictionary,t: float) -> void:
	if fallback(r.get("ab"),0)>0:put(L,int(r.i),'<b class="abl" '+style(t)+'><small>'+u("심연")+'</small>−'+s(r.ab)+'</b>')
	var list=fallback(r.get("list"),[])
	for n in range(list.size()):
		var c=list[n];put(L,int(c.i),'<b class="abl" '+style(t+.35+(n+1)*.08)+'><small>'+u("깨진 유리창 이론")+'</small>−'+s(c.n)+'</b>')
func result(L: Dictionary,r: Dictionary,t: float,o: Dictionary={}) -> void:
	var i=int(r.i);var tier=int(o.get("tier",0));var weak=false
	for x in fallback(r.get("tags"),[]):
		if "약점" in x:weak=true
	if (r.get("c",0)==1 or weak) and tier<1:tier=1
	var k: Variant=null
	if truth(o.get("last")):tier=2;k=2
	var options={"tier":tier,"k":k,"crit":r.get("c",0)==1}
	for field in ["el","arc","r","abfx"]:
		if o.has(field):options[field]=o[field]
	var td=t+hit(L,i,t,options)
	if r.get("c",0)==1:put(L,i,critical(r.d,td))
	elif r.sh>=r.d:put(L,i,number(u("막음 {n}",{"n":r.d}),td,"sh"))
	else:put(L,i,number(r.d,td,"h" if i<=4 else ("huge" if r.d>=600 else ("big" if r.d>=300 else ""))))
	if r.sh>0 and r.sh<r.d:put(L,i,number(u("보호막 -{n}",{"n":r.sh}),td+.25,"g",50,56))
	if not fallback(r.get("tags"),[]).is_empty():
		var tags=""
		for x in r.tags:tags+='<span class="'+Text.tag_class(x)+'">'+x+'</span>'
		put(L,i,'<span class="tg" '+style(td)+'>'+tags+'</span>')
	abyss(L,r,td+.1)
func cutin(L: Dictionary,a: int,nm: String,line: Variant,t: float) -> void:
	camera_add(L,"zz",t,null,2.5)
	if L.has("cuts"):L.cuts.append(floor(t*1000+.5+1e-9))
	var d=definitions[a-1]
	L.panel+='<div class="cut" data-dk-cut="1" '+style(t)+'><div class="band"><i class="spd"></i><div class="art art-'+d.art+'"></div></div><div class="txt"><small>'+u("고유 스킬: {name}",{"name":d.name})+'</small><b>'+translate(nm)+'</b>'+('<em>「'+translate(s(line))+'」</em>' if truth(line) and line!="" else '')+'</div></div>'
static func escape(value: String) -> String:
	return value.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;')
func persona_cutin(L: Dictionary,a: int,nm: String,t: float) -> void:
	camera_add(L,"zz",t,null,2.5)
	if L.has("cuts"):L.cuts.append(floor(t*1000+.5+1e-9))
	var has=false
	if profile_available and profile is String:
		var re=RegEx.new();re.compile('^\\{\\{inlayed::[^}]+\\}\\}$')
		has=re.search(profile)!=null or profile.begins_with('data:image/') or profile.begins_with('http://') or profile.begins_with('https://')
	var d=definitions[a-1];var pic=""
	if has:pic='<span class="pc-img">'+profile+'</span>' if profile.begins_with('{{') else '<img class="pc-img" src="'+escape(profile)+'" alt="">'
	else:pic='<span class="pc-img pc-ic"><i class="im im-cls-'+d.get("clsid","")+'"></i><span class="pc-src" style="background-image:url(\'{{source::user}}\')"></span></span>'
	L.panel+='<div class="cut pcut" data-dk-cut="1" '+style(t)+'><div class="pc-ring">'+pic+'</div><div class="pc-name"><small>'+u("고유 스킬: {name}",{"name":d.name})+'</small><b>'+translate(nm)+'</b></div></div>'
func event(state: Dictionary,e: Dictionary,L: Dictionary) -> void:
	var t=float(e.t);var kind=e.k;var a=int(e.a);var key=str(a);var tg=fallback(e.get("tg"),[])
	match kind:
		"atk","snipe":
			var r=tg[0];var ht=fallback(e.get("ht"),t+.4)
			put(L,a,'<i class="av" '+style(t)+'></i>'+ (plaque(translate(e.nm),t+.1,"ab" if a==1 else "") if e.nm!="일반 공격" else ""))
			if kind=="snipe":put(L,int(r.i),'<i class="xh" '+style(ht-.75)+'></i><i class="ar" '+style(ht-.3)+'></i>')
			var o={"el":e.get("el"),"tier":0 if e.nm=="일반 공격" else 1,"r":24,"last":e.get("last"),"abfx":a==1}
			if a==2:o.arc=96
			result(L,r,ht,o)
		"wave","burst":
			put(L,a,plaque(translate(e.nm),t+(.1 if kind=="wave" else 1.2),"ab" if kind=="wave" else null))
			if kind=="wave":L.field+='<i class="fflash" '+style(e.ht-.2)+'></i>'
			else:L.field+='<div class="mcw" '+style(t+1.3)+'><i class="mc m1"></i><i class="mc m2"></i><i class="mc m3"></i><i class="mc m4"></i><i class="mc m5"></i><i class="mc m6"></i></div><i class="shw" '+style(e.ht-.25)+'></i>'
			for n in range(tg.size()):result(L,tg[n],e.ht+(.05 if kind=="burst" else 0)+n*.07,{"el":e.get("el"),"tier":1,"last":e.get("last"),"abfx":kind=="wave"})
		"eatk":
			put(L,a,'<i class="av" '+style(t)+'></i>'+('<span class="sk e" '+style(t)+'>'+translate(e.nm)+'</span>' if truth(e.get("nm")) else ''))
			L.lun[key]=t+.15
			var r=tg[0];var o={"tier":1 if e.get("big")==1 else 0}
			if e.get("shoot")==1:put(L,int(r.i),'<i class="bolt" '+style(t+.28)+'></i>')
			else:o.arc=92;o.r=24
			result(L,r,t+(.62 if e.get("shoot")==1 else .52),o)
		"shield":
			put(L,a,plaque(translate(e.nm),t+1))
			L.party+='<div class="dome" '+style(t+1)+'><i class="dglow"></i><i class="lat"></i><i class="rimg"></i></div>'
			for n in range(1,15):L.party+='<i class="mo" '+style(t+1.2+(n%7)*.18,'left:'+s((n*37)%92+4)+'%;--x:'+s((n*53)%50-25)+'px')+'></i>'
			for n in range(tg.size()):
				var r=tg[n];var id=str(int(r.i));put(L,int(r.i),number('+'+s(r.d),t+1.5+(n+1)*.1,'sh',20,40));L.cls[id]=L.cls.get(id,'')+' shd';L.vars[id]='--t:'+Text.fixed_two(t+1.45+(n+1)*.1)+'s'
		"taunt":
			put(L,a,plaque(translate(e.nm),t+.1))
			for i in range(5,state.u.size()+1):
				if state.u[i-1].al==1 or state.ev.pre[i-1].hp>0:put(L,i,'<i class="rg" '+style(t+.2+(i-5)*.08)+'></i><i class="tf0" '+style(t+.2)+'></i>')
			var r=tg[0];var hs=hit(L,int(r.i),t+.9,{"el":"holy","tier":1});abyss(L,r,t+.95+hs);L.taunt=t+.3
		"def","oath":
			put(L,a,plaque(translate(e.nm),t+(.05 if kind=="def" else .1)))
			L.cls[key]=L.cls.get(key,'')+' shd';L.vars[key]='--t:'+Text.fixed_two(t+(.1 if kind=="def" else .2))+'s'
			if kind=="oath" and tg[0].i!=a:
				var ti=str(int(tg[0].i));L.cls[ti]=L.cls.get(ti,'')+' shd';L.vars[ti]='--t:'+Text.fixed_two(t+.5)+'s'
		"mark":
			put(L,a,plaque(translate(e.nm),t+.1));var r=tg[0];put(L,int(r.i),'<i class="xh keep" '+style(t+.3)+'></i>');abyss(L,r,t+.85)
		"rev":put(L,a,plaque(translate(e.nm),t+.1,'ab'));put(L,a,number('-'+s(e.d),t+.3,'h'));put(L,a,'<i class="hf" '+style(t+.3)+'></i>')
		"chg":put(L,a,plaque(u('마력 폭발 - 충전'),t+.1));put(L,int(tg[0].i),number(u('지연'),t+.8,'g')+'<i class="hf w" '+style(t+.7)+'></i>')
		"cut":
			if truth(e.get("pc")):persona_cutin(L,a,e.nm,t)
			else:cutin(L,a,e.nm,e.get("line"),t)
		"trait":put(L,a,'<span class="trp'+(' ab' if e.get('ab')==1 else '')+'" '+style(t)+'><i class="im im-t-'+definitions[a-1].art+'"></i>'+translate(e.nm)+'</span>');L.trg[key]=t
		"deplete":
			put(L,a,'<i class="hf ab" '+style(t)+'></i><i class="spr fx-burst" '+style(t,'--s:220px')+'></i><div class="drb" '+style(t+.05)+'><b>'+u('심연 고갈')+'</b><small>'+u('다음 차례 상실, 받는 피해 ×1.5')+'</small></div>');L.drn[key]=t;L.panel+='<i class="vig" '+style(t)+'></i>';camera_add(L,'z6',t,null,3)
		"recover":put(L,a,number(u('심연 회복'),t+.5,'ab'))
		"edef","ebuff","eall","edeb","eheal","esum","echg":
			put(L,a,('<i class="av" '+style(t)+'></i>' if kind=='eall' else '')+'<span class="sk e" '+style(t)+'>'+translate(e.nm)+'</span>')
			match kind:
				"ebuff":
					put(L,a,'<i class="hf" '+style(t+.1)+'></i>')
					for r in tg:
						if r.i!=a:put(L,int(r.i),'<i class="hf" '+style(t+.3)+'></i>')
				"eall":
					L.lun[key]=t+.15
					if e.get('big')==1:L.party+='<i class="fflash" '+style(t+.45)+'></i>'
					for n in range(tg.size()):result(L,tg[n],t+.62+n*.07,{"tier":1 if e.get('big')==1 else 0})
				"edeb":
					for r in tg:put(L,int(r.i),'<i class="hf w" '+style(t+.45)+'></i>'+number(u('약화'),t+.6,'g'))
				"eheal":
					for r in tg:put(L,int(r.i),number('+'+s(r.d),t+.7,'sh',20,40)+'<i class="hf" '+style(t+.5)+'></i>')
				"esum":
					if not L.has('spawn'):L.spawn={}
					for r in tg:L.spawn[str(int(r.i))]=t+.6
				"echg":put(L,a,'<i class="hf ab" '+style(t+.2)+'></i>')
		"item":
			put(L,a,plaque(translate(e.nm),t+.1))
			for r in tg:
				var field=r.get('f');var txt='MP +'+s(r.d) if field=='mp' else (u('해제') if field=='cure' else (u('보호막 +{n}',{"n":r.d}) if field=='sh' else '+'+s(r.d)))
				put(L,int(r.i),number(txt,t+.7,'ab' if field=='mp' else 'sh',20,40)+'<i class="hf" '+style(t+.5)+'></i>')
		"ecut":put(L,a,number(u('충전 끊김'),t+.3,'ab'))
		"phase":L.panel+='<div class="phb" '+style(t)+'><b>'+u('2단계')+'</b><small>'+translate(e.nm)+'</small></div>';camera_add(L,'z6',t+.2,2,3)
		"adot":result(L,tg[0],t+.3,{"tier":0})
		"end":
			if e.win==1:L.panel+='<div class="vic" '+style(t)+'><i class="dim"></i><i class="vsw"></i><i class="vem"></i><i class="vem e2"></i><div class="vban"><b>'+u('승리')+'</b></div><i class="vfl"></i></div>'
			else:L.panel+='<div class="vic lose" '+style(t)+'><i class="dim"></i><div class="vban"><b>'+u('퇴각')+'</b><small>'+u('전원 부상')+'</small></div></div>'
func render_events(state: Dictionary,events: Array) -> Dictionary:
	var L=layers()
	for e in events:event(state,e,L)
	return L
