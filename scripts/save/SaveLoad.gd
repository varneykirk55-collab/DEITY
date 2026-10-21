class_name SaveLoad
extends RefCounted


static func list_saves() -> Array:
	GameState._ensure_save_dir()
	var out: Array = []
	var dir := DirAccess.open(GameState.SAVE_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".deity.json"):
			out.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out


static func path_for(name: String) -> String:
	var safe := name.to_lower().validate_filename().replace(" ", "_")
	if safe.is_empty():
		safe = "world"
	return GameState.SAVE_DIR + "/" + safe + ".deity.json"


static func write_save(data: Dictionary, display_name: String) -> String:
	GameState._ensure_save_dir()
	var path := path_for(display_name)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(data))
	f.close()
	return path


static func read_save(filename: String) -> Dictionary:
	var path := filename
	if not path.begins_with("user://"):
		path = GameState.SAVE_DIR + "/" + filename
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(txt) != OK:
		return {}
	var d = json.data
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	return d
