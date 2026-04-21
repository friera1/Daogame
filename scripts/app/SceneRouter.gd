extends Node

var current_scene: Node = null

func _ready() -> void:
	pass

func goto_scene(scene_path: String) -> void:
	call_deferred("_deferred_goto_scene", scene_path)

func _deferred_goto_scene(scene_path: String) -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()

	var packed := load(scene_path)
	if packed == null:
		push_error("Scene not found: %s" % scene_path)
		return

	current_scene = packed.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
