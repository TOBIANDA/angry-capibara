extends Node

# Autoload pengelola progres lokal (100% offline, user://save_data.json) sesuai TRD v4.0.

const SAVE_PATH := "user://save_data.json"
const TOTAL_W1_STAGES := 20

var selected_stage_id: String = "1-1"
var unlock_all_preview: bool = false
var audio_volume: float = 100.0
var is_muted: bool = false
var progress: Dictionary = {}

func _ready() -> void:
	_init_defaults()
	load_save()
	apply_audio_settings()

func apply_audio_settings() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_mute(bus, is_muted)
		if audio_volume <= 1.0:
			AudioServer.set_bus_volume_db(bus, -80.0)
		else:
			AudioServer.set_bus_volume_db(bus, linear_to_db(audio_volume / 100.0))

func set_audio_volume(val: float) -> void:
	audio_volume = clampf(val, 0.0, 100.0)
	apply_audio_settings()

func toggle_mute() -> bool:
	is_muted = not is_muted
	apply_audio_settings()
	return is_muted

func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func toggle_fullscreen() -> bool:
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	return is_fullscreen()

func world_has_levels(world_id: int) -> bool:
	return FileAccess.file_exists("res://data/levels/w%d/%d-1.json" % [world_id, world_id])

func _init_defaults() -> void:
	for s in range(1, TOTAL_W1_STAGES + 1):
		var sid := "1-%d" % s
		if not progress.has(sid):
			progress[sid] = {
				"unlocked": (s == 1),
				"best_score": 0,
				"stars": 0
			}

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var txt := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(txt)
	if parsed is Dictionary and parsed.has("progress") and parsed["progress"] is Dictionary:
		var saved_prog: Dictionary = parsed["progress"]
		for sid in saved_prog.keys():
			if progress.has(sid) and saved_prog[sid] is Dictionary:
				var entry: Dictionary = saved_prog[sid]
				progress[sid]["unlocked"] = bool(entry.get("unlocked", sid == "1-1"))
				progress[sid]["best_score"] = int(entry.get("best_score", 0))
				progress[sid]["stars"] = clampi(int(entry.get("stars", 0)), 0, 3)

func save_to_disk() -> void:
	var payload := {
		"version": 4,
		"progress": progress
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload, "\t"))
		f.close()

func is_stage_unlocked(stage_id: String) -> bool:
	if unlock_all_preview:
		return true
	if not progress.has(stage_id):
		return false
	return bool(progress[stage_id]["unlocked"])

func get_stage_stars(stage_id: String) -> int:
	if not progress.has(stage_id):
		return 0
	return int(progress[stage_id]["stars"])

func get_stage_best_score(stage_id: String) -> int:
	if not progress.has(stage_id):
		return 0
	return int(progress[stage_id]["best_score"])

func get_world1_total_stars() -> int:
	var total := 0
	for s in range(1, TOTAL_W1_STAGES + 1):
		total += get_stage_stars("1-%d" % s)
	return total

func record_stage_clear(stage_id: String, score: int, stars: int) -> void:
	if not progress.has(stage_id):
		progress[stage_id] = { "unlocked": true, "best_score": 0, "stars": 0 }
	var cur: Dictionary = progress[stage_id]
	cur["unlocked"] = true
	cur["best_score"] = maxi(int(cur["best_score"]), score)
	cur["stars"] = maxi(int(cur["stars"]), clampi(stars, 1, 3))

	# Buka sub-level berikutnya secara otomatis (TRD §3.3)
	var parts := stage_id.split("-")
	if parts.size() == 2:
		var w_num: int = int(parts[0])
		var s_num: int = int(parts[1])
		if w_num == 1 and s_num < TOTAL_W1_STAGES:
			var next_id := "1-%d" % (s_num + 1)
			if progress.has(next_id):
				progress[next_id]["unlocked"] = true
	save_to_disk()

func get_next_stage_id(stage_id: String) -> String:
	var parts := stage_id.split("-")
	if parts.size() == 2:
		var w_num: int = int(parts[0])
		var s_num: int = int(parts[1])
		if w_num == 1 and s_num < TOTAL_W1_STAGES:
			return "1-%d" % (s_num + 1)
	return ""
