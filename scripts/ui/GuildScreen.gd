extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var title_label: Label = %TitleLabel
@onready var summary_label: RichTextLabel = %SummaryLabel
@onready var member_list: VBoxContainer = %MemberList

var guild_data: Dictionary = {}

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_load_guild_data()
	_refresh()

func _load_guild_data() -> void:
	var file := FileAccess.open("res://data/mock/guild_profile.json", FileAccess.READ)
	if file == null:
		guild_data = {"guild": {}}
		return
	guild_data = JSON.parse_string(file.get_as_text())
	if typeof(guild_data) != TYPE_DICTIONARY:
		guild_data = {"guild": {}}

func _add_boss_card() -> void:
	var boss := GameSession.get_guild_boss_state()
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, UITheme.COLOR_WARNING if int(boss.get("remaining_runs", 0)) > 0 else UITheme.COLOR_TEXT_SECONDARY)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_item_icon("breakthrough_stone")
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "[БОСС ОРДЕНА] %s · прогресс %d%% · попытки %d/%d" % [str(boss.get("name", "Дракон")), int(boss.get("progress", 0)), int(boss.get("remaining_runs", 0)), int(boss.get("max_runs", 0))]
	var fight_button := Button.new()
	fight_button.text = "В бой"
	fight_button.icon = IconLoader.get_skill_icon("azure_slash")
	UITheme.apply_accent_button(fight_button, true)
	fight_button.disabled = int(boss.get("remaining_runs", 0)) <= 0
	fight_button.pressed.connect(_enter_boss)
	row.add_child(icon)
	row.add_child(label)
	row.add_child(fight_button)
	member_list.add_child(card)

func _add_contribution_ranking() -> void:
	var guild := guild_data.get("guild", {})
	var boss := GameSession.get_guild_boss_state()
	var ranking: Array = []
	for member in guild.get("member_list", []):
		var member_power := int(member.get("power", 0))
		var contribution := int(floor(float(member_power) / 5000.0)) + int(boss.get("progress", 0))
		ranking.append({
			"name": str(member.get("name", "Ученик")),
			"role": str(member.get("role", "Участник")),
			"contribution": contribution
		})
	ranking.sort_custom(func(a, b): return int(a.get("contribution", 0)) > int(b.get("contribution", 0)))
	var limit := min(3, ranking.size())
	for i in range(limit):
		var entry := ranking[i]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_GOLD if i == 0 else UITheme.COLOR_GOLD_DARK)
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
		label.text = "[TOP %d] %s · %s · вклад %d" % [i + 1, str(entry.get("name", "Ученик")), str(entry.get("role", "Участник")), int(entry.get("contribution", 0))]
		row.add_child(icon)
		row.add_child(label)
		member_list.add_child(card)

func _refresh() -> void:
	for child in member_list.get_children():
		child.queue_free()
	GameSession.refresh_live_ops_state()
	var guild := guild_data.get("guild", {})
	var boss_progress := int(guild.get("boss_progress", 0))
	var member_count := int(guild.get("members", 0))
	var max_members := int(guild.get("max_members", 1))
	var live_boss := GameSession.get_guild_boss_state()
	title_label.text = str(guild.get("name", "Орден"))
	title_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	title_label.add_theme_font_size_override("font_size", 28)
	summary_label.text = "[b]Глава[/b]: %s\n[b]Уровень[/b]: %s\n[b]Сила ордена[/b]: %s\n[b]Состав[/b]: %s / %s [%s]\n[b]Пожертвования сегодня[/b]: %s\n[b]Прогресс босса ордена[/b]: %s%% [%s]\n[b]Weekly PvE[/b]: %s · попытки %d/%d · цена %d энергии\n[b]Рейтинг вклада[/b]: очки растут от силы участников и прогресса босса\n\n[i]%s[/i]" % [str(guild.get("leader", "-")), str(guild.get("level", 1)), str(guild.get("power", 0)), str(member_count), str(max_members), "ПОЛОН" if member_count >= max_members else "НАБОР", str(guild.get("daily_donations", 0)), str(max(boss_progress, int(live_boss.get("progress", 0)))), "ГОТОВ" if int(live_boss.get("remaining_runs", 0)) > 0 else "ЛИМИТ", str(live_boss.get("name", "Дракон")), int(live_boss.get("remaining_runs", 0)), int(live_boss.get("max_runs", 0)), int(live_boss.get("stamina_cost", 0)), str(guild.get("announcement", ""))]
	_add_boss_card()
	_add_contribution_ranking()
	for member in guild.get("member_list", []):
		var power := int(member.get("power", 0))
		var badge := "[ЭЛИТА]" if power >= 250000 else "[АКТИВ]"
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
		icon.texture = IconLoader.get_icon("story_marker")
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s %s · %s · %s" % [badge, str(member.get("name", "Ученик")), str(member.get("role", "Участник")), str(power)]
		var gift_button := Button.new()
		gift_button.text = "Поддержать"
		gift_button.icon = IconLoader.get_currency_icon("jade")
		UITheme.apply_accent_button(gift_button, true)
		gift_button.pressed.connect(_donate.bind(str(member.get("name", "Ученик"))))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(gift_button)
		member_list.add_child(card)

func _enter_boss() -> void:
	var boss := GameSession.get_guild_boss_state()
	if int(boss.get("remaining_runs", 0)) <= 0:
		summary_label.text = "[b]Попытки босса ордена закончились[/b]"
		return
	GameSession.set_battle_context({"source": "guild_boss", "chapter_index": 5 + int(boss.get("cycle", 0)), "enemy_name": str(boss.get("name", "Дракон небесной меди")), "boss_id": str(boss.get("boss_id", "guild_boss_0"))})
	OnlineSyncService.queue_action("guild_boss_enter", {"boss_id": str(boss.get("boss_id", "guild_boss_0"))})
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _donate(member_name: String) -> void:
	if not PlayerState.spend_currency("gold", 500):
		summary_label.text = "[b]Недостаточно золота для пожертвования[/b]"
		return
	summary_label.text = "[b]Пожертвование отправлено[/b]\n\nПоддержка участника %s укрепила единство ордена." % member_name

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
