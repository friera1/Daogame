extends Control

@onready var list_container: VBoxContainer = %ItemList

func _ready() -> void:
	for child in list_container.get_children():
		child.queue_free()

	for entry in PlayerState.get_inventory():
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = "%s x%s" % [str(entry.get("item_id", "item")), str(entry.get("quantity", 1))]

		var rarity_label := Label.new()
		rarity_label.text = str(entry.get("rarity", "common"))

		var lock_label := Label.new()
		lock_label.text = "🔒" if bool(entry.get("locked", false)) else ""

		row.add_child(name_label)
		row.add_child(rarity_label)
		row.add_child(lock_label)
		list_container.add_child(row)

func _on_back_pressed() -> void:
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
