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
signal summon_progress_changed
signal attendance_changed
signal stamina_changed
signal mailbox_changed

const MAILBOX_CAP := 40
const DEFAULT_MAIL_LIFETIME_SEC := 604800
const EQUIPMENT_ENHANCE_MAX := 15

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
			"battle_stars": {},
			"claimed_rewards": {}
		}
	else:
		var story_progress := profile.get("story_progress", {})
		if not story_progress.has("unlocked_chapters"):
			story_progress["unlocked_chapters"] = {"chapter_01": true}
		if not story_progress.has("completed_battles"):
			story_progress["completed_battles"] = {}
		if not story_progress.has("battle_stars"):
			story_progress["battle_stars"] = {}
		if not story_progress.has("claimed_rewards"):
			story_progress["claimed_rewards"] = {}
		profile["story_progress"] = story_progress
	if not profile.has("summon_progress"):
		profile["summon_progress"] = {}
	if not profile.has("attendance_progress"):
		profile["attendance_progress"] = {"last_claim_key": "", "streak": 0, "total_days": 0}
	if not profile.has("stamina_progress"):
		profile["stamina_progress"] = {"current": 30, "max": 30, "last_regen_time": Time.get_unix_time_from_system(), "regen_interval_sec": 300}
	if not profile.has("mailbox_progress"):
		profile["mailbox_progress"] = {"claimed_messages": {}, "generated_keys": {}, "inbox_messages": []}
	else:
		var mailbox := profile.get("mailbox_progress", {})
		if not mailbox.has("claimed_messages"):
			mailbox["claimed_messages"] = {}
		if not mailbox.has("generated_keys"):
			mailbox["generated_keys"] = {}
		if not mailbox.has("inbox_messages"):
			mailbox["inbox_messages"] = []
		profile["mailbox_progress"] = mailbox
	if not profile.has("equipment_enhancement"):
		profile["equipment_enhancement"] = {}
	_prune_inbox_messages(false)

func save_profile() -> void:
	SaveService.save_profile(profile)

func _today_key_utc() -> String:
	var now := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [int(now.get("year", 1970)), int(now.get("month", 1)), int(now.get("day", 1))]

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

func get_current_stage_id() -> String:
	return str(get_cultivation().get("current_stage_id", "mortal_early"))

func get_equipment() -> Dictionary:
	return profile.get("equipment", {})

func get_equipment_enhancement() -> Dictionary:
	return profile.get("equipment_enhancement", {})

func get_equipment_enhance_level(slot_id: String) -> int:
	return int(get_equipment_enhancement().get(slot_id, 0))

func get_tutorial() -> Dictionary:
	return profile.get("tutorial", {"completed": false, "step_index": 0})

func get_pet_shards() -> Dictionary:
	return profile.get("pet_shards", {})

func get_pet_shards_for(pet_id: String) -> int:
	return int(get_pet_shards().get(pet_id, 0))

func get_story_progress() -> Dictionary:
	return profile.get("story_progress", {})

func get_summon_progress() -> Dictionary:
	return profile.get("summon_progress", {})

func get_attendance_progress() -> Dictionary:
	return profile.get("attendance_progress", {"last_claim_key": "", "streak": 0, "total_days": 0})

func get_stamina_progress() -> Dictionary:
	return profile.get("stamina_progress", {"current": 30, "max": 30, "last_regen_time": Time.get_unix_time_from_system(), "regen_interval_sec": 300})

func get_mailbox_progress() -> Dictionary:
	return profile.get("mailbox_progress", {"claimed_messages": {}, "generated_keys": {}, "inbox_messages": []})

func _mail_expired(message: Dictionary) -> bool:
	var expires_at := int(message.get("expires_at", 0))
	return expires_at > 0 and int(Time.get_unix_time_from_system()) >= expires_at

func get_inbox_messages() -> Array:
	_prune_inbox_messages(false)
	return get_mailbox_progress().get("inbox_messages", [])

