extends Control

@onready var player_name: Label = %PlayerName
@onready var player_hp: Label = %PlayerHP
@onready var enemy_name: Label = %EnemyName
@onready var enemy_hp: Label = %EnemyHP
@onready var battle_log: RichTextLabel = %BattleLog
@onready var skill_1: Button = %Skill1Button
@onready var skill_2: Button = %Skill2Button
@onready var ultimate_button: Button = %UltimateButton

var player_hp_value := 1200
var enemy_hp_value := 1800
var battle_over := false

func _ready() -> void:
	player_name.text = PlayerState.get_name()
	enemy_name.text = "Страж духовных руин"
	_append_log("Бой начался")
	_refresh()

func _refresh() -> void:
	player_hp.text = "HP: %d" % player_hp_value
	enemy_hp.text = "HP: %d" % enemy_hp_value
	if enemy_hp_value <= 0 and not battle_over:
		battle_over = true
		_append_log("Победа")
		_finalize_battle(true)
		_disable_skills()
	if player_hp_value <= 0 and not battle_over:
		battle_over = true
		_append_log("Поражение")
		_finalize_battle(false)
		_disable_skills()

func _append_log(text: String) -> void:
	battle_log.text += "• %s\n" % text

func _disable_skills() -> void:
	skill_1.disabled = true
	skill_2.disabled = true
	ultimate_button.disabled = true

func _finalize_battle(victory: bool) -> void:
	GameSession.last_battle_result = {
		"victory": victory,
		"rewards": {
			"gold": 320 if victory else 80,
			"qi_essence": 18 if victory else 6,
			"spirit_stone": 1 if victory else 0,
		}
	}
	await get_tree().create_timer(1.0).timeout
	SceneRouter.goto_scene("res://scenes/battle/BattleResultScreen.tscn")

func _enemy_turn() -> void:
	if battle_over:
		return
	var damage := 90
	player_hp_value = max(player_hp_value - damage, 0)
	_append_log("Противник наносит %d урона" % damage)
	_refresh()

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")

func _on_skill_1_pressed() -> void:
	if battle_over:
		return
	var damage := 160
	enemy_hp_value = max(enemy_hp_value - damage, 0)
	_append_log("Лазурный разрез наносит %d урона" % damage)
	_refresh()
	_enemy_turn()

func _on_skill_2_pressed() -> void:
	if battle_over:
		return
	var shield := 70
	player_hp_value = min(player_hp_value + shield, 1200)
	_append_log("Нефритовый щит восстанавливает устойчивость на %d" % shield)
	_refresh()
	_enemy_turn()

func _on_ultimate_pressed() -> void:
	if battle_over:
		return
	var damage := 420
	enemy_hp_value = max(enemy_hp_value - damage, 0)
	_append_log("Цветение души наносит %d урона" % damage)
	_refresh()
	if not battle_over:
		_enemy_turn()
