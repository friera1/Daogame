extends Control

const SUMMON_BG_PATH := "res://assets/art/generated/lobby_background_primary.png"
const SUMMON_BANNER_PATH := "res://assets/art/generated/summon_banner_primary.png"
const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var banner_label: Label = %BannerLabel
@onready var info_label: RichTextLabel = %InfoLabel
@onready var summon_background_art: TextureRect = %SummonBackgroundArt
@onready var banner_art: TextureRect = %BannerArt
@onready var header_title: Label = %HeaderTitle
@onready var result_list: VBoxContainer = %ResultList
@onready var pull_once_button: Button = %PullOnceButton
@onready var pull_ten_button: Button = %PullTenButton

var current_banner: Dictionary = {}
var pity_counter := 0

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_apply_visual_polish()
	_apply_art()
	_apply_icons()
	_apply_button_styles()
	var banners := ConfigRepository.summon_pools.get("banners", [])
	if banners.size() > 0:
		current_banner = banners[0]
		banner_label.text = str(current_banner.get("title", "Призыв"))
		pity_counter = PlayerState.get_banner_pity(_banner_id())
		_refresh_info("Готов к призыву")
	_clear_results_placeholder()
	PlayerState.summon_progress_changed.connect(_on_summon_progress_changed)

func _banner_id() -> String:
	return str(current_banner.get("id", "default_banner"))

func _on_summon_progress_changed() -> void:
	pity_counter = PlayerState.get_banner_pity(_banner_id())
	_refresh_info("Прогресс призыва синхронизирован")

func _apply_visual_polish() -> void:
	header_title.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	header_title.add_theme_font_size_override("font_size", 28)
	banner_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	banner_label.add_theme_font_size_override("font_size", 24)
	$Panel/VBox/ResultPanel.add_theme_stylebox_override("panel", UITheme.make_card_style(UITheme.COLOR_GOLD_DARK))

func _apply_art() -> void:
	var bg := ArtLoader.load_texture_safe(SUMMON_BG_PATH)
	if bg != null:
		summon_background_art.texture = bg
	var banner := ArtLoader.load_texture_safe(SUMMON_BANNER_PATH)
	if banner != null:
		banner_art.texture = banner

func _apply_icons() -> void:
	pull_once_button.icon = IconLoader.get_currency_icon("jade")
	pull_ten_button.icon = IconLoader.get_skill_icon("azure_slash")

func _apply_button_styles() -> void:
	UITheme.apply_accent_button(pull_once_button, true)
	UITheme.apply_accent_button(pull_ten_button, false)

func _refresh_info(message: String) -> void:
	var cost := int(current_banner.get("cost_per_pull", 10))
	var pity_max := int(current_banner.get("pity", 30))
	var currency_id := str(current_banner.get("currency", "jade"))
	var balance := int(PlayerState.get_currencies().get(currency_id, 0))
	var ready_badge := "[ГОТОВО]" if balance >= cost else "[НЕТ ВАЛЮТЫ]"
	var pity_badge := "[PITY ГОТОВ]" if pity_counter >= pity_max else "[PITY %d/%d]" % [pity_counter, pity_max]
	info_label.text = "[b]%s[/b]\n\n%s\nВалюта: %s\nЦена: %s\n%s" % [
		message,
		ready_badge,
		currency_id,
		str(cost),
		pity_badge
	]
	pull_once_button.disabled = balance < cost
	pull_ten_button.disabled = balance < cost * 10

func _clear_results_placeholder() -> void:
	for child in result_list.get_children():
		child.queue_free()
	var label := Label.new()
	label.text = "Здесь появятся результаты призыва"
	label.modulate = UITheme.COLOR_TEXT_SECONDARY
	result_list.add_child(label)

