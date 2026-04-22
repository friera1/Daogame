extends Control

const BATTLE_BG_PATH := "res://assets/art/generated/battle_background_primary.png"
const BATTLE_STAMINA_COST := 6

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
var player_hp_max := 1200
var battle_over := false
var battle_context: Dictionary = {}

func _ready() -> void:
	battle_context = GameSession.get_battle_context()
	_apply_art()
	player_name.text = PlayerState.get_name()
	enemy_name.text = str(battle_context.get("enemy_name", "Страж духовных руин"))
	var source := str(battle_context.get("source", ""))
	if source == "event_dungeon":
		var event_start := GameSession.begin_event_dungeon_run()
		if not bool(event_start.get("ok", false)):
			_append_log(str(event_start.get("text", "Ивент-подземелье недоступно")))
			_disable_skills()
			await get_tree().create_timer(1.2).timeout
			SceneRouter.goto_scene("res://scenes/events/DailyMissionsScreen.tscn")
			return
		_append_log("Потрачено энергии: %d" % int(event_start.get("stamina_cost", 0)))
		_append_log("Осталось попыток события: %d" % int(event_start.get("remaining_runs", 0)))
	elif source == "guild_boss":
		var guild_start := GameSession.begin_guild_boss_run()
		if not bool(guild_start.get("ok", false)):
			_append_log(str(guild_start.get("text", "Босс ордена недоступен")))
			_disable_skills()
			await get_tree().create_timer(1.2).timeout
			SceneRouter.goto_scene("res://scenes/guild/GuildScreen.tscn")
			return
		_append_log("Потрачено энергии: %d" % int(guild_start.get("stamina_cost", 0)))
		_append_log("Осталось попыток босса: %d" % int(guild_start.get("remaining_runs", 0)))
		_append_log("Прогресс босса ордена: %d%%" % int(guild_start.get("progress", 0)))
	elif source == "arena":
		var arena_start := GameSession.begin_arena_run(int(battle_context.get("opponent_index", 0)))
		if not bool(arena_start.get("ok", false)):
			_append_log(str(arena_start.get("text", "Арена недоступна")))
			_disable_skills()
			await get_tree().create_timer(1.2).timeout
			SceneRouter.goto_scene("res://scenes/events/DailyMissionsScreen.tscn")
			return
		var opponent := arena_start.get("opponent", {})
		enemy_name.text = str(opponent.get("name", enemy_name.text))
		_append_log("Арена: выбран соперник ранга #%d" % int(opponent.get("rank", 999)))
		_append_log("Осталось попыток арены: %d" % int(arena_start.get("remaining_runs", 0)))
	else:
		var stamina_cost := _battle_stamina_cost()
		if not PlayerState.spend_stamina(stamina_cost):
			_append_log("Недостаточно энергии: нужно %d" % stamina_cost)
			_disable_skills()
			await get_tree().create_timer(1.2).timeout
			SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
			return
		_append_log("Потрачено энергии: %d" % stamina_cost)
	_apply_context_scaling()
	_append_log("Бой начался")
	_refresh()

func _battle_node_type() -> String:
	return str(battle_context.get("node_type", "battle"))

func _battle_stamina_cost() -> int:
	if str(battle_context.get("source", "")) == "story":
		return GameSession.get_story_sweep_cost(_battle_node_type()) + 2
	return BATTLE_STAMINA_COST

func _battle_multiplier() -> float:
	var source := str(battle_context.get("source", ""))
	if source == "event_dungeon":
		return 1.55
	if source == "guild_boss":
		return 2.1
	if source == "arena":
		return 1.25
	match _battle_node_type():
		"elite_battle":
			return 1.35
		"boss_battle":
			return 1.8
		_:
			return 1.0

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
	var mult := _battle_multiplier()
	var support_bonus := int(battle_context.get("support_bonus", 0))
	enemy_hp_value = int(floor(float(enemy_hp_value + (chapter_index - 1) * 220 + stage_bonus * 60) * mult))
	player_hp_value += stage_bonus * 40 + support_bonus
	player_hp_max = player_hp_value
	_append_log("Контекст боя: глава %d, стадия %s" % [chapter_index, ConfigRepository.get_stage_name(stage_id)])
	if support_bonus > 0:
		_append_log("Support unit усиливает тебя на +%d HP" % support_bonus)
	var source := str(battle_context.get("source", ""))
	if source == "event_dungeon":
		_append_log("Лимитированное подземелье активно: усиленные трофеи и дневные попытки")
	elif source == "guild_boss":
		_append_log("Босс ордена активен: недельный лимит заходов и усиленные награды")
	elif source == "arena":
		_append_log("Арена активна: асинхронный PvP бой за сезонный рейтинг")
	elif _battle_node_type() == "elite_battle":
		_append_log("Элитный враг усиливает награды и сложность")
	elif _battle_node_type() == "boss_battle":
		_append_log("Босс-узел активен: повышенная цена входа и редкие трофеи")

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
	var source := str(battle_context.get("source", ""))
	if source == "event_dungeon":
		return GameSession.get_event_dungeon_rewards(victory)
	if source == "guild_boss":
		return GameSession.get_guild_boss_rewards(victory)
	if source == "arena":
		return GameSession.get_arena_rewards(victory)
	return GameSession._build_story_rewards(int(battle_context.get("chapter_index", 1)), _battle_node_type(), victory) if source == "story" else {"gold": 320, "qi_essence": 18, "spirit_stone": 1, "items": [{"id": "qi_pill_small", "quantity": 1, "rarity": "rare"}]}

func _story_battle_stars(victory: bool) -> int:
	if not victory:
		return 0
	var hp_ratio := 0.0
	if player_hp_max > 0:
		hp_ratio = float(player_hp_value) / float(player_hp_max)
	var stars := 1
	if hp_ratio >= 0.5:
		stars += 1
	if hp_ratio >= 0.85:
		stars += 1
	return clamp(stars, 1, 3)

func _finalize_battle(victory: bool) -> void:
	var stars := _story_battle_stars(victory) if str(battle_context.get("source", "")) == "story" else 0
	if stars > 0:
		_append_log("Получено звёзд: %d" % stars)
	GameSession.last_battle_result = {"victory": victory, "claimed": false, "stars": stars, "context": battle_context, "rewards": _build_rewards(victory)}
	await get_tree().create_timer(1.0).timeout
	SceneRouter.goto_scene("res://scenes/battle/BattleResultScreen.tscn")

func _enemy_turn() -> void:
	if battle_over:
		return
	var damage := int(floor((90 + int(battle_context.get("chapter_index", 1) - 1) * 18) * _battle_multiplier()))
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
	player_hp_value = min(player_hp_value + shield, player_hp_max)
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
