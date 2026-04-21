extends Control

@onready var equipment_list: VBoxContainer = %EquipmentList
@onready var detail_label: RichTextLabel = %DetailLabel

func _ready() -> void:
	_refresh()
	PlayerState.equipment_changed.connect(_refresh)

func _refresh() -> void:
	for child in equipment_list.get_children():
		child.queue_free()
	var equipment := PlayerState.get_equipment()
	for slot_id in ["weapon", "armor", "boots", "ring"]:
		var item_id := str(equipment.get(slot_id, "none"))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s: %s" % [_slot_name(slot_id), _item_name(item_id)]
		var button := Button.new()
		button.text = "Сменить"
		button.pressed.connect(_cycle_slot.bind(slot_id))
		row.add_child(label)
		row.add_child(button)
		equipment_list.add_child(row)
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

func _cycle_slot(slot_id: String) -> void:
	var candidates: Array = []
	for item in ConfigRepository.items.get("items", []):
		if str(item.get("type", "")) == slot_id:
			candidates.append(str(item.get("id", "")))
	if candidates.is_empty():
		return
	PlayerState.equip_item(slot_id, candidates[0])
	_show_summary()

func _show_summary() -> void:
	var equipment := PlayerState.get_equipment()
	detail_label.text = "[b]Текущий комплект[/b]\n\n" + \
		"Оружие: %s\n" % _item_name(str(equipment.get("weapon", "-"))) + \
		"Броня: %s\n" % _item_name(str(equipment.get("armor", "-"))) + \
		"Сапоги: %s\n" % _item_name(str(equipment.get("boots", "-"))) + \
		"Кольцо: %s" % _item_name(str(equipment.get("ring", "-")))

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/character/CharacterScreen.tscn")
