extends Control

const CULTIVATION_BG_PATH := "res://assets/art/generated/cultivation_background_primary.png"
const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var stage_label: Label = %StageLabel
@onready var qi_label: Label = %QiLabel
@onready var status_label: Label = %StatusLabel
@onready var body_label: Label = %BodyLabel
@onready var spirit_label: Label = %SpiritLabel
@onready var dao_label: Label = %DaoLabel
@onready var cultivate_button: Button = %CultivateButton
@onready var breakthrough_button: Button = %BreakthroughButton
@onready var cultivation_background_art: TextureRect = %CultivationBackgroundArt
@onready var meditation_art: TextureRect = %MeditationArt

func _ready() -> void:
	_apply_art()
	cultivate_button.icon = IconLoader.get_skill_icon("azure_slash")
	breakthrough_button.icon = IconLoader.get_item_icon("breakthrough_stone")
	_refresh()
	PlayerState.cultivation_changed.connect(_refresh)
	PlayerState.inventory_changed.connect(_refresh)

func _apply_art() -> void:
	var art := ArtLoader.load_texture_safe(CULTIVATION_BG_PATH)
	if art != null:
		cultivation_background_art.texture = art
		meditation_art.texture = art

func _refresh() -> void:
	var cult := PlayerState.get_cultivation()
	var stage_id := str(cult.get("current_stage_id", ""))
	stage_label.text = "%s %s" % ["[ГОТОВ]" if bool(cult.get("breakthrough_ready", false)) else "[ПУТЬ]", ConfigRepository.get_stage_name(stage_id)]
	qi_label.text = "Ци: %d / %d" % [int(cult.get("qi_exp", 0)), int(cult.get("qi_exp_required", 1))]
	body_label.text = "Тело: %d" % int(cult.get("body_refinement_level", 0))
	spirit_label.text = "Дух: %d" % int(cult.get("spirit_refinement_level", 0))
	dao_label.text = "Дао-сердце: %d" % int(cult.get("dao_heart_level", 0))
	var ready := bool(cult.get("breakthrough_ready", false))
	var has_stone := _has_breakthrough_stone()
	if ready and has_stone:
		status_label.text = "Прорыв готов · Камень прорыва найден"
		status_label.modulate = UITheme.COLOR_SUCCESS
	elif ready:
		status_label.text = "Прорыв готов, но нужен Камень прорыва"
		status_label.modulate = UITheme.COLOR_GOLD
	else:
		status_label.text = "Нужна дальнейшая культивация"
		status_label.modulate = UITheme.COLOR_TEXT
	breakthrough_button.disabled = not (ready and has_stone)
	breakthrough_button.text = "Прорыв" if has_stone else "Нужен камень"

func _has_breakthrough_stone() -> bool:
	for entry in PlayerState.get_inventory():
		if str(entry.get("item_id", "")) == "breakthrough_stone" and int(entry.get("quantity", 0)) > 0:
			return true
	return false

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")

func _on_cultivate_pressed() -> void:
	if not PlayerState.spend_currency("bound_spirit_stone", 25):
		status_label.text = "Недостаточно связанных духовных камней"
		status_label.modulate = UITheme.COLOR_DANGER
		return
	PlayerState.add_qi(2500000)
	status_label.text = "Культивация успешна"
	status_label.modulate = UITheme.COLOR_SUCCESS

func _on_breakthrough_pressed() -> void:
	var result_text := PlayerState.perform_breakthrough()
	status_label.text = result_text
	status_label.modulate = UITheme.COLOR_SUCCESS if result_text.begins_with("Прорыв успешен") else UITheme.COLOR_GOLD

func _on_body_pressed() -> void:
	PlayerState.refine_body()
	status_label.text = "Тело укреплено"
	status_label.modulate = UITheme.COLOR_SUCCESS

func _on_spirit_pressed() -> void:
	PlayerState.refine_spirit()
	status_label.text = "Дух очищен"
	status_label.modulate = UITheme.COLOR_SUCCESS

func _on_dao_pressed() -> void:
	PlayerState.refine_dao_heart()
	status_label.text = "Дао-сердце стало сильнее"
	status_label.modulate = UITheme.COLOR_SUCCESS
