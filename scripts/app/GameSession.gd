extends Node

var is_initialized: bool = false
var last_battle_result: Dictionary = {}
var claimed_story_rewards: Dictionary = {}

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
