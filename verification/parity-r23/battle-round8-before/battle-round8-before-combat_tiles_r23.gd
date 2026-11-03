extends "res://game/combat_hud_r23.gd"
## Source-record tile renderer used by the battle replay/display boundary.
var skills=[]
static func entry(L: Dictionary,key: String,i: int) -> Variant:return L.get(key,{}).get(str(i))
static func style(values: Array) -> String:return ' style="'+';'.join(values)+'"' if not values.is_empty() else ''
func target_pending(state: Dictionary,unit: Dictionary,kind: String,i: int) -> bool:
	if state.pend<=0 or state.over!='' or unit.al!=1:return false
	var sk=skills[int(state.cur)-1][int(state.pend)-1]
	return sk.tgt==kind and (kind!='ally' or i!=state.cur or sk.get('cid','')!='marceline')
func enemy_tile(state: Dictionary,i: int,L: Dictionary,K: Array,visible: Dictionary,boss=false) -> String:
	var unit=state.u[i-1];var d=definitions[i-1]
	if not boss and unit.get('empty')==1:return '<div class="en gone empty" data-u="'+str(i)+'"></div>'
	var cls=('en rdb' if boss else 'en')+(' elite' if truth(d.get('elite')) else '')+(' boss' if truth(d.get('boss')) else '')+(' deep' if truth(d.get('deepn')) else '')+(' add' if not boss and unit.get('add')==1 else '')
	var dies: Variant=null
	if unit.al==0:
		if state.get('ev') is Dictionary:
			for x in state.ev.h[i-1]:
				if x.f=='hp' and x.v<=0:dies=x.t
		cls+=' dying' if truth(dies) else ' gone'
	var ws=[]
	if truth(dies):ws.append('--dt:'+Text.fixed_two(dies+.4)+'s')
	if truth(entry(L,'lun',i)):cls+=' lun';ws.append('--lt:'+Text.fixed_two(entry(L,'lun',i))+'s')
	if not boss and truth(entry(L,'spawn',i)):cls+=' spawn';ws.append('--sp:'+Text.fixed_two(entry(L,'spawn',i))+'s')
	var intent_html=''
	if unit.al==1 and state.over=='':
		var act=d.acts[int(unit.ia)-1]
		if unit.dr==1:intent_html='<div class="'+('rdi' if boss else 'int')+' dep">'+u('고갈: 차례 상실. 지금이 기회다' if boss else '고갈: 차례 상실')+'</div>'
		elif boss:
			var charge=charge_info(unit,d)
			if not charge.is_empty():intent_html='<div class="rdi chg"><i class="im im-'+icon('charge')+'"></i><b>'+u('{n}차례 뒤 {name}',{"n":charge.n,"name":charge.name})+'</b><small>'+u('{name} 충전 중' if charge.n==1 else '{name} 준비',{"name":charge.action.name})+u('. 심연을 0으로 깎으면 끊긴다')+'</small></div>'
			else:intent_html=intent(state,i,act,L).replace('class="int','class="rdi')
		elif truth(visible.get(str(i))):intent_html=intent(state,i,act,L)
		else:intent_html='<div class="int unk">'+u('예고 전')+'</div>'
	var cdc='cd rdc' if boss else 'cd';var cs=[]
	if truth(entry(L,'hit',i)):
		cdc+=' hit';var scale=entry(L,'hk',i);cs.append('--kt:'+Text.fixed_two(entry(L,'hit',i))+'s'+(';--k:'+s(scale) if truth(scale) and scale>1 else ''))
	if unit.dr==1 and unit.al==1:
		if truth(entry(L,'drn',i)):cdc+=' drn';cs.append('--dt2:'+Text.fixed_two(entry(L,'drn',i))+'s');cdc=cdc.replace(' hit','')
		else:cdc+=' dr'
	var weak=[]
	for element in d.wk:weak.append('<i class="el im im-'+element+'"></i>')
	var out='<div class="'+cls+'" data-u="'+str(i)+'"'+style(ws)+'>'
	if truth(d.get('elite')) or truth(d.get('boss')):out+='<i class="eb im im-elite'+(' big' if boss or truth(d.get('boss')) else '')+'"></i>'
	if not boss:out+=intent_html
	out+='<div class="'+cdc+'"'+style(cs)+'>'
	if boss:
		out+='<div class="rdh"><div class="rdm"><i class="im im-'+d.ic+'"></i></div><div class="rdn"><b>'+Locale.t(d.name,lang)+'</b><small>'+Locale.t(d.lv,lang)+'</small>'+phase_pips(d.get('foe',''),int(unit.get('ph',0)))+'</div></div>'+intent_html+'<div class="rdg">'
		var notch=50 if truth(d.get('ph2')) and unit.get('ph')==1 else null
		out+=hp_stat('HP','hp',unit,'hp',unit.mhp,K,i,true,false,notch)+hp_stat(u('심연'),'ab',unit,'ay',unit.ym,K,i,true,true)+'</div>'
	else:
		out+='<div class="bd">'+('<i class="im im-'+d.ic+'"></i>' if truth(d.get('ic')) else d.glyph)+'</div><div class="ei"><div class="nm">'+Locale.t(d.name,lang)+'<small>'+Locale.t(d.lv,lang)+'</small></div>'
		out+=hp_stat('HP','hp',unit,'hp',unit.mhp,K,i,true,false)+hp_stat(u('심연'),'ab',unit,'ay',unit.ym,K,i,false,true)
	out+='<div class="wk"><b>'+u('약점')+'</b>'+''.join(weak)+'</div><div class="sts">'+chips(state,i)+'</div>'+('' if boss else '</div>')+'<i class="crk fx-crack"></i></div><div class="fxl">'+s(entry(L,'u',i) if truth(entry(L,'u',i)) else '')+'</div>'
	if target_pending(state,unit,'enemy',i):out+='<button type="button" class="tgt" risu-btn="tg_'+str(i)+'">'+u('대상 선택')+'</button>'
	return out+'</div>'
