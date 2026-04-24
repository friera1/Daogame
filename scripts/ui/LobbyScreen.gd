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
@onready var sync_meta_label: Label = %SyncMetaLabel
@onready var sync_reconnect_button: Button = %SyncReconnectButton
@onready var sync_ack_button: Button = %SyncAckButton
@onready var sync_flush_button: Button = %SyncFlushButton
@onready var lobby_background_art: TextureRect = %LobbyBackgroundArt
@onready var hero_art: TextureRect = %HeroArt
@onready var hero_hint: Label = %HeroHint
@onready var hero_title: Label = %HeroTitle
@onready var hero_silhouette: ColorRect = %HeroSilhouette
@onready var spirit_stone_icon: TextureRect = %SpiritStoneIcon
@onready var bound_stone_icon: TextureRect = %BoundStoneIcon
@onready var jade_icon: TextureRect = %JadeIcon
@onready var mail_button: Button = $TopBar/TopMargin/TopHBox/MailButton

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
	PlayerState.stamina_changed.connect(_refresh)
	PlayerState.mailbox_changed.connect(_refresh)
	_show_idle_status()
	_maybe_show_tutorial()

func _maybe_show_tutorial() -> void:
	var tutorial := PlayerState.get_tutorial()
	if bool(tutorial.get("completed", false)):
		return
	var overlay := TUTORIAL_OVERLAY_SCENE.instantiate()
	add_child(overlay)

func _style_menu_button(button: Button, is_primary: bool = false) -> void:
	button.custom_minimum_size = Vector2(128, 54)
	button.add_theme_font_size_override("font_size", 17)
	button.text = button.text.strip_edges()
	UITheme.apply_accent_button(button, is_primary)
	if not is_primary:
		button.add_theme_stylebox_override("normal", UITheme.make_button_style(Color(UITheme.COLOR_PANEL_ALT, 0.86), Color(UITheme.COLOR_JADE_DARK, 0.55), UITheme.COLOR_TEXT))
		button.add_theme_stylebox_override("hover", UITheme.make_button_style(Color(UITheme.COLOR_CARD_SOFT, 0.95), UITheme.COLOR_JADE_LIGHT, UITheme.COLOR_TEXT))

func _style_menu_container(path: NodePath) -> void:
	var node := get_node_or_null(path)
	if node == null:
		return
	if node is VBoxContainer or node is HBoxContainer:
		node.add_theme_constant_override("separation", 8)
	for child in node.get_children():
		if child is Button:
			_style_menu_button(child, false)

func _apply_visual_polish() -> void:
	var bg_panel := StyleBoxFlat.new()
	bg_panel.bg_color = UITheme.COLOR_BG
	add_theme_stylebox_override("panel", bg_panel)
	UITheme.style_title(name_label)
	UITheme.style_title(hero_title)
	level_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	stage_label.add_theme_color_override("font_color", UITheme.COLOR_JADE_LIGHT)
	progress_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	power_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SOFT)
	status_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	status_label.add_theme_font_size_override("font_size", 17)
	sync_status_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT)
	sync_status_label.add_theme_font_size_override("font_size", 15)
	sync_meta_label.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	sync_meta_label.add_theme_font_size_override("font_size", 13)
	hero_title.add_theme_font_size_override("font_size", 30)
	hero_hint.add_theme_color_override("font_color", UITheme.COLOR_TEXT_SECONDARY)
	hero_hint.add_theme_font_size_override("font_size", 15)
	hero_silhouette.color = Color(UITheme.COLOR_JADE_DARK, 0.16)
	cta_button.custom_minimum_size = Vector2(0, 64)
	cta_button.add_theme_font_size_override("font_size", 24)
	UITheme.apply_accent_button(cta_button, true)
	_style_menu_container("LeftMenu")
	_style_menu_container("RightMenu")
	_style_menu_container("BottomNav")
	for button in [sync_reconnect_button, sync_ack_button, sync_flush_button, mail_button]:
		button.add_theme_font_size_override("font_size", 14)
		button.custom_minimum_size.y = 42
	UITheme.apply_accent_button(sync_reconnect_button, false)
	UITheme.apply_accent_button(sync_ack_button, true)
	UITheme.apply_accent_button(sync_flush_button, false)
	UITheme.apply_accent_button(mail_button, false)
	for icon in [spirit_stone_icon, bound_stone_icon, jade_icon]:
		icon.custom_minimum_size = Vector2(28, 28)
	for label in [stones_label, bound_label, jade_label]:
		label.add_theme_font_size_override("font_size", 17)
		label.add_theme_color_override("font_color", UITheme.COLOR_TEXT)

