extends Control

const LOBBY_BG_PATH := "res://assets/art/generated/lobby_background_primary.png"
const HERO_ART_PATH := "res://assets/art/generated/hero_fullbody_primary.png"
const TUTORIAL_OVERLAY_SCENE := preload("res://scenes/tutorial/TutorialOverlay.tscn")
const IconLoader = preload("res://scripts/ui/IconLoader.gd")

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
@onready var sync_status_label: Label = %SyncStatusLabel
@onready var sync_flush_button: Button = %SyncFlushButton
@onready var lobby_background_art: TextureRect = %LobbyBackgroundArt
@onready var hero_art: TextureRect = %HeroArt
@onready var hero_hint: Label = %HeroHint
@onready var hero_title: Label = %HeroTitle
@onready var hero_silhouette: ColorRect = %HeroSilhouette
@onready var spirit_stone_icon: TextureRect = %SpiritStoneIcon
@onready var bound_stone_icon: TextureRect = %BoundStoneIcon
@onready var jade_icon: TextureRect = %JadeIcon

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_apply_visual_polish()
	_apply_art()
	_apply_icons()
	_refresh()
	PlayerState.player_loaded.connect(_refresh)
	PlayerState.cultivation_changed.connect(_refresh)
	PlayerState.currencies_changed.connect(_refresh)
	PlayerState.skills_changed.connect(_refresh)
	PlayerState.pets_changed.connect(_refresh)
	_show_idle_status()
	_maybe_show_tutorial()

func _maybe_show_tutorial() -> void:
	var tutorial := PlayerState.get_tutorial()
	if bool(tutorial.get("completed", false)):
		return
	var overlay := TUTORIAL_OVERLAY_SCENE.instantiate()
	add_child(overlay)

func _apply_visual_polish() -> void:
	cta_button.add_theme_font_size_override("font_size", 28)
	cta_button.add_theme_color_override("font_color", UITheme.COLOR_BG)
	cta_button.modulate = UITheme.COLOR_GOLD
	status_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	sync_status_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
	sync_flush_button.add_theme_font_size_override("font_size", 16)
	UITheme.apply_accent_button(sync_flush_button, false)
	hero_title.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	hero_title.add_theme_font_size_override("font_size", 28)
	hero_hint.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	hero_silhouette.color = Color(UITheme.COLOR_JADE_DARK, 0.22)

func _apply_art() -> void:
	var bg := ArtLoader.load_texture_safe(LOBBY_BG_PATH)
	if bg != null:
		lobby_background_art.texture = bg
	var hero := ArtLoader.load_texture_safe(HERO_ART_PATH)
	if hero != null:
		hero_art.texture = hero
		hero_hint.text = ""

func _apply_icons() -> void:
	spirit_stone_icon.texture = IconLoader.get_currency_icon("spirit_stone")
	bound_stone_icon.texture = IconLoader.get_currency_icon("bound_spirit_stone")
	jade_icon.texture = IconLoader.get_currency_icon("jade")
	cta_button.icon = IconLoader.get_skill_icon("azure_slash")
	sync_flush_button.icon = IconLoader.get_skill_icon("jade_guard")
	$LeftMenu/StoryButton.icon = IconLoader.get_skill_icon("jade_guard")
	$LeftMenu/EventsButton.icon = IconLoader.get_item_icon("breakthrough_stone")
	$LeftMenu/GuildButton.icon = IconLoader.get_currency_icon("jade")
	$LeftMenu/DailyButton.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	$LeftMenu/BattleButton.icon = IconLoader.get_skill_icon("azure_slash")
	$RightMenu/InventoryButton.icon = IconLoader.get_item_icon("breakthrough_stone")
	$RightMenu/SkillsButton.icon = IconLoader.get_skill_icon("azure_slash")
	$RightMenu/PetButton.icon = IconLoader.get_currency_icon("jade")
	$RightMenu/ShopButton.icon = IconLoader.get_currency_icon("spirit_stone")
	$RightMenu/SummonButton.icon = IconLoader.get_currency_icon("jade")
	$BottomNav/CharacterButton.icon = IconLoader.get_currency_icon("jade")
	$BottomNav/BottomStoryButton.icon = IconLoader.get_skill_icon("jade_guard")
	$BottomNav/BottomGuildButton.icon = IconLoader.get_currency_icon("jade")
	$BottomNav/BottomHomeButton.icon = IconLoader.get_currency_icon("bound_spirit_stone")
	$BottomNav/SocialButton.icon = IconLoader.get_currency_icon("spirit_stone")

func _refresh() -> void:
	name_label.text = PlayerState.get_name()
	level_label.text = "Ур. %d" % PlayerState.get_level()
	power_label.text = "Сила: %d" % PlayerState.get_power()
	hero_title.text = PlayerState.get_name()

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
	_refresh_sync_status()

func _refresh_sync_status() -> void:
	var sync := OnlineSyncService.get_sync_status()
	sync_status_label.text = "SYNC rev.%d · pending %d" % [int(sync.get("local_revision", 0)), int(sync.get("pending_count", 0))]
	sync_status_label.modulate = UITheme.COLOR_GOLD if int(sync.get("pending_count", 0)) > 0 else UITheme.COLOR_SUCCESS

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

func _on_sync_flush_pressed() -> void:
	OnlineSyncService.flush_pending_mock()
	status_label.text = "Очередь синхронизации очищена mock-flush"
	status_label.modulate = UITheme.COLOR_SUCCESS
	_refresh_sync_status()

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

func _on_shop_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/shop/ShopScreen.tscn")

func _on_summon_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/shop/SummonScreen.tscn")

func _on_guild_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/guild/GuildScreen.tscn")

func _on_battle_pressed() -> void:
	GameSession.set_battle_context({
		"source": "lobby",
		"chapter_index": 1,
		"enemy_name": "Страж духовных руин"
	})
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _on_stub_pressed(feature_name: String) -> void:
	print("%s пока в разработке" % feature_name)
