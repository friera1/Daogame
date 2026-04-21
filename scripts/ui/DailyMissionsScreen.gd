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
	var claimed_count := 0
	for mission in missions:
		if GameSession.has_claimed_daily_mission(str(mission.get("id", mission.get("title", "mission")))):
			claimed_count += 1
	summary_label.text = "Активных поручений: %d · Забрано: %d" % [missions.size(), claimed_count]
	for mission in missions:
		var mission_id := str(mission.get("id", mission.get("title", "mission")))
		var claimed := GameSession.has_claimed_daily_mission(mission_id)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK if claimed else UITheme.COLOR_JADE_DARK)
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
		var badge := "[ЗАБРАНО]" if claimed else "[ГОТОВО]"
		label.text = "%s %s · цель %d" % [badge, str(mission.get("title", "Миссия")), int(mission.get("target", 1))]
		var claim_button := Button.new()
		claim_button.text = "Забрано" if claimed else "Забрать"
		claim_button.icon = IconLoader.get_currency_icon("jade")
		UITheme.apply_accent_button(claim_button, true)
		claim_button.disabled = claimed
		claim_button.pressed.connect(_claim_reward.bind(mission))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(claim_button)
		mission_list.add_child(card)

func _claim_reward(mission: Dictionary) -> void:
	var mission_id := str(mission.get("id", mission.get("title", "mission")))
	if GameSession.has_claimed_daily_mission(mission_id):
		summary_label.text = "Награда уже была получена."
		return
	var reward := int(mission.get("reward_gold", 0))
	PlayerState.add_currency("gold", reward)
	GameSession.mark_daily_mission_claimed(mission_id)
	summary_label.text = "Получено золота: %d" % reward
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
