extends Node

signal player_loaded
signal cultivation_changed
signal currencies_changed
signal skills_changed
signal pets_changed
signal equipment_changed
signal tutorial_changed
signal inventory_changed
signal story_progress_changed

var profile: Dictionary = {}

func load_mock_profile() -> void:
	var path := "res://data/mock/player_profile.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open mock player profile")
		return
	profile = JSON.parse_string(file.get_as_text())
	_ensure_profile_defaults()
	save_profile()
	emit_signal("player_loaded")

func load_or_create_profile() -> void:
	var saved := SaveService.load_profile()
	if saved.is_empty():
		load_mock_profile()
		return
	profile = saved
	_ensure_profile_defaults()
	emit_signal("player_loaded")

func _ensure_profile_defaults() -> void:
	if not profile.has("tutorial"):
		profile["tutorial"] = {"completed": false, "step_index": 0}
	if not profile.has("pet_shards"):
		profile["pet_shards"] = {}
	if not profile.has("story_progress"):
		profile["story_progress"] = {
			"unlocked_chapters": {"chapter_01": true},
			"completed_battles": {},
			"claimed_rewards": {}
		}

func save_profile() -> void:
	SaveService.save_profile(profile)

func get_name() -> String:
	return str(profile.get("name", "Безымянный культиватор"))

func get_level() -> int:
	return int(profile.get("level", 1))

func get_power() -> int:
	return int(profile.get("combat_power", 0))

func add_power(amount: int) -> void:
	profile["combat_power"] = get_power() + amount
	save_profile()
	emit_signal("player_loaded")

func get_currencies() -> Dictionary:
	return profile.get("currencies", {})

func get_cultivation() -> Dictionary:
	return profile.get("cultivation_progress", {})

func get_equipment() -> Dictionary:
	return profile.get("equipment", {})

func get_tutorial() -> Dictionary:
	return profile.get("tutorial", {"completed": false, "step_index": 0})

func get_pet_shards() -> Dictionary:
	return profile.get("pet_shards", {})

func get_pet_shards_for(pet_id: String) -> int:
	return int(get_pet_shards().get(pet_id, 0))

func get_story_progress() -> Dictionary:
	return profile.get("story_progress", {})

func is_story_chapter_unlocked(chapter_id: String) -> bool:
	return bool(get_story_progress().get("unlocked_chapters", {}).get(chapter_id, false))

func unlock_story_chapter(chapter_id: String) -> void:
	var story_progress := get_story_progress()
	var unlocked := story_progress.get("unlocked_chapters", {})
	unlocked[chapter_id] = true
	story_progress["unlocked_chapters"] = unlocked
	profile["story_progress"] = story_progress
	save_profile()
	emit_signal("story_progress_changed")

func has_completed_story_battle(node_id: String) -> bool:
	return bool(get_story_progress().get("completed_battles", {}).get(node_id, false))

func mark_story_battle_completed(node_id: String) -> void:
	var story_progress := get_story_progress()
	var completed := story_progress.get("completed_battles", {})
	completed[node_id] = true
	story_progress["completed_battles"] = completed
	profile["story_progress"] = story_progress
	save_profile()
	emit_signal("story_progress_changed")

func has_claimed_story_reward(node_id: String) -> bool:
	return bool(get_story_progress().get("claimed_rewards", {}).get(node_id, false))

func mark_story_reward_claimed(node_id: String) -> void:
	var story_progress := get_story_progress()
	var claimed := story_progress.get("claimed_rewards", {})
	claimed[node_id] = true
	story_progress["claimed_rewards"] = claimed
	profile["story_progress"] = story_progress
	save_profile()
	emit_signal("story_progress_changed")

func set_tutorial_step(step_index: int) -> void:
	var tutorial := get_tutorial()
	tutorial["step_index"] = step_index
	profile["tutorial"] = tutorial
	save_profile()
	emit_signal("tutorial_changed")

func complete_tutorial() -> void:
	var tutorial := get_tutorial()
	tutorial["completed"] = true
	profile["tutorial"] = tutorial
	save_profile()
	emit_signal("tutorial_changed")

func equip_item(slot_id: String, item_id: String) -> void:
	var equipment := get_equipment()
	equipment[slot_id] = item_id
	profile["equipment"] = equipment
	save_profile()
	emit_signal("equipment_changed")

func refine_body() -> void:
	var cult := get_cultivation()
	cult["body_refinement_level"] = int(cult.get("body_refinement_level", 0)) + 1
	profile["cultivation_progress"] = cult
	save_profile()
	emit_signal("cultivation_changed")

func refine_spirit() -> void:
	var cult := get_cultivation()
	cult["spirit_refinement_level"] = int(cult.get("spirit_refinement_level", 0)) + 1
	profile["cultivation_progress"] = cult
	save_profile()
	emit_signal("cultivation_changed")

