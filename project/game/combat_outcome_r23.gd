extends RefCounted
## 30-engine finish/rewards over the shared battle record boundary.
const State=preload('res://game/battle_source_state_r23.gd')
const Record=preload('res://game/combat_record_r23.gd')
const Rules=preload('res://game/dungeon_rules_r21.gd')
const Text=preload('res://game/combat_display_r22.gd')
const REWARD={"exp":480,"gold":340,"item":""} # 10-data.lua:85
var source=State.new()
var rules=Rules.new()
var lang='ko':
	set(value):lang=value;source.lang=value
var definitions=[]:
	set(value):definitions=value;source.definitions=value
func u(s: String,vars: Dictionary={}) -> String:return source.u(s,vars)
func exp_multiplier(st: Dictionary) -> float:
	var border=0;var seredia=0
	for m in st.get('pm',[]):
		if m.get('id','')=='':continue
		var ids=State.trait_ids(m)
		if ids[2]=='border':border+=1
		if ids[2]=='seredia':seredia+=1
	return 1+.1*border+(.1 if seredia>=3 else 0)
func experience(st: Dictionary) -> float:
	var sum=0.0;var mult=1.0
	if State.truth(st.get('fl')):
		var R=rules.catalog.tune.reward
		if st.get('raid',0)==1:
			sum=st.get('el',1)*12*R.exp_ref_enemies*{'chief':R.chief,'boss':R.boss,'core':R.core}.get(definitions[4].get('grade',''),R.chief)
		else:
			for j in range(4,st.u.size()):
				var d=definitions[j]
				if st.u[j].get('empty')!=1 and not d.get('empty',false):sum+=d.get('lvn',st.get('el',1))*State.Data.GRADES.get(d.get('grade',''),State.Data.GRADES.mob).get('exp',12)
		mult=rules.floor_mult(int(st.dn.floor)).reward if st.get('dn') is Dictionary and State.truth(st.dn.get('floor')) else rules.star_mult(st).reward
	else:
		for j in range(4,st.u.size()):
			if st.u[j].get('empty')!=1:sum+=definitions[j].get('lvn',st.get('el',1))*(36 if definitions[j].get('kind')=='elite' else 12)
		var stars=rules.config.stats.stars;var star=st.get('star',1)
		mult=stars[int(star)-1].reward if star>=1 and star<=stars.size() and floor(star)==star else stars[0].reward
	mult*=st.get('qmult',1)*exp_multiplier(st)
	return floor(sum*mult+1e-9)+(st.dn.get('ae',0) if State.truth(st.get('fl')) and st.get('dn') is Dictionary else 0)
func finish(st: Dictionary,result: String) -> void:
	if st.over!='':return
	st.over=result
	var ev=st.get('ev');var T=ev.T if ev is Dictionary else 0
	var win=result=='win';var hurt=[];var parts=[]
	for i in range(4):
		var unit=st.u[i];var d=definitions[i]
		if not d.get('empty',false):
			parts.append(source.t(d.full)+' '+Text.lua_string(unit.hp)+'/'+Text.lua_string(unit.mhp))
			if unit.al==0:hurt.append(source.t(d.full))
	st.exp=experience(st) if win else 0
	var lines=[u('[전투 결과 - 승리]' if win else '[전투 결과 - 패배]')]
	var context=source.result_context(st)
	if context is String:lines.append(context)
	if win:
		lines.append(u('적을 모두 물리쳤다. 마지막 일격은 {last} 행동 {turns}번 만에 끝났다. 심연 고갈 {depletions}회.',{"last":st.kill+Text.Josa.tail(st.kill,'이다',lang)+'.' if st.kill!='' else '알 수 없다.',"turns":st.n,"depletions":st.nd}))
	else:lines.append(u('파티가 버티지 못했다. 전원 부상으로 퇴각한다. 사망자는 없다. 행동 {turns}번째에 무너졌다.',{"turns":st.n}))
	lines.append(u('남은 체력: {party}',{"party":', '.join(parts)}));lines.append(u('부상자: {party}',{"party":', '.join(hurt) if not hurt.is_empty() else '없음'}))
	if win:
		if st.get('dn') is Dictionary and st.dn.get('kind')=='explore':lines.append(u('얻은 것: 경험치 {exp}, 금화 {gold} (층 정산 때 합산해 받는다. 퇴각해도 모은 것은 가져간다)',{"exp":st.exp,"gold":st.get('rg',0)}))
		elif st.get('dn') is Dictionary and st.dn.get('stage')==1:lines.append(u('얻은 것: 아직 없음 (층 보스를 쓰러뜨리면 이 구역 전투 몫까지 합산해 받는다)'))
		else:lines.append(u('얻은 것: 경험치 {exp}, 금화 {gold}{item}',{"exp":st.exp,"gold":st.get('rg',REWARD.gold),"item":', '+REWARD.item if REWARD.item!='' else ''}))
	else:lines.append(u('얻은 것: 없음 (원정 물자 일부 분실)'))
	lines.append(u('이 결과는 확정이다. 번복하지 말고 장면으로 서술하라. 위 숫자는 화면에 이미 보이니 대사로 읊지 않는다.'))
	st.res='\n'.join(lines)
	if ev is Dictionary:Record.push(st,{"k":"end","t":T+.3,"win":1 if win else 0})
	Record.say(st,u('<b>승리</b>. 전투가 끝났다.' if win else '<b>퇴각</b>. 파티 전원이 부상으로 물러난다.'),T+.6)
	st.cur=0;st.q=[]
func check_end(st: Dictionary) -> bool:
	if st.over!='':return true
	var friends=0;var foes=0
	for i in range(st.u.size()):
		if st.u[i].al==1:
			if i<4:friends+=1
			else:foes+=1
	if foes==0:finish(st,'win');return true
	if friends==0 or st.n>=400:finish(st,'lose');return true
	return false