func get_unclaimed_mail_count() -> int:
	var count := 0
	for message in get_inbox_messages():
		if not has_claimed_mail(str(message.get("id", ""))):
			count += 1
	return count

func add_inbox_message(message: Dictionary) -> void:
	var mailbox_progress := get_mailbox_progress()
	var inbox := get_inbox_messages()
	var entry := message.duplicate(true)
	if not entry.has("created_at"):
		entry["created_at"] = int(Time.get_unix_time_from_system())
	if not entry.has("expires_at"):
		entry["expires_at"] = int(entry.get("created_at", Time.get_unix_time_from_system())) + DEFAULT_MAIL_LIFETIME_SEC
	inbox.append(entry)
	mailbox_progress["inbox_messages"] = inbox
	profile["mailbox_progress"] = mailbox_progress
	_prune_inbox_messages(true)
	save_profile()
	emit_signal("mailbox_changed")

func _prune_inbox_messages(keep_latest: bool) -> void:
	var mailbox_progress := get_mailbox_progress()
	var inbox: Array = mailbox_progress.get("inbox_messages", [])
	var filtered: Array = []
	for message in inbox:
		if _mail_expired(message) and has_claimed_mail(str(message.get("id", ""))):
			continue
		if _mail_expired(message):
			continue
		filtered.append(message)
	if filtered.size() > MAILBOX_CAP:
		filtered.sort_custom(func(a, b): return int(a.get("created_at", 0)) < int(b.get("created_at", 0)))
		while filtered.size() > MAILBOX_CAP:
			filtered.remove_at(0)
	mailbox_progress["inbox_messages"] = filtered
	profile["mailbox_progress"] = mailbox_progress

func has_generated_mail_key(mail_key: String) -> bool:
	return bool(get_mailbox_progress().get("generated_keys", {}).get(mail_key, false))

func mark_generated_mail_key(mail_key: String) -> void:
	var mailbox_progress := get_mailbox_progress()
	var keys := mailbox_progress.get("generated_keys", {})
	keys[mail_key] = true
	mailbox_progress["generated_keys"] = keys
	profile["mailbox_progress"] = mailbox_progress
	save_profile()
	emit_signal("mailbox_changed")

func has_claimed_mail(message_id: String) -> bool:
	return bool(get_mailbox_progress().get("claimed_messages", {}).get(message_id, false))

func mark_mail_claimed(message_id: String) -> void:
	var mailbox_progress := get_mailbox_progress()
	var claimed := mailbox_progress.get("claimed_messages", {})
	claimed[message_id] = true
	mailbox_progress["claimed_messages"] = claimed
	profile["mailbox_progress"] = mailbox_progress
	_prune_inbox_messages(true)
	save_profile()
	emit_signal("mailbox_changed")

func refresh_stamina() -> Dictionary:
	var stamina := get_stamina_progress()
	var current := int(stamina.get("current", 30))
	var maximum := int(stamina.get("max", 30))
	var last_regen := int(stamina.get("last_regen_time", Time.get_unix_time_from_system()))
	var regen_interval := int(stamina.get("regen_interval_sec", 300))
	var now := int(Time.get_unix_time_from_system())
	if current >= maximum:
		stamina["current"] = maximum
		stamina["last_regen_time"] = now
		profile["stamina_progress"] = stamina
		return stamina
	var elapsed := max(now - last_regen, 0)
	var regen_points := elapsed / regen_interval
	if regen_points > 0:
		current = min(current + regen_points, maximum)
		last_regen += regen_points * regen_interval
		stamina["current"] = current
		stamina["last_regen_time"] = last_regen
		profile["stamina_progress"] = stamina
		save_profile()
		emit_signal("stamina_changed")
	return profile.get("stamina_progress", stamina)

func spend_stamina(amount: int) -> bool:
	var stamina := refresh_stamina()
	var current := int(stamina.get("current", 0))
	if current < amount:
		return false
	stamina["current"] = current - amount
	stamina["last_regen_time"] = int(Time.get_unix_time_from_system()) if int(stamina.get("current", 0)) < int(stamina.get("max", 30)) else int(stamina.get("last_regen_time", Time.get_unix_time_from_system()))
	profile["stamina_progress"] = stamina
	save_profile()
	emit_signal("stamina_changed")
	return true

