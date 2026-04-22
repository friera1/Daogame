extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var mail_list: VBoxContainer = %MailList
@onready var detail_label: RichTextLabel = %DetailLabel

var mailbox: Dictionary = {}

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_load_mailbox()
	_refresh()
	PlayerState.mailbox_changed.connect(_refresh)

func _load_mailbox() -> void:
	var file := FileAccess.open("res://data/mock/mailbox.json", FileAccess.READ)
	if file == null:
		mailbox = {"messages": []}
		return
	mailbox = JSON.parse_string(file.get_as_text())
	if typeof(mailbox) != TYPE_DICTIONARY:
		mailbox = {"messages": []}

func _is_claimed(message: Dictionary) -> bool:
	var message_id := str(message.get("id", ""))
	return bool(message.get("claimed", false)) or PlayerState.has_claimed_mail(message_id)

func _reward_summary(rewards: Dictionary) -> String:
	var parts: Array[String] = []
	if int(rewards.get("gold", 0)) > 0:
		parts.append("%s золота" % str(rewards.get("gold", 0)))
	if int(rewards.get("bound_spirit_stone", 0)) > 0:
		parts.append("%s связанных духовных камней" % str(rewards.get("bound_spirit_stone", 0)))
	if int(rewards.get("jade", 0)) > 0:
		parts.append("%s нефрита" % str(rewards.get("jade", 0)))
	if int(rewards.get("stamina", 0)) > 0:
		parts.append("%s энергии" % str(rewards.get("stamina", 0)))
	for item in rewards.get("items", []):
		parts.append("%s x%s" % [ConfigRepository.get_item_name(str(item.get("id", ""))), str(item.get("quantity", 1))])
	return "нет" if parts.is_empty() else ", ".join(parts)

func _apply_rewards(rewards: Dictionary) -> void:
	PlayerState.add_currency("gold", int(rewards.get("gold", 0)))
	PlayerState.add_currency("bound_spirit_stone", int(rewards.get("bound_spirit_stone", 0)))
	PlayerState.add_currency("jade", int(rewards.get("jade", 0)))
	if int(rewards.get("stamina", 0)) > 0:
		PlayerState.add_stamina(int(rewards.get("stamina", 0)))
	for item in rewards.get("items", []):
		PlayerState.add_inventory_item(str(item.get("id", "")), int(item.get("quantity", 1)), str(item.get("rarity", "rare")))

func _refresh() -> void:
	for child in mail_list.get_children():
		child.queue_free()
	var claimed_count := 0
	for message in mailbox.get("messages", []):
		if _is_claimed(message):
			claimed_count += 1
	for message in mailbox.get("messages", []):
		var msg_id := str(message.get("id", ""))
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var claimed := _is_claimed(message)
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
		var claimed := _is_claimed(message)
		var badge := "[ПОЛУЧЕНО]" if claimed else "[НОВОЕ]"
		detail_label.text = "%s [b]%s[/b]\nОт: %s\n\n%s\n\nНаграды: %s" % [
			badge,
			str(message.get("title", "Письмо")),
			str(message.get("from", "Система")),
			str(message.get("body", "")),
			_reward_summary(rewards)
		]
		return

func _claim_message(message: Dictionary) -> bool:
	var message_id := str(message.get("id", ""))
	if _is_claimed(message):
		return false
	var rewards := message.get("rewards", {})
	_apply_rewards(rewards)
	PlayerState.mark_mail_claimed(message_id)
	OnlineSyncService.queue_action("mail_claim", {"message_id": message_id, "rewards": rewards})
	return true

func _claim_all_pressed() -> void:
	var changed := false
	for message in mailbox.get("messages", []):
		if _claim_message(message):
			changed = true
	if changed:
		detail_label.text = "[b]Письма обработаны[/b]\n\nВсе доступные награды получены."
	else:
		detail_label.text = "[b]Новых наград нет[/b]"
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
