extends RefCounted
## 50-render.lua primitives over the source record ABI. No saved fields change.
const Text=preload("res://game/combat_display_r22.gd")
const Locale=preload("res://game/combat_source_text_r23.gd")
var lang="ko"
var definitions=[]
var profile: Variant=null
var profile_available=false
static func truth(v: Variant) -> bool:return v!=null and not (v is bool and not v)
static func s(v: Variant) -> String:return Text.lua_string(v)
func u(text: String,vars: Dictionary={}) -> String:return Locale.u(text,vars,lang)
func short_name(i: int) -> String:
	var d=definitions[i-1] if i>0 and i<=definitions.size() else null
	if i<=4:return Locale.t(d.name,lang) if d!=null else ""
	if d!=null and truth(d.get("foe")):return Locale.t(d.name,lang)
	return Locale.t({5:"사냥개 A",6:"사냥개 B",7:"궁수",8:"감시관"}.get(i,""),lang)
static func numspan(v: Variant,k: Variant=null) -> String:
	return '<span class="num '+s(k)+'" style="--n:'+s(v)+'"></span>' if truth(k) else s(v)
static func chip(c: String,txt: String) -> String:return '<span class="chip '+c+'">'+txt+'</span>'
func chip_turns(b: Variant) -> String:
	return u(" ({n}턴)",{"n":b.n}) if b is Dictionary and truth(b.get("n")) and b.n>0 else ""
static func dot_turns(list: Array) -> float:
	var m=0.0
	for x in list:m=maxf(m,x.get("n",0))
	return m
static func icon(ic: String) -> String:return {"summon":"int-summon","charge":"int-charge","heal":"int-heal","protect":"int-protect"}.get(ic,ic)
func kind_chip(active: Variant) -> String:
	return '<span class="dk-kind act">'+u("액티브")+'</span>' if truth(active) else '<span class="dk-kind pas">'+u("패시브")+'</span>'
static func camera_before(p: Dictionary,q: Dictionary) -> bool:return p.rank>q.rank if p.rank!=q.rank else p.t<q.t
static func camera_wrapper(c: String,x: Variant=null) -> String:
	if not truth(x):return '<div class="'+c+'">'
	return '<div class="'+c+' '+x.cls+'" style="--bt:'+Text.fixed_two(x.t)+'s'+Text.scale_style(x.get('k'))+'">'
func log_html(state: Dictionary) -> String:
	var out=''
	for n in range(state.log.size()):
		var line=state.log[n];var cur=' cur' if n==state.log.size()-1 else ''
		out+='<div class="ln'+(' nw' if line.t>=0 else '')+cur+'"'+(' style="--t:'+Text.fixed_two(line.t)+'s"' if line.t>=0 else '')+'>'+line.h+'</div>'
	return '<section class="log">'+out+'</section>'
func passive_badges(unit: Dictionary,cls: String) -> String:
	var list=Locale.Lex.PBADGES.get(cls)
	if list==null:return ''
	var out='';var used=cls=='priest' and unit.get('ps',0)==1
	for ic in list:out+='<span class="pbg'+(' used' if used else '')+'"><i class="im im-'+ic+'"></i>'+('<b class="pbn">'+('0' if used else '1')+'</b>' if cls=='priest' else '')+'</span>'
	return '<span class="pbgs">'+out+'</span>'
func phase_pips(foe: String,phase: int) -> String:
	if not foe in Locale.Lex.PHASE_IDS:return ''
	return '<span class="rdp"><b class="pip'+(' on' if phase!=2 else '')+'">1</b><b class="pip'+(' on' if phase==2 else '')+'">2</b><small>'+u('단계')+'</small></span>'
