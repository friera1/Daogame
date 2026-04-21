extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var pet_list: VBoxContainer = %PetList
@onready var detail_label: RichTextLabel = %DetailLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh()
	PlayerState.pets_changed.connect(_refresh)

func _refresh() -> void:
	for child in pet_list.get_children():
		child.queue_free()
	var pets := PlayerState.get_pets()
	for pet in pets:
		var pet_id := str(pet.get("pet_id", ""))
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_JADE_DARK)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = IconLoader.get_pet_icon(pet_id)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s · ур. %d · ★%d" % [_get_pet_name(pet_id), int(pet.get("level", 1)), int(pet.get("stars", 1))]
		var details_button := Button.new()
		details_button.text = "Детали"
		details_button.icon = IconLoader.get_skill_icon("jade_guard")
		UITheme.apply_accent_button(details_button, false)
		details_button.pressed.connect(_show_pet.bind(pet_id))
		var equip_button := Button.new()
		equip_button.text = "Активен" if bool(pet.get("equipped", false)) else "Выбрать"
		equip_button.icon = IconLoader.get_skill_icon("azure_slash")
		UITheme.apply_accent_button(equip_button, bool(pet.get("equipped", false)))
		equip_button.pressed.connect(_equip_pet.bind(pet_id))
		row.add_child(icon)
		row.add_child(label)
		row.add_child(details_button)
		row.add_child(equip_button)
		pet_list.add_child(card)
	if pets.size() > 0:
		_show_pet(str(pets[0].get("pet_id", "")))

func _get_pet_name(pet_id: String) -> String:
	for pet in ConfigRepository.pets.get("pets", []):
		if str(pet.get("id", "")) == pet_id:
			return str(pet.get("name", pet_id))
	return pet_id

func _show_pet(pet_id: String) -> void:
	for pet in ConfigRepository.pets.get("pets", []):
		if str(pet.get("id", "")) == pet_id:
			detail_label.text = "[b]%s[/b]\n\nРедкость: %s\nЭлемент: %s\nРоль: %s\nПассив: %s" % [
				str(pet.get("name", pet_id)),
				str(pet.get("rarity", "common")),
				str(pet.get("element", "neutral")),
				str(pet.get("role", "support")),
				str(pet.get("passive", "-"))
			]
			return
	detail_label.text = "Питомец не найден"

func _equip_pet(pet_id: String) -> void:
	PlayerState.equip_pet(pet_id)
	_show_pet(pet_id)

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
