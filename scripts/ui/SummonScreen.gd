extends Control

const SUMMON_BG_PATH := "res://assets/art/generated/lobby_background_primary.png"
const SUMMON_BANNER_PATH := "res://assets/art/generated/summon_banner_primary.png"
const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var banner_label: Label = %BannerLabel
@onready var info_label: RichTextLabel = %InfoLabel
@onready var summon_background_art: TextureRect = %SummonBackgroundArt
@onready var banner_art: TextureRect = %BannerArt
@onready var header_title: Label = %HeaderTitle
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
		_refresh_info("Готов к призыву")

func _apply_visual_polish() -> void:
	header_title.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	header_title.add_theme_font_size_override("font_size", 28)
	banner_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	banner_label.add_theme_font_size_override("font_size", 24)

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
	var ready_badge := "[ГОТОВО]" if int(PlayerState.get_currencies().get(str(current_banner.get("currency", "jade")), 0)) >= cost else "[НЕТ ВАЛЮТЫ]"
	var pity_badge := "[PITY ГОТОВ]" if pity_counter >= pity_max else "[PITY %d/%d]" % [pity_counter, pity_max]
	info_label.text = "[b]%s[/b]\n\n%s\nВалюта: %s\nЦена: %s\n%s" % [
		message,
		ready_badge,
		str(current_banner.get("currency", "jade")),
		str(cost),
		pity_badge
	]
	var can_pull := int(PlayerState.get_currencies().get(str(current_banner.get("currency", "jade")), 0)) >= cost
	pull_once_button.disabled = not can_pull
	pull_ten_button.disabled = int(PlayerState.get_currencies().get(str(current_banner.get("currency", "jade")), 0)) < cost * 10

func _on_pull_once_pressed() -> void:
	var cost := int(current_banner.get("cost_per_pull", 10))
	if not PlayerState.spend_currency(str(current_banner.get("currency", "jade")), cost):
		_refresh_info("Недостаточно валюты для призыва")
		return
	pity_counter += 1
	var reward := _resolve_reward()
	_refresh_info("Получено: %s" % reward)

func _resolve_reward() -> String:
	var pool := current_banner.get("pool", [])
	if pity_counter >= int(current_banner.get("pity", 30)) and pool.size() > 0:
		pity_counter = 0
		return str(pool[0].get("id", "reward"))
	if pool.size() == 0:
		return "пусто"
	var index := randi() % pool.size()
	return str(pool[index].get("id", "reward"))

func _on_pull_ten_pressed() -> void:
	for i in range(10):
		if pull_once_button.disabled:
			break
		_on_pull_once_pressed()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
