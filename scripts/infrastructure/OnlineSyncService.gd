extends Node

const OUTBOX_PATH := "user://sync_outbox.json"

var online_mode_enabled: bool = true
var session_id: String = ""
var local_revision: int = 0
var pending_events: Array = []

func _ready() -> void:
	if session_id.is_empty():
		session_id = "sess_%d" % Time.get_unix_time_from_system()
	_load_outbox()

func queue_profile_snapshot(profile: Dictionary, reason: String = "profile_save") -> void:
	if not online_mode_enabled:
		return
	local_revision += 1
	pending_events.append({
		"kind": "profile_snapshot",
		"reason": reason,
		"revision": local_revision,
		"session_id": session_id,
		"payload": profile.duplicate(true),
		"queued_at": Time.get_unix_time_from_system()
	})
	_persist_outbox()

func queue_action(action_type: String, payload: Dictionary = {}) -> void:
	if not online_mode_enabled:
		return
	local_revision += 1
	pending_events.append({
		"kind": "action",
		"action_type": action_type,
		"revision": local_revision,
		"session_id": session_id,
		"payload": payload,
		"queued_at": Time.get_unix_time_from_system()
	})
	_persist_outbox()

func queue_battle_complete(payload: Dictionary) -> void:
	queue_action("battle_complete", payload)

func queue_summon_pull(payload: Dictionary) -> void:
	queue_action("summon_pull", payload)

func queue_breakthrough(payload: Dictionary) -> void:
	queue_action("breakthrough", payload)

func queue_item_use(payload: Dictionary) -> void:
	queue_action("item_use", payload)

func queue_pet_merge(payload: Dictionary) -> void:
	queue_action("pet_merge", payload)

func get_sync_status() -> Dictionary:
	return {
		"online_mode_enabled": online_mode_enabled,
		"session_id": session_id,
		"local_revision": local_revision,
		"pending_count": pending_events.size()
	}

func flush_pending_mock() -> void:
	pending_events.clear()
	_persist_outbox()

func _persist_outbox() -> void:
	var file := FileAccess.open(OUTBOX_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"session_id": session_id,
		"local_revision": local_revision,
		"pending_events": pending_events
	}, "\t"))

func _load_outbox() -> void:
	if not FileAccess.file_exists(OUTBOX_PATH):
		return
	var file := FileAccess.open(OUTBOX_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	session_id = str(parsed.get("session_id", session_id))
	local_revision = int(parsed.get("local_revision", local_revision))
	pending_events = parsed.get("pending_events", [])
