extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var equipment_list: VBoxContainer = %EquipmentList
@onready var detail_label: RichTextLabel = %DetailLabel

var selected_slot_id := "weapon"

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh()
	PlayerState.equipment_changed.connect(_refresh)
	PlayerState.currencies_changed.connect(_refresh)

func _refresh() -> void:
	for child in equipment_list.get_children():
		child.queue_free()
	var equipment := PlayerState.get_equipment()
	for slot_id in ["weapon", "armor", "boots", "ring"]:
		var item_id := str(equipment.get(slot_id, "none"))
		var equipped := item_id != "none"
		var enhance_level := PlayerState.get_equipment_enhance_level(slot_id)
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK if equipped else UITheme.COLOR_JADE_DARK)
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
		var state_badge := "[ЭКИП]" if equipped else "[ПУСТО]"
		label.text = "%s %s: %s  +%d" % [state_badge, _slot_name(slot_id), _item_name(item_id), enhance_level]
		var choose_button := Button.new()
		choose_button.text = "Кандидаты"
		choose_button.icon = IconLoader.get_skill_icon("jade_guard")
		UITheme.apply_accent_button(choose_button, false)
		choose_button.pressed.connect(_show_candidates.bind(slot_id))
		var equip_button := Button.new()
		equip_button.text = "Сменить" if equipped else "Надеть"
		equip_button.icon = IconLoader.get_skill_icon("azure_slash")
		UITheme.apply_accent_button(equip_button, true)
		equip_button.pressed.connect(_equip_first_candidate.bind(slot_id))
		var forge_button := Button.new()
		forge_button.text = "Усилить"
		forge_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
		UITheme.apply_accent_button(forge_button, false)
		forge_button.disabled = not equipped
		forge_button.pressed.connect(_enhance_slot.bind(slot_id))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(choose_button)
		row.add_child(equip_button)
		row.add_child(forge_button)
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
	detail_label.text = "[b]%s[/b]\n\nДоступные предметы (%d):\n• %s" % [_slot_name(slot_id), candidates.size(), "\n• ".join(lines)]

func _equip_first_candidate(slot_id: String) -> void:
	var candidates := _inventory_candidates(slot_id)
	if candidates.is_empty():
		_show_candidates(slot_id)
		return
	PlayerState.equip_item(slot_id, str(candidates[0]))
	_show_summary()

func _enhance_slot(slot_id: String) -> void:
	var result := PlayerState.enhance_equipment(slot_id)
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("equipment_enhance", result)
		detail_label.text = "[b]%s[/b]\n\n%s\nСила +%d\nЦена: %d золота, %d связанных камней" % [
			_slot_name(slot_id),
			str(result.get("text", "Усиление выполнено")),
			int(result.get("power_gain", 0)),
			int(result.get("cost", {}).get("gold", 0)),
			int(result.get("cost", {}).get("bound_spirit_stone", 0))
		]
	else:
		detail_label.text = "[b]%s[/b]\n\n%s" % [_slot_name(slot_id), str(result.get("text", "Усиление недоступно"))]
	_refresh()

func _show_summary() -> void:
	var equipment := PlayerState.get_equipment()
	var enhancement := PlayerState.get_equipment_enhancement()
	var next_cost := PlayerState.get_equipment_enhance_cost(selected_slot_id)
	detail_label.text = "[b]Текущий комплект[/b]\n\n" + \
		"Оружие: %s  +%d\n" % [_item_name(str(equipment.get("weapon", "-"))), int(enhancement.get("weapon", 0))] + \
		"Броня: %s  +%d\n" % [_item_name(str(equipment.get("armor", "-"))), int(enhancement.get("armor", 0))] + \
		"Сапоги: %s  +%d\n" % [_item_name(str(equipment.get("boots", "-"))), int(enhancement.get("boots", 0))] + \
		"Кольцо: %s  +%d\n\n" % [_item_name(str(equipment.get("ring", "-"))), int(enhancement.get("ring", 0))] + \
		"Следующее усиление %s:\n• золото: %d\n• связанные камни: %d" % [_slot_name(selected_slot_id), int(next_cost.get("gold", 0)), int(next_cost.get("bound_spirit_stone", 0))]

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/character/CharacterScreen.tscn")
