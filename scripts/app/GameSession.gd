extends Node

var is_initialized: bool = false
var last_battle_result: Dictionary = {}
var claimed_daily_missions: Dictionary = {}
var pending_battle_context: Dictionary = {}
var current_daily_key: String = ""

func initialize() -> void:
	if is_initialized:
		return
	ConfigRepository.load_all()
	PlayerState.load_or_create_profile()
	IdleRewardService.mark_exit_time()
	current_daily_key = _today_key_utc()
	_apply_daily_reset_if_needed()
	is_initialized = true

func _today_key_utc() -> String:
	var now := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [int(now.get("year", 1970)), int(now.get("month", 1)), int(now.get("day", 1))]

func _cycle_day_index() -> int:
	return int(floor(float(Time.get_unix_time_from_system()) / 86400.0))

func _apply_daily_reset_if_needed() -> void:
	var today := _today_key_utc()
	if current_daily_key == "":
		current_daily_key = today
	if current_daily_key == today:
		return
	claimed_daily_missions.clear()
	current_daily_key = today

func refresh_live_ops_state() -> void:
	_apply_daily_reset_if_needed()

func get_daily_reset_status() -> Dictionary:
	_apply_daily_reset_if_needed()
	var now := Time.get_unix_time_from_system()
	var seconds_until_reset := 86400 - int(now % 86400)
	return {
		"daily_key": current_daily_key,
		"seconds_until_reset": seconds_until_reset,
		"shop_cycle": _cycle_day_index() % 3,
		"banner_cycle": _cycle_day_index() % 2
	}

func get_shop_offer_state(offer_id: String) -> Dictionary:
	var live_ops := get_daily_reset_status()
	var cycle := int(live_ops.get("shop_cycle", 0))
	var enabled := true
	if offer_id.contains("breakthrough"):
		enabled = cycle != 1
	elif offer_id.contains("jade"):
		enabled = cycle != 2
	return {
		"enabled": enabled,
		"cycle": cycle
	}

func get_banner_live_state(banner_id: String) -> Dictionary:
	var live_ops := get_daily_reset_status()
	var cycle := int(live_ops.get("banner_cycle", 0))
	return {
		"featured": cycle == 0,
		"cycle": cycle,
		"banner_id": banner_id
	}

func has_claimed_story_reward(node_id: String) -> bool:
	return PlayerState.has_claimed_story_reward(node_id)

func mark_story_reward_claimed(node_id: String) -> void:
	PlayerState.mark_story_reward_claimed(node_id)

func has_claimed_daily_mission(mission_id: String) -> bool:
	_apply_daily_reset_if_needed()
	return bool(claimed_daily_missions.get(mission_id, false))

func mark_daily_mission_claimed(mission_id: String) -> void:
	_apply_daily_reset_if_needed()
	claimed_daily_missions[mission_id] = true

func set_battle_context(context: Dictionary) -> void:
	pending_battle_context = context

func get_battle_context() -> Dictionary:
	return pending_battle_context

func clear_battle_context() -> void:
	pending_battle_context = {}

func has_claimed_battle_rewards() -> bool:
	return bool(last_battle_result.get("claimed", false))

func has_completed_story_battle(node_id: String) -> bool:
	return PlayerState.has_completed_story_battle(node_id)

func is_story_chapter_unlocked(chapter_id: String) -> bool:
	return PlayerState.is_story_chapter_unlocked(chapter_id)

func mark_story_battle_completed(node_id: String, chapter_id: String) -> void:
	PlayerState.mark_story_battle_completed(node_id)
	var next_id := _next_chapter_id(chapter_id)
	if not next_id.is_empty():
		PlayerState.unlock_story_chapter(next_id)

func _next_chapter_id(chapter_id: String) -> String:
	var chapters := ConfigRepository.story.get("chapters", [])
	for i in range(chapters.size()):
		if str(chapters[i].get("id", "")) == chapter_id and i + 1 < chapters.size():
			return str(chapters[i + 1].get("id", ""))
	return ""

func claim_last_battle_rewards() -> Dictionary:
	if has_claimed_battle_rewards():
		return last_battle_result.get("rewards", {})
	var rewards := last_battle_result.get("rewards", {})
	PlayerState.add_currency("gold", int(rewards.get("gold", 0)))
	PlayerState.add_currency("bound_spirit_stone", int(rewards.get("qi_essence", 0)))
	PlayerState.add_currency("spirit_stone", int(rewards.get("spirit_stone", 0)))
	var items := rewards.get("items", [])
	for item in items:
		PlayerState.add_inventory_item(str(item.get("id", "")), int(item.get("quantity", 1)), str(item.get("rarity", "rare")))
	if bool(last_battle_result.get("victory", false)):
		var context := last_battle_result.get("context", {})
		if str(context.get("source", "")) == "story":
			mark_story_battle_completed(str(context.get("node_id", "")), str(context.get("chapter_id", "")))
	last_battle_result["claimed"] = true
	return rewards
