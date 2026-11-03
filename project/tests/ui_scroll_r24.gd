extends RefCounted
## Layout oracle for scrollable controls: clipping is not overlap; every action
## must fit inside the scroll content and be small enough to reveal wholly.
static func scroller(node: Control) -> ScrollContainer:
	var p=node.get_parent()
	while p:
		if p is ScrollContainer:return p
		p=p.get_parent()
	return null
static func visible_rect(node: Control) -> Rect2:
	var rect=node.get_global_rect();var p=node.get_parent()
	while p:
		if p is ScrollContainer:rect=rect.intersection(p.get_global_rect())
		p=p.get_parent()
	return rect
static func reachable(node: Control,viewport: Rect2) -> bool:
	var rect=node.get_global_rect();var sc=scroller(node)
	if sc==null:return viewport.grow(1).encloses(rect)
	var content=sc.get_child(0).get_global_rect()
	return content.grow(1).encloses(rect) and rect.size.x<=sc.get_global_rect().size.x+1 and rect.size.y<=sc.get_global_rect().size.y+1 and viewport.grow(1).encloses(sc.get_global_rect())
static func overlaps(a: Rect2,b: Rect2) -> bool:
	return a.has_area() and b.has_area() and a.grow(-1).intersects(b.grow(-1))
