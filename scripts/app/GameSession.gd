extends Node

var is_initialized: bool = false
var last_battle_result: Dictionary = {}
var claimed_story_rewards: Dictionary = {}
var claimed_daily_missions: Dictionary = {}

func initialize() -> void:
	if is_initialized:
		return
	ConfigRepository.load_all()
	PlayerState.load_or_create_profile()
	IdleRewardService.mark_exit_time()
	is_initialized = true

func has_claimed_story_reward(node_id: String) -> bool:
	return bool(claimed_story_rewards.get(node_id, false))

func mark_story_reward_claimed(node_id: String) -> void:
	claimed_story_rewards[node_id] = true

func has_claimed_daily_mission(mission_id: String) -> bool:
	return bool(claimed_daily_missions.get(mission_id, false))

func mark_daily_mission_claimed(mission_id: String) -> void:
	claimed_daily_missions[mission_id] = true

func has_claimed_battle_rewards() -> bool:
	return bool(last_battle_result.get("claimed", false))

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
	last_battle_result["claimed"] = true
	return rewards
