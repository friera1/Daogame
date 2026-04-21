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

func _refresh_info(message: String) -> void:
	info_label.text = "[b]%s[/b]\n\nВалюта: %s\nЦена: %s\nPity: %d / %d" % [
		message,
		str(current_banner.get("currency", "jade")),
		str(current_banner.get("cost_per_pull", 10)),
		pity_counter,
		int(current_banner.get("pity", 30))
	]

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
		_on_pull_once_pressed()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