func chips(state: Dictionary,i: int) -> String:
	var w=state.u[i-1]
	if w.al==0:return chip('x',u('부상 이탈' if i<=4 else '쓰러짐'))
	var c=''
	if w.sh>0:c+=chip('g',u('보호막 {n}',{"n":w.sh}))
	if w.tau>0:c+=chip('r',u('도발'))
	if w.df==1:c+=chip('b',u('방어'))
	if w.chg==1 or w.get('cq',0)==1:c+=chip('p',u('충전 (다음 차례 발동)'))
	if w.get('pt',0)>0:c+=chip('g',u('보호 → {name}',{"name":short_name(int(w.pt))}))
	if w.get('hid',0)==1:c+=chip('b',u('은신'))
	if w.get('sil','')!='':c+=chip('r',u('침묵'))
	if w.oath>0:c+=chip('g',u('서약 → {name}',{"name":short_name(int(w.oath))}))
	if w.rv==1:c+=chip('p',u('심연 깎기 ×1.5'))
	if w.mk==1:c+=chip('r',u('표식'))
	if w.get('fx',0)>0:c+=chip('r',u('여우불 {n}턴',{"n":w.fx}))
	var bf=w.get('bf',{})
	for row in [['atk','g','공격 +{n}%{turns}'],['def','g','방어 +{n}%{turns}'],['adn','r','공격 −{n}%{turns}'],['ddn','r','방어 −{n}%{turns}'],['spd','g','속도 +{n}%{turns}'],['sdn','r','속도 −{n}%{turns}']]:
		if bf.has(row[0]):c+=chip(row[1],u(row[2],{"n":floor(bf[row[0]].v*100+1e-9),"turns":chip_turns(bf[row[0]])}))
	for row in [['bl','r','피의 갈증{turns}'],['g2','b','굳건한 방어{turns}'],['bs','p','백스텝{turns}']]:
		if bf.has(row[0]):c+=chip(row[1],u(row[2],{"turns":chip_turns(bf[row[0]])}))
	for list in [w.get('dot',[]),w.get('edot',[])]:
		if not list.is_empty():c+=chip('r',u('지속 피해 ×{n} ({turns}턴)',{"n":list.size(),"turns":dot_turns(list)}))
	if w.am>1:c+=chip('r',u('강화'))
	if w.seal==1:c+=chip('x',u('노트 사용'))
	if w.lf>0:c+=chip('x',u('판결 사용'))
	return c
func intent(state: Dictionary,i: int,act: Dictionary,L: Dictionary) -> String:
	var who=u('자신');var extra='';var tn='';var sty='';var kind=act.kind
	if kind=='atk':
		if truth(act.get('all')):who=u('아군 전체')
		else:
			var target=enemy_target(state,i);who=short_name(target[0])
			if target[1]=='taunt':extra=u(' (도발)');tn=' tn';sty=' style="--t:'+Text.fixed_two(L.get('taunt',0)+.2)+'s"'
	elif kind in ['dot','special'] or (kind=='debuff' and act.get('target')!='all'):who=short_name(enemy_target(state,i)[0])
	elif kind=='debuff':who=u('아군 전체')
	elif kind=='buff':who=u('적 전체' if act.get('target')=='allies' else ('동료' if act.get('target')=='ally' else '자신'))
	elif kind in ['heal','summon','protect','charge']:who=u({'heal':'동료','summon':'하수인','protect':'동료를 감싼다','charge':'큰 기술 준비'}[kind])
	return '<div class="int'+tn+'"'+sty+'><i class="im im-'+icon(act.ic)+'"></i>'+Locale.t(act.name,lang)+' → '+who+extra+'</div>'
static func enemy_target(state: Dictionary,i: int) -> Array:
	var target=int(state.u[i-1].it);var why=''
	for j in range(4):
		if state.u[j].al==1 and state.u[j].tau>0:
			if target!=j+1:why='taunt'
			target=j+1;break
	if target<1 or target>4 or state.u[target-1].al!=1:
		for j in range(4):
			if state.u[j].al==1:target=j+1;break
	return [target,why]
func tile(state: Dictionary,idx: int,pos: int,mark: Variant=null,lost: bool=false) -> String:
	var d=definitions[idx-1];var foe=idx>=5;var fr='f-cur' if pos==1 else ('f-ally' if not foe else ('f-elite' if d.get('elite',false) else 'f-foe'))
	var cls='tq'+(' cur' if pos==1 else '')+(' lost' if lost else '');var pt=''
	if idx<=4:
		if d.art!='':pt='<div class="pt fc-'+d.art+'"></div>'
		else:pt='<div class="pt">'+(persona_image() if d.get('cid')=='persona' else '<i class="im im-ph-persona"></i>')+'</div>'
	else:pt='<div class="pt">'+('<i class="im im-'+d.ic+'"></i>' if truth(d.get('ic')) else d.glyph)+'</div>'
	var m='<span class="mk '+mark[0]+'">'+u(mark[1])+'</span>' if truth(mark) else ''
	return '<div class="'+cls+'" data-u="'+str(idx)+'"><i class="fr im im-'+fr+'"></i>'+pt+m+'</div>'
