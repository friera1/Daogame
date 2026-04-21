extends Node

var is_initialized: bool = false
var last_battle_result: Dictionary = {}

func initialize() -> void:
	if is_initialized:
		return
	ConfigRepository.load_all()
	PlayerState.load_or_create_profile()
	IdleRewardService.mark_exit_time()
	is_initialized = true
