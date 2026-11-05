extends SceneTree
## Inventory untranslated authored content without replacing or deleting its prose.
const L=preload("res://game/localization_r22.gd")
var total=0
var missing=[]
var examples=[]
var counts={}
var korean=RegEx.new()
func _initialize():korean.compile("[가-힣]");call_deferred("run")
func inspect(file: String,path: String,value: String):
	total+=1
	var shown=L.authored_display(value,{"settings":{"lang":"en"},"persona":{"name":"You"}})
	if korean.search(shown):
		missing.append({"file":file,"field":path,"source_sha256":value.sha256_text()});counts[file]=counts.get(file,0)+1
		if examples.size()<20:examples.append({"file":file,"field":path,"source":value,"display":shown})
func run():
	var args=OS.get_cmdline_user_args()
	var selected=Array(args[0].split(",")) if not args.is_empty() else []
	for filename in DirAccess.get_files_at("res://data/dialogue-r21"):
		if not filename.ends_with(".json"):continue
		if not selected.is_empty() and filename.get_basename() not in selected:continue
		var file="project/data/dialogue-r21/"+filename;var d=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue-r21/"+filename))
		for i in d.inn.size():
			var row=d.inn[i];var path="inn/"+str(i)
			inspect(file,path+"/situation",row.situation);inspect(file,path+"/seen",row.seen)
			for j in row.lines.size():inspect(file,path+"/lines/"+str(j),row.lines[j])
			for j in row.choices.size():
				var c=row.choices[j];var at=path+"/choices/"+str(j);inspect(file,at+"/text",c.text)
				for k in c.response.size():inspect(file,at+"/response/"+str(k),c.response[k])
		for i in d.dungeon.size():
			for j in d.dungeon[i].variants.size():inspect(file,"dungeon/"+str(i)+"/variants/"+str(j),d.dungeon[i].variants[j])
		for i in d.transitions.size():
			var row=d.transitions[i];var path="transitions/"+str(i);inspect(file,path+"/situation",row.situation)
			for j in row.lines.size():inspect(file,path+"/lines/"+str(j),row.lines[j])
	var destination="res://../verification/finish-r24/authored-language-audit.json" if selected.is_empty() else "res://../verification/en-r24/batch-language-audit.json"
	FileAccess.open(destination,FileAccess.WRITE).store_string(JSON.stringify({"fields":total,"untranslated":missing.size(),"per_file":counts,"missing":missing,"examples":examples,"selected":selected,"scope":"Authored inn, response, bark and transition prose after actual English display resolution. Same-file en.display fields supply English; missing translations retain their Korean source and remain counted."},"\t"))
	print("AUTHORED LANGUAGE AUDIT FIELDS ",total," UNTRANSLATED ",missing.size());quit()
