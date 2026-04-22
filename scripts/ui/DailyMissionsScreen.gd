extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var mission_list: VBoxContainer = %MissionList
@onready var summary_label: Label = %SummaryLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh()

func _format_reset(seconds_until_reset: int) -> String:
	var hours := seconds_until_reset / 3600
	var minutes := (seconds_until_reset % 3600) / 60
	return "%02d:%02d" % [hours, minutes]

func _attendance_reward_text(day_index: int) -> String:
	var gold := 200 + day_index * 50
	var bound := 20 + day_index * 5
	var parts: Array[String] = ["%d зол." % gold, "%d эсс." % bound]
	if day_index == 3:
		parts.append("10 энергии")
	if day_index == 7:
		parts.append("10 нефрита")
	return " · ".join(parts)

func _add_attendance_card() -> void:
	var attendance := PlayerState.get_attendance_progress()
	var can_claim := PlayerState.can_claim_daily_login()
	var streak := int(attendance.get("streak", 0))
	var total_days := int(attendance.get("total_days", 0))

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK if can_claim else UITheme.COLOR_JADE_DARK)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 10)
	card.add_child(root)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_currency_icon("jade")

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var badge := "[LOGIN ГОТОВ]" if can_claim else "[УЖЕ ЗАБРАНО]"
	label.text = "%s Вход дня · серия %d/7 · всего дней %d" % [badge, streak, total_days]

	var claim_button := Button.new()
	claim_button.text = "Получить" if can_claim else "Получено"
	claim_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	UITheme.apply_accent_button(claim_button, true)
	claim_button.disabled = not can_claim
	claim_button.pressed.connect(_claim_attendance)

	header.add_child(icon)
	header.add_child(label)
	header.add_child(claim_button)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	root.add_child(grid)

	var preview_day := streak + 1 if can_claim else streak
	if preview_day <= 0:
		preview_day = 1
	if preview_day > 7:
		preview_day = 7

	for day_index in range(1, 8):
		var day_card := PanelContainer.new()
		day_card.custom_minimum_size = Vector2(0, 86)
		var is_claimed := day_index < preview_day or (day_index == preview_day and not can_claim)
		var is_today := day_index == preview_day and can_claim
		var is_bonus := day_index == 7
		var border := UITheme.COLOR_TEXT_SECONDARY
		if is_claimed:
			border = UITheme.COLOR_SUCCESS
		elif is_today:
			border = UITheme.COLOR_GOLD
		elif is_bonus:
			border = Color(0.74, 0.52, 0.95, 1)
		UITheme.apply_card(day_card, border)

		var day_box := VBoxContainer.new()
		day_box.add_theme_constant_override("separation", 4)
		day_card.add_child(day_box)

		var day_title := Label.new()
		day_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var state_badge := "[TODAY]" if is_today else "[DONE]" if is_claimed else "[DAY]"
		if is_bonus and not is_claimed and not is_today:
			state_badge = "[BONUS]"
		day_title.text = "%s %d" % [state_badge, day_index]

		var day_reward := Label.new()
		day_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		day_reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_reward.text = _attendance_reward_text(day_index)
		day_reward.add_theme_font_size_override("font_size", 12)

		day_box.add_child(day_title)
		day_box.add_child(day_reward)
		grid.add_child(day_card)

	mission_list.add_child(card)

func _add_event_dungeon_card() -> void:
	var state := GameSession.get_event_dungeon_state()
	var remaining := int(state.get("remaining_runs", 0))
	var max_runs := int(state.get("max_runs", 0))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, UITheme.COLOR_WARNING if remaining > 0 else UITheme.COLOR_TEXT_SECONDARY)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	card.add_child(root)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_item_icon("breakthrough_stone")

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var badge := "[EVENT OPEN]" if remaining > 0 else "[LIMIT REACHED]"
	label.text = "%s %s · попытки %d/%d" % [badge, str(state.get("title", "Ивент-подземелье")), remaining, max_runs]

	var enter_button := Button.new()
	enter_button.text = "Войти"
	enter_button.icon = IconLoader.get_skill_icon("azure_slash")
	UITheme.apply_accent_button(enter_button, true)
	enter_button.disabled = remaining <= 0
	enter_button.pressed.connect(_enter_event_dungeon)

	header.add_child(icon)
	header.add_child(label)
	header.add_child(enter_button)

	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.text = "Противник: %s · Цена входа: %d энергии · Награды: золото, нефрит, материалы прорыва." % [str(state.get("enemy_name", "Хранитель")), int(state.get("stamina_cost", 0))]
	root.add_child(info)

	mission_list.add_child(card)

func _refresh() -> void:
	GameSession.refresh_live_ops_state()
	for child in mission_list.get_children():
		child.queue_free()
	var missions := ConfigRepository.daily_missions.get("missions", [])
	var claimed_count := 0
	for mission in missions:
		if GameSession.has_claimed_daily_mission(str(mission.get("id", mission.get("title", "mission")))):
			claimed_count += 1
	var reset_state := GameSession.get_daily_reset_status()
	summary_label.text = "Активных поручений: %d · Забрано: %d · Сброс через %s" % [missions.size(), claimed_count, _format_reset(int(reset_state.get("seconds_until_reset", 0)))]
	_add_attendance_card()
	_add_event_dungeon_card()
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

func _claim_attendance() -> void:
	var result := PlayerState.claim_daily_login()
	summary_label.text = str(result.get("text", "Награда входа"))
	if bool(result.get("claimed", false)):
		OnlineSyncService.queue_action("daily_login_claim", result)
	_refresh()

func _enter_event_dungeon() -> void:
	var state := GameSession.get_event_dungeon_state()
	if int(state.get("remaining_runs", 0)) <= 0:
		summary_label.text = "Попытки ивент-подземелья на сегодня закончились."
		_refresh()
		return
	GameSession.set_battle_context({
		"source": "event_dungeon",
		"chapter_index": 3 + int(state.get("cycle", 0)),
		"event_id": str(state.get("event_id", "event_dungeon_0")),
		"enemy_name": str(state.get("enemy_name", "Хранитель жилы"))
	})
	OnlineSyncService.queue_action("event_dungeon_enter", {"event_id": str(state.get("event_id", "event_dungeon_0"))})
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _claim_reward(mission: Dictionary) -> void:
	var mission_id := str(mission.get("id", mission.get("title", "mission")))
	if GameSession.has_claimed_daily_mission(mission_id):
		summary_label.text = "Награда уже была получена."
		return
	var reward := int(mission.get("reward_gold", 0))
	PlayerState.add_currency("gold", reward)
	GameSession.mark_daily_mission_claimed(mission_id)
	OnlineSyncService.queue_action("daily_claim", {"mission_id": mission_id, "reward_gold": reward})
	summary_label.text = "Получено золота: %d" % reward
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