func refine_dao_heart() -> void:
	var cult := get_cultivation()
	cult["dao_heart_level"] = int(cult.get("dao_heart_level", 0)) + 1
	profile["cultivation_progress"] = cult
	save_profile()
	emit_signal("cultivation_changed")

func _stage_index(stage_id: String) -> int:
	var stages := ConfigRepository.stages.get("stages", [])
	for i in range(stages.size()):
		if str(stages[i].get("id", "")) == stage_id:
			return i
	return 0

func _stage_by_index(index: int) -> Dictionary:
	var stages := ConfigRepository.stages.get("stages", [])
	if index < 0 or index >= stages.size():
		return {}
	return stages[index]

func add_qi(amount: int) -> void:
	var cult := get_cultivation()
	cult["qi_exp"] = int(cult.get("qi_exp", 0)) + amount
	var required := int(cult.get("qi_exp_required", 1))
	cult["breakthrough_ready"] = int(cult.get("qi_exp", 0)) >= required
	profile["cultivation_progress"] = cult
	save_profile()
	emit_signal("cultivation_changed")

func perform_breakthrough() -> String:
	var cult := get_cultivation()
	if not bool(cult.get("breakthrough_ready", false)):
		return "Недостаточно Ци для прорыва"
	if not consume_inventory_item("breakthrough_stone", 1):
		return "Нужен Камень прорыва"
	var current_stage_id := str(cult.get("current_stage_id", "mortal_early"))
	var next_stage := _stage_by_index(_stage_index(current_stage_id) + 1)
	if next_stage.is_empty():
		add_inventory_item("breakthrough_stone", 1, "epic")
		return "Достигнут предел текущего вертикального среза"
	cult["current_stage_id"] = str(next_stage.get("id", current_stage_id))
	cult["qi_exp"] = 0
	cult["qi_exp_required"] = int(next_stage.get("qi_required", cult.get("qi_exp_required", 1)))
	cult["breakthrough_ready"] = false
	profile["cultivation_progress"] = cult
	profile["level"] = get_level() + 1
	profile["combat_power"] = get_power() + 180
	save_profile()
	emit_signal("cultivation_changed")
	emit_signal("player_loaded")
	return "Прорыв успешен: %s" % ConfigRepository.get_stage_name(str(next_stage.get("id", current_stage_id)))

func spend_currency(currency_id: String, amount: int) -> bool:
	var currencies := get_currencies()
	var current := int(currencies.get(currency_id, 0))
	if current < amount:
		return false
	currencies[currency_id] = current - amount
	profile["currencies"] = currencies
	save_profile()
	emit_signal("currencies_changed")
	return true

func add_currency(currency_id: String, amount: int) -> void:
	var currencies := get_currencies()
	currencies[currency_id] = int(currencies.get(currency_id, 0)) + amount
	profile["currencies"] = currencies
	save_profile()
	emit_signal("currencies_changed")

func apply_idle_rewards() -> Dictionary:
	var rewards := IdleRewardService.calculate_rewards()
	add_currency("gold", int(rewards.get("gold", 0)))
	add_currency("bound_spirit_stone", int(rewards.get("qi_essence", 0)))
	IdleRewardService.mark_exit_time()
	return rewards

func get_inventory() -> Array:
	return profile.get("inventory", [])

func add_inventory_item(item_id: String, quantity: int = 1, rarity: String = "common") -> void:
	var inventory := get_inventory()
	for i in range(inventory.size()):
		if str(inventory[i].get("item_id", "")) == item_id and not bool(inventory[i].get("locked", false)):
			inventory[i]["quantity"] = int(inventory[i].get("quantity", 0)) + quantity
			profile["inventory"] = inventory
			save_profile()
			emit_signal("inventory_changed")
			return
	inventory.append({
		"item_uid": "itm_%s_%d" % [item_id, Time.get_unix_time_from_system()],
		"item_id": item_id,
		"quantity": quantity,
		"rarity": rarity,
		"locked": false
	})
	profile["inventory"] = inventory
	save_profile()
	emit_signal("inventory_changed")

func consume_inventory_item(item_id: String, quantity: int = 1) -> bool:
	var inventory := get_inventory()
	for i in range(inventory.size()):
		if str(inventory[i].get("item_id", "")) != item_id:
			continue
		var current := int(inventory[i].get("quantity", 0))
		if current < quantity:
			return false
		inventory[i]["quantity"] = current - quantity
		if int(inventory[i].get("quantity", 0)) <= 0:
			inventory.remove_at(i)
		profile["inventory"] = inventory
		save_profile()
		emit_signal("inventory_changed")
		return true
	return false

