extends Node

var stages: Dictionary = {}
var items: Dictionary = {}
var skills: Dictionary = {}
var idle: Dictionary = {}
var pets: Dictionary = {}
var story: Dictionary = {}
var daily_missions: Dictionary = {}
var shop_offers: Dictionary = {}
var summon_pools: Dictionary = {}

func load_all() -> void:
	stages = _load_json("res://data/configs/stages.json")
	items = _load_json("res://data/configs/item_defs.json")
	skills = _load_json("res://data/configs/skill_defs.json")
	idle = _load_json("res://data/configs/idle_reward_tables.json")
	pets = _load_json("res://data/configs/pet_defs.json")
	story = _load_json("res://data/configs/story_chapters.json")
	daily_missions = _load_json("res://data/configs/daily_missions.json")
	shop_offers = _load_json("res://data/configs/shop_offers.json")
	summon_pools = _load_json("res://data/configs/summon_pools.json")

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing config file: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid JSON dictionary in: %s" % path)
		return {}
	return data

func get_stage_name(stage_id: String) -> String:
	for stage in stages.get("stages", []):
		if stage.get("id", "") == stage_id:
			return str(stage.get("name", stage_id))
	return stage_id
