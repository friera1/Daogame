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

func _add_social_support_card() -> void:
	var social := GameSession.get_friends_state()
	var friends: Array = social.get("friends", [])
	var selected := str(social.get("selected_support", ""))
	for friend in friends:
		var friend_id := str(friend.get("id", ""))
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_GOLD if friend_id == selected else UITheme.COLOR_JADE_DARK)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = IconLoader.get_skill_icon("jade_guard")
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "[FRIEND] %s · %s · сила %d · support %s" % [str(friend.get("name", "Союзник")), "ONLINE" if bool(friend.get("online", false)) else "OFFLINE", int(friend.get("power", 0)), str(friend.get("support_unit", ""))]
		var button := Button.new()
		button.text = "Выбран" if friend_id == selected else "Выбрать"
		button.icon = IconLoader.get_currency_icon("jade")
		UITheme.apply_accent_button(button, true)
		button.disabled = friend_id == selected
		button.pressed.connect(_select_support.bind(friend_id))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(button)
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
	for bundle in GameSession.get_event_shop_bundles():
		var bundle_card := PanelContainer.new()
		bundle_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(bundle_card, UITheme.COLOR_GOLD_DARK if not bool(bundle.get("claimed", false)) else UITheme.COLOR_TEXT_SECONDARY)
		var bundle_row := HBoxContainer.new()
		bundle_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bundle_row.add_theme_constant_override("separation", 12)
		bundle_card.add_child(bundle_row)
		var bundle_icon := TextureRect.new()
		bundle_icon.custom_minimum_size = Vector2(44, 44)
		bundle_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bundle_icon.texture = IconLoader.get_currency_icon("jade")
		var reward := bundle.get("reward", {})
		var bundle_label := Label.new()
		bundle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bundle_label.text = "[EVENT BUNDLE] %s · цена %d нефрита · %d зол. / %d эсс." % [str(bundle.get("title", "Пак")), int(bundle.get("price_jade", 0)), int(reward.get("gold", 0)), int(reward.get("bound_spirit_stone", 0))]
		var bundle_button := Button.new()
		bundle_button.text = "Куплено" if bool(bundle.get("claimed", false)) else "Купить"
		bundle_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
		UITheme.apply_accent_button(bundle_button, true)
		bundle_button.disabled = bool(bundle.get("claimed", false))
		bundle_button.pressed.connect(_buy_event_bundle.bind(str(bundle.get("id", ""))))
		bundle_row.add_child(bundle_icon)
		bundle_row.add_child(bundle_label)
		bundle_row.add_child(bundle_button)
		mission_list.add_child(bundle_card)

func _add_arena_card() -> void:
	var state := GameSession.get_arena_state()
	var opponents: Array = state.get("opponents", [])
	var top := opponents[0] if not opponents.is_empty() else {}
	var reward := GameSession.get_arena_rank_reward_preview()
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_skill_icon("jade_guard")
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "[ARENA] %s · рейтинг %d · попытки %d/%d · refresh %d · support +%d" % [str(state.get("league", "Бронза")), int(state.get("season_rating", 1200)), int(state.get("remaining_runs", 0)), int(state.get("max_runs", 0)), int(state.get("refresh_remaining", 0)), int(state.get("support_bonus", 0))]
	var fight_button := Button.new()
	fight_button.text = "Дуэль"
	fight_button.icon = IconLoader.get_skill_icon("azure_slash")
	UITheme.apply_accent_button(fight_button, true)
	fight_button.disabled = int(state.get("remaining_runs", 0)) <= 0
	fight_button.pressed.connect(_enter_arena)
	var refresh_button := Button.new()
	refresh_button.text = "Refresh"
	refresh_button.icon = IconLoader.get_currency_icon("jade")
	UITheme.apply_accent_button(refresh_button, false)
	refresh_button.disabled = int(state.get("refresh_remaining", 0)) <= 0
	refresh_button.pressed.connect(_refresh_arena_opponents)
	row.add_child(icon)
	row.add_child(label)
	row.add_child(refresh_button)
	row.add_child(fight_button)
	mission_list.add_child(card)
	var reward_card := PanelContainer.new()
	reward_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(reward_card, UITheme.COLOR_GOLD)
	var reward_row := HBoxContainer.new()
	reward_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.add_theme_constant_override("separation", 12)
	reward_card.add_child(reward_row)
	var reward_icon := TextureRect.new()
	reward_icon.custom_minimum_size = Vector2(44, 44)
	reward_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_icon.texture = IconLoader.get_currency_icon("jade")
	var reward_label := Label.new()
	reward_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_label.text = "[ARENA REWARD] %s · %d зол. · %d нефрита · лучший соперник %s" % [str(reward.get("tier", "bronze")), int(reward.get("gold", 0)), int(reward.get("jade", 0)), str(top.get("name", "-"))]
	var reward_button := Button.new()
	reward_button.text = "Забрать"
	reward_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	UITheme.apply_accent_button(reward_button, true)
	reward_button.pressed.connect(_claim_arena_rank_reward)
	reward_row.add_child(reward_icon)
	reward_row.add_child(reward_label)
	reward_row.add_child(reward_button)
	mission_list.add_child(reward_card)

