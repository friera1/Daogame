extends Node

signal player_loaded
signal cultivation_changed
signal currencies_changed

var profile: Dictionary = {}

func load_mock_profile() -> void:
	var path := "res://data/mock/player_profile.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open mock player profile")
		return
	profile = JSON.parse_string(file.get_as_text())
	emit_signal("player_loaded")

func get_name() -> String:
	return str(profile.get("name", "Безымянный культиватор"))

func get_level() -> int:
	return int(profile.get("level", 1))

func get_power() -> int:
	return int(profile.get("combat_power", 0))

func get_currencies() -> Dictionary:
	return profile.get("currencies", {})

func get_cultivation() -> Dictionary:
	return profile.get("cultivation_progress", {})

func add_qi(amount: int) -> void:
	var cult := get_cultivation()
	cult["qi_exp"] = int(cult.get("qi_exp", 0)) + amount
	var required := int(cult.get("qi_exp_required", 1))
	cult["breakthrough_ready"] = cult["qi_exp"] >= required
	profile["cultivation_progress"] = cult
	emit_signal("cultivation_changed")

func spend_currency(currency_id: String, amount: int) -> bool:
	var currencies := get_currencies()
	var current := int(currencies.get(currency_id, 0))
	if current < amount:
		return false
	currencies[currency_id] = current - amount
	profile["currencies"] = currencies
	emit_signal("currencies_changed")
	return true

func get_inventory() -> Array:
	return profile.get("inventory", [])

func get_skills() -> Array:
	return profile.get("skills", [])
