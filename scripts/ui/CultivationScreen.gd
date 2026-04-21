extends Control

@onready var stage_label: Label = %StageLabel
@onready var qi_label: Label = %QiLabel
@onready var status_label: Label = %StatusLabel
@onready var cultivate_button: Button = %CultivateButton
@onready var breakthrough_button: Button = %BreakthroughButton

func _ready() -> void:
	_refresh()
	PlayerState.cultivation_changed.connect(_refresh)

func _refresh() -> void:
	var cult := PlayerState.get_cultivation()
	stage_label.text = ConfigRepository.get_stage_name(str(cult.get("current_stage_id", "")))
	qi_label.text = "Ци: %d / %d" % [int(cult.get("qi_exp", 0)), int(cult.get("qi_exp_required", 1))]
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
	status_label.text = "Анимация прорыва и новая стадия будут следующим шагом"
	status_label.modulate = UITheme.COLOR_GOLD
