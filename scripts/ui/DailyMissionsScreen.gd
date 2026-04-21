extends Control

@onready var mission_list: VBoxContainer = %MissionList
@onready var summary_label: Label = %SummaryLabel

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	for child in mission_list.get_children():
		child.queue_free()
	var missions := ConfigRepository.daily_missions.get("missions", [])
	summary_label.text = "Активных поручений: %d" % missions.size()
	for mission in missions:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s · цель %d" % [str(mission.get("title", "Миссия")), int(mission.get("target", 1))]
		var claim_button := Button.new()
		claim_button.text = "Забрать"
		claim_button.pressed.connect(_claim_reward.bind(mission))
		row.add_child(label)
		row.add_child(claim_button)
		mission_list.add_child(row)

func _claim_reward(mission: Dictionary) -> void:
	var reward := int(mission.get("reward_gold", 0))
	PlayerState.add_currency("gold", reward)
	summary_label.text = "Получено золота: %d" % reward

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
