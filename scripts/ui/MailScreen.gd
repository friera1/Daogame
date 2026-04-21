extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var mail_list: VBoxContainer = %MailList
@onready var detail_label: RichTextLabel = %DetailLabel

var mailbox: Dictionary = {}

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_load_mailbox()
	_refresh()

func _load_mailbox() -> void:
	var file := FileAccess.open("res://data/mock/mailbox.json", FileAccess.READ)
	if file == null:
		mailbox = {"messages": []}
		return
	mailbox = JSON.parse_string(file.get_as_text())
	if typeof(mailbox) != TYPE_DICTIONARY:
		mailbox = {"messages": []}

func _refresh() -> void:
	for child in mail_list.get_children():
		child.queue_free()
	var claimed_count := 0
	for message in mailbox.get("messages", []):
		if bool(message.get("claimed", false)):
			claimed_count += 1
	for message in mailbox.get("messages", []):
		var msg_id := str(message.get("id", ""))
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var claimed := bool(message.get("claimed", false))
		var badge := "[ПОЛУЧЕНО]" if claimed else "[НОВОЕ]"
		UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK if claimed else UITheme.COLOR_JADE_DARK)
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
		label.text = "%s %s" % [badge, str(message.get("title", "Письмо"))]
		var open_button := Button.new()
		open_button.text = "Открыть"
		open_button.icon = IconLoader.get_skill_icon("jade_guard")
		UITheme.apply_accent_button(open_button, claimed)
		open_button.pressed.connect(_open_message.bind(msg_id))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(open_button)
		mail_list.add_child(card)
	if mailbox.get("messages", []).size() > 0:
		detail_label.text = "Писем: %d · Получено: %d" % [mailbox.get("messages", []).size(), claimed_count]
		_open_message(str(mailbox.get("messages", [])[0].get("id", "")))

func _open_message(message_id: String) -> void:
	for message in mailbox.get("messages", []):
		if str(message.get("id", "")) != message_id:
			continue
		var rewards := message.get("rewards", {})
		var badge := "[ПОЛУЧЕНО]" if bool(message.get("claimed", false)) else "[НОВОЕ]"
		detail_label.text = "%s [b]%s[/b]\nОт: %s\n\n%s\n\nНаграды: %s золота, %s связанных духовных камней" % [
			badge,
			str(message.get("title", "Письмо")),
			str(message.get("from", "Система")),
			str(message.get("body", "")),
			str(rewards.get("gold", 0)),
			str(rewards.get("bound_spirit_stone", 0))
		]
		return

func _claim_all_pressed() -> void:
	var changed := false
	for message in mailbox.get("messages", []):
		if bool(message.get("claimed", false)):
			continue
		var rewards := message.get("rewards", {})
		PlayerState.add_currency("gold", int(rewards.get("gold", 0)))
		PlayerState.add_currency("bound_spirit_stone", int(rewards.get("bound_spirit_stone", 0)))
		message["claimed"] = true
		changed = true
	if changed:
		detail_label.text = "[b]Письма обработаны[/b]\n\nВсе доступные награды получены."
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
