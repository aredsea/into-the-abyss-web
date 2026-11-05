extends SceneTree
const Scroll=preload("res://tests/ui_scroll_r24.gd")
func _initialize():
	var failures=[]
	var cases=[
		[Rect2(0,0,10,1),Rect2(0,0,10,10),false,"one-pixel clipped height"],
		[Rect2(0,0,1,10),Rect2(0,0,10,10),false,"one-pixel clipped width"],
		[Rect2(0,0,10,0),Rect2(0,0,10,10),false,"fully clipped"],
		[Rect2(0,0,10,2),Rect2(0,0,10,10),false,"two-pixel inset empty"],
		[Rect2(0,0,10,10),Rect2(5,0,10,10),true,"real overlap retained"],
		[Rect2(0,0,10,10),Rect2(10,0,10,10),false,"touching edges"],
		[Rect2(0,0,10,10),Rect2(9,0,10,10),false,"existing one-pixel tolerance"],
		[Rect2(0,0,10,10),Rect2(7,0,10,10),true,"three-pixel overlap retained"],
		[Rect2(-5,-5,10,10),Rect2(-2,-2,10,10),true,"negative position with positive size"],
		[Rect2(0,0,10,10),Rect2(0,0,1,10),false,"clipped second rectangle"]
	]
	for row in cases:
		if Scroll.overlaps(row[0],row[1])!=row[2]:failures.append(row[3])
	print("SCROLL OVERLAP CHECKS ",cases.size()," FAILURES ",failures.size())
	for failure in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