static func charge_info(unit: Dictionary,d: Dictionary) -> Dictionary:
	var index=int(unit.ia)-1
	if index<0 or index>=d.acts.size():return {}
	var a=d.acts[index]
	if unit.get('cq')==1:return {"n":1,"name":a.name,"action":a}
	if a.kind=='charge':return {"n":2,"name":d.acts[(index+1)%d.acts.size()].name,"action":a}
	return {}
func raid_field(state: Dictionary,L: Dictionary,K: Array,visible: Dictionary,target: bool) -> String:
	var boss=enemy_tile(state,5,L,K,visible,true);var adds=[]
	for j in range(6,state.u.size()+1):
		if state.u[j-1].get('empty')!=1 and not truth(definitions[j-1].get('empty')):adds.append(enemy_tile(state,j,L,K,visible))
	return '<section class="fld rdf" data-dk-zone="foe"'+(' data-dk-anchor="target"' if target else '')+'>'+boss+('<div class="rdadds">'+''.join(adds)+'</div>' if not adds.is_empty() else '')+'<div class="fldfx">'+L.field+'</div></section>'
func ally_tile(state: Dictionary,i: int,L: Dictionary,K: Array,item_ok: bool=false) -> String:
	var unit=state.u[i-1];var d=definitions[i-1]
	if truth(d.get('empty')):return '<div class="pc dead empty" data-u="'+str(i)+'"><div class="mid"><div class="nm">'+u('빈 자리')+'</div></div></div>'
	var cls='pc'+(' act' if state.cur==i and state.over=='' else '')+(' chg' if unit.chg==1 else '')+(' dead' if unit.al==0 else '')+s(entry(L,'cls',i) if truth(entry(L,'cls',i)) else '')
	var vars=[]
	if truth(entry(L,'hit',i)):vars.append('--kt:'+Text.fixed_two(entry(L,'hit',i))+'s');cls+=' hit'
	if truth(entry(L,'vars',i)):vars.append(entry(L,'vars',i))
	if unit.chg==1:vars.append('--nd:-'+Text.fixed_two(fposmod(state.n*.37,1.5))+'s')
	var trg=' trg" style="--t:'+Text.fixed_two(entry(L,'trg',i))+'s' if truth(entry(L,'trg',i)) else ''
	var out='<div class="'+cls+'" data-u="'+str(i)+'"'+style(vars)+'><div class="ic"><div class="face'+(' fc-'+d.art if d.art!='' else ' fc-none')+'">'
	if d.art=='':out+=persona_image() if d.cid=='persona' else '<i class="im im-cls-'+d.clsid+'"></i>'
	out+='</div>'
	if truth(entry(L,'icwf',i)):out+='<i class="wf" style="--t:'+Text.fixed_two(entry(L,'icwf',i))+'s;--p:.85;border-radius:6px"></i>'
	if d.art!='':out+='<i class="trb im im-t-'+d.art+trg+'"></i>'
	out+=passive_badges(unit,d.get('clsid',''))+'<div class="lvb im im-lv">'+s(d.get('lv',''))+'</div><i class="clb im im-cls-'+d.get('clsid','')+'"></i></div><div class="mid"><div class="nm">'+Locale.t(d.name,lang)+'</div><div class="t2">'+Locale.t(d.cls,lang)+', '+Locale.t(d.row,lang)+'</div>'
	if d.trn!='':out+='<div class="trn"><span class="trl">'+u('패시브')+'</span> '+Locale.t(d.trn,lang)+'</div>'
	out+=hp_stat('HP','hp',unit,'hp',unit.mhp,K,i,true,false)+hp_stat('MP','mp',unit,'mp',unit.mmp,K,i,true,false)
	if unit.sh>0 or K[i-1].has('sh'):out+=hp_stat('SH','sh',unit,'sh',unit.mhp,K,i,false,false)
	out+='<div class="sts">'+chips(state,i)+'</div></div><div class="fxl">'+s(entry(L,'u',i) if truth(entry(L,'u',i)) else '')+'</div>'
	if target_pending(state,unit,'ally',i):out+='<button type="button" class="tgt" risu-btn="tg_'+str(i)+'">'+u('대상 선택')+'</button>'
	if state.get('imenu')==1 and state.get('ipk','')!='' and state.over=='' and item_ok:out+='<button type="button" class="tgt" risu-btn="it_to_'+str(i)+'">'+u('대상 선택')+'</button>'
	return out+'</div>'
