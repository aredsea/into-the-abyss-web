extends RefCounted
## Source PAGE=6, one locked next floor and uncapped recommendation contract.
static func build(v) -> void:
	var w=v.host.model;var mx=w.dungeon_max();var pg=clampi(int(w.s.dungeon_r21.get("pg",1)),1,int(ceil((mx+1)/6.0)));var rec=w.expedition_rules.recommended(w.average_level(),mx)
	v.text("추천 %d층 · 최심층 %d · 완료 %d회"%[rec,w.s.dungeon_r21.best,w.s.dungeon_r21.runs],16)
	var h=v.row()
	v.button("floor_prev","이전",func():w.floor_page(pg-1);v.host._save();v.host._draw_screen(),false,pg<=1,h)
	v.text("%d / %d쪽"%[pg,int(ceil((mx+1)/6.0))],14,v.T.INK,h)
	v.button("floor_next","다음",func():w.floor_page(pg+1);v.host._save();v.host._draw_screen(),false,pg>=int(ceil((mx+1)/6.0)),h)
	for f in range((pg-1)*6+1,mini(pg*6,mx+1)+1):
		var info=w.dungeon_rules.floor_info(f);var status="잠김" if f>mx else "완료" if f<=w.s.dungeon_r21.best else "도전 가능"
		v.button("floor:"+str(f),"%d층 · %s · %s%s"%[f,w.dungeon_rules.zones[info.zone].name,status," · 추천" if f==rec else ""],func():w.select_dungeon_floor(f);v.host._save();v.host._draw_screen(),f==w.selected_floor,f>mx)
		v.text("★%d · 권장 Lv.%d · 적 Lv.%d"%[w.dungeon_rules.floor_star(info),w.expedition_rules.rec_level(f),w.dungeon_rules.floor_level(w.average_level(),info)],13)
		v.text("층 끝: 구역 보스 "+w.dungeon_rules.foes[w.dungeon_rules.zones[info.zone].boss].name if info.ord>=3 else "층 끝: 우두머리",13)
