extends Control

@onready var title_label: Label = %TitleLabel
@onready var summary_label: RichTextLabel = %SummaryLabel
@onready var member_list: VBoxContainer = %MemberList

var guild_data: Dictionary = {}

func _ready() -> void:
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
	title_label.text = str(guild.get("name", "Орден"))
	summary_label.text = "[b]Глава[/b]: %s\n[b]Уровень[/b]: %s\n[b]Сила ордена[/b]: %s\n[b]Состав[/b]: %s / %s\n[b]Пожертвования сегодня[/b]: %s\n[b]Прогресс босса ордена[/b]: %s%%\n\n[i]%s[/i]" % [
		str(guild.get("leader", "-")),
		str(guild.get("level", 1)),
		str(guild.get("power", 0)),
		str(guild.get("members", 0)),
		str(guild.get("max_members", 0)),
		str(guild.get("daily_donations", 0)),
		str(guild.get("boss_progress", 0)),
		str(guild.get("announcement", ""))
	]
	for member in guild.get("member_list", []):
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s · %s · %s" % [str(member.get("name", "Ученик")), str(member.get("role", "Участник")), str(member.get("power", 0))]
		var gift_button := Button.new()
		gift_button.text = "Поддержать"
		gift_button.pressed.connect(_donate.bind(str(member.get("name", "Ученик"))))
		row.add_child(label)
		row.add_child(gift_button)
		member_list.add_child(row)

func _donate(member_name: String) -> void:
	if not PlayerState.spend_currency("gold", 500):
		summary_label.text = "[b]Недостаточно золота для пожертвования[/b]"
		return
		summary_label.text = "[b]Пожертвование отправлено[/b]"
	summary_label.text = "[b]Пожертвование отправлено[/b]\n\nПоддержка участника %s укрепила единство ордена." % member_name

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