func add_stamina(amount: int) -> void:
	var stamina := refresh_stamina()
	stamina["current"] = min(int(stamina.get("current", 0)) + amount, int(stamina.get("max", 30)))
	profile["stamina_progress"] = stamina
	save_profile()
	emit_signal("stamina_changed")

func can_claim_daily_login() -> bool:
	return str(get_attendance_progress().get("last_claim_key", "")) != _today_key_utc()

func claim_daily_login() -> Dictionary:
	var attendance := get_attendance_progress()
	if str(attendance.get("last_claim_key", "")) == _today_key_utc():
		return {"claimed": false, "text": "Награда входа уже получена сегодня"}
	var streak := int(attendance.get("streak", 0)) + 1
	if streak > 7:
		streak = 1
	var reward_gold := 200 + streak * 50
	var reward_bound := 20 + streak * 5
	var reward_jade := 10 if streak == 7 else 0
	var reward_stamina := 10 if streak == 3 else 0
	attendance["last_claim_key"] = _today_key_utc()
	attendance["streak"] = streak
	attendance["total_days"] = int(attendance.get("total_days", 0)) + 1
	profile["attendance_progress"] = attendance
	add_currency("gold", reward_gold)
	add_currency("bound_spirit_stone", reward_bound)
	if reward_jade > 0:
		add_currency("jade", reward_jade)
	if reward_stamina > 0:
		add_stamina(reward_stamina)
	save_profile()
	emit_signal("attendance_changed")
	return {"claimed": true, "streak": streak, "gold": reward_gold, "bound_spirit_stone": reward_bound, "jade": reward_jade, "stamina": reward_stamina, "text": "Вход дня %d получен" % streak}

func get_banner_pity(banner_id: String) -> int:
	return int(get_summon_progress().get(banner_id, 0))

func set_banner_pity(banner_id: String, pity_value: int) -> void:
	var summon_progress := get_summon_progress()
	summon_progress[banner_id] = pity_value
	profile["summon_progress"] = summon_progress
	save_profile()
	emit_signal("summon_progress_changed")

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

func get_story_battle_stars(node_id: String) -> int:
	return int(get_story_progress().get("battle_stars", {}).get(node_id, 0))

func mark_story_battle_completed(node_id: String) -> void:
	var story_progress := get_story_progress()
	var completed := story_progress.get("completed_battles", {})
	completed[node_id] = true
	story_progress["completed_battles"] = completed
	profile["story_progress"] = story_progress
	save_profile()
	emit_signal("story_progress_changed")

func set_story_battle_stars(node_id: String, stars: int) -> void:
	var story_progress := get_story_progress()
	var battle_stars := story_progress.get("battle_stars", {})
	battle_stars[node_id] = max(int(battle_stars.get(node_id, 0)), clamp(stars, 0, 3))
	story_progress["battle_stars"] = battle_stars
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

func get_equipment_enhance_cost(slot_id: String) -> Dictionary:
	var next_level := get_equipment_enhance_level(slot_id) + 1
	return {"gold": 300 + next_level * 180, "bound_spirit_stone": 12 + next_level * 6}