func use_inventory_item(item_id: String) -> String:
	var item_def := ConfigRepository.get_item_def(item_id)
	var item_type := str(item_def.get("type", ""))
	if item_type == "consumable":
		if not consume_inventory_item(item_id, 1):
			return "Предмет закончился"
		var qi_gain := int(item_def.get("qi_gain", 0))
		if qi_gain > 0:
			add_qi(qi_gain * 10000)
		return "%s использован, получено %d Ци" % [ConfigRepository.get_item_name(item_id), qi_gain]
	if item_type == "material" and item_id == "breakthrough_stone":
		if not consume_inventory_item(item_id, 1):
			return "Камень прорыва отсутствует"
		add_currency("bound_spirit_stone", 50)
		return "Камень прорыва преобразован в 50 связанных духовных камней"
	return "Этот предмет пока нельзя использовать напрямую"

func get_skills() -> Array:
	return profile.get("skills", [])

func upgrade_skill(skill_id: String) -> bool:
	var skills := get_skills()
	for i in range(skills.size()):
		if str(skills[i].get("skill_id", "")) == skill_id:
			skills[i]["level"] = int(skills[i].get("level", 1)) + 1
			profile["skills"] = skills
			save_profile()
			emit_signal("skills_changed")
			return true
	return false

func get_pets() -> Array:
	return profile.get("pets", [])

func has_pet(pet_id: String) -> bool:
	for pet in get_pets():
		if str(pet.get("pet_id", "")) == pet_id:
			return true
	return false

func add_pet(pet_id: String) -> bool:
	if has_pet(pet_id):
		return false
	var pets := get_pets()
	pets.append({
		"pet_id": pet_id,
		"level": 1,
		"stars": 1,
		"bond_level": 1,
		"equipped": false
	})
	profile["pets"] = pets
	save_profile()
	emit_signal("pets_changed")
	return true

func add_pet_shards(pet_id: String, amount: int) -> int:
	var shards := get_pet_shards()
	shards[pet_id] = int(shards.get(pet_id, 0)) + amount
	profile["pet_shards"] = shards
	save_profile()
	emit_signal("pets_changed")
	return int(shards[pet_id])

func evolve_pet_with_shards(pet_id: String) -> bool:
	var shards_needed := 3
	var shards := get_pet_shards()
	var current_shards := int(shards.get(pet_id, 0))
	if current_shards < shards_needed:
		return false
	var pets := get_pets()
	for i in range(pets.size()):
		if str(pets[i].get("pet_id", "")) != pet_id:
			continue
		pets[i]["stars"] = int(pets[i].get("stars", 1)) + 1
		shards[pet_id] = current_shards - shards_needed
		profile["pets"] = pets
		profile["pet_shards"] = shards
		save_profile()
		emit_signal("pets_changed")
		return true
	return false

func equip_pet(pet_id: String) -> void:
	var pets := get_pets()
	for i in range(pets.size()):
		pets[i]["equipped"] = str(pets[i].get("pet_id", "")) == pet_id
	profile["pets"] = pets
	save_profile()
	emit_signal("pets_changed")

func _reward_rarity(reward_type: String, reward_id: String) -> String:
	if reward_type == "pet":
		for pet in ConfigRepository.pets.get("pets", []):
			if str(pet.get("id", "")) == reward_id:
				return str(pet.get("rarity", "rare"))
		return "rare"
	for item in ConfigRepository.items.get("items", []):
		if str(item.get("id", "")) == reward_id:
			return str(item.get("rarity", "rare"))
	return "rare"

func grant_summon_reward(reward: Dictionary) -> Dictionary:
	var reward_type := str(reward.get("type", "item"))
	var reward_id := str(reward.get("id", ""))
	var rarity := _reward_rarity(reward_type, reward_id)
	var result := {
		"type": reward_type,
		"id": reward_id,
		"rarity": rarity,
		"is_new": false,
		"duplicate": false,
		"status": "item",
		"text": ""
	}
	if reward_type == "pet":
		if add_pet(reward_id):
			result["is_new"] = true
			result["status"] = "new_pet"
			result["text"] = "%s добавлен в питомцы" % reward_id
			return result
		var shard_total := add_pet_shards(reward_id, 1)
		result["duplicate"] = true
		result["status"] = "duplicate_pet"
		result["text"] = "%s уже был у тебя, получен осколок (%d/3)" % [reward_id, shard_total]
		return result
	if reward_id == "breakthrough_stone":
		rarity = "epic"
		result["rarity"] = rarity
		add_inventory_item(reward_id, 1, rarity)
		result["status"] = "epic_item"
		result["text"] = "%s x1" % reward_id
		return result
	if reward_id == "spirit_stone":
		add_currency("spirit_stone", 10)
		result["status"] = "currency"
		result["text"] = "spirit_stone x10"
		return result
	add_inventory_item(reward_id, 1, rarity)
	result["status"] = "item"
	result["text"] = "%s x1" % reward_id
	return result