func persona_image() -> String:
	if profile_available and profile is String:
		var re=RegEx.new();re.compile('^\\{\\{inlayed::[^}]+\\}\\}$')
		if re.search(profile)!=null or profile.begins_with('data:image/') or profile.begins_with('http://') or profile.begins_with('https://'):
			return '<span class="dk-pimg">'+profile+'</span>' if profile.begins_with('{{') else '<img class="dk-pimg" src="'+escape(profile)+'" alt="">'
	return '<span class="dk-pimgw"><i class="im im-ph-persona"></i><span class="dk-pimgs" style="background-image:url(\'{{source::user}}\')"></span></span>'
func rail(state: Dictionary) -> String:
	var mk={}
	for i in range(4):
		if state.u[i].chg==1:mk[i+1]=['chg','충전']
	if truth(state.get('ev')):
		for e in state.ev.list:
			if e.k=='chg' and not mk.has(int(e.tg[0].i)):mk[int(e.tg[0].i)]=['dly','밀림']
			if e.k=='trait' and e.a<=4 and '상대성 이론' in e.nm and not mk.has(int(e.a)):mk[int(e.a)]=['adv','당김']
	var tiles='';var seen={}
	for pos in range(state.q.size()):
		var idx=int(state.q[pos]);var m=mk.get(idx) if not seen.has(idx) else null;var lost=not seen.has(idx) and idx>=5 and state.u[idx-1].dr==1
		seen[idx]=true;tiles+=tile(state,idx,pos+1,m,lost)
	var now=u('지금: {name}',{"name":definitions[int(state.cur)-1].name}) if state.over=='' else u('전투 종료')
	return '<div class="rail"><span class="rlb">'+u('행동 순서')+'</span>'+tiles+'<span class="rnow">'+now+'</span></div>'
func head(state: Dictionary) -> String:
	var syn=''
	for item in synergies(state):syn+='<span class="hc'+(' syn' if state.n==0 else '')+'"'+(' style="--t:1.1s"' if state.n==0 else '')+'><i class="im im-spell"></i>'+u('{type} {n}: {effect}',{"type":item.t,"n":item.n,"effect":item.fx})+'</span>'
	var n=0;var sum=0.0;var me=false
	for i in range(4):
		var d=definitions[i]
		if not truth(d.get('empty')):n+=1;sum+=d.get('lv',1);me=me or d.get('cid')=='persona'
	var avg=floor(sum/n+.5+1e-9) if n>0 else 0
	var stars=u('심층 {n}',{"n":state.get('dc',1)}) if state.get('dk',0)>0 else ('★'+s(state.star) if state.get('star',1)>5 else '★'.repeat(int(state.get('star',1))))
	var place=Locale.t(escape(state.get('place','심연 균열')),lang)
	return '<div class="bh"><span class="loc">'+u('{place}, {stars}<small>평균 Lv.{avg}, 적 Lv.{enemy}</small>',{"place":place,"stars":stars,"avg":avg,"enemy":state.get('el',40)})+'</span><span class="hrt">'+syn+'<span class="hc pv">'+u('출전 동료 {n}, 페르소나 {status}',{"n":n-1 if me else n,"status":u('출전' if me else '대기')})+'</span></span></div>'
static func escape(text: String) -> String:return text.replace('&','&amp;').replace('<','&lt;').replace('>','&gt;').replace('"','&quot;')
func synergies(state: Dictionary) -> Array:
	var counts={};var ints=0;var out=[]
	for i in range(4):
		var w=state.u[i]
		if w.al!=1:continue
		if definitions[i].get('line')=='지능':ints+=1
		for f in ['rc','na']:
			var k=w.get(f,'')
			if k is String and not k.is_empty():counts[k]=counts.get(k,0)+1
	if ints>=2:out.append({"t":"지능","n":ints,"fx":"라운드마다 MP 4 회복"})
	var Traits=preload("res://game/trait_rules_r22.gd")
	for k in Traits.ORDER:
		var lv=Traits.level(counts.get(k,0))
		if lv>=2:
			var node=Traits.passive_node(k);out.append({"t":node.short,"n":counts[k],"fx":Traits.passive_text(Locale.t(node.tier[lv-2],lang))})
	return out
