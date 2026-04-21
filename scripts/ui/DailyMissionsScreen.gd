extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var mission_list: VBoxContainer = %MissionList
@onready var summary_label: Label = %SummaryLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh()

func _refresh() -> void:
	for child in mission_list.get_children():
		child.queue_free()
	var missions := ConfigRepository.daily_missions.get("missions", [])
	summary_label.text = "Активных поручений: %d" % missions.size()
	for mission in missions:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_JADE_DARK)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = IconLoader.get_currency_icon("bound_spirit_stone")
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s · цель %d" % [str(mission.get("title", "Миссия")), int(mission.get("target", 1))]
		var claim_button := Button.new()
		claim_button.text = "Забрать"
		claim_button.icon = IconLoader.get_currency_icon("jade")
		UITheme.apply_accent_button(claim_button, true)
		claim_button.pressed.connect(_claim_reward.bind(mission))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(claim_button)
		mission_list.add_child(card)

func _claim_reward(mission: Dictionary) -> void:
	var reward := int(mission.get("reward_gold", 0))
	PlayerState.add_currency("gold", reward)
	summary_label.text = "Получено золота: %d" % reward

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
