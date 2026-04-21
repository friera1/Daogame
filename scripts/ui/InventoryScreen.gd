extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var list_container: VBoxContainer = %ItemList

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh_list()
	PlayerState.inventory_changed.connect(_refresh_list)

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for entry in PlayerState.get_inventory():
		list_container.add_child(_build_item_row(entry))

func _build_item_row(entry: Dictionary) -> Control:
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
	icon.texture = IconLoader.get_item_icon(str(entry.get("item_id", "")))
	row.add_child(icon)

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = "%s x%s" % [ConfigRepository.get_item_name(str(entry.get("item_id", "item"))), str(entry.get("quantity", 1))]

	var rarity_label := Label.new()
	var rarity := str(entry.get("rarity", "common"))
	rarity_label.text = rarity.capitalize()
	rarity_label.modulate = _rarity_color(rarity)

	var lock_label := Label.new()
	lock_label.text = "LOCK" if bool(entry.get("locked", false)) else ""
	lock_label.modulate = UITheme.COLOR_GOLD

	row.add_child(name_label)
	row.add_child(rarity_label)
	row.add_child(lock_label)
	return card

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
