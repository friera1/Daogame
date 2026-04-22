extends Control

const IconLoader = preload("res://scripts/ui/IconLoader.gd")

@onready var chapter_list: VBoxContainer = %ChapterList
@onready var node_list: VBoxContainer = %NodeList
@onready var info_label: RichTextLabel = %InfoLabel

func _ready() -> void:
	UITheme.apply_lobby_style(self)
	_refresh_chapters()

func _is_battle_node(node_type: String) -> bool:
	return node_type == "battle" or node_type == "elite_battle" or node_type == "boss_battle"

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
		var unlocked := GameSession.is_story_chapter_unlocked(chapter_id)
		var chapter_badge := "[LOCK]" if not unlocked else "[%d/%d]" % [claimed_total, reward_total]
		var button := Button.new()
		button.text = "%s %s" % [chapter_badge, str(chapter.get("name", chapter_id))]
		button.icon = IconLoader.get_icon("story_marker")
		UITheme.apply_accent_button(button, unlocked and claimed_total == reward_total and reward_total > 0)
		button.disabled = not unlocked
		button.pressed.connect(_show_chapter.bind(chapter_id))
		chapter_list.add_child(button)
	for chapter in ConfigRepository.story.get("chapters", []):
		var chapter_id := str(chapter.get("id", ""))
		if GameSession.is_story_chapter_unlocked(chapter_id):
			_show_chapter(chapter_id)
			break

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
			var battle_done := _is_battle_node(node_type) and GameSession.has_completed_story_battle(node_id)
			var stars := PlayerState.get_story_battle_stars(node_id) if _is_battle_node(node_type) else 0
			var badge := _node_badge(node_type, claimed, battle_done, stars)
			var card := PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var border := UITheme.COLOR_GOLD_DARK if node_type == "reward" else UITheme.COLOR_JADE_DARK
			if node_type == "elite_battle":
				border = UITheme.COLOR_GOLD
			elif node_type == "boss_battle":
				border = UITheme.COLOR_WARNING
			elif battle_done:
				border = UITheme.COLOR_SUCCESS
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
			var action_box := HBoxContainer.new()
			action_box.add_theme_constant_override("separation", 8)
			var action := Button.new()
			action.text = _node_action_text(node_type, claimed, battle_done)
			UITheme.apply_accent_button(action, node_type == "reward" or battle_done or _is_battle_node(node_type))
			action.disabled = claimed or (battle_done and not _is_battle_node(node_type))
			action.pressed.connect(_open_node.bind(node, chapter_id))
			action_box.add_child(action)
			if _is_battle_node(node_type) and battle_done:
				var sweep_button := Button.new()
				sweep_button.text = "Sweep"
				sweep_button.icon = IconLoader.get_currency_icon("bound_spirit_stone")
				UITheme.apply_accent_button(sweep_button, true)
				sweep_button.pressed.connect(_sweep_node.bind(node, chapter_id))
				action_box.add_child(sweep_button)
				var multi_button := Button.new()
				multi_button.text = "x3"
				multi_button.icon = IconLoader.get_currency_icon("jade")
				UITheme.apply_accent_button(multi_button, false)
				multi_button.pressed.connect(_multi_sweep_node.bind(node, chapter_id, 3))
				action_box.add_child(multi_button)
				var auto_button := Button.new()
				auto_button.text = "Auto"
				auto_button.icon = IconLoader.get_skill_icon("azure_slash")
				UITheme.apply_accent_button(auto_button, false)
				auto_button.pressed.connect(_auto_farm_node.bind(node, chapter_id))
				action_box.add_child(auto_button)
			row.add_child(icon)
			row.add_child(label)
			row.add_child(action_box)
			node_list.add_child(card)
		return

func _stars_text(stars: int) -> String:
	if stars <= 0:
		return ""
	return "%s%s" % ["★".repeat(stars), "☆".repeat(3 - stars)]

func _node_badge(node_type: String, claimed: bool, battle_done: bool, stars: int = 0) -> String:
	if node_type == "reward":
		return "[ЗАБРАНО]" if claimed else "[НАГРАДА]"
	if node_type == "elite_battle":
		return "[ЭЛИТА %s]" % _stars_text(stars) if battle_done else "[ЭЛИТА]"
	if node_type == "boss_battle":
		return "[БОСС %s]" % _stars_text(stars) if battle_done else "[БОСС]"
	if node_type == "battle":
		return "[ПРОЙДЕНО %s]" % _stars_text(stars) if battle_done else "[БОЙ]"
	return "[СЮЖЕТ]"

func _node_action_text(node_type: String, claimed: bool, battle_done: bool) -> String:
	if node_type == "reward":
		return "Получено" if claimed else "Открыть"
	if _is_battle_node(node_type):
		return "Повтор" if battle_done else "В бой"
	return "Открыть"

