extends Control

const BATTLE_BG_PATH := "res://assets/art/generated/battle_background_primary.png"

@onready var player_name: Label = %PlayerName
@onready var player_hp: Label = %PlayerHP
@onready var enemy_name: Label = %EnemyName
@onready var enemy_hp: Label = %EnemyHP
@onready var battle_log: RichTextLabel = %BattleLog
@onready var skill_1: Button = %Skill1Button
@onready var skill_2: Button = %Skill2Button
@onready var ultimate_button: Button = %UltimateButton
@onready var battle_background_art: TextureRect = %BattleBackgroundArt
@onready var arena_backdrop_art: TextureRect = %ArenaBackdropArt

var player_hp_value := 1200
var enemy_hp_value := 1800
var battle_over := false
var battle_context: Dictionary = {}

func _ready() -> void:
	battle_context = GameSession.get_battle_context()
	_apply_art()
	player_name.text = PlayerState.get_name()
	enemy_name.text = str(battle_context.get("enemy_name", "Страж духовных руин"))
	_apply_context_scaling()
	_append_log("Бой начался")
	_refresh()

func _apply_art() -> void:
	var art := ArtLoader.load_texture_safe(BATTLE_BG_PATH)
	if art != null:
		battle_background_art.texture = art
		arena_backdrop_art.texture = art

func _apply_context_scaling() -> void:
	var chapter_index := int(battle_context.get("chapter_index", 1))
	var cult := PlayerState.get_cultivation()
	var stage_id := str(cult.get("current_stage_id", "mortal_early"))
	var stage_bonus := 0
	var stages := ConfigRepository.stages.get("stages", [])
	for i in range(stages.size()):
		if str(stages[i].get("id", "")) == stage_id:
			stage_bonus = i
			break
	enemy_hp_value += (chapter_index - 1) * 220 + stage_bonus * 60
	player_hp_value += stage_bonus * 40
	_append_log("Контекст боя: глава %d, стадия %s" % [chapter_index, ConfigRepository.get_stage_name(stage_id)])

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

func _build_rewards(victory: bool) -> Dictionary:
	var chapter_index := int(battle_context.get("chapter_index", 1))
	var gold := (320 if victory else 80) + (chapter_index - 1) * 140
	var qi_essence := (18 if victory else 6) + (chapter_index - 1) * 8
	var spirit_stone := (1 if victory else 0) + (1 if victory and chapter_index >= 3 else 0)
	var items: Array = []
	if victory:
		items.append({"id": "qi_pill_small", "quantity": 1 + int(chapter_index >= 2), "rarity": "rare"})
		if chapter_index >= 3:
			items.append({"id": "breakthrough_stone", "quantity": 1, "rarity": "epic"})
	return {
		"gold": gold,
		"qi_essence": qi_essence,
		"spirit_stone": spirit_stone,
		"items": items
	}

func _finalize_battle(victory: bool) -> void:
	GameSession.last_battle_result = {
		"victory": victory,
		"claimed": false,
		"context": battle_context,
		"rewards": _build_rewards(victory)
	}
	await get_tree().create_timer(1.0).timeout
	SceneRouter.goto_scene("res://scenes/battle/BattleResultScreen.tscn")

func _enemy_turn() -> void:
	if battle_over:
		return
	var damage := 90 + int(battle_context.get("chapter_index", 1) - 1) * 18
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
