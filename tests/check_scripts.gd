extends Node
## Loads every script of the project (with the autoloads running, as in the game), so a parse or type
## error anywhere shows up at once:
##   godot --headless --path . res://tests/check_scripts.tscn


func _ready() -> void:
	var failed := 0
	var count := 0
	for path in _scripts("res://"):
		count += 1
		var s: Script = load(path)
		if s == null or not s.can_instantiate():
			print("FAILED: ", path)
			failed += 1
	print("%d scripts, %d failed" % [count, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for sub in DirAccess.get_directories_at(dir):
		if sub.begins_with(".") or sub == "addons":
			continue
		out.append_array(_scripts(dir.path_join(sub)))
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	return out
