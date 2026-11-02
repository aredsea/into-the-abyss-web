extends RefCounted
## 01-game G_rnd; 72-guild gd_new/gd_star_range. Signed overflow is Lua's uint64 wrap.
const Dungeon=preload("res://game/dungeon_rules_r21.gd")
const DIFFICULTY=["낮음","중간","높음","엘리트"]
const DELTA={"낮음":-3,"중간":0,"높음":3,"엘리트":0}
const KINDS=[
	{"k":"토벌","t":"균열 핵 토벌","d":"균열 안쪽에 자리 잡은 핵을 부순다."},
	{"k":"구조","t":"고립된 탐사대 구조","d":"갇힌 길드 탐사대에게 닿는 길을 막은 균열의 적을 물리친다."},
	{"k":"회수","t":"잃어버린 유품 회수","d":"숨진 모험가의 유품이 놓인 자리를 지키는 균열의 적을 물리친다."}]
static func unsigned_shift(x: int,n: int) -> int: return (x>>n)&((1<<(64-n))-1)
static func random(seed: int,index: int) -> float:
	var x=seed*-7046029254386353131+index*-4658895280553007687
	x=(x^unsigned_shift(x,30))*-4658895280553007687
	x=(x^unsigned_shift(x,27))*-7723592293110705685
	x=x^unsigned_shift(x,31)
	return float(unsigned_shift(x,11))/9007199254740992.0

static func quest(seed: int,index: int,qn: int,base_level: int,board: Array) -> Dictionary:
	var missing=[]
	for d in DIFFICULTY:
		if not board.any(func(q):return q.difficulty==d): missing.append(d)
	var rr=Dungeon.PM.new(int(floor(random(seed,index)*2147483646)))
	var draw=rr.next()
	var difficulty=missing[int(floor(draw*missing.size()))] if not missing.is_empty() else "중간"
	var rift=""; var kind={}; var stars=1
	for attempt in range(6):
		rift=rr.pick(["남서 설산 균열","남동 숲 균열"])
		var lo=1 if rift=="남서 설산 균열" else 2; var hi=2
		stars=hi if difficulty in ["높음","엘리트"] else lo if difficulty=="낮음" else lo+int(floor(rr.next()*(hi-lo+1)))
		var kinds=KINDS.filter(func(k):return k.k!="토벌" or difficulty in ["높음","엘리트"])
		kind=rr.pick(kinds)
		if not board.any(func(q):return q.rift==rift and q.get("kind","")==kind.k): break
	var q={"id":qn,"source_id":"q"+str(qn),"title":rift+", "+kind.t,"name":kind.t,"rift":rift,"kind":kind.k,"stars":stars,"difficulty":difficulty,"gold":100,"reward_v":2,"d":kind.d,"lv":clampi(base_level+DELTA[difficulty],1,40),"cmp":true,"elite":difficulty=="엘리트"}
	q.level=q.lv
	if difficulty=="엘리트": q.strength=1.5+floor(rr.next()*6)*.1
	return q

static func reward_gold(base: int,marento: int) -> int: return int(floor(base*(1+.15*marento)+.5))

static func gear_count(seed: int,qn: int) -> int:
	return 1+int(floor(Dungeon.mix(seed+qn,1,9,0)*2))

static func elite_gear(rules,seed: int,qn: int,classes: Array,index: int) -> Dictionary:
	var local_seed=seed+qn*7919
	var roll=Dungeon.mix(local_seed,index,2,0)*100
	var rarity="rare"
	for r in [["rare",78],["epic",21],["legend",1]]:
		roll-=r[1]
		if roll<0: rarity=r[0];break
	var cls=[]
	for c in classes:
		if c not in cls and rules.config.gear_items.any(func(g):return g.cls==c): cls.append(c)
	if cls.is_empty(): cls=["warrior"]
	var chosen=cls[int(floor(Dungeon.mix(local_seed,index,3,0)*cls.size()))]
	var slot=["weapon","armor","acc"][int(floor(Dungeon.mix(local_seed,index,4,0)*3))]
	var pool=rules.config.gear_items.filter(func(g):return g.cls==chosen and g.slot==slot and g.rarity==rarity)
	if pool.is_empty(): return {}
	var item=pool[int(floor(Dungeon.mix(local_seed,index,5,0)*pool.size()))]
	var roll_seed=int(floor(Dungeon.mix(local_seed,index,6,0)*1099511627776))+1
	return {"id":item.id,"seed":roll_seed,"code":item.id+"."+Dungeon.base36(roll_seed)+"."+str(int(rules.config.gear_version))}
