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

func _refresh() -> void:
	for child in member_list.get_children():
		child.queue_free()
	var guild := guild_data.get("guild", {})
	var boss_progress := int(guild.get("boss_progress", 0))
	var member_count := int(guild.get("members", 0))
	var max_members := int(guild.get("max_members", 1))
	title_label.text = str(guild.get("name", "Орден"))
	title_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	title_label.add_theme_font_size_override("font_size", 28)
	summary_label.text = "[b]Глава[/b]: %s\n[b]Уровень[/b]: %s\n[b]Сила ордена[/b]: %s\n[b]Состав[/b]: %s / %s [%s]\n[b]Пожертвования сегодня[/b]: %s\n[b]Прогресс босса ордена[/b]: %s%% [%s]\n\n[i]%s[/i]" % [
		str(guild.get("leader", "-")),
		str(guild.get("level", 1)),
		str(guild.get("power", 0)),
		str(member_count),
		str(max_members),
		"ПОЛОН" if member_count >= max_members else "НАБОР",
		str(guild.get("daily_donations", 0)),
		str(boss_progress),
		"ГОТОВ" if boss_progress >= 100 else "ПРОГРЕСС",
		str(guild.get("announcement", ""))
	]
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

func _donate(member_name: String) -> void:
	if not PlayerState.spend_currency("gold", 500):
		summary_label.text = "[b]Недостаточно золота для пожертвования[/b]"
		return
	summary_label.text = "[b]Пожертвование отправлено[/b]\n\nПоддержка участника %s укрепила единство ордена." % member_name

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