func enhance_equipment(slot_id: String) -> Dictionary:
	var equipped_item := str(get_equipment().get(slot_id, "none"))
	if equipped_item == "none":
		return {"ok": false, "text": "Сначала нужно экипировать предмет"}
	var current_level := get_equipment_enhance_level(slot_id)
	if current_level >= EQUIPMENT_ENHANCE_MAX:
		return {"ok": false, "text": "Достигнут максимум усиления"}
	var cost := get_equipment_enhance_cost(slot_id)
	if not spend_currency("gold", int(cost.get("gold", 0))):
		return {"ok": false, "text": "Недостаточно золота"}
	if not spend_currency("bound_spirit_stone", int(cost.get("bound_spirit_stone", 0))):
		add_currency("gold", int(cost.get("gold", 0)))
		return {"ok": false, "text": "Недостаточно связанных духовных камней"}
	var enhancement := get_equipment_enhancement()
	enhancement[slot_id] = current_level + 1
	profile["equipment_enhancement"] = enhancement
	profile["combat_power"] = get_power() + 18 + (current_level + 1) * 6
	save_profile()
	emit_signal("equipment_changed")
	emit_signal("player_loaded")
	return {"ok": true, "slot_id": slot_id, "item_id": equipped_item, "new_level": current_level + 1, "power_gain": 18 + (current_level + 1) * 6, "cost": cost, "text": "%s усилен до +%d" % [slot_id, current_level + 1]}

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
	return ConfigRepository.get_stage_index(stage_id)

func _stage_by_index(index: int) -> Dictionary:
	var stages := ConfigRepository.stages.get("stages", [])
	if index < 0 or index >= stages.size():
		return {}
	return stages[index]

func add_qi(amount: int) -> void:
	var cult := get_cultivation()
	cult["qi_exp"] = int(cult.get("qi_exp", 0)) + amount
	cult["breakthrough_ready"] = int(cult.get("qi_exp", 0)) >= int(cult.get("qi_exp_required", 1))
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

func get_inventory_item_quantity(item_id: String) -> int:
	var total := 0
	for entry in get_inventory():
		if str(entry.get("item_id", "")) == item_id:
			total += int(entry.get("quantity", 0))
	return total

func _item_stack_limit(item_id: String) -> int:
	var item_def := ConfigRepository.get_item_def(item_id)
	return int(item_def.get("stack_limit", 999))

func _can_access_item_def(item_def: Dictionary) -> bool:
	if item_def.is_empty():
		return false
	if not ConfigRepository.is_stage_requirement_met(str(item_def.get("qi_stage_required", "")), get_current_stage_id()):
		return false
	return get_level() >= int(item_def.get("player_level_required", 1))

func can_access_item(item_id: String) -> bool:
	return _can_access_item_def(ConfigRepository.get_item_def(item_id))

func add_inventory_item(item_id: String, quantity: int = 1, rarity: String = "common") -> void:
	var inventory := get_inventory()
	var remaining := quantity
	var stack_limit := max(_item_stack_limit(item_id), 1)
	for i in range(inventory.size()):
		if remaining <= 0:
			break
		if str(inventory[i].get("item_id", "")) != item_id or bool(inventory[i].get("locked", false)):
			continue
		var current_qty := int(inventory[i].get("quantity", 0))
		if current_qty >= stack_limit:
			continue
		var addable := min(stack_limit - current_qty, remaining)
		inventory[i]["quantity"] = current_qty + addable
		remaining -= addable
	while remaining > 0:
		var stack_qty := min(stack_limit, remaining)
		inventory.append({"item_uid": "itm_%s_%d" % [item_id, Time.get_unix_time_from_system() + inventory.size()], "item_id": item_id, "quantity": stack_qty, "rarity": rarity, "locked": false})
		remaining -= stack_qty
	profile["inventory"] = inventory
	save_profile()
	emit_signal("inventory_changed")

func consume_inventory_item(item_id: String, quantity: int = 1) -> bool:
	if get_inventory_item_quantity(item_id) < quantity:
		return false
	var inventory := get_inventory()
	var remaining := quantity
	for i in range(inventory.size() - 1, -1, -1):
		if str(inventory[i].get("item_id", "")) != item_id:
			continue
		var current := int(inventory[i].get("quantity", 0))
		var consume := min(current, remaining)
		inventory[i]["quantity"] = current - consume
		remaining -= consume
		if int(inventory[i].get("quantity", 0)) <= 0:
			inventory.remove_at(i)
		if remaining <= 0:
			break
	profile["inventory"] = inventory
	save_profile()
	emit_signal("inventory_changed")
	return true

func can_use_inventory_item(item_id: String) -> bool:
	var item_def := ConfigRepository.get_item_def(item_id)
	return bool(item_def.get("usable", false)) and _can_access_item_def(item_def)