func _apply_art() -> void:
	var bg := ArtLoader.load_texture_safe(LOBBY_BG_PATH)
	if bg != null:
		lobby_background_art.texture = bg
		lobby_background_art.modulate = Color(0.75, 0.9, 1, 0.72)
	var hero := ArtLoader.load_texture_safe(HERO_ART_PATH)
	if hero != null:
		hero_art.texture = hero
		hero_art.modulate = Color(1, 1, 1, 0.96)
		hero_hint.text = ""

func _apply_icons() -> void:
	spirit_stone_icon.texture = IconLoader.get_currency_icon("spirit_stone")
	bound_stone_icon.texture = IconLoader.get_currency_icon("bound_spirit_stone")
	jade_icon.texture = IconLoader.get_currency_icon("jade")
	cta_button.icon = IconLoader.get_skill_icon("azure_slash")
	sync_reconnect_button.icon = IconLoader.get_skill_icon("jade_guard")
	sync_ack_button.icon = IconLoader.get_currency_icon("jade")
	sync_flush_button.icon = IconLoader.get_skill_icon("azure_slash")
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
	hero_title.text = PlayerState.get_name()
	var cult := PlayerState.get_cultivation()
	var stage_id := str(cult.get("current_stage_id", "mortal_early"))
	stage_label.text = ConfigRepository.get_stage_name(stage_id)
	progress_label.text = "Ци: %s / %s" % [_format_big(int(cult.get("qi_exp", 0))), _format_big(int(cult.get("qi_exp_required", 1)))]
	var stamina := PlayerState.refresh_stamina()
	power_label.text = "⚔ %d   •   ⚡ %d/%d" % [PlayerState.get_power(), int(stamina.get("current", 0)), int(stamina.get("max", 30))]
	var currencies := PlayerState.get_currencies()
	stones_label.text = _format_big(int(currencies.get("spirit_stone", 0)))
	bound_label.text = _format_big(int(currencies.get("bound_spirit_stone", 0)))
	jade_label.text = _format_big(int(currencies.get("jade", 0)))
	var mail_count := PlayerState.get_unclaimed_mail_count()
	mail_button.text = "Почта" if mail_count <= 0 else "Почта %d" % mail_count
	mail_button.modulate = UITheme.COLOR_GOLD if mail_count > 0 else Color(1, 1, 1, 1)
	cta_button.text = "Прорыв готов" if bool(cult.get("breakthrough_ready", false)) else "Культивировать"
	_refresh_sync_status()

func _format_ack_time(timestamp: int) -> String:
	if timestamp <= 0:
		return "never"
	return Time.get_datetime_string_from_unix_time(timestamp, true)

func _refresh_sync_status() -> void:
	var sync := OnlineSyncService.get_sync_status()
	var pending := int(sync.get("pending_count", 0))
	var state := str(sync.get("reconnect_state", "live"))
	sync_status_label.text = "SYNC %s · rev.%d · pending %d" % [state, int(sync.get("local_revision", 0)), pending]
	if state == "restored" or state == "reconnected":
		sync_status_label.modulate = UITheme.COLOR_GOLD
	elif pending > 0:
		sync_status_label.modulate = UITheme.COLOR_WARNING
	else:
		sync_status_label.modulate = UITheme.COLOR_SUCCESS
	sync_meta_label.text = "restore %d · ack %s" % [int(sync.get("restored_event_count", 0)), _format_ack_time(int(sync.get("last_ack_time", 0)))]
	sync_ack_button.disabled = pending <= 0

func _show_idle_status() -> void:
	var rewards := IdleRewardService.calculate_rewards()
	var seconds := int(rewards.get("seconds", 0))
	if seconds <= 0:
		status_label.text = "Мир спокоен · оффлайн-наград пока нет"
		return
	status_label.text = "Оффлайн: %s золота · %s эссенции" % [str(rewards.get("gold", 0)), str(rewards.get("qi_essence", 0))]

func _format_big(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)

func _on_sync_reconnect_pressed() -> void:
	OnlineSyncService.simulate_reconnect()
	status_label.text = "Mock reconnect выполнен"
	status_label.modulate = UITheme.COLOR_SUCCESS
	_refresh_sync_status()

func _on_sync_ack_pressed() -> void:
	var acked := OnlineSyncService.ack_pending_mock()
	status_label.text = "Подтверждено сервером событий: %d" % acked
	status_label.modulate = UITheme.COLOR_SUCCESS
	_refresh_sync_status()

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
	var stamina := PlayerState.refresh_stamina()
	if int(stamina.get("current", 0)) < 6:
		status_label.text = "Недостаточно энергии для боя · нужно 6"
		status_label.modulate = UITheme.COLOR_WARNING
		return
	GameSession.set_battle_context({"source": "lobby", "chapter_index": 1, "enemy_name": "Страж духовных руин"})
	SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")

func _on_stub_pressed(feature_name: String) -> void:
	print("%s пока в разработке" % feature_name)