func _add_season_pass_card() -> void:
	var state := GameSession.get_season_pass_state()
	var level := int(state.get("level", 1))
	var preview := GameSession.get_season_pass_reward_preview(level)
	var claimed := bool(state.get("claimed", {}).get(str(level), false))
	var premium_active := bool(state.get("premium_active", false))
	var premium_preview := GameSession.get_season_pass_premium_reward_preview(level)
	var premium_claimed := bool(state.get("premium_claimed", {}).get(str(level), false))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, UITheme.COLOR_GOLD if not claimed else UITheme.COLOR_TEXT_SECONDARY)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_currency_icon("jade")
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "[SEASON PASS] ур. %d/%d · XP %d/%d · free: %d зол., %d нефрита" % [level, int(state.get("max_level", 30)), int(state.get("xp_in_level", 0)), int(state.get("xp_needed", 100)), int(preview.get("gold", 0)), int(preview.get("jade", 0))]
	var claim_button := Button.new()
	claim_button.text = "Забрать" if not claimed else "Получено"
	claim_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	UITheme.apply_accent_button(claim_button, true)
	claim_button.disabled = claimed
	claim_button.pressed.connect(_claim_season_pass.bind(level))
	row.add_child(icon)
	row.add_child(label)
	row.add_child(claim_button)
	mission_list.add_child(card)
	var premium_card := PanelContainer.new()
	premium_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(premium_card, UITheme.COLOR_GOLD_DARK if premium_active else UITheme.COLOR_WARNING)
	var premium_row := HBoxContainer.new()
	premium_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	premium_row.add_theme_constant_override("separation", 12)
	premium_card.add_child(premium_row)
	var premium_icon := TextureRect.new()
	premium_icon.custom_minimum_size = Vector2(44, 44)
	premium_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	premium_icon.texture = IconLoader.get_currency_icon("jade")
	var premium_label := Label.new()
	premium_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	premium_label.text = "[PREMIUM LANE] %s · reward: %d зол. / %d нефрита" % ["АКТИВНА" if premium_active else "ЗАКРЫТА · 120 нефрита", int(premium_preview.get("gold", 0)), int(premium_preview.get("jade", 0))]
	var premium_button := Button.new()
	premium_button.text = "Премиум награда" if premium_active else "Открыть"
	premium_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	UITheme.apply_accent_button(premium_button, true)
	premium_button.disabled = premium_active and premium_claimed
	premium_button.pressed.connect(_premium_pass_action.bind(level, premium_active))
	premium_row.add_child(premium_icon)
	premium_row.add_child(premium_label)
	premium_row.add_child(premium_button)
	mission_list.add_child(premium_card)
	for mission in GameSession.get_season_pass_missions():
		var mission_card := PanelContainer.new()
		mission_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var done := int(mission.get("progress", 0)) >= int(mission.get("target", 1))
		var mission_claimed := bool(mission.get("claimed", false))
		UITheme.apply_card(mission_card, UITheme.COLOR_SUCCESS if mission_claimed else UITheme.COLOR_GOLD_DARK if done else UITheme.COLOR_TEXT_SECONDARY)
		var mission_row := HBoxContainer.new()
		mission_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mission_row.add_theme_constant_override("separation", 12)
		mission_card.add_child(mission_row)
		var mission_icon := TextureRect.new()
		mission_icon.custom_minimum_size = Vector2(44, 44)
		mission_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mission_icon.texture = IconLoader.get_currency_icon("bound_spirit_stone")
		var mission_label := Label.new()
		mission_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mission_label.text = "[PASS MISSION] %s · %d/%d · XP %d" % [str(mission.get("title", "Миссия")), int(mission.get("progress", 0)), int(mission.get("target", 1)), int(mission.get("xp", 0))]
		var mission_button := Button.new()
		mission_button.text = "Получено" if mission_claimed else "Зачесть"
		mission_button.icon = IconLoader.get_currency_icon("jade")
		UITheme.apply_accent_button(mission_button, true)
		mission_button.disabled = mission_claimed or not done
		mission_button.pressed.connect(_claim_season_mission.bind(str(mission.get("id", "pass_event"))))
		mission_row.add_child(mission_icon)
		mission_row.add_child(mission_label)
		mission_row.add_child(mission_button)
		mission_list.add_child(mission_card)

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
	_add_social_support_card()
	_add_event_dungeon_card()
	_add_arena_card()
	_add_season_pass_card()
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
		GameSession.award_season_pass_xp(12, "daily_login")
		OnlineSyncService.queue_action("daily_login_claim", result)
	_refresh()

