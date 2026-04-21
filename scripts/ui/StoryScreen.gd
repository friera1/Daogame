extends Control

@onready var chapter_list: VBoxContainer = %ChapterList
@onready var node_list: VBoxContainer = %NodeList
@onready var info_label: RichTextLabel = %InfoLabel

func _ready() -> void:
	_refresh_chapters()

func _refresh_chapters() -> void:
	for child in chapter_list.get_children():
		child.queue_free()
	for child in node_list.get_children():
		child.queue_free()
	for chapter in ConfigRepository.story.get("chapters", []):
		var chapter_id := str(chapter.get("id", ""))
		var button := Button.new()
		button.text = str(chapter.get("name", chapter_id))
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
			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var label := Label.new()
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.text = "%s · %s" % [str(node.get("type", "node")), str(node.get("title", "Узел"))]
			var action := Button.new()
			action.text = "Открыть"
			action.pressed.connect(_open_node.bind(node))
			row.add_child(label)
			row.add_child(action)
			node_list.add_child(row)
		return

func _open_node(node: Dictionary) -> void:
	var node_type := str(node.get("type", "story"))
	if node_type == "battle":
		SceneRouter.goto_scene("res://scenes/battle/BattleScreen.tscn")
		return
	info_label.text = "[b]%s[/b]\n\n%s" % [str(node.get("title", "Узел")), _node_description(node_type)]

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
