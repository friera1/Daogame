extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var chapter_list: VBoxContainer = %ChapterList
@onready var node_list: VBoxContainer = %NodeList
@onready var info_label: RichTextLabel = %InfoLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh_chapters()

func _refresh_chapters() -> void:
	for child in chapter_list.get_children():
		child.queue_free()
	for child in node_list.get_children():
		child.queue_free()
	for chapter in ConfigRepository.story.get("chapters", []):
		var chapter_id := str(chapter.get("id", ""))
		var reward_total := 0
		var claimed_total := 0
		for node in chapter.get("nodes", []):
			if str(node.get("type", "")) == "reward":
				reward_total += 1
				if GameSession.has_claimed_story_reward(str(node.get("id", ""))):
					claimed_total += 1
		var chapter_badge := "[%d/%d]" % [claimed_total, reward_total]
		var button := Button.new()
		button.text = "%s %s" % [chapter_badge, str(chapter.get("name", chapter_id))]
		button.icon = IconLoader.get_icon("story_marker")
		UITheme.apply_accent_button(button, claimed_total == reward_total and reward_total > 0)
		button.pressed.connect(_show_chapter.bind(chapter_id))
		chapter_list.add_child(button)
	if ConfigRepository.story.get("chapters", []).size() > 0:
		_show_chapter(str(ConfigRepository.story.get("chapters", [])[0].get("id", "")))

func _show_chapter(chapter_id: String) -> void:
	for child in node_list.get_children():
		child.queue_free()
	for chapter in ConfigRepository.story.get("chapters", []):
		if str(chapter.get("id", "")) != chapter_id:
			continue
		info_label.text = "[b]%s[/b]\n\nВыбери узел главы." % str(chapter.get("name", chapter_id))
		for node in chapter.get("nodes", []):
			var node_id := str(node.get("id", ""))
			var node_type := str(node.get("type", "node"))
			var claimed := node_type == "reward" and GameSession.has_claimed_story_reward(node_id)
			var badge := _node_badge(node_type, claimed)
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var border := UITheme.COLOR_GOLD_DARK if node_type == "reward" else UITheme.COLOR_JADE_DARK
			UITheme.apply_card(card, border)
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", 12)
			card.add_child(row)
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(44, 44)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture = _node_icon(node_type)
			var label := Label.new()
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.text = "%s %s" % [badge, str(node.get("title", "Узел"))]
			var action := Button.new()
			action.text = "Получено" if claimed else "Открыть"
			UITheme.apply_accent_button(action, node_type == "reward")
			action.disabled = claimed
			action.pressed.connect(_open_node.bind(node, chapter_id))
			row.add_child(icon)
			row.add_child(label)
			row.add_child(action)
			node_list.add_child(card)
		return

func _node_badge(node_type: String, claimed: bool) -> String:
	if node_type == "reward":
		return "[ЗАБРАНО]" if claimed else "[НАГРАДА]"
	if node_type == "battle":
		return "[БОЙ]"
	return "[СЮЖЕТ]"

func _node_icon(node_type: String) -> Texture2D:
	match node_type:
		"reward":
			return IconLoader.get_currency_icon("jade")
		"battle":
			return IconLoader.get_skill_icon("azure_slash")
		_:
			return IconLoader.get_icon("story_marker")

func _chapter_index(chapter_id: String) -> int:
	var chapters := ConfigRepository.story.get("chapters", [])
	for i in range(chapters.size()):
		if str(chapters[i].get("id", "")) == chapter_id:
			return i + 1
	return 1

func _open_node(node: Dictionary, chapter_id: String) -> void:
	var node_type := str(node.get("type", "story"))
	if node_type == "battle":
		GameSession.set_battle_context({
			"source": "story",
			"chapter_id": chapter_id,
			"chapter_index": _chapter_index(chapter_id),
			"node_id": str(node.get("id", "")),
			"enemy_name": str(node.get("title", "Страж главы"))
		})
		SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")
		return
	if node_type == "reward":
		_claim_reward_node(node)
		return
	info_label.text = "[b]%s[/b]\n\n%s" % [str(node.get("title", "Узел")), _node_description(node_type)]

func _claim_reward_node(node: Dictionary) -> void:
	var node_id := str(node.get("id", ""))
	if GameSession.has_claimed_story_reward(node_id):
		info_label.text = "[b]%s[/b]\n\nНаграда уже получена." % str(node.get("title", "Награда"))
		return
	var rewards := node.get("rewards", {})
	for currency_id in rewards.keys():
		PlayerState.add_currency(str(currency_id), int(rewards[currency_id]))
	GameSession.mark_story_reward_claimed(node_id)
	info_label.text = "[b]%s[/b]\n\nПолучено:\n%s" % [str(node.get("title", "Награда")), _format_rewards(rewards)]
	_refresh_chapters()

func _format_rewards(rewards: Dictionary) -> String:
	var lines: Array[String] = []
	for currency_id in rewards.keys():
		lines.append("• %s: %s" % [str(currency_id), str(rewards[currency_id])])
	return "\n".join(lines)

func _node_description(node_type: String) -> String:
	match node_type:
		"story":
			return "Сюжетная сцена и диалог будут следующим шагом."
		"reward":
			return "Узел награды и выдача ресурсов будут следующим шагом."
		_:
			return "Неизвестный узел."

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
