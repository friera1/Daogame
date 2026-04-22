extends Control

@onready var title_label: Label = %TitleLabel
@onready var rewards_label: RichTextLabel = %RewardsLabel

func _ready() -> void:
	var result := GameSession.last_battle_result
	var victory := bool(result.get("victory", false))
	title_label.text = "Победа" if victory else "Поражение"
	_refresh_rewards_text()

func _refresh_rewards_text() -> void:
	var rewards := GameSession.last_battle_result.get("rewards", {})
	var items := rewards.get("items", [])
	var item_lines: Array[String] = []
	for item in items:
		item_lines.append("• %s x%s" % [ConfigRepository.get_item_name(str(item.get("id", ""))), str(item.get("quantity", 1))])
	var claim_badge := "[ПОЛУЧЕНО]" if GameSession.has_claimed_battle_rewards() else "[ГОТОВО К ПОЛУЧЕНИЮ]"
	var items_text := "Предметы: нет"
	if item_lines.size() > 0:
		items_text = "Предметы:\n%s" % "\n".join(item_lines)
	rewards_label.text = "%s\n\n[b]Награды[/b]\n\nЗолото: %s\nЭссенция Ци: %s\nДуховные камни: %s\nНефрит: %s\n%s" % [
		claim_badge,
		str(rewards.get("gold", 0)),
		str(rewards.get("qi_essence", 0)),
		str(rewards.get("spirit_stone", 0)),
		str(rewards.get("jade", 0)),
		items_text
	]

func _claim_if_needed() -> void:
	if GameSession.has_claimed_battle_rewards():
		return
	var result := GameSession.last_battle_result
	var rewards := GameSession.claim_last_battle_rewards()
	OnlineSyncService.queue_battle_complete({
		"victory": bool(result.get("victory", false)),
		"context": result.get("context", {}),
		"rewards": rewards
	})
	GameSession.clear_battle_context()
	_refresh_rewards_text()

func _on_continue_pressed() -> void:
	_claim_if_needed()
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")

func _on_retry_pressed() -> void:
	_claim_if_needed()
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _on_upgrade_pressed() -> void:
	_claim_if_needed()
	SceneRouter.goto_scene("res://scenes/cultivation/CultivationScreen.tscn")
