extends Control

@onready var list_container: VBoxContainer = %SkillList
@onready var detail_label: RichTextLabel = %DetailLabel

func _ready() -> void:
	_refresh()
	PlayerState.skills_changed.connect(_refresh)

func _refresh() -> void:
	for child in list_container.get_children():
		child.queue_free()
	var skills := PlayerState.get_skills()
	for entry in skills:
		var skill_id := str(entry.get("skill_id", ""))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = "%s · ур. %d" % [_get_skill_name(skill_id), int(entry.get("level", 1))]
		var upgrade_button := Button.new()
		upgrade_button.text = "Усилить"
		upgrade_button.pressed.connect(_on_upgrade_pressed.bind(skill_id))
		row.add_child(name_label)
		row.add_child(upgrade_button)
		list_container.add_child(row)
	if skills.size() > 0:
		_show_skill(str(skills[0].get("skill_id", "")))

func _get_skill_name(skill_id: String) -> String:
	for skill in ConfigRepository.skills.get("skills", []):
		if str(skill.get("id", "")) == skill_id:
			return str(skill.get("name", skill_id))
	return skill_id

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
