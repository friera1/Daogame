extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var list_container: VBoxContainer = %ItemList
@onready var detail_label: RichTextLabel = %DetailLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh_list()
	PlayerState.inventory_changed.connect(_refresh_list)

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for entry in PlayerState.get_inventory():
		list_container.add_child(_build_item_row(entry))
	if PlayerState.get_inventory().is_empty():
		detail_label.text = "[b]Рюкзак пуст[/b]\n\nПолучи предметы из призыва, магазина или сюжетных наград."

func _build_item_row(entry: Dictionary) -> Control:
	var item_id := str(entry.get("item_id", ""))
	var item_def := ConfigRepository.get_item_def(item_id)
	var item_type := str(item_def.get("type", ""))
	var usable := item_type == "consumable" or (item_type == "material" and item_id == "breakthrough_stone")

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, _rarity_color(str(entry.get("rarity", "common"))))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_item_icon(item_id)
	row.add_child(icon)

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var badge := "[ИСПОЛЬЗ.]" if usable else "[ХРАНИТЬ]"
	name_label.text = "%s %s x%s" % [badge, ConfigRepository.get_item_name(item_id), str(entry.get("quantity", 1))]

	var rarity_label := Label.new()
	var rarity := str(entry.get("rarity", "common"))
	rarity_label.text = rarity.capitalize()
	rarity_label.modulate = _rarity_color(rarity)

	var use_button := Button.new()
	use_button.text = "Исп." if usable else "Осмотр"
	use_button.icon = IconLoader.get_skill_icon("azure_slash") if usable else IconLoader.get_skill_icon("jade_guard")
	UITheme.apply_accent_button(use_button, usable)
	use_button.pressed.connect(_on_item_action.bind(item_id, usable))

	var lock_label := Label.new()
	lock_label.text = "LOCK" if bool(entry.get("locked", false)) else ""
	lock_label.modulate = UITheme.COLOR_GOLD

	row.add_child(name_label)
	row.add_child(rarity_label)
	row.add_child(use_button)
	row.add_child(lock_label)
	return card

func _on_item_action(item_id: String, usable: bool) -> void:
	if usable:
		var result_text := PlayerState.use_inventory_item(item_id)
		detail_label.text = "[b]%s[/b]\n\n%s" % [ConfigRepository.get_item_name(item_id), result_text]
		if not result_text.contains("пока нельзя") and not result_text.contains("отсутствует") and not result_text.contains("закончился"):
			OnlineSyncService.queue_item_use({
				"item_id": item_id,
				"item_name": ConfigRepository.get_item_name(item_id),
				"result": result_text
			})
		return
	var item_def := ConfigRepository.get_item_def(item_id)
	detail_label.text = "[b]%s[/b]\n\nТип: %s\nРедкость: %s\nСтатус: пока используется только в системах прогрессии." % [
		ConfigRepository.get_item_name(item_id),
		str(item_def.get("type", "unknown")),
		str(item_def.get("rarity", "common"))
	]

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"legendary":
			return UITheme.COLOR_GOLD
		"epic":
			return Color(0.74, 0.52, 0.95, 1)
		"rare":
			return Color(0.47, 0.8, 1.0, 1)
		_:
			return UITheme.COLOR_TEXT_SECONDARY

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
