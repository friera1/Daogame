extends Node

var stages: Dictionary = {}
var items: Dictionary = {}
var item_rarities: Dictionary = {}
var crafting_recipes: Dictionary = {}
var skills: Dictionary = {}
var idle: Dictionary = {}
var pets: Dictionary = {}
var story: Dictionary = {}
var daily_missions: Dictionary = {}
var shop_offers: Dictionary = {}
var summon_pools: Dictionary = {}
var tutorial: Dictionary = {}

func load_all() -> void:
	stages = _load_json("res://data/configs/stages.json")
	items = _load_json("res://data/configs/item_defs.json")
	item_rarities = _load_json("res://data/configs/item_rarities.json")
	crafting_recipes = _load_json("res://data/configs/crafting_recipes.json")
	skills = _load_json("res://data/configs/skill_defs.json")
	idle = _load_json("res://data/configs/idle_reward_tables.json")
	pets = _load_json("res://data/configs/pet_defs.json")
	story = _load_json("res://data/configs/story_chapters.json")
	daily_missions = _load_json("res://data/configs/daily_missions.json")
	shop_offers = _load_json("res://data/configs/shop_offers.json")
	summon_pools = _load_json("res://data/configs/summon_pools.json")
	tutorial = _load_json("res://data/configs/tutorial_steps.json")

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

func get_stage_index(stage_id: String) -> int:
	var stage_list := stages.get("stages", [])
	for i in range(stage_list.size()):
		if str(stage_list[i].get("id", "")) == stage_id:
			return i
	return -1

func is_stage_requirement_met(required_stage_id: String, current_stage_id: String) -> bool:
	if required_stage_id == "":
		return true
	return get_stage_index(current_stage_id) >= get_stage_index(required_stage_id)

func get_item_def(item_id: String) -> Dictionary:
	for item in items.get("items", []):
		if str(item.get("id", "")) == item_id:
			return item
	return {}

func get_item_name(item_id: String) -> String:
	var item := get_item_def(item_id)
	return str(item.get("name", item_id))

func get_rarity_def(rarity_id: String) -> Dictionary:
	for rarity in item_rarities.get("rarities", []):
		if str(rarity.get("id", "")) == rarity_id:
			return rarity
	return {}

func get_rarity_name(rarity_id: String) -> String:
	var rarity := get_rarity_def(rarity_id)
	return str(rarity.get("name", rarity_id))

func get_recipe_def(recipe_id: String) -> Dictionary:
	for recipe in crafting_recipes.get("recipes", []):
		if str(recipe.get("id", "")) == recipe_id:
			return recipe
	return {}

func get_recipe_name(recipe_id: String) -> String:
	var recipe := get_recipe_def(recipe_id)
	return str(recipe.get("name", recipe_id))

func get_available_recipes(current_stage_id: String, player_level: int) -> Array:
	var result: Array = []
	for recipe in crafting_recipes.get("recipes", []):
		if not is_stage_requirement_met(str(recipe.get("qi_stage_required", "")), current_stage_id):
			continue
		if player_level < int(recipe.get("player_level_required", 1)):
			continue
		result.append(recipe)
	return result

func get_skill_def(skill_id: String) -> Dictionary:
	for skill in skills.get("skills", []):
		if str(skill.get("id", "")) == skill_id:
			return skill
	return {}

func get_skill_name(skill_id: String) -> String:
	var skill := get_skill_def(skill_id)
	return str(skill.get("name", skill_id))
