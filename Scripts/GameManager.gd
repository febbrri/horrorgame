extends Node

func trigger_ending(result: String) -> void:
	if result == "escape":
		SceneTransition.load_scene(
			load("res://Scenes/Levels/Ending_Escape.tscn")
		)
	elif result == "caught":
		SceneTransition.load_scene(
			load("res://Scenes/Levels/Ending_Caught.tscn")
		)
