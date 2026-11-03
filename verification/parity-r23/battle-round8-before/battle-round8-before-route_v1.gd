extends RefCounted

# Versioned, fixed prototype graph. Never change this graph in place once saves exist.
# Room names, routes and rewards are provisional, not canonical dungeon generation.
const NODES={
	"entry":{"name":"학술원 입구","short":"입구","kind":"entry","next":["archive","patrol"],"pos":[0.07,0.5],"hint":"다음 장소를 선택하세요.","detail":"끊어진 복도 너머로 두 갈래 길이 보인다."},
	"archive":{"name":"쓰러진 서가","short":"서가","kind":"find_card","next":["cache","coins"],"pos":[0.28,0.22],"hint":"탐색 · 봉인 해제 카드 1장","detail":"봉인을 푸는 기록을 발견했다. 봉인 해제 카드가 보유 패에 추가됐다."},
	"patrol":{"name":"인형 순찰로","short":"순찰로","kind":"battle","next":["cache","supplies"],"pos":[0.28,0.78],"hint":"전투 · 승리 시 금화 40, 야영 카드","detail":"인형을 물리쳤다. 금화 40, 경험치 14와 안전한 야영 카드 1장을 얻었다."},
	"cache":{"name":"봉인된 보관함","short":"보관함","kind":"sealed","next":["rest"],"pos":[0.52,0.16],"hint":"사건 · 봉인 해제 카드로 회복약 획득","detail":"금속 상자의 잠금에 마력이 남아 있다. 카드로 열거나 그대로 지나갈 수 있다."},
	"coins":{"name":"붕괴한 회랑","short":"회랑","kind":"coins","next":["rest"],"pos":[0.52,0.5],"hint":"탐색 · 금화 20","detail":"무너진 회랑에서 금화 20을 모았다."},
	"supplies":{"name":"버려진 야영지","short":"야영지","kind":"supplies","next":["rest"],"pos":[0.52,0.84],"hint":"탐색 · 안전한 야영 카드 1장","detail":"쓸 만한 야영 도구를 발견했다. 안전한 야영 카드가 보유 패에 추가됐다."},
	"rest":{"name":"닫힌 휴게실","short":"휴게실","kind":"rest","next":["gate"],"pos":[0.75,0.5],"hint":"휴식 · HP 30%, MP 60% 회복","detail":"문을 닫고 잠시 쉴 수 있다. 이곳을 떠나면 집행실의 정예와 맞선다."},
	"gate":{"name":"마도 집행실","short":"집행실","kind":"battle","next":[],"pos":[0.94,0.5],"hint":"목표 · 마지막 정예 전투","detail":"집행 인형을 쓰러뜨리고 원정을 마친다."}
}

static func valid(r: Dictionary) -> bool:
	if r.get("route_version")!=1 or r.get("route_seed")!=1: return false
	var path=r.get("path")
	if not path is Array or path.is_empty() or path.size()>5 or path[0]!="entry": return false
	for i in range(path.size()):
		if not path[i] is String or not NODES.has(path[i]): return false
		if i>0 and path[i] not in NODES[path[i-1]].next: return false
	if r.get("node")!=path[-1] or r.step!=path.size()-1: return false
	var node=NODES[path[-1]]
	if r.event!=node.kind: return false
	if r.final!=(path[-1]=="gate"): return false
	if r.rested and "rest" not in path: return false
	if r.phase=="rest": return false
	if r.phase=="battle" and (node.kind!="battle" or r.resolved): return false
	if r.phase=="explore" and path[-1]=="gate": return false
	if r.phase=="explore" and node.kind in ["entry","find_card","coins","supplies","battle"] and not r.resolved: return false
	return true
