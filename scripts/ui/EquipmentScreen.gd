extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var equipment_list: VBoxContainer = %EquipmentList
@onready var detail_label: RichTextLabel = %DetailLabel

var selected_slot_id := "weapon"

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh()
	PlayerState.equipment_changed.connect(_refresh)

func _refresh() -> void:
	for child in equipment_list.get_children():
		child.queue_free()
	var equipment := PlayerState.get_equipment()
	for slot_id in ["weapon", "armor", "boots", "ring"]:
		var item_id := str(equipment.get(slot_id, "none"))
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK if item_id != "none" else UITheme.COLOR_JADE_DARK)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(44, 44)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = IconLoader.get_item_icon(item_id)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s: %s" % [_slot_name(slot_id), _item_name(item_id)]
		var choose_button := Button.new()
		choose_button.text = "Выбрать"
		choose_button.icon = IconLoader.get_skill_icon("jade_guard")
		UITheme.apply_accent_button(choose_button, false)
		choose_button.pressed.connect(_show_candidates.bind(slot_id))
		var equip_button := Button.new()
		equip_button.text = "Надеть"
		equip_button.icon = IconLoader.get_skill_icon("azure_slash")
		UITheme.apply_accent_button(equip_button, true)
		equip_button.pressed.connect(_equip_first_candidate.bind(slot_id))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(choose_button)
		row.add_child(equip_button)
		equipment_list.add_child(card)
	_show_summary()

func _slot_name(slot_id: String) -> String:
	match slot_id:
		"weapon": return "Оружие"
		"armor": return "Броня"
		"boots": return "Сапоги"
		"ring": return "Кольцо"
		_: return slot_id

func _item_name(item_id: String) -> String:
	for item in ConfigRepository.items.get("items", []):
		if str(item.get("id", "")) == item_id:
			return str(item.get("name", item_id))
	return item_id

func _inventory_candidates(slot_id: String) -> Array:
	var result: Array = []
	var inventory := PlayerState.get_inventory()
	for entry in inventory:
		var entry_item_id := str(entry.get("item_id", ""))
		for item in ConfigRepository.items.get("items", []):
			if str(item.get("id", "")) == entry_item_id and str(item.get("type", "")) == slot_id:
				result.append(entry_item_id)
	return result

func _show_candidates(slot_id: String) -> void:
	selected_slot_id = slot_id
	var candidates := _inventory_candidates(slot_id)
	if candidates.is_empty():
		detail_label.text = "[b]%s[/b]\n\nПодходящих предметов в инвентаре нет." % _slot_name(slot_id)
		return
	var lines: Array[String] = []
	for item_id in candidates:
		lines.append(_item_name(item_id))
	detail_label.text = "[b]%s[/b]\n\nДоступные предметы:\n• %s" % [_slot_name(slot_id), "\n• ".join(lines)]

func _equip_first_candidate(slot_id: String) -> void:
	var candidates := _inventory_candidates(slot_id)
	if candidates.is_empty():
		_show_candidates(slot_id)
		return
	PlayerState.equip_item(slot_id, str(candidates[0]))
	_show_summary()

func _show_summary() -> void:
	var equipment := PlayerState.get_equipment()
	detail_label.text = "[b]Текущий комплект[/b]\n\n" + \
		"Оружие: %s\n" % _item_name(str(equipment.get("weapon", "-"))) + \
		"Броня: %s\n" % _item_name(str(equipment.get("armor", "-"))) + \
		"Сапоги: %s\n" % _item_name(str(equipment.get("boots", "-"))) + \
		"Кольцо: %s\n\n" % _item_name(str(equipment.get("ring", "-"))) + \
		"Нажми «Выбрать», чтобы посмотреть кандидатов из инвентаря."

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/character/CharacterScreen.tscn")
