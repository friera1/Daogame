extends Node

var online_mode_enabled: bool = true
var session_id: String = ""
var local_revision: int = 0
var pending_events: Array = []

func _ready() -> void:
	if session_id.is_empty():
		session_id = "sess_%d" % Time.get_unix_time_from_system()

func queue_profile_snapshot(profile: Dictionary, reason: String = "profile_save") -> void:
	if not online_mode_enabled:
		return
	local_revision += 1
	pending_events.append({
		"kind": "profile_snapshot",
		"reason": reason,
		"revision": local_revision,
		"session_id": session_id,
		"payload": profile.duplicate(true)
	})

func queue_action(action_type: String, payload: Dictionary = {}) -> void:
	if not online_mode_enabled:
		return
	local_revision += 1
	pending_events.append({
		"kind": "action",
		"action_type": action_type,
		"revision": local_revision,
		"session_id": session_id,
		"payload": payload
	})

func get_sync_status() -> Dictionary:
	return {
		"online_mode_enabled": online_mode_enabled,
		"session_id": session_id,
		"local_revision": local_revision,
		"pending_count": pending_events.size()
	}

func flush_pending_mock() -> void:
	pending_events.clear()
