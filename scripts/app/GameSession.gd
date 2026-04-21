extends Node

var is_initialized: bool = false
var last_battle_result: Dictionary = {}

func initialize() -> void:
	if is_initialized:
		return
	ConfigRepository.load_all()
	PlayerState.load_mock_profile()
	is_initialized = true
