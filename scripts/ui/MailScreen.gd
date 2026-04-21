extends Control

@onready var mail_list: VBoxContainer = %MailList
@onready var detail_label: RichTextLabel = %DetailLabel

var mailbox: Dictionary = {}

func _ready() -> void:
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
	for message in mailbox.get("messages", []):
		var msg_id := str(message.get("id", ""))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var claimed := bool(message.get("claimed", false))
		label.text = "%s%s" % [str(message.get("title", "Письмо")), " · получено" if claimed else ""]
		var open_button := Button.new()
		open_button.text = "Открыть"
		open_button.pressed.connect(_open_message.bind(msg_id))
		row.add_child(label)
		row.add_child(open_button)
		mail_list.add_child(row)
	if mailbox.get("messages", []).size() > 0:
		_open_message(str(mailbox.get("messages", [])[0].get("id", "")))

func _open_message(message_id: String) -> void:
	for message in mailbox.get("messages", []):
		if str(message.get("id", "")) != message_id:
			continue
		var rewards := message.get("rewards", {})
		detail_label.text = "[b]%s[/b]\nОт: %s\n\n%s\n\nНаграды: %s золота, %s связанных духовных камней" % [
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