func _node_icon(node_type: String) -> Texture2D:
	match node_type:
		"reward":
			return IconLoader.get_currency_icon("jade")
		"elite_battle":
			return IconLoader.get_item_icon("breakthrough_stone")
		"boss_battle":
			return IconLoader.get_currency_icon("spirit_stone")
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
	if _is_battle_node(node_type):
		GameSession.set_battle_context({
			"source": "story",
			"chapter_id": chapter_id,
			"chapter_index": _chapter_index(chapter_id),
			"node_id": str(node.get("id", "")),
			"node_type": node_type,
			"enemy_name": str(node.get("title", "Страж главы"))
		})
		SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")
		return
	if node_type == "reward":
		_claim_reward_node(node)
		return
	info_label.text = "[b]%s[/b]\n\n%s" % [str(node.get("title", "Узел")), _node_description(node_type)]

func _queue_story_sweep(action_type: String, node: Dictionary, chapter_id: String, result: Dictionary) -> void:
	OnlineSyncService.queue_action(action_type, {
		"chapter_id": chapter_id,
		"node_id": str(node.get("id", "")),
		"node_type": str(node.get("type", "battle")),
		"chapter_index": _chapter_index(chapter_id),
		"enemy_name": str(node.get("title", "Страж главы")),
		"stamina_spent": int(result.get("stamina_spent", 0)),
		"runs": int(result.get("runs", 1)),
		"stars": int(result.get("stars", 1)),
		"rewards": result.get("rewards", {})
	})

func _sweep_node(node: Dictionary, chapter_id: String) -> void:
	var node_type := str(node.get("type", "battle"))
	var result := GameSession.perform_story_sweep(chapter_id, str(node.get("id", "")), _chapter_index(chapter_id), str(node.get("title", "Страж главы")), node_type)
	if not bool(result.get("ok", false)):
		info_label.text = "[b]%s[/b]\n\n%s" % [str(node.get("title", "Узел")), str(result.get("text", "Sweep недоступен"))]
		return
	_queue_story_sweep("story_sweep", node, chapter_id, result)
	info_label.text = "[b]%s[/b]\n\nБыстрый проход выполнен за %d энергии.\nЗвёзды узла: %s\n\nПолучено:\n%s" % [str(node.get("title", "Узел")), int(result.get("stamina_spent", 0)), _stars_text(int(result.get("stars", 1))), _format_sweep_rewards(result.get("rewards", {}))]
	_refresh_chapters()

func _multi_sweep_node(node: Dictionary, chapter_id: String, runs: int) -> void:
	var node_type := str(node.get("type", "battle"))
	var result := GameSession.perform_multi_story_sweep(chapter_id, str(node.get("id", "")), _chapter_index(chapter_id), str(node.get("title", "Страж главы")), runs, node_type)
	if not bool(result.get("ok", false)):
		info_label.text = "[b]%s[/b]\n\n%s" % [str(node.get("title", "Узел")), str(result.get("text", "Multi-sweep недоступен"))]
		return
	_queue_story_sweep("story_multi_sweep", node, chapter_id, result)
	info_label.text = "[b]%s[/b]\n\nСерия x%d выполнена за %d энергии.\nЗвёзды узла: %s\n\nПолучено:\n%s" % [str(node.get("title", "Узел")), int(result.get("runs", runs)), int(result.get("stamina_spent", 0)), _stars_text(int(result.get("stars", 1))), _format_sweep_rewards(result.get("rewards", {}))]
	_refresh_chapters()

func _auto_farm_node(node: Dictionary, chapter_id: String) -> void:
	var node_type := str(node.get("type", "battle"))
	var result := GameSession.perform_story_auto_farm(chapter_id, str(node.get("id", "")), _chapter_index(chapter_id), str(node.get("title", "Страж главы")), node_type)
	if not bool(result.get("ok", false)):
		info_label.text = "[b]%s[/b]\n\n%s" % [str(node.get("title", "Узел")), str(result.get("text", "Auto-farm недоступен"))]
		return
	_queue_story_sweep("story_auto_farm", node, chapter_id, result)
	info_label.text = "[b]%s[/b]\n\nАвтофарм x%d выполнен за %d энергии.\nЗвёзды узла: %s\n\nПолучено:\n%s" % [str(node.get("title", "Узел")), int(result.get("runs", 1)), int(result.get("stamina_spent", 0)), _stars_text(int(result.get("stars", 1))), _format_sweep_rewards(result.get("rewards", {}))]
	_refresh_chapters()

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

func _format_sweep_rewards(rewards: Dictionary) -> String:
	var lines: Array[String] = ["• gold: %s" % str(rewards.get("gold", 0)), "• qi_essence: %s" % str(rewards.get("qi_essence", 0)), "• spirit_stone: %s" % str(rewards.get("spirit_stone", 0))]
	for item in rewards.get("items", []):
		lines.append("• %s x%s" % [ConfigRepository.get_item_name(str(item.get("id", ""))), str(item.get("quantity", 1))])
	return "\n".join(lines)

func _node_description(node_type: String) -> String:
	match node_type:
		"story":
			return "Сюжетная сцена и диалог будут следующим шагом."
		"reward":
			return "Узел награды и выдача ресурсов будут следующим шагом."
		"elite_battle":
			return "Элитный узел: выше цена входа, усиленные трофеи и сложность."
		"boss_battle":
			return "Босс-узел: максимальная награда главы, тяжёлый бой и редкие материалы."
		_:
			return "Неизвестный узел."

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
