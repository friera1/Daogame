extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var list_container: VBoxContainer = %ItemList
@onready var detail_label: RichTextLabel = %DetailLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh_list()
	PlayerState.inventory_changed.connect(_refresh_list)
	PlayerState.currencies_changed.connect(_refresh_list)
	PlayerState.cultivation_changed.connect(_refresh_list)

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()
	for entry in PlayerState.get_inventory():
		list_container.add_child(_build_item_row(entry))
	for recipe in ConfigRepository.get_available_recipes(PlayerState.get_current_stage_id(), PlayerState.get_level()):
		list_container.add_child(_build_recipe_row(recipe))
	if PlayerState.get_inventory().is_empty():
		detail_label.text = "[b]Рюкзак пуст[/b]\n\nПолучи предметы из призыва, магазина, крафта или сюжетных наград."

func _build_item_row(entry: Dictionary) -> Control:
	var item_id := str(entry.get("item_id", ""))
	var item_def := ConfigRepository.get_item_def(item_id)
	var usable := PlayerState.can_use_inventory_item(item_id)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, _rarity_color(str(item_def.get("rarity", entry.get("rarity", "common")))))
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_item_icon(str(item_def.get("icon_key", item_id)))
	row.add_child(icon)
	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var badge := "[ИСПОЛЬЗ.]" if usable else "[ПРЕДМЕТ]"
	name_label.text = "%s %s x%s" % [badge, ConfigRepository.get_item_name(item_id), str(entry.get("quantity", 1))]
	var rarity_label := Label.new()
	var rarity := str(item_def.get("rarity", entry.get("rarity", "common")))
	rarity_label.text = ConfigRepository.get_rarity_name(rarity)
	rarity_label.modulate = _rarity_color(rarity)
	var use_button := Button.new()
	use_button.text = "Исп." if bool(item_def.get("usable", false)) else "Осмотр"
	use_button.icon = IconLoader.get_skill_icon("azure_slash") if bool(item_def.get("usable", false)) else IconLoader.get_skill_icon("jade_guard")
	UITheme.apply_accent_button(use_button, usable)
	use_button.pressed.connect(_on_item_action.bind(item_id, bool(item_def.get("usable", false))))
	var lock_label := Label.new()
	lock_label.text = "LOCK" if bool(entry.get("locked", false)) else ""
	lock_label.modulate = UITheme.COLOR_GOLD
	row.add_child(name_label)
	row.add_child(rarity_label)
	row.add_child(use_button)
	row.add_child(lock_label)
	return card

func _build_recipe_row(recipe: Dictionary) -> Control:
	var result := recipe.get("result", {})
	var result_item_id := str(result.get("item_id", ""))
	var craftable := true
	for ingredient in recipe.get("ingredients", []):
		if PlayerState.get_inventory_item_quantity(str(ingredient.get("item_id", ""))) < int(ingredient.get("quantity", 1)):
			craftable = false
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, UITheme.COLOR_GOLD_DARK if craftable else UITheme.COLOR_TEXT_SECONDARY)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_item_icon(str(recipe.get("icon_key", result_item_id)))
	row.add_child(icon)
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "[КРАФТ] %s → %s x%s" % [str(recipe.get("discipline", "craft")).capitalize(), ConfigRepository.get_item_name(result_item_id), str(result.get("quantity", 1))]
	var craft_button := Button.new()
	craft_button.text = "Создать"
	craft_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	UITheme.apply_accent_button(craft_button, true)
	craft_button.disabled = not craftable
	craft_button.pressed.connect(_on_craft_action.bind(str(recipe.get("id", ""))))
	row.add_child(label)
	row.add_child(craft_button)
	return card

func _on_item_action(item_id: String, is_usable_item: bool) -> void:
	var item_def := ConfigRepository.get_item_def(item_id)
	if is_usable_item and PlayerState.can_use_inventory_item(item_id):
		var result_text := PlayerState.use_inventory_item(item_id)
		detail_label.text = "[b]%s[/b]\n\n%s" % [ConfigRepository.get_item_name(item_id), result_text]
		if not result_text.contains("пока нельзя") and not result_text.contains("Недостаточная") and not result_text.contains("закончился"):
			OnlineSyncService.queue_item_use({"item_id": item_id, "item_name": ConfigRepository.get_item_name(item_id), "result": result_text})
		return
	detail_label.text = "[b]%s[/b]\n\nТип: %s\nКатегория: %s\nРедкость: %s\nТребуемая стадия: %s\nТребуемый уровень: %d\nИсточники: %s\nIcon key: %s\nImage slot: %s" % [ConfigRepository.get_item_name(item_id), str(item_def.get("type", "unknown")), str(item_def.get("category", "unknown")), ConfigRepository.get_rarity_name(str(item_def.get("rarity", "common"))), ConfigRepository.get_stage_name(str(item_def.get("qi_stage_required", "mortal_early"))), int(item_def.get("player_level_required", 1)), ", ".join(item_def.get("sources", [])), str(item_def.get("icon_key", item_id)), str(item_def.get("image_future_slot", ""))]

func _on_craft_action(recipe_id: String) -> void:
	var result := PlayerState.craft_recipe(recipe_id)
	detail_label.text = "[b]%s[/b]\n\n%s" % [ConfigRepository.get_recipe_name(recipe_id), str(result.get("text", "Крафт завершён"))]
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("item_craft", result)

func _rarity_color(rarity: String) -> Color:
	var rarity_def := ConfigRepository.get_rarity_def(rarity)
	if not rarity_def.is_empty():
		return Color(str(rarity_def.get("color", "#B8BFCB")))
	return UITheme.COLOR_TEXT_SECONDARY

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
