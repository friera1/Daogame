extends Node

const OFFLINE_CAP_SECONDS := 8 * 60 * 60
const LAST_EXIT_PATH := "user://last_exit_time.txt"

func mark_exit_time() -> void:
	var file := FileAccess.open(LAST_EXIT_PATH, FileAccess.WRITE)
	if file:
		file.store_string(str(Time.get_unix_time_from_system()))

func get_offline_seconds() -> int:
	if not FileAccess.file_exists(LAST_EXIT_PATH):
		return 0
	var file := FileAccess.open(LAST_EXIT_PATH, FileAccess.READ)
	if file == null:
		return 0
	var previous := int(file.get_as_text())
	var now := int(Time.get_unix_time_from_system())
	return clamp(now - previous, 0, OFFLINE_CAP_SECONDS)

func calculate_rewards() -> Dictionary:
	var seconds := get_offline_seconds()
	var minutes := float(seconds) / 60.0
	var base_rates := ConfigRepository.idle.get("base_per_minute", {})
	return {
		"gold": int(round(minutes * float(base_rates.get("gold", 0)))),
		"qi_essence": int(round(minutes * float(base_rates.get("qi_essence", 0)))),
		"seconds": seconds,
	}
