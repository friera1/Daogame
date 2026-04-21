extends Control

const CULTIVATION_BG_PATH := "res://assets/art/generated/cultivation_background_primary.png"

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
	_refresh()
	PlayerState.cultivation_changed.connect(_refresh)

func _apply_art() -> void:
	var art := ArtLoader.load_texture_safe(CULTIVATION_BG_PATH)
	if art != null:
		cultivation_background_art.texture = art
		meditation_art.texture = art

func _refresh() -> void:
	var cult := PlayerState.get_cultivation()
	stage_label.text = ConfigRepository.get_stage_name(str(cult.get("current_stage_id", "")))
	qi_label.text = "Ци: %d / %d" % [int(cult.get("qi_exp", 0)), int(cult.get("qi_exp_required", 1))]
	body_label.text = "Тело: %d" % int(cult.get("body_refinement_level", 0))
	spirit_label.text = "Дух: %d" % int(cult.get("spirit_refinement_level", 0))
	dao_label.text = "Дао-сердце: %d" % int(cult.get("dao_heart_level", 0))
	var ready := bool(cult.get("breakthrough_ready", false))
	status_label.text = "Прорыв готов" if ready else "Нужна дальнейшая культивация"
	status_label.modulate = UITheme.COLOR_SUCCESS if ready else UITheme.COLOR_TEXT
	breakthrough_button.disabled = not ready

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
	status_label.text = "Безопасный прорыв будет следующим шагом vertical slice"
	status_label.modulate = UITheme.COLOR_GOLD

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
