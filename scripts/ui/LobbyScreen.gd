extends Control

@onready var name_label: Label = %NameLabel
@onready var level_label: Label = %LevelLabel
@onready var stage_label: Label = %StageLabel
@onready var progress_label: Label = %ProgressLabel
@onready var power_label: Label = %PowerLabel
@onready var stones_label: Label = %StonesLabel
@onready var bound_label: Label = %BoundLabel
@onready var jade_label: Label = %JadeLabel
@onready var cta_button: Button = %MainCTAButton
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	_refresh()
	PlayerState.player_loaded.connect(_refresh)
	PlayerState.cultivation_changed.connect(_refresh)
	PlayerState.currencies_changed.connect(_refresh)
	PlayerState.skills_changed.connect(_refresh)
	PlayerState.pets_changed.connect(_refresh)
	_show_idle_status()

func _refresh() -> void:
	name_label.text = PlayerState.get_name()
	level_label.text = "Ур. %d" % PlayerState.get_level()
	power_label.text = "Сила: %d" % PlayerState.get_power()

	var cult := PlayerState.get_cultivation()
	var stage_id := str(cult.get("current_stage_id", "mortal_early"))
	stage_label.text = ConfigRepository.get_stage_name(stage_id)
	progress_label.text = "%s / %s" % [_format_big(int(cult.get("qi_exp", 0))), _format_big(int(cult.get("qi_exp_required", 1)))]

	var currencies := PlayerState.get_currencies()
	stones_label.text = str(currencies.get("spirit_stone", 0))
	bound_label.text = str(currencies.get("bound_spirit_stone", 0))
	jade_label.text = str(currencies.get("jade", 0))

	if bool(cult.get("breakthrough_ready", false)):
		cta_button.text = "Прорыв"
	else:
		cta_button.text = "Культивация"

func _show_idle_status() -> void:
	var rewards := IdleRewardService.calculate_rewards()
	var seconds := int(rewards.get("seconds", 0))
	if seconds <= 0:
		status_label.text = "Мир спокоен. Новых оффлайн-наград пока нет."
		return
	status_label.text = "Оффлайн: %s золота, %s эссенции Ци" % [str(rewards.get("gold", 0)), str(rewards.get("qi_essence", 0))]

func _format_big(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)

func _on_cultivation_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/cultivation/CultivationScreen.tscn")

func _on_character_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/character/CharacterScreen.tscn")

func _on_inventory_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/inventory/InventoryScreen.tscn")

func _on_skills_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/skills/SkillsScreen.tscn")

func _on_pets_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/pets/PetScreen.tscn")

func _on_story_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/story/StoryScreen.tscn")

func _on_daily_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/events/DailyMissionsScreen.tscn")

func _on_mail_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/social/MailScreen.tscn")

func _on_battle_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _on_stub_pressed(feature_name: String) -> void:
	print("%s пока в разработке" % feature_name)
