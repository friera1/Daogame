extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var list_container: VBoxContainer = %SkillList
@onready var detail_label: RichTextLabel = %DetailLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh()
	PlayerState.skills_changed.connect(_refresh)

func _refresh() -> void:
	for child in list_container.get_children():
		child.queue_free()
	var skills := PlayerState.get_skills()
	for entry in skills:
		var skill_id := str(entry.get("skill_id", ""))
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.apply_card(card, UITheme.COLOR_JADE_DARK)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = IconLoader.get_skill_icon(skill_id)
		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = "%s · ур. %d" % [_get_skill_name(skill_id), int(entry.get("level", 1))]
		var upgrade_button := Button.new()
		upgrade_button.text = "Усилить"
		upgrade_button.icon = IconLoader.get_skill_icon(skill_id)
		UITheme.apply_accent_button(upgrade_button, true)
		upgrade_button.pressed.connect(_on_upgrade_pressed.bind(skill_id))
		var show_button := Button.new()
		show_button.text = "Детали"
		show_button.icon = IconLoader.get_skill_icon("jade_guard")
		UITheme.apply_accent_button(show_button, false)
		show_button.pressed.connect(_show_skill.bind(skill_id))
		row.add_child(icon)
		row.add_child(name_label)
		row.add_child(show_button)
		row.add_child(upgrade_button)
		list_container.add_child(card)
	if skills.size() > 0:
		_show_skill(str(skills[0].get("skill_id", "")))

func _get_skill_name(skill_id: String) -> String:
	return ConfigRepository.get_skill_name(skill_id)

func _show_skill(skill_id: String) -> void:
	for skill in ConfigRepository.skills.get("skills", []):
		if str(skill.get("id", "")) == skill_id:
			detail_label.text = "[b]%s[/b]\n\nМножитель: %s\nКД: %s\nЭлемент: %s" % [
				str(skill.get("name", skill_id)),
				str(skill.get("multiplier", "-")),
				str(skill.get("cooldown", "-")),
				str(skill.get("element", skill.get("effect", "neutral")))
			]
			return
	detail_label.text = "Навык не найден"

func _on_upgrade_pressed(skill_id: String) -> void:
	if PlayerState.upgrade_skill(skill_id):
		_show_skill(skill_id)

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
