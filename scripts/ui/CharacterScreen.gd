extends Control

const CHARACTER_BG_PATH := "res://assets/art/generated/hero_portrait_primary.png"
const PORTRAIT_ART_PATH := "res://assets/art/generated/hero_portrait_primary.png"

@onready var name_label: Label = %NameLabel
@onready var power_label: Label = %PowerLabel
@onready var stage_label: Label = %StageLabel
@onready var stats_label: RichTextLabel = %StatsLabel
@onready var character_background_art: TextureRect = %CharacterBackgroundArt
@onready var portrait_art: TextureRect = %PortraitArt

func _ready() -> void:
	_apply_art()
	var profile := PlayerState.profile
	name_label.text = "%s · Ур. %d" % [PlayerState.get_name(), PlayerState.get_level()]
	power_label.text = "Боевая мощь: %d" % PlayerState.get_power()
	stage_label.text = ConfigRepository.get_stage_name(str(PlayerState.get_cultivation().get("current_stage_id", "")))
	stats_label.text = "[b]Текущий статус[/b]\n\n" + \
		"• Путь: Праведный\n" + \
		"• Элемент: Металл / Свет\n" + \
		"• VIP: %s\n" % str(profile.get("vip_level", 0)) + \
		"• Сервер: %s\n" % str(profile.get("server_id", "s1")) + \
		"• Титул: Наследник нефритового меча"

func _apply_art() -> void:
	var bg := ArtLoader.load_texture_safe(CHARACTER_BG_PATH)
	if bg != null:
		character_background_art.texture = bg
	var portrait := ArtLoader.load_texture_safe(PORTRAIT_ART_PATH)
	if portrait != null:
		portrait_art.texture = portrait

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