static func hp_stat(label: String,cls: String,unit: Dictionary,f: String,mx: float,K: Array,i: int,show_num: bool,ticks: bool,notch: Variant=null) -> String:
	var k=K[i-1].get(f);var v=unit[f];var low=" low" if f=="hp" and v/mx<=.3 else "";var lay=""
	if truth(k) and f=="hp":lay='<i class="gh '+s(k)+'g" style="width:'+s(Text.ratio_text(v,mx))+'%"></i><i class="fl '+s(k)+'l"></i>'
	return '<div class="stat'+(' abr' if cls=='ab' else '')+'"><b>'+label+'</b><div class="bar '+cls+low+'">'+lay+'<i class="'+(s(k) if truth(k) else '')+'" style="width:'+s(Text.ratio_text(v,mx))+'%"></i>'+('<u></u>' if ticks else '')+('<u class="nt" style="left:'+s(notch)+'%"></u>' if truth(notch) else '')+'</div><em>'+numspan(v,k)+('/'+s(mx) if show_num else '')+'</em></div>'
static func dyn(state: Dictionary,D: float) -> Dictionary:
	var K=[]
	for unit in state.u:K.append({})
	if not truth(state.get("ev")) or D<=0:return {"css":"","K":K}
	var css=[];var ev=state.ev
	for i in range(state.u.size()):
		var unit=state.u[i]
		for f in ["hp","mp","sh","ay"]:
			var pts=ev.h[i].filter(func(x):return x.f==f)
			if pts.is_empty():continue
			pts.sort_custom(func(p,q):return p.t<q.t)
			var mx=unit.mhp if f in ["hp","sh"] else (unit.mmp if f=="mp" else unit.ym)
			var prev=ev.pre[i][f];var kf=['0%{width:'+s(Text.ratio_text(prev,mx))+'%;--n:'+s(prev)+'}'];var is_hp=f=="hp"
			var gk=['0%{width:'+s(Text.ratio_text(prev,mx))+'%}'];var fk=['0%{opacity:0;left:0;width:0}'];var last=0.0
			for x in pts:
				var a=maxf(x.t,last+.002);var b=a+(.08 if is_hp else .3);var pa=a/D*100;var pb=minf(b/D*100,99.5);pa=minf(pa,pb-.01)
				kf.append(Text.fixed_two(pa)+'%{width:'+s(Text.ratio_text(prev,mx))+'%;--n:'+s(prev)+'}');kf.append(Text.fixed_two(pb)+'%{width:'+s(Text.ratio_text(x.v,mx))+'%;--n:'+s(x.v)+'}')
				if is_hp:
					var ga=(a+.2)/D*100;var gb=(a+.9)/D*100
					if x.v>=prev:ga=pa;gb=pb
					gb=minf(gb,99.7);ga=minf(ga,gb-.01)
					gk.append(Text.fixed_two(ga)+'%{width:'+s(Text.ratio_text(prev,mx))+'%}');gk.append(Text.fixed_two(gb)+'%{width:'+s(Text.ratio_text(x.v,mx))+'%}')
					if x.v<prev:
						var l0=s(Text.ratio_text(x.v,mx));var w0=Text.fixed_decimal(float(Text.ratio_text(prev,mx))-float(Text.ratio_text(x.v,mx)),1)
						var fa=maxf(pa-.02,.01);var fe=minf((a+.12)/D*100,99.6);var suffix=';left:'+l0+'%;width:'+w0+'%}'
						fk.append(Text.fixed_two(fa)+'%{opacity:0'+suffix);fk.append(Text.fixed_two(pa)+'%{opacity:1'+suffix);fk.append(Text.fixed_two(fe)+'%{opacity:0'+suffix)
				prev=x.v;last=b
			kf.append('100%{width:'+s(Text.ratio_text(prev,mx))+'%;--n:'+s(prev)+'}')
			var name='k'+s(state.n)+'u'+str(i+1)+f
			css.append('@keyframes '+name+'{'+''.join(kf)+'}');css.append('.'+name+'{animation:'+name+' '+Text.fixed_two(D)+'s linear both}');K[i][f]=name
			if is_hp:
				gk.append('100%{width:'+s(Text.ratio_text(prev,mx))+'%}');fk.append('100%{opacity:0}')
				for pair in [['g',gk],['l',fk]]:css.append('@keyframes '+name+pair[0]+'{'+''.join(pair[1])+'}');css.append('.'+name+pair[0]+'{animation:'+name+pair[0]+' '+Text.fixed_two(D)+'s linear both}')
	return {"css":'<style>'+''.join(css)+'</style>' if not css.is_empty() else '',"K":K}