func _select_support(friend_id: String) -> void:
	var result := GameSession.select_support_unit(friend_id)
	summary_label.text = str(result.get("text", "Support unit обновлён"))
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("support_unit_select", result)
	_refresh()

func _enter_event_dungeon() -> void:
	var state := GameSession.get_event_dungeon_state()
	if int(state.get("remaining_runs", 0)) <= 0:
		summary_label.text = "Попытки ивент-подземелья на сегодня закончились."
		_refresh()
		return
	GameSession.set_battle_context({"source": "event_dungeon", "chapter_index": 3 + int(state.get("cycle", 0)), "event_id": str(state.get("event_id", "event_dungeon_0")), "enemy_name": str(state.get("enemy_name", "Хранитель жилы")), "support_bonus": int(GameSession.get_selected_support_bonus().get("power_bonus", 0))})
	OnlineSyncService.queue_action("event_dungeon_enter", {"event_id": str(state.get("event_id", "event_dungeon_0"))})
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _buy_event_bundle(bundle_id: String) -> void:
	var result := GameSession.buy_event_bundle(bundle_id)
	summary_label.text = str(result.get("text", "Пак недоступен"))
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("event_bundle_buy", result)
	_refresh()

func _enter_arena() -> void:
	var state := GameSession.get_arena_state()
	if int(state.get("remaining_runs", 0)) <= 0:
		summary_label.text = "Попытки арены на сегодня закончились."
		return
	var opponents: Array = state.get("opponents", [])
	if opponents.is_empty():
		summary_label.text = "Соперники арены недоступны."
		return
	var opponent := opponents[0]
	GameSession.set_battle_context({"source": "arena", "chapter_index": 4, "opponent_index": 0, "enemy_name": str(opponent.get("name", "Соперник арены")), "support_bonus": int(GameSession.get_selected_support_bonus().get("power_bonus", 0))})
	OnlineSyncService.queue_action("arena_enter", {"opponent": opponent})
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _refresh_arena_opponents() -> void:
	var result := GameSession.refresh_arena_opponents()
	summary_label.text = str(result.get("text", "Арена обновлена"))
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("arena_refresh", result)
	_refresh()

func _claim_arena_rank_reward() -> void:
	var result := GameSession.claim_arena_rank_reward()
	summary_label.text = str(result.get("text", "Season reward арены недоступен"))
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("arena_rank_claim", result)
	_refresh()

func _claim_season_pass(level: int) -> void:
	var result := GameSession.claim_season_pass_reward(level)
	if not bool(result.get("ok", false)):
		summary_label.text = str(result.get("text", "Награда season pass недоступна"))
		return
	OnlineSyncService.queue_action("season_pass_claim", {"level": level, "reward": result.get("reward", {})})
	summary_label.text = str(result.get("text", "Награда season pass получена"))
	_refresh()

func _premium_pass_action(level: int, premium_active: bool) -> void:
	var result := GameSession.claim_season_pass_premium_reward(level) if premium_active else GameSession.activate_premium_pass()
	summary_label.text = str(result.get("text", "Premium lane недоступна"))
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("premium_pass_action", result)
	_refresh()

func _claim_season_mission(mission_id: String) -> void:
	var result := GameSession.claim_season_pass_mission(mission_id)
	summary_label.text = str(result.get("text", "Season mission недоступна"))
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("season_mission_claim", result)
	_refresh()

func _claim_reward(mission: Dictionary) -> void:
	var mission_id := str(mission.get("id", mission.get("title", "mission")))
	if GameSession.has_claimed_daily_mission(mission_id):
		summary_label.text = "Награда уже была получена."
		return
	var reward := int(mission.get("reward_gold", 0))
	PlayerState.add_currency("gold", reward)
	GameSession.mark_daily_mission_claimed(mission_id)
	GameSession.award_season_pass_xp(10, "daily_mission")
	OnlineSyncService.queue_action("daily_claim", {"mission_id": mission_id, "reward_gold": reward})
	summary_label.text = "Получено золота: %d" % reward
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
