extends Control

const CHARACTER_BG_PATH := "res://assets/art/generated/hero_portrait_primary.png"
const PORTRAIT_ART_PATH := "res://assets/art/generated/hero_portrait_primary.png"
const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var name_label: Label = %NameLabel
@onready var power_label: Label = %PowerLabel
@onready var stage_label: Label = %StageLabel
@onready var stats_label: RichTextLabel = %StatsLabel
@onready var character_background_art: TextureRect = %CharacterBackgroundArt
@onready var portrait_art: TextureRect = %PortraitArt

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_apply_art()
	_refresh()
	PlayerState.player_loaded.connect(_refresh)
	PlayerState.cultivation_changed.connect(_refresh)
	PlayerState.equipment_changed.connect(_refresh)
	PlayerState.currencies_changed.connect(_refresh)

func _refresh() -> void:
	var profile := PlayerState.profile
	var cult := PlayerState.get_cultivation()
	var breakthrough_ready := bool(cult.get("breakthrough_ready", false))
	var enhancement := PlayerState.get_equipment_enhancement()
	var total_forge := int(enhancement.get("weapon", 0)) + int(enhancement.get("armor", 0)) + int(enhancement.get("boots", 0)) + int(enhancement.get("ring", 0))
	name_label.text = "%s · Ур. %d" % [PlayerState.get_name(), PlayerState.get_level()]
	power_label.text = "Боевая мощь: %d · Forge: +%d" % [PlayerState.get_power(), total_forge]
	stage_label.text = "%s %s" % ["[ГОТОВ]" if breakthrough_ready else "[ПУТЬ]", ConfigRepository.get_stage_name(str(cult.get("current_stage_id", "")))]
	stats_label.text = "[b]Текущий статус[/b]\n\n" + \
		"• Путь: Праведный\n" + \
		"• Элемент: Металл / Свет\n" + \
		"• VIP: %s\n" % str(profile.get("vip_level", 0)) + \
		"• Сервер: %s\n" % str(profile.get("server_id", "s1")) + \
		"• Титул: Наследник нефритового меча\n" + \
		"• Прорыв: %s\n\n" % ("готов" if breakthrough_ready else "накапливает Ци") + \
		"[b]Кузница экипировки[/b]\n" + \
		"• Оружие: +%d\n" % int(enhancement.get("weapon", 0)) + \
		"• Броня: +%d\n" % int(enhancement.get("armor", 0)) + \
		"• Сапоги: +%d\n" % int(enhancement.get("boots", 0)) + \
		"• Кольцо: +%d\n\n" % int(enhancement.get("ring", 0)) + \
		"• Совокупный forge-рейтинг: +%d\n" % total_forge + \
		"• Усиление выполняется на экране снаряжения"
	$Panel.add_theme_stylebox_override("panel", UITheme.make_card_style(UITheme.COLOR_GOLD_DARK))
	$Panel/VBox/Header/EquipmentButton.icon = IconLoader.get_item_icon("jade_sword_01")
	UITheme.apply_accent_button($Panel/VBox/Header/EquipmentButton, true)

func _apply_art() -> void:
	var bg := ArtLoader.load_texture_safe(CHARACTER_BG_PATH)
	if bg != null:
		character_background_art.texture = bg
	var portrait := ArtLoader.load_texture_safe(PORTRAIT_ART_PATH)
	if portrait != null:
		portrait_art.texture = portrait

func _on_equipment_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/equipment/EquipmentScreen.tscn")

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