func craft_recipe(recipe_id: String) -> Dictionary:
	var recipe := ConfigRepository.get_recipe_def(recipe_id)
	if recipe.is_empty():
		return {"ok": false, "text": "Рецепт не найден"}
	if not ConfigRepository.is_stage_requirement_met(str(recipe.get("qi_stage_required", "")), get_current_stage_id()):
		return {"ok": false, "text": "Недостаточная стадия Ци для рецепта"}
	if get_level() < int(recipe.get("player_level_required", 1)):
		return {"ok": false, "text": "Недостаточный уровень для рецепта"}
	for ingredient in recipe.get("ingredients", []):
		if get_inventory_item_quantity(str(ingredient.get("item_id", ""))) < int(ingredient.get("quantity", 1)):
			return {"ok": false, "text": "Не хватает материалов для крафта"}
	var gold_cost := int(recipe.get("gold_cost", 0))
	var bound_cost := int(recipe.get("bound_spirit_stone_cost", 0))
	if int(get_currencies().get("gold", 0)) < gold_cost:
		return {"ok": false, "text": "Недостаточно золота"}
	if int(get_currencies().get("bound_spirit_stone", 0)) < bound_cost:
		return {"ok": false, "text": "Недостаточно связанных духовных камней"}
	for ingredient in recipe.get("ingredients", []):
		consume_inventory_item(str(ingredient.get("item_id", "")), int(ingredient.get("quantity", 1)))
	if gold_cost > 0:
		spend_currency("gold", gold_cost)
	if bound_cost > 0:
		spend_currency("bound_spirit_stone", bound_cost)
	var result := recipe.get("result", {})
	add_inventory_item(str(result.get("item_id", "")), int(result.get("quantity", 1)), str(result.get("rarity", "common")))
	return {"ok": true, "recipe_id": recipe_id, "result": result, "text": "%s создан" % ConfigRepository.get_item_name(str(result.get("item_id", "")))}

func use_inventory_item(item_id: String) -> String:
	var item_def := ConfigRepository.get_item_def(item_id)
	if item_def.is_empty():
		return "Предмет не найден"
	if not _can_access_item_def(item_def):
		return "Недостаточная стадия Ци или уровень для использования"
	if not bool(item_def.get("usable", false)):
		return "Этот предмет пока нельзя использовать напрямую"
	if not consume_inventory_item(item_id, 1):
		return "Предмет закончился"
	match str(item_def.get("use_type", "")):
		"grant_qi":
			var qi_gain := int(item_def.get("qi_gain", 0))
			add_qi(qi_gain * 10000)
			return "%s использован, получено %d Ци" % [ConfigRepository.get_item_name(item_id), qi_gain]
		"restore_stamina":
			var stamina_gain := int(item_def.get("stamina_gain", 0))
			add_stamina(stamina_gain)
			return "%s использован, восстановлено %d энергии" % [ConfigRepository.get_item_name(item_id), stamina_gain]
		"refine_material":
			var currency_id := str(item_def.get("currency_id", "bound_spirit_stone"))
			var amount := int(item_def.get("currency_amount", 0))
			add_currency(currency_id, amount)
			return "%s преобразован в %d %s" % [ConfigRepository.get_item_name(item_id), amount, currency_id]
		_:
			return "%s использован" % ConfigRepository.get_item_name(item_id)

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
	pets.append({"pet_id": pet_id, "level": 1, "stars": 1, "bond_level": 1, "equipped": false})
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
	var result := {"type": reward_type, "id": reward_id, "rarity": rarity, "is_new": false, "duplicate": false, "status": "item", "text": ""}
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
	if reward_id == "spirit_stone":
		add_currency("spirit_stone", 10)
		result["status"] = "currency"
		result["text"] = "spirit_stone x10"
		return result
	add_inventory_item(reward_id, 1, rarity)
	result["status"] = "item"
	result["text"] = "%s x1" % reward_id
	return result
