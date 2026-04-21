extends Control

func _ready() -> void:
	GameSession.initialize()
	await get_tree().process_frame
	SceneRouter.goto_scene("res://scenes/lobby/LobbyScreen.tscn")
