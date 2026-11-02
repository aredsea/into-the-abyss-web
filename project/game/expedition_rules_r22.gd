extends RefCounted
## Source 34-traits tx_* and 76/77/78 contracts; no combat engine mutation.
const D=preload("res://game/dungeon_rules_r21.gd")
var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/expedition-r22.json"))

func counts(pm: Array,cast: Array) -> Dictionary:
	var out={}
	for m in pm.slice(0,4):
		if m.get("id","")=="":continue
		var nation=m.get("nat","")
		if m.id!="persona":
			for c in cast:
				if c.id==m.id:nation=c.nation;break
		var k=data.nations.get(nation,"")
		if k!="":out[k]=out.get(k,0)+1
	return out

func modifiers(pm: Array,cast: Array) -> Dictionary:
	var c=counts(pm,cast);var x=data.traits
	return {"rest_hp":x.solen.rest3 if c.get("solen",0)>=3 else 0.0,"rest_mp":x.naerin.rest_mp3 if c.get("naerin",0)>=3 else 0.0,
		"aff":1+x.solen.aff3 if c.get("solen",0)>=3 else 1.0,"coin":1+x.karashin.find3 if c.get("karashin",0)>=3 else 1.0,
		"dup":x.border.dup3 if c.get("border",0)>=3 else x.border.dup2 if c.get("border",0)>=2 else 0.0,
		"herb":x.naerin.herb3 if c.get("naerin",0)>=3 else x.naerin.herb2 if c.get("naerin",0)>=2 else 0.0,
		"loss":1-x.kern.lose2 if c.get("kern",0)>=2 else 1.0,"keep":x.kern.keep3 if c.get("kern",0)>=3 else 0.0,
		"gold":1+x.marento.gold*c.get("marento",0),"item":1+x.marento.item2 if c.get("marento",0)>=2 else 1.0,
		"exp":1+x.border.exp*c.get("border",0)+(x.seredia.exp3 if c.get("seredia",0)>=3 else 0.0),
		"shop":1-x.marento.shop3 if c.get("marento",0)>=3 else 1-x.marento.shop2 if c.get("marento",0)>=2 else 1.0}

func discovery(out: Dictionary,seed: int,f: int,step: int,mods: Dictionary) -> Dictionary:
	var value=out.duplicate(true)
	if out.kind=="coin":value.gold=maxi(1,int(floor(out.gold*mods.coin+.5)))
	if out.kind=="item":value.count=1+int(mods.dup>0 and D.mix(seed,f,step,11)<mods.dup)+int(mods.herb>0 and out.item.begins_with("hp_") and D.mix(seed,f,step,12)<mods.herb)
	return value

func recommended(avg: float,mx: int) -> int:
	# Compare the uncapped level: Lv40 must not recommend arbitrarily deep floors.
	var best=1
	for f in range(1,mx+1):
		if floor(f*1.5+.5)<=avg+.0001:best=f
	return best

func rec_level(f: int) -> int:return clampi(int(floor(f*1.5+.5)),1,40)
