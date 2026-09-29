class_name Progress
extends RefCounted
## Estrelas por fase, modo professor e fases criadas no editor (user://).

const FILE := "user://progresso.json"
const CUSTOM_DIR := "user://fases_criadas"

static var stars := {}
static var teacher_mode := false
static var sound_on := true


static func load_data() -> void:
	if not FileAccess.file_exists(FILE):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(FILE))
	if typeof(data) == TYPE_DICTIONARY:
		stars = data.get("stars", {})
		teacher_mode = data.get("teacher_mode", false)
		sound_on = data.get("sound_on", true)


static func save_data() -> void:
	var f := FileAccess.open(FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"stars": stars, "teacher_mode": teacher_mode, "sound_on": sound_on}))


static func stars_for(level_id: String) -> int:
	return int(stars.get(level_id, 0))


static func record(level_id: String, value: int) -> void:
	if value > stars_for(level_id):
		stars[level_id] = value
		save_data()


static func save_custom(problem: GridProblem) -> String:
	DirAccess.make_dir_recursive_absolute(CUSTOM_DIR)
	var index := list_custom().size() + 1
	var path := "%s/fase_%02d.json" % [CUSTOM_DIR, index]
	while FileAccess.file_exists(path):
		index += 1
		path = "%s/fase_%02d.json" % [CUSTOM_DIR, index]
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(problem.to_dict(), "  "))
	return path


static func list_custom() -> Array:
	var result := []
	if not DirAccess.dir_exists_absolute(CUSTOM_DIR):
		return result
	for file in DirAccess.get_files_at(CUSTOM_DIR):
		if file.ends_with(".json"):
			result.append(CUSTOM_DIR + "/" + file)
	result.sort()
	return result
