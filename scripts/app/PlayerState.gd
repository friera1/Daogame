extends Node

signal player_loaded
signal cultivation_changed
signal currencies_changed
signal skills_changed
signal pets_changed
signal equipment_changed
signal tutorial_changed
signal inventory_changed

var profile: Dictionary = {}

func load_mock_profile() -> void:
	var path := "res://data/mock/player_profile.json"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open mock player profile")
		return
	profile = JSON.parse_string(file.get_as_text())
	if not profile.has("tutorial"):
		profile["tutorial"] = {"completed": false, "step_index": 0}
	save_profile()
	emit_signal("player_loaded")

func load_or_create_profile() -> void:
	var saved := SaveService.load_profile()
	if saved.is_empty():
		load_mock_profile()
		return
	profile = saved
	if not profile.has("tutorial"):
		profile["tutorial"] = {"completed": false, "step_index": 0}
	emit_signal("player_loaded")

func save_profile() -> void:
	SaveService.save_profile(profile)

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

func get_equipment() -> Dictionary:
	return profile.get("equipment", {})

func get_tutorial() -> Dictionary:
	return profile.get("tutorial", {"completed": false, "step_index": 0})

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

func add_qi(amount: int) -> void:
	var cult := get_cultivation()
	cult["qi_exp"] = int(cult.get("qi_exp", 0)) + amount
	var required := int(cult.get("qi_exp_required", 1))
	cult["breakthrough_ready"] = cult["qi_exp"] >= required
	profile["cultivation_progress"] = cult
	save_profile()
	emit_signal("cultivation_changed")

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

func equip_pet(pet_id: String) -> void:
	var pets := get_pets()
	for i in range(pets.size()):
		pets[i]["equipped"] = str(pets[i].get("pet_id", "")) == pet_id
	profile["pets"] = pets
	save_profile()
	emit_signal("pets_changed")

func grant_summon_reward(reward: Dictionary) -> String:
	var reward_type := str(reward.get("type", "item"))
	var reward_id := str(reward.get("id", ""))
	if reward_type == "pet":
		if add_pet(reward_id):
			return "%s добавлен в питомцы" % reward_id
		add_inventory_item("breakthrough_stone", 1, "epic")
		return "%s уже был у тебя, выдан камень прорыва" % reward_id
	var rarity := "rare"
	if reward_id == "breakthrough_stone":
		rarity = "epic"
	elif reward_id == "spirit_stone":
		add_currency("spirit_stone", 10)
		return "spirit_stone x10"
	add_inventory_item(reward_id, 1, rarity)
	return "%s x1" % reward_id
