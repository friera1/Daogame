extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var list_container: VBoxContainer = %ItemList
@onready var detail_label: RichTextLabel = %DetailLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_style_screen()
	_refresh_list()
	PlayerState.inventory_changed.connect(_refresh_list)
	PlayerState.currencies_changed.connect(_refresh_list)
	PlayerState.cultivation_changed.connect(_refresh_list)

func _style_screen() -> void:
	list_container.add_theme_constant_override("separation", 10)
	detail_label.add_theme_font_size_override("normal_font_size", 17)
	detail_label.add_theme_color_override("default_color", UITheme.COLOR_TEXT_SOFT)
	detail_label.text = "[b]Инвентарь[/b]\n\nВыбери предмет или рецепт, чтобы увидеть требования, источники и будущий слот изображения."

func _refresh_list() -> void:
	for child in list_container.get_children():
		child.queue_free()
	_add_section_title("Предметы")
	for entry in PlayerState.get_inventory():
		list_container.add_child(_build_item_row(entry))
	_add_section_title("Крафт")
	for recipe in ConfigRepository.get_available_recipes(PlayerState.get_current_stage_id(), PlayerState.get_level()):
		list_container.add_child(_build_recipe_row(recipe))
	if PlayerState.get_inventory().is_empty():
		detail_label.text = "[b]Рюкзак пуст[/b]\n\nПолучи предметы из призыва, магазина, крафта или сюжетных наград."

func _add_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	label.add_theme_font_size_override("font_size", 16)
	label.custom_minimum_size.y = 30
	list_container.add_child(label)

func _make_meta_label(text: String, color: Color = UITheme.COLOR_TEXT_SECONDARY) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _build_item_row(entry: Dictionary) -> Control:
	var item_id := str(entry.get("item_id", ""))
	var item_def := ConfigRepository.get_item_def(item_id)
	var rarity := str(item_def.get("rarity", entry.get("rarity", "common")))
	var usable := PlayerState.can_use_inventory_item(item_id)
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, _rarity_color(rarity))
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(66, 66)
	UITheme.apply_card(icon_panel, _rarity_color(rarity))
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(58, 58)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_item_icon(str(item_def.get("icon_key", item_id)))
	icon_panel.add_child(icon)
	row.add_child(icon_panel)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = "%s  x%s" % [ConfigRepository.get_item_name(item_id), str(entry.get("quantity", 1))]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
	var meta := _make_meta_label("%s · %s · ур.%d · %s" % [ConfigRepository.get_rarity_name(rarity), str(item_def.get("category", "item")), int(item_def.get("player_level_required", 1)), ConfigRepository.get_stage_name(str(item_def.get("qi_stage_required", "mortal_early")))], _rarity_color(rarity))
	var hint := _make_meta_label(str(item_def.get("description", "")))
	text_box.add_child(title)
	text_box.add_child(meta)
	text_box.add_child(hint)
	var use_button := Button.new()
	use_button.text = "Исп." if bool(item_def.get("usable", false)) else "Info"
	use_button.custom_minimum_size = Vector2(86, 48)
	use_button.icon = IconLoader.get_skill_icon("azure_slash") if bool(item_def.get("usable", false)) else IconLoader.get_skill_icon("jade_guard")
	UITheme.apply_accent_button(use_button, usable)
	use_button.pressed.connect(_on_item_action.bind(item_id, bool(item_def.get("usable", false))))
	row.add_child(text_box)
	row.add_child(use_button)
	return card

func _build_recipe_row(recipe: Dictionary) -> Control:
	var result := recipe.get("result", {})
	var result_item_id := str(result.get("item_id", ""))
	var result_def := ConfigRepository.get_item_def(result_item_id)
	var rarity := str(result_def.get("rarity", result.get("rarity", "common")))
	var craftable := true
	var missing_parts: Array[String] = []
	for ingredient in recipe.get("ingredients", []):
		var ingredient_id := str(ingredient.get("item_id", ""))
		var have := PlayerState.get_inventory_item_quantity(ingredient_id)
		var need := int(ingredient.get("quantity", 1))
		if have < need:
			craftable = false
			missing_parts.append("%s %d/%d" % [ConfigRepository.get_item_name(ingredient_id), have, need])
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_card(card, _rarity_color(rarity) if craftable else UITheme.COLOR_MUTED)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(66, 66)
	UITheme.apply_card(icon_panel, _rarity_color(rarity))
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(58, 58)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = IconLoader.get_item_icon(str(recipe.get("icon_key", result_item_id)))
	icon_panel.add_child(icon)
	row.add_child(icon_panel)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 3)
	var title := Label.new()
	title.text = ConfigRepository.get_recipe_name(str(recipe.get("id", "")))
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
	var meta := _make_meta_label("%s → %s x%s · %d зол. · %d эсс." % [str(recipe.get("discipline", "craft")).capitalize(), ConfigRepository.get_item_name(result_item_id), str(result.get("quantity", 1)), int(recipe.get("gold_cost", 0)), int(recipe.get("bound_spirit_stone_cost", 0))], _rarity_color(rarity))
	var hint_text := "Готово к созданию" if craftable else "Не хватает: %s" % ", ".join(missing_parts)
	var hint := _make_meta_label(hint_text, UITheme.COLOR_SUCCESS if craftable else UITheme.COLOR_WARNING)
	text_box.add_child(title)
	text_box.add_child(meta)
	text_box.add_child(hint)
	var craft_button := Button.new()
	craft_button.text = "Создать"
	craft_button.custom_minimum_size = Vector2(98, 48)
	craft_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	UITheme.apply_accent_button(craft_button, true)
	craft_button.disabled = not craftable
	craft_button.pressed.connect(_on_craft_action.bind(str(recipe.get("id", ""))))
	row.add_child(text_box)
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
	detail_label.text = "[b]%s[/b]\n\n%s\n\n[b]Тип[/b]: %s\n[b]Категория[/b]: %s\n[b]Редкость[/b]: %s\n[b]Требования[/b]: %s · ур.%d\n[b]Источники[/b]: %s\n\n[b]Icon key[/b]: %s\n[b]Image slot[/b]: %s" % [ConfigRepository.get_item_name(item_id), str(item_def.get("description", "")), str(item_def.get("type", "unknown")), str(item_def.get("category", "unknown")), ConfigRepository.get_rarity_name(str(item_def.get("rarity", "common"))), ConfigRepository.get_stage_name(str(item_def.get("qi_stage_required", "mortal_early"))), int(item_def.get("player_level_required", 1)), ", ".join(item_def.get("sources", [])), str(item_def.get("icon_key", item_id)), str(item_def.get("image_future_slot", ""))]

func _on_craft_action(recipe_id: String) -> void:
	var result := PlayerState.craft_recipe(recipe_id)
	detail_label.text = "[b]%s[/b]\n\n%s" % [ConfigRepository.get_recipe_name(recipe_id), str(result.get("text", "Крафт завершён"))]
	if bool(result.get("ok", false)):
		OnlineSyncService.queue_action("item_craft", result)

func _rarity_color(rarity: String) -> Color:
	return UITheme.rarity_color(rarity)

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
