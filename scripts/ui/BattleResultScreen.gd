extends Control

@onready var title_label: Label = %TitleLabel
@onready var rewards_label: RichTextLabel = %RewardsLabel

func _ready() -> void:
	var result := GameSession.last_battle_result
	var victory := bool(result.get("victory", false))
	title_label.text = "Победа" if victory else "Поражение"
	var rewards := result.get("rewards", {})
	rewards_label.text = "[b]Награды[/b]\n\n" + \
		"Золото: %s\n" % str(rewards.get("gold", 0)) + \
		"Эссенция Ци: %s\n" % str(rewards.get("qi_essence", 0)) + \
		"Духовные камни: %s" % str(rewards.get("spirit_stone", 0))

func _on_continue_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")

func _on_retry_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _on_upgrade_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/cultivation/CultivationScreen.tscn")