func _show_results(results: Array) -> void:
	for child in result_list.get_children():
		child.queue_free()
	for entry in results:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var border := _result_border(str(entry.get("rarity", "rare")), str(entry.get("status", "item")))
		UITheme.apply_card(card, border)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _result_icon(entry)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "%s %s" % [_result_badge(str(entry.get("status", "item"))), str(entry.get("text", "Награда"))]
		row.add_child(icon)
		row.add_child(label)
		result_list.add_child(card)

func _result_badge(status: String) -> String:
	match status:
		"new_pet":
			return "[НОВЫЙ ПИТОМЕЦ]"
		"duplicate_pet":
			return "[ДУБЛЬ → КОМПЕНСАЦИЯ]"
		"epic_item":
			return "[ЭПИК]"
		"currency":
			return "[ВАЛЮТА]"
		_:
			return "[ПРЕДМЕТ]"

func _result_border(rarity: String, status: String) -> Color:
	if status == "new_pet":
		return UITheme.COLOR_GOLD
	if status == "duplicate_pet":
		return UITheme.COLOR_GOLD_DARK
	match rarity:
		"epic":
			return Color(0.74, 0.52, 0.95, 1)
		"rare":
			return Color(0.47, 0.8, 1.0, 1)
		_:
			return UITheme.COLOR_JADE_DARK

func _result_icon(entry: Dictionary) -> Texture2D:
	var reward_type := str(entry.get("type", "item"))
	var reward_id := str(entry.get("id", ""))
	if reward_type == "pet":
		return IconLoader.get_pet_icon(reward_id)
	return IconLoader.get_item_icon(reward_id)

func _queue_summon_action(results: Array, pull_count: int) -> void:
	OnlineSyncService.queue_summon_pull({
		"banner_id": _banner_id(),
		"banner_title": str(current_banner.get("title", "Призыв")),
		"pull_count": pull_count,
		"cost_per_pull": int(current_banner.get("cost_per_pull", 10)),
		"currency_id": str(current_banner.get("currency", "jade")),
		"pity_after": pity_counter,
		"results": results
	})

func _persist_pity() -> void:
	PlayerState.set_banner_pity(_banner_id(), pity_counter)

func _on_pull_once_pressed() -> void:
	var cost := int(current_banner.get("cost_per_pull", 10))
	var currency_id := str(current_banner.get("currency", "jade"))
	if not PlayerState.spend_currency(currency_id, cost):
		_refresh_info("Недостаточно валюты для призыва")
		return
	pity_counter += 1
	var reward := _resolve_reward()
	_persist_pity()
	var result := PlayerState.grant_summon_reward(reward)
	_show_results([result])
	_queue_summon_action([result], 1)
	_refresh_info("Получено: %s" % str(result.get("text", "награда")))

func _resolve_reward() -> Dictionary:
	var pool := current_banner.get("pool", [])
	if pity_counter >= int(current_banner.get("pity", 30)) and pool.size() > 0:
		pity_counter = 0
		return pool[0]
	if pool.size() == 0:
		return {"type": "item", "id": "spirit_stone"}
	var total_weight := 0
	for entry in pool:
		total_weight += int(entry.get("weight", 1))
	var roll := randi() % max(total_weight, 1)
	var cursor := 0
	for entry in pool:
		cursor += int(entry.get("weight", 1))
		if roll < cursor:
			return entry
	return pool[0]

func _on_pull_ten_pressed() -> void:
	var results: Array = []
	for i in range(10):
		var cost := int(current_banner.get("cost_per_pull", 10))
		if int(PlayerState.get_currencies().get(str(current_banner.get("currency", "jade")), 0)) < cost:
			break
		PlayerState.spend_currency(str(current_banner.get("currency", "jade")), cost)
		pity_counter += 1
		var reward := _resolve_reward()
		results.append(PlayerState.grant_summon_reward(reward))
	_persist_pity()
	if results.is_empty():
		_refresh_info("Недостаточно валюты для x10 призыва")
		return
	_show_results(results)
	_queue_summon_action(results, results.size())
	_refresh_info("Серия призыва завершена")

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
